import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/responsive.dart';

class SendNotificationDialog extends StatefulWidget {
  final Friend friend;
  final VoidCallback onNotificationSent;

  const SendNotificationDialog({
    super.key,
    required this.friend,
    required this.onNotificationSent,
  });

  @override
  State<SendNotificationDialog> createState() => _SendNotificationDialogState();
}

class _SendNotificationDialogState extends State<SendNotificationDialog> {
  bool _isSending = false;

  final List<Map<String, String>> _messages = [
    {
      'emoji': '🎯',
      'text': 'Hey! Start focusing!',
    },
    {
      'emoji': '📚',
      'text': 'Let\'s study together!',
    },
    {
      'emoji': '📱',
      'text': 'Open the app!',
    },
    {
      'emoji': '💪',
      'text': 'Time to be productive!',
    },
    {
      'emoji': '⏰',
      'text': 'Don\'t forget your focus session!',
    },
    {
      'emoji': '🔥',
      'text': 'Let\'s keep the streak going!',
    },
    {
      'emoji': '🏆',
      'text': 'Challenge accepted? Let\'s compete!',
    },
  ];

  Future<void> _sendNotification(String message) async {
    setState(() => _isSending = true);

    try {
      final supabase = SupabaseService();
      await supabase.sendNotification(
        receiverId: widget.friend.id,
        message: message,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onNotificationSent();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: Responsive.getPadding(context),
        vertical: Responsive.getSpacing(context, 24),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: Responsive.getMaxContentWidth(context)),
        padding: EdgeInsets.all(Responsive.getPadding(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: Responsive.getIconSize(context, 20),
                  backgroundImage: NetworkImage(widget.friend.avatarUrl),
                ),
                SizedBox(width: Responsive.getSpacing(context, 10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send Reminder',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, 18),
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground,
                        ),
                      ),
                      Text(
                        'to ${widget.friend.name}',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, 13),
                          color: AppColors.foreground.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: AppColors.foreground.withValues(alpha: 0.6),
                    size: Responsive.getIconSize(context, 22),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.getSpacing(context, 20)),
            
            // Message options
            Text(
              'Choose a message',
              style: TextStyle(
                fontSize: Responsive.getFontSize(context, 13),
                fontWeight: FontWeight.w600,
                color: AppColors.foreground.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: Responsive.getSpacing(context, 10)),
            
            if (_isSending)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(Responsive.getSpacing(context, 24)),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else
              ...  _messages.map((msg) => _buildMessageOption(
                context: context,
                emoji: msg['emoji']!,
                text: msg['text']!,
                onTap: () => _sendNotification(msg['text']!),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageOption({
    required BuildContext context,
    required String emoji,
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.getSpacing(context, 6)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(Responsive.getSpacing(context, 12)),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  emoji,
                  style: TextStyle(fontSize: Responsive.getFontSize(context, 20)),
                ),
                SizedBox(width: Responsive.getSpacing(context, 10)),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, 14),
                      color: AppColors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: Responsive.getIconSize(context, 14),
                  color: AppColors.foreground.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
