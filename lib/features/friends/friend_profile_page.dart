import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/supabase_service.dart';
import '../../core/models/models.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/soft_card.dart';
import 'friend_habits_page.dart';

class FriendProfilePage extends StatefulWidget {
  final Friend friend;

  const FriendProfilePage({
    super.key,
    required this.friend,
  });

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<FocusSession> _focusSessions = [];
  List<CalorieEntry> _calorieEntries = [];
  Map<String, dynamic> _weeklyStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriendData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendData() async {
    setState(() => _isLoading = true);
    
    try {
      final supabase = SupabaseService();
      
      // Load focus sessions
      final focusData = await supabase.getFriendFocusSessions(widget.friend.id);
      _focusSessions = focusData.map((data) => FocusSession(
        id: data['id'] as String,
        durationMinutes: data['duration_minutes'] as int,
        subjectTags: List<String>.from(data['subject_tags'] ?? []),
        sessionDate: DateTime.parse(data['session_date'] as String),
        completed: data['completed'] as bool? ?? false,
        breakCount: data['break_count'] as int? ?? 0,
        focusMode: data['focus_mode'] as String? ?? 'normal',
      )).toList();
      
      // Load calorie entries
      final calorieData = await supabase.getFriendCalorieEntries(widget.friend.id);
      _calorieEntries = calorieData.map((data) => CalorieEntry(
        id: data['id'] as String,
        type: data['type'] as String,
        description: data['description'] as String,
        amount: data['amount'] as int,
        entryDate: DateTime.parse(data['entry_date'] as String),
      )).toList();
      
      // Load weekly stats
      _weeklyStats = await supabase.getFriendWeeklyStats(widget.friend.id);
      
    } catch (e) {
      print('Error loading friend data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
        actions: [
          IconButton(
            icon: Icon(Icons.check_circle_outline, color: AppTheme.primaryOrange),
            tooltip: 'View Habits',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FriendHabitsPage(
                    friendId: widget.friend.id,
                    friendName: widget.friend.name,
                  ),
                ),
              );
            },
          ),
        ],
        title: Row(
          children: [
            CircleAvatar(
              radius: Responsive.getIconSize(context, 16),
              backgroundImage: NetworkImage(widget.friend.avatarUrl),
            ),
            SizedBox(width: Responsive.getSpacing(context, 10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friend.name,
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: Responsive.getFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.friend.status == 'focusing'
                        ? '🎯 Focusing'
                        : widget.friend.status == 'online'
                            ? '🟢 Online'
                            : '⚫ Offline',
                    style: TextStyle(
                      color: AppColors.foreground.withValues(alpha: 0.6),
                      fontSize: Responsive.getFontSize(context, 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Weekly Stats Summary
                _buildWeeklySummary(),
                
                // Tab Bar
                Container(
                  margin: EdgeInsets.symmetric(horizontal: Responsive.getPadding(context), vertical: Responsive.getSpacing(context, 8)),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.primary,
                    labelStyle: TextStyle(fontSize: Responsive.getFontSize(context, 13)),
                    unselectedLabelStyle: TextStyle(fontSize: Responsive.getFontSize(context, 13)),
                    unselectedLabelColor: AppColors.foreground.withValues(alpha: 0.6),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: '🎯 Focus'),
                      Tab(text: '🍎 Nutrition'),
                    ],
                  ),
                ),
                
                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFocusHistory(),
                      _buildNutritionHistory(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWeeklySummary() {
    final focusHours = _weeklyStats['focusHours'] as double? ?? 0.0;
    final caloriesBurned = _weeklyStats['caloriesBurned'] as int? ?? 0;
    
    return Container(
      margin: EdgeInsets.all(Responsive.getPadding(context)),
      child: SoftCard(
        padding: EdgeInsets.all(Responsive.getPadding(context)),
        child: Column(
          children: [
            Text(
              'This Week',
              style: TextStyle(
                color: AppColors.foreground.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${focusHours.toStringAsFixed(1)}h',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Focus Time',
                        style: TextStyle(
                          color: AppColors.foreground.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: AppColors.foreground.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$caloriesBurned',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Calories Burned',
                        style: TextStyle(
                          color: AppColors.foreground.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusHistory() {
    if (_focusSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppColors.foreground.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No focus sessions yet',
              style: TextStyle(
                color: AppColors.foreground.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Group sessions by date
    final groupedSessions = <String, List<FocusSession>>{};
    for (final session in _focusSessions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(session.sessionDate);
      groupedSessions.putIfAbsent(dateKey, () => []);
      groupedSessions[dateKey]!.add(session);
    }

    final sortedDates = groupedSessions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final sessions = groupedSessions[dateKey]!;
        final date = DateTime.parse(dateKey);
        
        final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _formatDate(date),
                style: TextStyle(
                  color: AppColors.foreground.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...sessions.map((session) => _buildFocusSessionCard(session)),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Text(
                'Total: ${totalMinutes} minutes',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFocusSessionCard(FocusSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${session.durationMinutes}m',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.subject,
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(session.sessionDate),
                    style: TextStyle(
                      color: AppColors.foreground.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (session.completed)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionHistory() {
    if (_calorieEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: 64,
              color: AppColors.foreground.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No nutrition data yet',
              style: TextStyle(
                color: AppColors.foreground.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Group entries by date
    final groupedEntries = <String, List<CalorieEntry>>{};
    for (final entry in _calorieEntries) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.entryDate);
      groupedEntries.putIfAbsent(dateKey, () => []);
      groupedEntries[dateKey]!.add(entry);
    }

    final sortedDates = groupedEntries.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final entries = groupedEntries[dateKey]!;
        final date = DateTime.parse(dateKey);
        
        final foodCalories = entries
            .where((e) => e.type == 'food')
            .fold<int>(0, (sum, e) => sum + e.amount);
        final burnedCalories = entries
            .where((e) => e.type == 'burn')
            .fold<int>(0, (sum, e) => sum + e.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      color: AppColors.foreground.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Net: ${foodCalories - burnedCalories} cal',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...entries.map((entry) => _buildCalorieEntryCard(entry)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildCalorieEntryCard(CalorieEntry entry) {
    final isFood = entry.type == 'food';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (isFood ? AppColors.accent : AppColors.secondary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  isFood ? '🍎' : '🔥',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description,
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(entry.entryDate),
                    style: TextStyle(
                      color: AppColors.foreground.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isFood ? '+' : '-'}${entry.amount} cal',
              style: TextStyle(
                color: isFood ? AppColors.accent : AppColors.secondary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
