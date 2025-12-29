import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/models.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/settings_button.dart';
import '../../shared/widgets/soft_card.dart';
import 'widgets/add_friend_dialog.dart';
import 'friend_profile_page.dart';
import 'widgets/send_notification_dialog.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  Map<String, dynamic> _getStatusInfo(String status) {
    if (status == 'focusing') {
      return {
        'color': AppColors.primary,
        'label': '🧠 Focusing',
        'bg': AppColors.primary.withValues(alpha: 0.1),
      };
    }
    if (status == 'online') {
      return {
        'color': AppColors.accentGreen,
        'label': '🟢 Online',
        'bg': AppColors.accentGreen.withValues(alpha: 0.1),
      };
    }
    return {
      'color': AppColors.foreground.withValues(alpha: 0.4),
      'label': '⚫ Offline',
      'bg': Colors.black.withValues(alpha: 0.03),
    };
  }

  void _showSendNotificationDialog(BuildContext context, AppProvider provider, Friend friend) {
    showDialog(
      context: context,
      builder: (dialogContext) => SendNotificationDialog(
        friend: friend,
        onNotificationSent: () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Reminder sent to ${friend.name}'),
                backgroundColor: AppColors.accentBlue,
              ),
            );
          }
        },
      ),
    );
  }

  void _showRemoveFriendDialog(BuildContext context, AppProvider provider, String friendId, String friendName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove $friendName from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.foreground.withValues(alpha: 0.6)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await provider.removeFriend(friendId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$friendName removed from friends'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to remove friend: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final friends = provider.friends;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Responsive.getPadding(context)),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: Responsive.getIconSize(context, 48),
                        height: Responsive.getIconSize(context, 48),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accentBlue],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.people, color: Colors.white, size: Responsive.getIconSize(context, 24)),
                      ),
                      SizedBox(width: Responsive.getSpacing(context, 12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Friends',
                              style: TextStyle(fontSize: Responsive.getFontSize(context, 24), fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${friends.length} connections',
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
                  SizedBox(height: Responsive.getSpacing(context, 24)),

                  // Friends List
                  ...friends.asMap().entries.map((entry) {
                    final index = entry.key;
                    final friend = entry.value;
                    final statusInfo = _getStatusInfo(friend.status);

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.only(bottom: Responsive.getSpacing(context, 16)),
                        child: Dismissible(
                          key: Key(friend.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.person_remove, color: Colors.red, size: 28),
                          ),
                          confirmDismiss: (direction) async {
                            _showRemoveFriendDialog(context, provider, friend.id, friend.name);
                            return false; // Don't actually dismiss, dialog handles it
                          },
                          child: GestureDetector(
                            onTap: () {
                              // Navigate to friend profile
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FriendProfilePage(friend: friend),
                                ),
                              );
                            },
                            onLongPress: () => _showRemoveFriendDialog(context, provider, friend.id, friend.name),
                            child: SoftCard(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      // Avatar
                                      Stack(
                                        children: [
                                          Container(
                                            width: Responsive.getIconSize(context, 56),
                                            height: Responsive.getIconSize(context, 56),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: statusInfo['color'] as Color,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.1),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            friend.avatarUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: AppColors.primary.withValues(alpha: 0.2),
                                              child: const Icon(Icons.person),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (friend.status == 'focusing')
                                        Positioned(
                                          bottom: -4,
                                          right: -4,
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.psychology,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          friend.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: Responsive.getFontSize(context, 16),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusInfo['bg'] as Color,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            statusInfo['label'] as String,
                                            style: TextStyle(
                                              fontSize: Responsive.getFontSize(context, 11),
                                              color: statusInfo['color'] as Color,
                                            ),
                                          ),
                                        ),
                                        if (friend.currentActivity != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '${friend.currentActivity} • ${friend.focusMinutes}m',
                                            style: TextStyle(
                                              fontSize: Responsive.getFontSize(context, 12),
                                              color: AppColors.foreground.withValues(alpha: 0.6),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Remove Friend Button
                                  IconButton(
                                    onPressed: () => _showRemoveFriendDialog(context, provider, friend.id, friend.name),
                                    icon: Icon(
                                      Icons.person_remove,
                                      color: Colors.red.withValues(alpha: 0.7),
                                      size: Responsive.getIconSize(context, 20),
                                    ),
                                    tooltip: 'Remove Friend',
                                  ),
                                ],
                              ),
                              SizedBox(height: Responsive.getSpacing(context, 12)),
                              Container(
                                padding: EdgeInsets.only(top: Responsive.getSpacing(context, 12)),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: AppColors.border),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.psychology, color: AppColors.primary, size: Responsive.getIconSize(context, 14)),
                                          SizedBox(width: Responsive.getSpacing(context, 6)),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Weekly Focus',
                                                  style: TextStyle(
                                                    fontSize: Responsive.getFontSize(context, 10),
                                                    color: AppColors.foreground.withValues(alpha: 0.6),
                                                  ),
                                                ),
                                                Text(
                                                  '${friend.weeklyFocusHours}h',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: Responsive.getFontSize(context, 13),
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.local_fire_department, color: AppColors.accentPink, size: Responsive.getIconSize(context, 14)),
                                          SizedBox(width: Responsive.getSpacing(context, 6)),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Calories',
                                                  style: TextStyle(
                                                    fontSize: Responsive.getFontSize(context, 10),
                                                    color: AppColors.foreground.withValues(alpha: 0.6),
                                                  ),
                                                ),
                                                Text(
                                                  '${friend.weeklyCaloriesBurned}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: Responsive.getFontSize(context, 13),
                                                    color: AppColors.accentPink,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: Responsive.getSpacing(context, 10)),
                              // Send Notification Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showSendNotificationDialog(context, provider, friend),
                                  icon: Icon(Icons.notifications_active, size: Responsive.getIconSize(context, 16)),
                                  label: Text('Send Reminder', style: TextStyle(fontSize: Responsive.getFontSize(context, 13))),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1),
                                    foregroundColor: AppColors.accentBlue,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(vertical: Responsive.getSpacing(context, 10)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                      ),
                    );
                  }),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddFriendDialog(
                  onAddFriend: (uniqueId) async {
                    await provider.addFriendByUniqueId(uniqueId);
                  },
                ),
              );
            },
            backgroundColor: const Color(0xFF4ADE80),
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text(
              'Add Friend',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
