import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';

class StudyTogetherDialog extends StatefulWidget {
  final List<Friend> friends;
  final Function(String friendId, String action) onAction;

  const StudyTogetherDialog({
    super.key,
    required this.friends,
    required this.onAction,
  });

  @override
  State<StudyTogetherDialog> createState() => _StudyTogetherDialogState();
}

class _StudyTogetherDialogState extends State<StudyTogetherDialog> {
  void _showMessageOptions(String friendId, String friendName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Message $friendName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildMessageButton(
                friendId,
                'I will come after 10 min ⏰',
                Icons.schedule,
              ),
              const SizedBox(height: 12),
              _buildMessageButton(
                friendId,
                'Just checking, not studying 👀',
                Icons.visibility,
              ),
              const SizedBox(height: 12),
              _buildMessageButton(
                friendId,
                'Let\'s study together! 📚',
                Icons.menu_book,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageButton(String friendId, String message, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close message dialog
        widget.onAction(friendId, 'message:$message');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message sent: $message'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final focusingFriends = widget.friends.where((f) => f.status == 'focusing').toList();
    final nonFocusingFriends = widget.friends.where((f) => f.status != 'focusing').toList();
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.people, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Study Together',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Friends List
            Flexible(
              child: widget.friends.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'No friends yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        // Non-focusing friends (colorful)
                        ...nonFocusingFriends.map((friend) => _buildFriendTile(friend, false)),
                        
                        // Focusing friends (grayed out)
                        ...focusingFriends.map((friend) => _buildFriendTile(friend, true)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendTile(Friend friend, bool isFocusing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFocusing ? Colors.grey.shade200 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocusing ? Colors.grey.shade300 : AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          if (!isFocusing)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isFocusing ? Colors.grey.shade400 : AppColors.primary,
                child: Text(
                  friend.name[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              if (isFocusing)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Friend Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isFocusing ? Colors.grey.shade600 : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isFocusing ? Colors.orange : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isFocusing ? 'Focusing now' : 'Available',
                      style: TextStyle(
                        fontSize: 12,
                        color: isFocusing ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          if (isFocusing)
            // Message button for focusing friends
            IconButton(
              onPressed: () => _showMessageOptions(friend.id, friend.name),
              icon: const Icon(Icons.message, size: 20),
              color: Colors.grey.shade600,
              tooltip: 'Send Message',
            )
          else
            // Invite button for non-focusing friends
            ElevatedButton(
              onPressed: () {
                widget.onAction(friend.id, 'invite');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invitation sent to ${friend.name}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Invite',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
