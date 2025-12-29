import 'dart:async';
import 'connectivity_service.dart';
import 'local_database_service.dart';
import 'supabase_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _connectivityService = ConnectivityService();
  final _localDb = LocalDatabaseService();
  final _supabase = SupabaseService();

  bool _isSyncing = false;
  StreamSubscription? _connectivitySubscription;

  Future<void> initialize() async {
    print('🚀 Initializing SyncService...');
    
    // Initialize local database first
    await _localDb.initialize();
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.connectionStatusStream.listen((isConnected) {
      if (isConnected && !_isSyncing) {
        print('🔄 Connection restored - starting sync...');
        syncAllData();
      }
    });

    // Initial sync if connected
    if (_connectivityService.isConnected) {
      print('✅ Connected - starting initial sync...');
      syncAllData();
    } else {
      print('📴 Offline - will sync when connection is available');
    }
  }

  Future<void> syncAllData() async {
    if (_isSyncing) return;
    if (!_connectivityService.isConnected) {
      print('📴 Offline - skipping sync');
      return;
    }
    if (!_supabase.isAuthenticated) {
      print('🔒 Not authenticated - skipping sync');
      return;
    }

    _isSyncing = true;
    print('🔄 Starting sync...');

    try {
      // Sync deletions first
      await _syncDeletedItems();
      
      // Sync focus sessions
      await _syncFocusSessions();
      
      // Sync calorie entries
      await _syncCalorieEntries();
      
      print('✅ Sync completed successfully');
    } catch (e) {
      print('❌ Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncFocusSessions() async {
    try {
      final unsyncedSessions = await _localDb.getUnsyncedFocusSessions();
      
      for (final session in unsyncedSessions) {
        try {
          // Try with all fields first
          await _supabase.addFocusSession({
            'id': session['id'],
            'duration_minutes': session['duration_minutes'],
            'subject_tags': session['subject_tags'],
            'session_date': session['session_date'],
            'completed': session['completed'],
            'focus_mode': session['focus_mode'] ?? 'normal',
            'break_count': session['break_count'] ?? 0,
          });
          
          await _localDb.markFocusSessionSynced(session['id'] as String);
          print('✓ Synced focus session: ${session['id']}');
        } catch (e) {
          // If it fails due to missing columns, try without extra fields
          if (e.toString().contains('break_count') || e.toString().contains('focus_mode')) {
            try {
              await _supabase.addFocusSessionBasic({
                'id': session['id'],
                'duration_minutes': session['duration_minutes'],
                'subject_tags': session['subject_tags'],
                'session_date': session['session_date'],
                'completed': session['completed'],
              });
              await _localDb.markFocusSessionSynced(session['id'] as String);
              print('✓ Synced focus session (basic): ${session['id']}');
            } catch (e2) {
              print('✗ Failed to sync focus session ${session['id']}: $e2');
            }
          } else {
            print('✗ Failed to sync focus session ${session['id']}: $e');
          }
        }
      }
    } catch (e) {
      print('Error syncing focus sessions: $e');
    }
  }

  Future<void> _syncCalorieEntries() async {
    try {
      final unsyncedEntries = await _localDb.getUnsyncedCalorieEntries();
      
      for (final entry in unsyncedEntries) {
        try {
          await _supabase.addCalorieEntry({
            'id': entry['id'],
            'type': entry['type'],
            'description': entry['description'],
            'amount': entry['amount'],
            'entry_date': entry['entry_date'],
          });
          
          await _localDb.markCalorieEntrySynced(entry['id'] as String);
          print('✓ Synced calorie entry: ${entry['id']}');
        } catch (e) {
          print('✗ Failed to sync calorie entry ${entry['id']}: $e');
        }
      }
    } catch (e) {
      print('Error syncing calorie entries: $e');
    }
  }

  Future<void> _syncDeletedItems() async {
    try {
      final deletedItems = await _localDb.getUnsyncedDeletedItems();
      
      for (final item in deletedItems) {
        try {
          if (item['item_type'] == 'calorie_entry') {
            await _supabase.deleteCalorieEntry(item['item_id'] as String);
          }
          
          await _localDb.markDeletedItemSynced(item['id'] as String);
          print('✓ Synced deletion: ${item['item_type']} ${item['item_id']}');
        } catch (e) {
          print('✗ Failed to sync deletion ${item['id']}: $e');
        }
      }
    } catch (e) {
      print('Error syncing deleted items: $e');
    }
  }

  // Add focus session (works offline)
  Future<void> addFocusSession(Map<String, dynamic> session) async {
    print('💾 Saving focus session locally...');
    // Always save locally first
    await _localDb.insertFocusSession(session);
    print('✅ Focus session saved locally');

    // Try to sync immediately if online
    if (_connectivityService.isConnected && _supabase.isAuthenticated) {
      print('☁️ Attempting to sync to cloud...');
      try {
        await _supabase.addFocusSession(session);
        await _localDb.markFocusSessionSynced(session['id'] as String);
        print('✅ Focus session synced to cloud');
      } catch (e) {
        print('⚠️ Cloud sync failed, will retry later: $e');
      }
    } else {
      print('📴 Offline or not authenticated - will sync later');
    }
  }

  // Add calorie entry (works offline)
  Future<void> addCalorieEntry(Map<String, dynamic> entry) async {
    print('💾 Saving calorie entry locally...');
    // Always save locally first
    await _localDb.insertCalorieEntry(entry);
    print('✅ Calorie entry saved locally');

    // Try to sync immediately if online
    if (_connectivityService.isConnected && _supabase.isAuthenticated) {
      print('☁️ Attempting to sync to cloud...');
      try {
        await _supabase.addCalorieEntry(entry);
        await _localDb.markCalorieEntrySynced(entry['id'] as String);
        print('✅ Calorie entry synced to cloud');
      } catch (e) {
        print('⚠️ Cloud sync failed, will retry later: $e');
      }
    } else {
      print('📴 Offline or not authenticated - will sync later');
    }
  }

  // Delete calorie entry (works offline)
  Future<void> deleteCalorieEntry(String id) async {
    // Delete locally
    await _localDb.deleteCalorieEntry(id);
    await _localDb.markItemDeleted('calorie_entry', id);
    print('💾 Calorie entry deleted locally');

    // Try to sync deletion if online
    if (_connectivityService.isConnected && _supabase.isAuthenticated) {
      try {
        await _supabase.deleteCalorieEntry(id);
        print('☁️ Deletion synced to cloud');
      } catch (e) {
        print('⚠️ Will sync deletion later: $e');
      }
    }
  }

  // Delete focus session (works offline)
  Future<void> deleteFocusSession(String id) async {
    // Delete locally
    await _localDb.deleteFocusSession(id);
    await _localDb.markItemDeleted('focus_session', id);
    print('💾 Focus session deleted locally');

    // Try to sync deletion if online
    if (_connectivityService.isConnected && _supabase.isAuthenticated) {
      try {
        await _supabase.deleteFocusSession(id);
        print('☁️ Deletion synced to cloud');
      } catch (e) {
        print('⚠️ Will sync deletion later: $e');
      }
    }
  }

  // Clear all focus sessions
  Future<void> clearAllFocusSessions() async {
    await _localDb.clearAllFocusSessions();
    print('💾 All focus sessions cleared locally');

    // Try to sync if online
    if (_connectivityService.isConnected && _supabase.isAuthenticated) {
      try {
        await _supabase.clearAllFocusSessions();
        print('☁️ All focus sessions cleared from cloud');
      } catch (e) {
        print('⚠️ Will sync later: $e');
      }
    }
  }

  // Get all focus sessions (from local DB)
  Future<List<Map<String, dynamic>>> getFocusSessions() async {
    return await _localDb.getAllFocusSessions();
  }

  // Get all calorie entries (from local DB)
  Future<List<Map<String, dynamic>>> getCalorieEntries() async {
    return await _localDb.getAllCalorieEntries();
  }

  // Clear all local data (for logout)
  Future<void> clearAllData() async {
    await _localDb.clearAllData();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
