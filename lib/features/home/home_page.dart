import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/settings_button.dart';
import '../../shared/widgets/soft_card.dart';
import 'widgets/friends_section.dart';
import 'widgets/progress_graph.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Refresh data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).refreshUserData();
    });
  }

  String _getCheerMessage(int todayFocus) {
    if (todayFocus > 120) return "Amazing focus today! 🌟";
    if (todayFocus > 60) return "Great progress! Keep it up! 💪";
    if (todayFocus > 0) return "You're doing well! 🎯";
    return "Ready to start your day? ✨";
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxWidth: Responsive.getMaxContentWidth(context)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.background,
                AppColors.background.withValues(alpha: 0.95),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.getPadding(context)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.foreground.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: AppColors.foreground.withValues(alpha: 0.6),
                        size: Responsive.getIconSize(context, 20),
                      ),
                    ),
                  ),
                ),
                
                // App Logo
                Container(
                  width: Responsive.getIconSize(context, 80),
                  height: Responsive.getIconSize(context, 80),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      'https://qtrypzzcjebvfcihiynt.supabase.co/storage/v1/object/public/base44-prod/public/69517e4e0d5abe0725ad05d1/df6fe7952_logo.PNG',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primary,
                        child: const Icon(Icons.track_changes, color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.getSpacing(context, 16)),
                
                // App Name
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.primary, AppColors.accentBlue, AppColors.accentPink],
                  ).createShader(bounds),
                  child: Text(
                    'AN Life Tracker',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, 28),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                SizedBox(height: Responsive.getSpacing(context, 8)),
                
                // Tagline
                Text(
                  'Track • Focus • Achieve',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, 14),
                    color: AppColors.foreground.withValues(alpha: 0.6),
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: Responsive.getSpacing(context, 24)),
                
                // Built with love section
                Container(
                  padding: EdgeInsets.all(Responsive.getSpacing(context, 16)),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Built with',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, 12),
                          color: AppColors.foreground.withValues(alpha: 0.6),
                        ),
                      ),
                      SizedBox(height: Responsive.getSpacing(context, 8)),
                      Text(
                        '❤️ Love  •  🤗 Care  •  ☕ Coffee',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, 16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.getSpacing(context, 20)),
                
                // Creators section
                Text(
                  '✨ Created By ✨',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, 12),
                    color: AppColors.foreground.withValues(alpha: 0.6),
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: Responsive.getSpacing(context, 12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCreatorChip(context, '👨‍💻', 'Aditya Pandey'),
                    SizedBox(width: Responsive.getSpacing(context, 12)),
                    _buildCreatorChip(context, '👩‍💻', 'Niharika Pandey'),
                  ],
                ),
                SizedBox(height: Responsive.getSpacing(context, 24)),
                
                // Features section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '🚀 Features',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                SizedBox(height: Responsive.getSpacing(context, 12)),
                _buildFeatureItem(context, '🎯', 'Focus Timer', 'Track your study sessions with Pomodoro'),
                _buildFeatureItem(context, '🍎', 'Calorie Tracker', 'Monitor your food & burned calories'),
                _buildFeatureItem(context, '👥', 'Friends', 'Connect and compete with friends'),
                _buildFeatureItem(context, '🏆', 'Leaderboard', 'See who\'s on top this week'),
                _buildFeatureItem(context, '🔔', 'Smart Reminders', 'Stay on track with notifications'),
                _buildFeatureItem(context, '📊', 'Progress Analytics', 'Visualize your weekly progress'),
                SizedBox(height: Responsive.getSpacing(context, 16)),
                
                // Version
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, 11),
                    color: AppColors.foreground.withValues(alpha: 0.4),
                  ),
                ),
                SizedBox(height: Responsive.getSpacing(context, 8)),
                Text(
                  '© 2025 AN Life Tracker',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, 11),
                    color: AppColors.foreground.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatorChip(BuildContext context, String emoji, String name) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.getSpacing(context, 12),
        vertical: Responsive.getSpacing(context, 8),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.accentBlue.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: Responsive.getFontSize(context, 16))),
          SizedBox(width: Responsive.getSpacing(context, 6)),
          Text(
            name,
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, 13),
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String emoji, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.getSpacing(context, 10)),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: Responsive.getFontSize(context, 20))),
          SizedBox(width: Responsive.getSpacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, 11),
                    color: AppColors.foreground.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    await Provider.of<AppProvider>(context, listen: false).refreshUserData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final user = provider.user;
        final todayFocus = provider.getTodayFocusMinutes();
        final todayCaloriesBurned = provider.getTodayCaloriesBurned();
        final firstName = user?.fullName.split(' ').first ?? 'Friend';

        final padding = Responsive.getPadding(context);
        final avatarSize = Responsive.getIconSize(context, 64);
        final spacing = Responsive.getSpacing(context, 16);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showAboutDialog(context),
                          child: Container(
                            width: avatarSize,
                            height: avatarSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(avatarSize * 0.25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(avatarSize * 0.25),
                              child: Image.network(
                                'https://qtrypzzcjebvfcihiynt.supabase.co/storage/v1/object/public/base44-prod/public/69517e4e0d5abe0725ad05d1/df6fe7952_logo.PNG',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.primary,
                                  child: Icon(Icons.track_changes, color: Colors.white, size: avatarSize * 0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $firstName! 👋',
                                style: TextStyle(
                                  fontSize: Responsive.getFontSize(context, 24),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.foreground,
                                ),
                              ),
                              Text(
                                _getCheerMessage(todayFocus),
                                style: TextStyle(
                                  fontSize: Responsive.getFontSize(context, 14),
                                  color: AppColors.foreground.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SettingsButton(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Productivity Summary
                    SoftCard(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentBlue.withValues(alpha: 0.2),
                          AppColors.accentPink.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.primary, AppColors.accentBlue],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Today's Productivity",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.foreground,
                                    ),
                                  ),
                                  Text(
                                    "You're making great progress!",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.foreground.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8BBDDD).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.psychology, color: AppColors.primary, size: 24),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${todayFocus ~/ 60}h ${todayFocus % 60}m',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        'Focused',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.foreground.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentPink.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.local_fire_department, color: AppColors.accentPink, size: 24),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$todayCaloriesBurned',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accentPink,
                                        ),
                                      ),
                                      Text(
                                        'Calories Burned',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.foreground.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Progress Graph
                    const ProgressGraph(),
                    const SizedBox(height: 24),

                    // Friends Section
                    FriendsSection(friends: provider.friends),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
