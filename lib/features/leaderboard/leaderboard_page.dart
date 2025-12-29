import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/soft_card.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  String _activeMetric = 'focus';
  bool _hideFocus = false;
  bool _hideCalories = false;

  @override
  void initState() {
    super.initState();
    // Refresh friend stats when leaderboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).loadFriends();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final user = provider.user;
        final friends = [...provider.friends];
        
        // Calculate user's weekly stats (Monday to Sunday)
        final now = DateTime.now();
        final weekday = now.weekday; // 1 = Monday, 7 = Sunday
        final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        
        print('📊 Leaderboard Week: ${weekStart.toString().split(' ')[0]} to ${weekEnd.toString().split(' ')[0]}');
        
        final userFocusMinutes = provider.focusSessions
            .where((s) => s.sessionDate.isAfter(weekStart) && s.sessionDate.isBefore(weekEnd))
            .fold(0, (sum, s) => sum + s.durationMinutes);
        
        final userCaloriesBurned = provider.calorieEntries
            .where((e) => e.entryDate.isAfter(weekStart) && e.entryDate.isBefore(weekEnd) && e.type == 'burn')
            .fold(0, (sum, e) => sum + e.amount);
        
        print('📊 Your Stats - Focus: ${userFocusMinutes}min (${userFocusMinutes/60}h), Calories: $userCaloriesBurned');
        
        // Create competitor list with user
        final competitors = <Map<String, dynamic>>[];
        
        // Add user
        if (user != null) {
          competitors.add({
            'id': user.id,
            'name': 'You',
            'avatarUrl': user.avatarUrl ?? 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100',
            'isYou': true,
            'focusHours': userFocusMinutes / 60,
            'caloriesBurned': userCaloriesBurned,
          });
        }
        
        // Add friends (with their stats)
        for (final friend in friends) {
          print('📊 Friend ${friend.name} - Focus: ${friend.weeklyFocusHours}h, Calories: ${friend.weeklyCaloriesBurned}');
          competitors.add({
            'id': friend.id,
            'name': friend.name,
            'avatarUrl': friend.avatarUrl,
            'isYou': false,
            'focusHours': friend.weeklyFocusHours.toDouble(),
            'caloriesBurned': friend.weeklyCaloriesBurned,
          });
        }
        
        // Sort by active metric
        competitors.sort((a, b) {
          if (_activeMetric == 'focus') {
            return (b['focusHours'] as double).compareTo(a['focusHours'] as double);
          }
          return (b['caloriesBurned'] as int).compareTo(a['caloriesBurned'] as int);
        });

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: friends.isEmpty 
                ? _buildEmptyState(context)
                : SingleChildScrollView(
                    padding: EdgeInsets.all(Responsive.getPadding(context)),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_events, color: const Color(0xFFFFD700), size: Responsive.getIconSize(context, 28)),
                            SizedBox(width: Responsive.getSpacing(context, 10)),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                              ).createShader(bounds),
                              child: Text(
                                'Leaderboard',
                                style: TextStyle(
                                  fontSize: Responsive.getFontSize(context, 28),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.getSpacing(context, 6)),
                        Text(
                          'Compete with ${friends.length} friend${friends.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: Responsive.getFontSize(context, 13),
                            color: AppColors.foreground.withOpacity(0.6),
                          ),
                        ),
                        SizedBox(height: Responsive.getSpacing(context, 20)),

                  // Metric Toggle
                  Container(
                    padding: EdgeInsets.all(Responsive.getSpacing(context, 5)),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeMetric = 'focus'),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: Responsive.getSpacing(context, 10)),
                              decoration: BoxDecoration(
                                gradient: _activeMetric == 'focus'
                                    ? LinearGradient(
                                        colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _activeMetric == 'focus'
                                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8)]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.psychology,
                                    size: Responsive.getIconSize(context, 14),
                                    color: _activeMetric == 'focus' ? Colors.white : Colors.grey.shade600,
                                  ),
                                  SizedBox(width: Responsive.getSpacing(context, 4)),
                                  Text(
                                    'Focus',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: Responsive.getFontSize(context, 12),
                                      color: _activeMetric == 'focus' ? Colors.white : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeMetric = 'calories'),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: Responsive.getSpacing(context, 10)),
                              decoration: BoxDecoration(
                                gradient: _activeMetric == 'calories'
                                    ? LinearGradient(
                                        colors: [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.8)],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _activeMetric == 'calories'
                                    ? [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 8)]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: Responsive.getIconSize(context, 14),
                                    color: _activeMetric == 'calories' ? Colors.white : Colors.grey.shade600,
                                  ),
                                  SizedBox(width: Responsive.getSpacing(context, 4)),
                                  Text(
                                    'Calories',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: Responsive.getFontSize(context, 12),
                                      color: _activeMetric == 'calories' ? Colors.white : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Responsive.getSpacing(context, 20)),

                  // Leaderboard
                  ...competitors.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final competitor = entry.value;

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + (rank * 50)),
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
                        padding: EdgeInsets.only(bottom: Responsive.getSpacing(context, 12)),
                        child: SoftCard(
                          child: Row(
                            children: [
                              // Rank
                              SizedBox(
                                width: Responsive.getIconSize(context, 40),
                                child: _buildRankBadge(rank),
                              ),
                              // Avatar
                              Stack(
                                children: [
                                  Container(
                                    width: Responsive.getIconSize(context, 48),
                                    height: Responsive.getIconSize(context, 48),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: competitor['isYou'] 
                                            ? AppColors.primary.withOpacity(0.5)
                                            : AppColors.primary.withOpacity(0.2),
                                        width: competitor['isYou'] ? 2 : 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        competitor['avatarUrl'] as String,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: AppColors.primary.withOpacity(0.2),
                                          child: const Icon(Icons.person),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (rank <= 3)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: rank == 1
                                                  ? Colors.yellow.withOpacity(0.3)
                                                  : AppColors.primary.withOpacity(0.2),
                                              blurRadius: 15,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(width: Responsive.getSpacing(context, 10)),
                              // Name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            competitor['name'] as String,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: Responsive.getFontSize(context, 15),
                                              color: competitor['isYou'] ? AppColors.primary : AppColors.foreground,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (competitor['isYou']) ...[
                                          SizedBox(width: Responsive.getSpacing(context, 4)),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: Responsive.getSpacing(context, 6), vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'YOU',
                                              style: TextStyle(
                                                fontSize: Responsive.getFontSize(context, 9),
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      competitor['isYou'] as bool ? 'Keep going!' : 'Active this week',
                                      style: TextStyle(
                                        fontSize: Responsive.getFontSize(context, 11),
                                        color: AppColors.foreground.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Stats
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!_hideFocus && _activeMetric == 'focus')
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.psychology, color: AppColors.primary, size: Responsive.getIconSize(context, 14)),
                                        SizedBox(width: Responsive.getSpacing(context, 3)),
                                        ShaderMask(
                                          shaderCallback: (bounds) => const LinearGradient(
                                            colors: [AppColors.primary, AppColors.accentBlue],
                                          ).createShader(bounds),
                                          child: Text(
                                            '${(competitor['focusHours'] as double).toStringAsFixed(1)}h',
                                            style: TextStyle(
                                              fontSize: Responsive.getFontSize(context, 16),
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (!_hideCalories && _activeMetric == 'calories')
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.local_fire_department, color: AppColors.secondary, size: Responsive.getIconSize(context, 14)),
                                        SizedBox(width: Responsive.getSpacing(context, 3)),
                                        Text(
                                          '${competitor['caloriesBurned']}',
                                          style: TextStyle(
                                            fontSize: Responsive.getFontSize(context, 16),
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Privacy Controls
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.visibility_off, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Privacy Controls',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildPrivacyToggle(
                          'Hide Focus Hours',
                          'Keep focus time private from leaderboard',
                          _hideFocus,
                          (value) => setState(() => _hideFocus = value),
                        ),
                        const SizedBox(height: 12),
                        _buildPrivacyToggle(
                          'Hide Calories',
                          'Keep nutrition private from leaderboard',
                          _hideCalories,
                          (value) => setState(() => _hideCalories = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.muted,
              ),
              child: Icon(
                Icons.people_outline,
                size: 80,
                color: AppColors.foreground.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Friends Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add friends to compete on the leaderboard!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.foreground.withOpacity(0.6),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFFD700).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
      );
    }
    if (rank == 2) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(Icons.emoji_events, color: Colors.white, size: 22),
      );
    }
    if (rank == 3) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.emoji_events, color: Colors.white, size: 20),
      );
    }
    return Text(
      '#$rank',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.foreground.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildPrivacyToggle(String title, String subtitle, bool value, Function(bool)? onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.foreground.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
