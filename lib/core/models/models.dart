// Export habit tracker models
export 'habit.dart';
export 'habit_log.dart';

class User {
  final String id;
  final String uniqueId; // For friend search
  final String fullName;
  final String email;
  final String? avatarUrl;
  final int dailyFocusGoal;
  final int dailyCalorieGoal;
  final bool notificationsEnabled;
  final bool weeklyReportEnabled;
  final int currentStreak;
  final int longestStreak;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    String? uniqueId,
    this.avatarUrl,
    this.dailyFocusGoal = 180,
    this.dailyCalorieGoal = 2000,
    this.notificationsEnabled = true,
    this.weeklyReportEnabled = true,
    this.currentStreak = 0,
    this.longestStreak = 0,
  }) : uniqueId = uniqueId ?? (id.length >= 8 ? id.substring(0, 8) : id.padRight(8, '0'));
}

class FocusSession {
  final String id;
  final int durationMinutes;
  final List<String> subjectTags;
  final DateTime sessionDate;
  final bool completed;
  final int breakCount;
  final String focusMode;

  FocusSession({
    required this.id,
    required this.durationMinutes,
    required this.subjectTags,
    required this.sessionDate,
    this.completed = false,
    this.breakCount = 0,
    this.focusMode = 'normal',
  });

  // Helper to get the primary subject
  String get subject => subjectTags.isNotEmpty ? subjectTags.first : 'Focus Session';
}

class CalorieEntry {
  final String id;
  final String type; // 'food' or 'burn'
  final String description;
  final int amount;
  final DateTime entryDate;

  CalorieEntry({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.entryDate,
  });
}

class Friend {
  final String id;
  final String name;
  final String avatarUrl;
  final String status; // 'focusing', 'online', 'offline'
  final String? currentActivity;
  final int? focusMinutes;
  final int weeklyFocusHours;
  final int weeklyCaloriesBurned;

  Friend({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.status,
    this.currentActivity,
    this.focusMinutes,
    this.weeklyFocusHours = 0,
    this.weeklyCaloriesBurned = 0,
  });
}

class Notification {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String receiverId;
  final String message;
  final DateTime createdAt;
  final DateTime? readAt;

  Notification({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.receiverId,
    required this.message,
    required this.createdAt,
    this.readAt,
  });

  bool get isRead => readAt != null;
}
