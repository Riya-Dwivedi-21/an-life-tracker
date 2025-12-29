import 'dart:async';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Simple database-based presence service
/// Tracks online status by updating last_seen timestamp
class PresenceService extends ChangeNotifier {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final _supabase = SupabaseService();
  Timer? _heartbeatTimer;
  Timer? _pollTimer;
  
  // Track online users: userId -> presence data
  final Map<String, PresenceState> _onlineUsers = {};
  
  // Current user's status
  String _currentStatus = 'online';
  String? _currentActivity;
  int? _focusMinutes;

  Map<String, PresenceState> get onlineUsers => Map.unmodifiable(_onlineUsers);
  String get currentStatus => _currentStatus;

  /// Initialize the presence service with database polling
  Future<void> initialize() async {
    if (!_supabase.isAuthenticated) {
      print('👤 Presence: Not authenticated, skipping initialization');
      return;
    }

    print('🔌 Presence: Initializing database-based presence...');
    
    try {
      // Update own presence immediately
      await _updateDatabaseStatus();
      
      // Start heartbeat to update own status
      _startHeartbeat();
      
      // Start polling for friend statuses
      _startPolling();
      
      print('✅ Presence: Initialized successfully');
    } catch (e) {
      print('❌ Presence: Failed to initialize - $e');
    }
  }

  /// Poll for online friends every 5 seconds (faster updates)
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _pollOnlineUsers();
    });
    
    // Initial poll
    _pollOnlineUsers();
  }

  /// Poll database for online users
  Future<void> _pollOnlineUsers() async {
    if (!_supabase.isAuthenticated) return;
    
    try {
      // Get all users who were active in the last 20 seconds
      final twentySecondsAgo = DateTime.now().subtract(const Duration(seconds: 20));
      
      // Query without current_activity if column doesn't exist
      final response = await _supabase.client
          .from('profiles')
          .select('id, status, last_seen')
          .gte('last_seen', twentySecondsAgo.toIso8601String());
      
      _onlineUsers.clear();
      
      for (final user in response) {
        final userId = user['id'] as String;
        final status = user['status'] as String? ?? 'offline';
        final lastSeen = DateTime.tryParse(user['last_seen'] as String? ?? '');
        
        // Only consider online if:
        // 1. Status is NOT 'offline' 
        // 2. last_seen is within the last 20 seconds
        if (lastSeen != null && status != 'offline') {
          final secondsAgo = DateTime.now().difference(lastSeen).inSeconds;
          
          // Only consider online if seen in last 20 seconds
          if (secondsAgo < 20) {
            _onlineUsers[userId] = PresenceState(
              userId: userId,
              status: status,
              activity: null, // Column not available yet
              focusMinutes: null,
              onlineAt: lastSeen,
            );
            // Debug log for focusing friends
            if (status == 'focusing') {
              print('🎯 Friend $userId is focusing!');
            }
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Start heartbeat timer to update presence every 5 seconds (faster updates)
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateDatabaseStatus();
    });
  }

  /// Update status in database
  Future<void> _updateDatabaseStatus() async {
    if (!_supabase.isAuthenticated) return;
    
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) return;
      
      // Only update fields that exist in the database
      final updates = <String, dynamic>{
        'status': _currentStatus,
        'last_seen': DateTime.now().toIso8601String(),
      };
      
      // Try to include current_activity if column exists
      final activity = _currentActivity;
      if (activity != null) {
        updates['current_activity'] = activity;
      }
      
      await _supabase.client.from('profiles').update(updates).eq('id', userId);
      
      print('📡 Presence: Updated status - $_currentStatus');
    } catch (e) {
      // Silently fail if column doesn't exist, just update last_seen
      try {
        final userId = _supabase.currentUserId;
        if (userId != null) {
          await _supabase.client.from('profiles').update({
            'status': _currentStatus,
            'last_seen': DateTime.now().toIso8601String(),
          }).eq('id', userId);
        }
      } catch (e2) {
        print('⚠️ Presence: Failed to update status - $e2');
      }
    }
  }

  /// Update current user's status
  Future<void> updateStatus(String status, {String? activity, int? focusMinutes}) async {
    _currentStatus = status;
    _currentActivity = activity;
    _focusMinutes = focusMinutes;
    
    await _updateDatabaseStatus();
    notifyListeners();
  }

  /// Set user as focusing
  Future<void> setFocusing({required String subject, required int minutes}) async {
    await updateStatus('focusing', activity: subject, focusMinutes: minutes);
  }

  /// Set user as online (not focusing)
  Future<void> setOnline() async {
    await updateStatus('online');
  }

  /// Set user as offline
  Future<void> setOffline() async {
    await updateStatus('offline');
  }

  /// Check if a specific user is online
  bool isUserOnline(String userId) {
    return _onlineUsers.containsKey(userId);
  }

  /// Get a user's presence state
  PresenceState? getUserPresence(String userId) {
    return _onlineUsers[userId];
  }

  /// Get status for a friend based on last_seen timestamp
  String getFriendStatus(String friendId, String? lastSeenDate) {
    // Check cached presence first (real-time polling)
    final presence = _onlineUsers[friendId];
    if (presence != null) {
      // Double-check: only return online/focusing if in cache AND recent (20 seconds)
      final onlineAt = presence.onlineAt;
      if (onlineAt != null) {
        final secondsAgo = DateTime.now().difference(onlineAt).inSeconds;
        if (secondsAgo < 20) {
          return presence.status;
        }
      }
    }
    
    // If not in cache, they're definitely offline
    // (cache is populated from database polling every 5 seconds)
    // Only trust last_seen if cache hasn't been populated yet
    if (_onlineUsers.isEmpty && lastSeenDate != null) {
      final lastSeen = DateTime.tryParse(lastSeenDate);
      if (lastSeen != null) {
        final secondsAgo = DateTime.now().difference(lastSeen).inSeconds;
        if (secondsAgo < 20) return 'online';
      }
    }
    
    return 'offline';
  }

  /// Dispose of resources - call this when logging out or closing the app
  Future<void> cleanup() async {
    _heartbeatTimer?.cancel();
    _pollTimer?.cancel();
    
    // Set status to offline before disconnecting
    if (_supabase.isAuthenticated) {
      try {
        final userId = _supabase.currentUserId;
        if (userId != null) {
          await _supabase.client.from('profiles').update({
            'status': 'offline',
            'last_seen': DateTime.now().toIso8601String(),
          }).eq('id', userId);
        }
      } catch (e) {
        print('⚠️ Presence: Failed to set offline status - $e');
      }
    }
    
    _onlineUsers.clear();
    print('🔌 Presence: Disconnected');
  }

  @override
  void dispose() {
    cleanup();
    super.dispose();
  }

  /// Reconnect after being away
  Future<void> reconnect() async {
    await cleanup();
    await initialize();
  }
}

/// Represents a user's presence state
class PresenceState {
  final String userId;
  final String status;
  final String? activity;
  final int? focusMinutes;
  final DateTime? onlineAt;

  PresenceState({
    required this.userId,
    required this.status,
    this.activity,
    this.focusMinutes,
    this.onlineAt,
  });

  bool get isOnline => status == 'online' || status == 'focusing';
  bool get isFocusing => status == 'focusing';
}
