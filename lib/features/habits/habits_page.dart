import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/habit_list_item.dart';
import 'widgets/add_habit_dialog.dart';
import 'widgets/habit_calendar_sheet.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).loadHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final habits = provider.habits;
        final selectedMonth = provider.selectedMonth;
        final isLoading = provider.isLoadingHabits;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, provider, selectedMonth),
                const SizedBox(height: 16),
                _buildTodayProgress(context, provider),
                const SizedBox(height: 16),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange))
                      : habits.isEmpty
                          ? _buildEmptyState(context)
                          : _buildHabitList(context, provider, habits),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddHabitDialog(context),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider, DateTime selectedMonth) {
    final monthName = _getMonthName(selectedMonth.month);
    final year = selectedMonth.year;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                onPressed: () => provider.previousMonth(),
              ),
              Text(
                '$monthName $year',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                onPressed: () => provider.nextMonth(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${provider.habits.length} Active Habits',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayProgress(BuildContext context, AppProvider provider) {
    final today = DateTime.now();
    final habits = provider.habits;
    
    int completedToday = 0;
    for (final habit in habits) {
      final log = provider.getHabitLogForDate(habit.id, today);
      if (log?.completed == true) completedToday++;
    }

    final totalHabits = habits.length;
    final percentage = totalHabits > 0 ? (completedToday / totalHabits * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
                Center(
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedToday of $totalHabits habits completed',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitList(BuildContext context, AppProvider provider, List habits) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        return HabitListItem(
          habit: habits[index],
          onTap: () => _showHabitCalendar(context, habits[index]),
          onToggle: (date) => provider.toggleHabitLog(
            habitId: habits[index].id,
            date: date,
            completed: !(provider.getHabitLogForDate(habits[index].id, date)?.completed ?? false),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppColors.foreground.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No habits yet',
            style: TextStyle(
              color: AppColors.foreground.withOpacity(0.6),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first habit',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddHabitDialog(),
    );
  }

  void _showHabitCalendar(BuildContext context, habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HabitCalendarSheet(habit: habit),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
