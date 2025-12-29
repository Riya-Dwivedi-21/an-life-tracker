import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/soft_card.dart';

class GroupSession extends StatefulWidget {
  final List<Friend> friends;

  const GroupSession({super.key, required this.friends});

  @override
  State<GroupSession> createState() => _GroupSessionState();
}

class _GroupSessionState extends State<GroupSession> {
  bool _showEmojis = false;
  bool _hasVoted = false;

  final _emojis = ['👍', '😂', '👋', '☕', '😠'];

  List<Friend> get _displayFriends {
    if (widget.friends.isNotEmpty) return widget.friends;
    return [
      Friend(id: '1', name: 'Alex', avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100', status: 'focusing', currentActivity: 'Math'),
      Friend(id: '2', name: 'Sarah', avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100', status: 'focusing', currentActivity: 'Physics'),
      Friend(id: '3', name: 'Mike', avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100', status: 'focusing', currentActivity: 'Coding'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Study Together (${_displayFriends.length + 1})',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showEmojis = !_showEmojis),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: const Text('😊 React', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (!_hasVoted) {
                        setState(() => _hasVoted = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🗳️ Break vote submitted!')),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: _hasVoted
                            ? null
                            : const LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)]),
                        color: _hasVoted ? Colors.grey.shade200 : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.how_to_vote, size: 12, color: _hasVoted ? Colors.grey : Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            _hasVoted ? 'Voted' : 'Vote Break',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _hasVoted ? Colors.grey : Colors.white,
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
          if (_showEmojis) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _emojis.map((emoji) => GestureDetector(
                onTap: () {
                  setState(() => _showEmojis = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sent $emoji')),
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                ),
              )).toList(),
            ),
          ],
          const SizedBox(height: 16),
          ..._displayFriends.map((friend) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFFDF2F8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(friend.avatarUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(friend.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('📚 ${friend.currentActivity ?? "Studying"}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('22:30', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                    Text('remaining', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          )),
          // Current user
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF9C3), Color(0xFFFFEDD5)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE047), width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('You', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You (Host)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('📚 Your Subject', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
