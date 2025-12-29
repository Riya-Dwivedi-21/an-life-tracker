import 'package:hive_flutter/hive_flutter.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static const String focusBox = 'focus_sessions';
  static const String caloriesBox = 'calorie_entries';
  static const String deletedBox = 'deleted_items';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    print('🗄️ Initializing Hive database...');
    await Hive.initFlutter();
    
    // Open boxes
    await Hive.openBox<Map>(focusBox);
    await Hive.openBox<Map>(caloriesBox);
    await Hive.openBox<Map>(deletedBox);
    
    _initialized = true;
    print('✅ Hive database initialized');
  }

  // Focus Sessions - Local Operations
  Future<void> insertFocusSession(Map<String, dynamic> session) async {
    if (!_initialized) await initialize();
    final box = Hive.box<Map>(focusBox);
    
    final data = {
      ...session,
      'synced': false,
    };
    
    await box.put(session['id'], data);
    print('💾 Saved focus session locally: ${session['id']}');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedFocusSessions() async {
    if (!_initialized) await initialize();
    final box = Hive.box<Map>(focusBox);
    
    final unsynced = <Map<String, dynamic>>[];
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && item['synced'] == false) {
        unsynced.add(Map<String, dynamic>.from(item));
      }
    }
    
    return unsynced;
  }

  Future<List<Map<String, dynamic>>> getAllFocusSessions() async {
    if (!_initialized) await initialize();
    final box = Hive.box<Map>(focusBox);
    
    final sessions = <Map<String, dynamic>>[];
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null) {
        sessions.add(Map<String, dynamic>.from(item));
      }
    }
    
    // Sort by session_date DESC
    sessions.sort((a, b) {
      final dateA = DateTime.parse(a['session_date'] ?? '2000-01-01');
      final dateB = DateTime.parse(b['session_date'] ?? '2000-01-01');
      return dateB.compareTo(dateA);
    });
    
    return sessions;
  }

  Future<void> markFocusSessionSynced(String id) async {
    if (!_initialized) await initialize();
    final box = Hive.box<Map>(focusBox);
    
    final item = box.get(id);
    if (item != null) {
      item['synced'] = true;
      await box.put(id, item);
    }
  }

  // Calorie Entries - Local Operations
  Future<void> insertCalorieEntry(Map<String, dynamic> entry) async {
    if (!_initialized) await initialize();
    final box = Hive.box<Map>(caloriesBox);
    
    final data = {
      ...entry,
      'synced': false,
    };
    
    await box.put(entry['id'], data);
    print('💾 Saved calorie entry locally: ${entry['id']}');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedCalorieEntries() async {
    if (!_initialized) await initialize();
    final box = Hive.box<Map>(caloriesBox);
    
    final unsynced = <Map<String, dynamic>>[];
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && item['synced'] == false) {
        unsynced.add(Map<String, dynamic>.from(item));
      }
    }
    
    return unsynced;
  }

  Future<List<Map<String, dynamic>>> getAllCalorieEntries() async {
    if (!_initialized) await initialize();
    final box = Hive.box<Map>(caloriesBox);
    
    final entries = <Map<String, dynamic>>[];
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null) {
        entries.add(Map<String, dynamic>.from(item));
      }
    }
    
    // Sort by entry_date DESC
    entries.sort((a, b) {
      final dateA = DateTime.parse(a['entry_date'] ?? '2000-01-01');
      final dateB = DateTime.parse(b['entry_date'] ?? '2000-01-01');
      return dateB.compareTo(dateA);
    });
    
    return entries;
  }

  Future<void> markCalorieEntrySynced(String id) async {
    if (!_initialized) await initialize();
    final box = Hive.box<Map>(caloriesBox);
    
    final item = box.get(id);
    if (item != null) {
      item['synced'] = true;
      await box.put(id, item);
    }
  }

  Future<void> deleteCalorieEntry(String id) async {
    if (!_initialized) await initialize();
    final box = Hive.box<Map>(caloriesBox);
    await box.delete(id);
    print('🗑️ Deleted calorie entry locally: $id');
  }

  Future<void> deleteFocusSession(String id) async {
    if (!_initialized) await initialize();
    final box = Hive.box<Map>(focusBox);
    await box.delete(id);
    print('🗑️ Deleted focus session locally: $id');
  }

  Future<void> clearAllFocusSessions() async {
    if (!_initialized) await initialize();
    final box = Hive.box<Map>(focusBox);
    await box.clear();
    print('🗑️ Cleared all focus sessions locally');
  }

  // Deleted items tracking
  Future<void> markItemDeleted(String itemType, String itemId) async {
    if (!_initialized) await initialize();
    final box = Hive.box<Map>(deletedBox);
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final data = {
      'id': id,
      'item_type': itemType,
      'item_id': itemId,
      'deleted_at': DateTime.now().toIso8601String(),
      'synced': false,
    };
    
    await box.put(id, data);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedDeletedItems() async {
    if (!_initialized) await initialize();
    final box = Hive.box<Map>(deletedBox);
    
    final unsynced = <Map<String, dynamic>>[];
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && item['synced'] == false) {
        unsynced.add(Map<String, dynamic>.from(item));
      }
    }
    
    return unsynced;
  }

  Future<void> markDeletedItemSynced(String id) async {
    if (!_initialized) await initialize();
    final box = Hive.box<Map>(deletedBox);
    
    final item = box.get(id);
    if (item != null) {
      item['synced'] = true;
      await box.put(id, item);
    }
  }

  // Clear all local data (for logout)
  Future<void> clearAllData() async {
    if (!_initialized) await initialize();
    
    await Hive.box<Map>(focusBox).clear();
    await Hive.box<Map>(caloriesBox).clear();
    await Hive.box<Map>(deletedBox).clear();
    
    print('🗑️ Cleared all local data');
  }
}
