import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/notification_service.dart';
import '../../shared/widgets/soft_card.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _notificationService = NotificationService();
  
  bool _inactivityReminders = true;
  bool _dailyGoalReminders = true;
  bool _streakProtection = true;
  bool _morningMotivation = true;
  bool _eveningReview = true;
  bool _friendNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Settings are already loaded in notification service
    // This is just for display
  }

  Future<void> _updateSetting(String key, bool value) async {
    await _notificationService.setNotificationSetting(key, value);
    setState(() {
      switch (key) {
        case 'inactivity_reminders':
          _inactivityReminders = value;
          break;
        case 'daily_goal_reminders':
          _dailyGoalReminders = value;
          break;
        case 'streak_protection':
          _streakProtection = value;
          break;
        case 'morning_motivation':
          _morningMotivation = value;
          break;
        case 'evening_review':
          _eveningReview = value;
          break;
      }
    });

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Notification enabled' : 'Notification disabled'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Settings',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            SoftCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.accentBlue],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stay Motivated',
                          style: TextStyle(
                            color: AppColors.foreground,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Customize your reminders',
                          style: TextStyle(
                            color: AppColors.foreground.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Daily Notifications Section
            Text(
              'Daily Reminders',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildNotificationTile(
              title: 'Morning Motivation',
              subtitle: 'Daily inspiration at 8:00 AM',
              icon: Icons.wb_sunny,
              iconColor: AppColors.accent,
              value: _morningMotivation,
              onChanged: (val) => _updateSetting('morning_motivation', val),
            ),
            const SizedBox(height: 8),
            
            _buildNotificationTile(
              title: 'Daily Goal Reminder',
              subtitle: 'Check your progress at 12:00 PM',
              icon: Icons.flag,
              iconColor: AppColors.primary,
              value: _dailyGoalReminders,
              onChanged: (val) => _updateSetting('daily_goal_reminders', val),
            ),
            const SizedBox(height: 8),
            
            _buildNotificationTile(
              title: 'Evening Review',
              subtitle: 'Reflect on your day at 8:00 PM',
              icon: Icons.nightlight_round,
              iconColor: AppColors.accentBlue,
              value: _eveningReview,
              onChanged: (val) => _updateSetting('evening_review', val),
            ),
            const SizedBox(height: 24),

            // Smart Notifications Section
            Text(
              'Smart Reminders',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildNotificationTile(
              title: 'Inactivity Reminders',
              subtitle: 'Nudge you if app not opened by noon, then hourly',
              icon: Icons.motion_photos_on,
              iconColor: AppColors.accentPink,
              value: _inactivityReminders,
              onChanged: (val) => _updateSetting('inactivity_reminders', val),
            ),
            const SizedBox(height: 8),
            
            _buildNotificationTile(
              title: 'Streak Protection',
              subtitle: 'Remind you at 10:00 PM to maintain streak',
              icon: Icons.local_fire_department,
              iconColor: AppColors.secondary,
              value: _streakProtection,
              onChanged: (val) => _updateSetting('streak_protection', val),
            ),
            const SizedBox(height: 24),

            // Info Card
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.accentBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Notifications help you stay consistent and reach your goals. You can customize them anytime.',
                      style: TextStyle(
                        color: AppColors.foreground.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.foreground.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
