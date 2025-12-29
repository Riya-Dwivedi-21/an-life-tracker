import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/habit.dart';
import '../../../core/models/habit_log.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/theme/app_theme.dart';

class HabitCalendarSheet extends StatefulWidget {
  final Habit habit;

  const HabitCalendarSheet({
    super.key,
    required this.habit,
  });

  @override
  State<HabitCalendarSheet> createState() => _HabitCalendarSheetState();
}

class _HabitCalendarSheetState extends State<HabitCalendarSheet> {
  late DateTime _selectedMonth;
  late Color _habitColor;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _habitColor = _parseColor(widget.habit.color);
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryOrange;
    }
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    
    return List.generate(daysInMonth, (index) => DateTime(month.year, month.month, index + 1));
  }

  int _getWeekdayOfFirstDay(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    return firstDay.weekday % 7; // 0 = Sunday, 1 = Monday, etc.
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final days = _getDaysInMonth(_selectedMonth);
        final firstDayOffset = _getWeekdayOfFirstDay(_selectedMonth);
        final monthName = _getMonthName(_selectedMonth.month);
        final logs = provider.getHabitLogs(widget.habit.id);
        
        // Calculate stats
        final completedCount = logs.where((log) => 
          log.completed && 
          log.date.year == _selectedMonth.year && 
          log.date.month == _selectedMonth.month
        ).length;
        final percentage = days.isEmpty ? 0 : ((completedCount / days.length) * 100).round();

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _habitColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(widget.habit.icon, style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.habit.name,
                                style: const TextStyle(
                                  color: AppColors.foreground,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.habit.description != null && widget.habit.description!.isNotEmpty)
                                Text(
                                  widget.habit.description!,
                                  style: TextStyle(
                                    color: AppColors.foreground.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _habitColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _habitColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '$completedCount',
                                  style: TextStyle(
                                    color: _habitColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Completed',
                                  style: TextStyle(
                                    color: AppColors.foreground.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppColors.border,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${days.length - completedCount}',
                                  style: const TextStyle(
                                    color: AppColors.foreground,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Remaining',
                                  style: TextStyle(
                                    color: AppColors.foreground.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '$percentage%',
                                  style: TextStyle(
                                    color: _habitColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Success Rate',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
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

              // Month navigation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: AppColors.foreground),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                        });
                      },
                    ),
                    Text(
                      '$monthName ${_selectedMonth.year}',
                      style: const TextStyle(
                        color: AppColors.foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: AppColors.foreground),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Weekday headers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                    return SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: AppColors.foreground.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Calendar grid
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: _buildCalendarGrid(days, firstDayOffset, logs, provider),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildCalendarGrid(List<DateTime> days, int firstDayOffset, List<HabitLog> logs, AppProvider provider) {
    final List<Widget> weeks = [];
    final List<Widget> currentWeek = [];
    
    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstDayOffset; i++) {
      currentWeek.add(const SizedBox(width: 40, height: 40));
    }
    
    // Add day cells
    for (final day in days) {
      final log = logs.firstWhere(
        (l) => l.date.year == day.year && l.date.month == day.month && l.date.day == day.day,
        orElse: () => HabitLog(
          id: '',
          userId: '',
          habitId: widget.habit.id,
          date: day,
          completed: false,
          count: 0,
          createdAt: DateTime.now(),
        ),
      );
      
      currentWeek.add(_buildDayCell(day, log, provider));
      
      // Start a new week after Saturday
      if (currentWeek.length == 7) {
        weeks.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.from(currentWeek),
        ));
        weeks.add(const SizedBox(height: 8));
        currentWeek.clear();
      }
    }
    
    // Add remaining cells in the last week
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(const SizedBox(width: 40, height: 40));
      }
      weeks.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: currentWeek,
      ));
    }
    
    return weeks;
  }

  Widget _buildDayCell(DateTime day, HabitLog log, AppProvider provider) {
    final isToday = DateTime.now().year == day.year &&
                    DateTime.now().month == day.month &&
                    DateTime.now().day == day.day;
    final isFuture = day.isAfter(DateTime.now());
    final isCompleted = log.completed;
    
    return GestureDetector(
      onTap: isFuture ? null : () async {
        // Toggle habit completion
        await provider.toggleHabitLog(
          habitId: widget.habit.id,
          date: day,
          completed: !isCompleted,
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isCompleted
              ? _habitColor
              : isToday
                  ? _habitColor.withOpacity(0.1)
                  : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isToday
                ? _habitColor
                : isCompleted
                    ? _habitColor
                    : AppColors.border,
            width: isToday ? 2 : 1,
          ),
        ),
        child: Center(
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isFuture
                        ? AppColors.foreground.withOpacity(0.3)
                        : AppColors.foreground,
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
        ),
      ),
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
