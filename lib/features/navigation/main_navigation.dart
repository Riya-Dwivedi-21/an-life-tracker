import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/home_page.dart';
import '../focus/focus_page.dart';
import '../calories/calories_page.dart';
import '../friends/friends_page.dart';
import '../leaderboard/leaderboard_page.dart';
import '../habits/habits_page.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../core/services/realtime_notification_service.dart';
import '../../shared/widgets/connection_status_banner.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late PageController _pageController;
  final _realtimeService = RealtimeNotificationService();
  bool _isShowingInvite = false;

  final List<Widget> _pages = [
    const HomePage(),
    const FocusPage(),
    const CaloriesPage(),
    const HabitsPage(),
    const FriendsPage(),
    const LeaderboardPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Listen for study invites - show priority popup
    _realtimeService.onStudyInvite(_handleStudyInvite);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _realtimeService.removeInviteCallback(_handleStudyInvite);
    super.dispose();
  }

  /// Handle incoming study invite - show priority popup
  void _handleStudyInvite(Map<String, dynamic> notification) {
    if (_isShowingInvite) return; // Prevent multiple popups
    
    _isShowingInvite = true;
    
    // Extract sender info
    final senderId = notification['sender_id'] as String? ?? '';
    final message = notification['message'] as String? ?? 'invited you to study!';
    final notificationId = notification['id'] as String? ?? '';
    
    // Get sender name from the notification or cache
    String senderName = 'A friend';
    final sender = notification['sender'] as Map<String, dynamic>?;
    if (sender != null) {
      senderName = sender['full_name'] as String? ?? 'A friend';
    }
    
    // Show priority popup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _StudyInvitePopup(
        senderName: senderName,
        message: message,
        onAccept: () async {
          Navigator.of(context).pop();
          _isShowingInvite = false;
          
          // Send acceptance and navigate to focus page
          await _realtimeService.respondToInvite(
            senderId: senderId,
            response: '✅ ${Provider.of<AppProvider>(context, listen: false).user?.fullName ?? 'I'} accepted your study invite! Let\'s focus together! 🎯',
          );
          if (notificationId.isNotEmpty) {
            await _realtimeService.markAsRead(notificationId);
          }
          
          // Navigate to Focus page
          _pageController.jumpToPage(1);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Starting study session with $senderName! 📚'),
                backgroundColor: const Color(0xFF14B8A6),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        onReject: () async {
          Navigator.of(context).pop();
          _isShowingInvite = false;
          
          await _realtimeService.respondToInvite(
            senderId: senderId,
            response: '❌ Sorry, I can\'t study right now. Maybe later!',
          );
          if (notificationId.isNotEmpty) {
            await _realtimeService.markAsRead(notificationId);
          }
        },
        onBusy: () async {
          Navigator.of(context).pop();
          _isShowingInvite = false;
          
          await _realtimeService.respondToInvite(
            senderId: senderId,
            response: '⏰ Currently busy, not focusing right now. Will join you later!',
          );
          if (notificationId.isNotEmpty) {
            await _realtimeService.markAsRead(notificationId);
          }
        },
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    // Refresh data when navigating back to home
    if (index == 0) {
      Provider.of<AppProvider>(context, listen: false).refreshUserData();
    }
  }

  void _onNavItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ConnectionStatusBanner(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const NeverScrollableScrollPhysics(),
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.psychology_rounded, 'Focus'),
                _buildNavItem(2, Icons.apple_rounded, 'Nutrition'),
                _buildNavItem(3, Icons.check_circle_rounded, 'Habits'),
                _buildNavItem(4, Icons.people_rounded, 'Friends'),
                _buildNavItem(5, Icons.leaderboard_rounded, 'Leaderboard'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    // Custom colors for each tab
    Color iconColor;
    Color backgroundColor;
    
    if (index == 1 && isSelected) {
      // Focus - Lavender
      iconColor = const Color(0xFFB4A7D6);
      backgroundColor = const Color(0xFFB4A7D6).withValues(alpha: 0.1);
    } else if (index == 2 && isSelected) {
      // Nutrition - Pink
      iconColor = Colors.pink.shade300;
      backgroundColor = Colors.pink.shade50;
    } else if (index == 3 && isSelected) {
      // Habits - Orangeish Yellow
      iconColor = const Color(0xFFFFB74D);
      backgroundColor = const Color(0xFFFFB74D).withValues(alpha: 0.1);
    } else if (index == 4 && isSelected) {
      // Friends - Green
      iconColor = const Color(0xFF4ADE80);
      backgroundColor = const Color(0xFF4ADE80).withValues(alpha: 0.1);
    } else if (isSelected) {
      // Other tabs - Primary color
      iconColor = AppColors.primary;
      backgroundColor = AppColors.primary.withValues(alpha: 0.1);
    } else {
      // Unselected
      iconColor = AppColors.foreground.withValues(alpha: 0.4);
      backgroundColor = Colors.transparent;
    }
    
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.foreground.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Priority Study Invite Popup - Shows immediately when invited
class _StudyInvitePopup extends StatelessWidget {
  final String senderName;
  final String message;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onBusy;

  const _StudyInvitePopup({
    required this.senderName,
    required this.message,
    required this.onAccept,
    required this.onReject,
    required this.onBusy,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              '📚 Study Invite!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            
            // Sender info
            Text(
              '$senderName wants to study together!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.foreground.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            
            // Message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Accept button (primary)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Accept & Study',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Busy button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onBusy,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Currently Busy',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Reject button
            TextButton(
              onPressed: onReject,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.foreground.withValues(alpha: 0.5),
              ),
              child: const Text(
                'Not now',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}