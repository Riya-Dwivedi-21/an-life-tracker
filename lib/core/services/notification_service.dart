import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'supabase_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final SupabaseService _supabase = SupabaseService();
  bool _initialized = false;
  Timer? _pollTimer;
  Timer? _usageCheckTimer;
  List<Notification> _friendNotifications = [];
  
  // Notification settings (can be toggled by user)
  bool _inactivityRemindersEnabled = true;
  bool _dailyGoalRemindersEnabled = true;
  bool _streakProtectionEnabled = true;
  bool _morningMotivationEnabled = true;
  bool _eveningReviewEnabled = true;

  List<Notification> get notifications => _friendNotifications;
  List<Notification> get unreadNotifications => _friendNotifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Load friend notifications
    await loadFriendNotifications();
    
    // Start polling for new friend notifications
    _startPolling();
    
    // Load notification settings
    await _loadNotificationSettings();
    
    // Schedule smart notifications
    await _scheduleSmartNotifications();
    
    // Track app open
    await _trackAppOpen();
    
    // Start usage monitoring
    _startUsageMonitoring();

    _initialized = true;
    print('✅ Notification service initialized');
  }

  /// Start polling for new friend notifications
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _pollFriendNotifications();
    });
  }

  /// Poll for new friend notifications
  Future<void> _pollFriendNotifications() async {
    if (!_supabase.isAuthenticated) return;

    try {
      final data = await _supabase.getUnreadNotifications();
      
      final newNotifications = data.map((item) {
        final sender = item['sender'] as Map<String, dynamic>?;
        return Notification(
          id: item['id'] as String,
          senderId: item['sender_id'] as String,
          senderName: sender?['full_name'] as String? ?? 'Unknown',
          senderAvatarUrl: sender?['avatar_url'] as String?,
          receiverId: item['receiver_id'] as String,
          message: item['message'] as String,
          createdAt: DateTime.parse(item['created_at'] as String),
          readAt: item['read_at'] != null ? DateTime.parse(item['read_at'] as String) : null,
        );
      }).toList();

      // Check for new notifications
      final currentIds = _friendNotifications.map((n) => n.id).toSet();
      final actuallyNew = newNotifications.where((n) => !currentIds.contains(n.id)).toList();

      if (actuallyNew.isNotEmpty) {
        // Show local notification for each new one
        for (final notification in actuallyNew) {
          await _showFriendReminderNotification(notification.senderName, notification.message);
        }
        
        // Update the list
        _friendNotifications.insertAll(0, actuallyNew);
        notifyListeners();
        
        print('🔔 Received ${actuallyNew.length} new friend notification(s)');
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Load all friend notifications
  Future<void> loadFriendNotifications() async {
    if (!_supabase.isAuthenticated) return;

    try {
      final data = await _supabase.getAllNotifications();
      
      _friendNotifications = data.map((item) {
        final sender = item['sender'] as Map<String, dynamic>?;
        return Notification(
          id: item['id'] as String,
          senderId: item['sender_id'] as String,
          senderName: sender?['full_name'] as String? ?? 'Unknown',
          senderAvatarUrl: sender?['avatar_url'] as String?,
          receiverId: item['receiver_id'] as String,
          message: item['message'] as String,
          createdAt: DateTime.parse(item['created_at'] as String),
          readAt: item['read_at'] != null ? DateTime.parse(item['read_at'] as String) : null,
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      print('❌ Error loading friend notifications: $e');
    }
  }

  /// Mark friend notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase.markNotificationAsRead(notificationId);
      
      // Update local list
      final index = _friendNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _friendNotifications[index] = Notification(
          id: _friendNotifications[index].id,
          senderId: _friendNotifications[index].senderId,
          senderName: _friendNotifications[index].senderName,
          senderAvatarUrl: _friendNotifications[index].senderAvatarUrl,
          receiverId: _friendNotifications[index].receiverId,
          message: _friendNotifications[index].message,
          createdAt: _friendNotifications[index].createdAt,
          readAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all friend notifications as read
  Future<void> markAllAsRead() async {
    for (final notification in unreadNotifications) {
      await markAsRead(notification.id);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    if (await Permission.notification.isGranted) {
      return true;
    }

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> scheduleDailyReminder() async {
    await _notifications.zonedSchedule(
      0,
      'Time to Focus! 🎯',
      'Ready to boost your productivity? Start a focus session now!',
      _nextInstanceOfNoon(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          channelDescription: 'Daily focus reminders at noon',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfNoon() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      12, // Noon
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> showFriendOnlineNotification(String friendName) async {
    await _notifications.show(
      friendName.hashCode,
      'Friend Online! 👋',
      '$friendName is now online and ready to focus!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'friend_status',
          'Friend Status',
          channelDescription: 'Notifications when friends come online',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _showFriendReminderNotification(String friendName, String message) async {
    await _notifications.show(
      (friendName + message).hashCode,
      '$friendName sent a reminder',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'friend_reminders',
          'Friend Reminders',
          channelDescription: 'Reminders from your friends',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> showStreakResetNotification(int streakCount) async {
    await _notifications.show(
      1,
      '🔥 Streak Broken',
      'Your $streakCount day streak has been reset. Start a new one today!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_updates',
          'Streak Updates',
          channelDescription: 'Notifications about streak changes',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showWeeklyReportNotification() async {
    await _notifications.show(
      2,
      '📊 Weekly Report Ready!',
      'Check your email for your weekly productivity report',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_report',
          'Weekly Reports',
          channelDescription: 'Weekly productivity report notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(0);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // ============================================================================
  // SMART NOTIFICATIONS SYSTEM
  // ============================================================================

  /// Load notification settings from shared preferences
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _inactivityRemindersEnabled = prefs.getBool('inactivity_reminders') ?? true;
      _dailyGoalRemindersEnabled = prefs.getBool('daily_goal_reminders') ?? true;
      _streakProtectionEnabled = prefs.getBool('streak_protection') ?? true;
      _morningMotivationEnabled = prefs.getBool('morning_motivation') ?? true;
      _eveningReviewEnabled = prefs.getBool('evening_review') ?? true;
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  /// Save notification setting
  Future<void> setNotificationSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      
      // Update local state
      switch (key) {
        case 'inactivity_reminders':
          _inactivityRemindersEnabled = value;
          break;
        case 'daily_goal_reminders':
          _dailyGoalRemindersEnabled = value;
          break;
        case 'streak_protection':
          _streakProtectionEnabled = value;
          break;
        case 'morning_motivation':
          _morningMotivationEnabled = value;
          break;
        case 'evening_review':
          _eveningReviewEnabled = value;
          break;
      }
      
      // Reschedule notifications
      await _scheduleSmartNotifications();
    } catch (e) {
      print('Error saving notification setting: $e');
    }
  }

  /// Track when user opens the app
  Future<void> _trackAppOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_app_open', DateTime.now().toIso8601String());
      
      // Cancel pending inactivity notifications since user just opened app
      await _notifications.cancel(1000); // Noon reminder
      await _notifications.cancel(1001); // 1pm reminder
      await _notifications.cancel(1002); // 2pm reminder
      await _notifications.cancel(1003); // 3pm reminder
      await _notifications.cancel(1004); // 4pm reminder
      
      print('📱 App open tracked');
    } catch (e) {
      print('Error tracking app open: $e');
    }
  }

  /// Start monitoring usage patterns
  void _startUsageMonitoring() {
    _usageCheckTimer?.cancel();
    
    // Check every hour if we need to send notifications
    _usageCheckTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkAndScheduleInactivityNotifications();
    });
  }

  /// Schedule all smart notifications
  Future<void> _scheduleSmartNotifications() async {
    // Cancel all scheduled notifications first
    await _cancelSmartNotifications();
    
    // Schedule different types of notifications
    if (_morningMotivationEnabled) {
      await _scheduleMorningMotivation();
    }
    
    if (_dailyGoalRemindersEnabled) {
      await _scheduleDailyGoalReminder();
    }
    
    if (_eveningReviewEnabled) {
      await _scheduleEveningReview();
    }
    
    if (_streakProtectionEnabled) {
      await _scheduleStreakProtection();
    }
    
    print('📅 Smart notifications scheduled');
  }

  /// Cancel all smart notifications
  Future<void> _cancelSmartNotifications() async {
    // Cancel all scheduled notification IDs
    for (int i = 1000; i < 1100; i++) {
      await _notifications.cancel(i);
    }
  }

  /// Check and schedule inactivity notifications
  Future<void> _checkAndScheduleInactivityNotifications() async {
    if (!_inactivityRemindersEnabled) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastOpenStr = prefs.getString('last_app_open');
      
      if (lastOpenStr == null) return;
      
      final lastOpen = DateTime.parse(lastOpenStr);
      final now = DateTime.now();
      final hoursSinceOpen = now.difference(lastOpen).inHours;
      
      // If not opened by noon (12pm)
      if (now.hour >= 12 && lastOpen.day != now.day) {
        await _showInactivityReminder(
          'Time to focus! 🎯',
          'You haven\'t checked in today. Start a focus session now!',
        );
      }
      // If still not opened after 1 hour
      else if (hoursSinceOpen >= 1) {
        await _showInactivityReminder(
          'We miss you! 👋',
          'It\'s been ${hoursSinceOpen}h since your last session. Come back and crush your goals!',
        );
      }
    } catch (e) {
      print('Error checking inactivity: $e');
    }
  }

  /// Show inactivity reminder
  Future<void> _showInactivityReminder(String title, String body) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'inactivity_reminders',
          'Inactivity Reminders',
          channelDescription: 'Reminders when you haven\'t used the app',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Schedule morning motivation (8 AM)
  Future<void> _scheduleMorningMotivation() async {
    final messages = [
      'Good morning! ☀️ Ready to make today count?',
      'Rise and shine! ✨ Your goals are waiting!',
      'New day, new opportunities! 🌅 Let\'s focus!',
      'Good morning, champion! 💪 Time to level up!',
      'Morning! 🌞 Your future self will thank you!',
    ];
    
    final message = messages[DateTime.now().day % messages.length];
    
    final scheduledDate = _nextInstanceOf(8, 0); // 8:00 AM
    
    await _notifications.zonedSchedule(
      1010,
      'Good Morning! ☀️',
      message,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'morning_motivation',
          'Morning Motivation',
          channelDescription: 'Daily morning motivation messages',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule daily goal reminder (12 PM)
  Future<void> _scheduleDailyGoalReminder() async {
    final scheduledDate = _nextInstanceOf(12, 0); // 12:00 PM
    
    await _notifications.zonedSchedule(
      1020,
      'Daily Goal Check! 🎯',
      'How\'s your progress today? Time for a focus session!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_goal_reminders',
          'Daily Goal Reminders',
          channelDescription: 'Reminders about your daily goals',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule evening review (8 PM)
  Future<void> _scheduleEveningReview() async {
    final scheduledDate = _nextInstanceOf(20, 0); // 8:00 PM
    
    await _notifications.zonedSchedule(
      1030,
      'Evening Review 📊',
      'How did today go? Review your progress and plan tomorrow!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'evening_review',
          'Evening Review',
          channelDescription: 'Evening reminders to review your day',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule streak protection (10 PM)
  Future<void> _scheduleStreakProtection() async {
    final scheduledDate = _nextInstanceOf(22, 0); // 10:00 PM
    
    await _notifications.zonedSchedule(
      1040,
      'Streak Alert! 🔥',
      'Don\'t break your streak! Log some activity before midnight!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_protection',
          'Streak Protection',
          channelDescription: 'Reminders to maintain your streak',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Get next instance of specific time
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Show achievement notification
  Future<void> showAchievementNotification(String title, String message) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'achievements',
          'Achievements',
          channelDescription: 'Notifications for milestones and achievements',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Show goal completion notification
  Future<void> showGoalCompletedNotification(String goalName) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🎉 Goal Completed!',
      'Congrats! You completed: $goalName',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_completion',
          'Goal Completion',
          channelDescription: 'Notifications when you complete goals',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          sound: RawResourceAndroidNotificationSound('success'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Show milestone notification
  Future<void> showMilestoneNotification(String milestone) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🏆 Milestone Reached!',
      milestone,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'milestones',
          'Milestones',
          channelDescription: 'Notifications for reaching milestones',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _usageCheckTimer?.cancel();
    super.dispose();
  }
}
