import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Real-time notification service using Supabase Realtime
/// Listens for new notifications and triggers callbacks immediately
class RealtimeNotificationService extends ChangeNotifier {
  static final RealtimeNotificationService _instance = RealtimeNotificationService._internal();
  factory RealtimeNotificationService() => _instance;
  RealtimeNotificationService._internal();

  final _supabase = SupabaseService();
  RealtimeChannel? _channel;
  
  // Callbacks for different notification types
  final List<Function(Map<String, dynamic>)> _onNotificationCallbacks = [];
  final List<Function(Map<String, dynamic>)> _onInviteCallbacks = [];
  
  // Latest notifications cache
  final List<Map<String, dynamic>> _recentNotifications = [];
  List<Map<String, dynamic>> get recentNotifications => List.unmodifiable(_recentNotifications);
  
  // Unread count
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  /// Initialize real-time subscription
  Future<void> initialize() async {
    if (!_supabase.isAuthenticated) {
      print('🔔 Realtime: Not authenticated, skipping');
      return;
    }

    final userId = _supabase.currentUserId;
    if (userId == null) return;

    print('🔔 Realtime: Setting up notification subscription...');

    try {
      // Subscribe to notifications table for current user
      _channel = _supabase.client
          .channel('notifications:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'receiver_id',
              value: userId,
            ),
            callback: (payload) {
              print('🔔 Realtime: New notification received!');
              _handleNewNotification(payload.newRecord);
            },
          )
          .subscribe((status, [error]) {
            print('🔔 Realtime: Subscription status: $status');
            if (error != null) {
              print('🔔 Realtime: Error: $error');
            }
          });

      // Load initial unread count
      await _loadUnreadCount();
      
      print('✅ Realtime: Notification subscription active');
    } catch (e) {
      print('❌ Realtime: Failed to initialize - $e');
    }
  }

  /// Handle incoming notification
  void _handleNewNotification(Map<String, dynamic> notification) {
    print('🔔 New notification: ${notification['message']}');
    
    // Add to recent notifications
    _recentNotifications.insert(0, notification);
    if (_recentNotifications.length > 50) {
      _recentNotifications.removeLast();
    }
    
    // Increment unread count
    _unreadCount++;
    
    // Check if it's a study invite
    final message = notification['message'] as String? ?? '';
    final isInvite = message.contains('invited you to study') || 
                     message.contains('study together') ||
                     message.contains('📚');
    
    // Trigger callbacks
    for (final callback in _onNotificationCallbacks) {
      callback(notification);
    }
    
    // If it's an invite, trigger priority callbacks
    if (isInvite) {
      for (final callback in _onInviteCallbacks) {
        callback(notification);
      }
    }
    
    notifyListeners();
  }

  /// Load unread notification count
  Future<void> _loadUnreadCount() async {
    try {
      final notifications = await _supabase.getUnreadNotifications();
      _unreadCount = notifications.length;
      _recentNotifications.clear();
      _recentNotifications.addAll(notifications);
      notifyListeners();
    } catch (e) {
      print('⚠️ Realtime: Failed to load unread count - $e');
    }
  }

  /// Register callback for all notifications
  void onNotification(Function(Map<String, dynamic>) callback) {
    _onNotificationCallbacks.add(callback);
  }

  /// Register callback for study invites (priority)
  void onStudyInvite(Function(Map<String, dynamic>) callback) {
    _onInviteCallbacks.add(callback);
  }

  /// Remove notification callback
  void removeNotificationCallback(Function(Map<String, dynamic>) callback) {
    _onNotificationCallbacks.remove(callback);
  }

  /// Remove invite callback
  void removeInviteCallback(Function(Map<String, dynamic>) callback) {
    _onInviteCallbacks.remove(callback);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase.markNotificationAsRead(notificationId);
      _unreadCount = (_unreadCount - 1).clamp(0, 999);
      notifyListeners();
    } catch (e) {
      print('⚠️ Realtime: Failed to mark as read - $e');
    }
  }

  /// Send a quick response to an invite
  Future<void> respondToInvite({
    required String senderId,
    required String response,
  }) async {
    try {
      await _supabase.sendNotification(
        receiverId: senderId,
        message: response,
      );
    } catch (e) {
      print('⚠️ Realtime: Failed to send response - $e');
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await _loadUnreadCount();
  }

  /// Cleanup
  Future<void> cleanup() async {
    await _channel?.unsubscribe();
    _channel = null;
    _onNotificationCallbacks.clear();
    _onInviteCallbacks.clear();
    print('🔔 Realtime: Disconnected');
  }

  @override
  void dispose() {
    cleanup();
    super.dispose();
  }
}
