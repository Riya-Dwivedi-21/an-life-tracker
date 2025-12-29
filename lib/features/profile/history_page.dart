import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/models.dart';
import '../../core/models/habit.dart';
import '../../core/models/habit_log.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _selectedYear = DateTime.now().year;
  int? _selectedMonth;
  DateTime? _selectedDate;

  List<int> _getAvailableYears() {
    final currentYear = DateTime.now().year;
    const startYear = 2025;
    
    // Generate years from 2025 to current year (or next year if after Dec 31)
    final endYear = DateTime.now().month == 12 && DateTime.now().day == 31 
        ? currentYear + 1 
        : currentYear;
    
    final years = <int>[];
    for (int year = endYear; year >= startYear; year--) {
      years.add(year);
    }
    return years;
  }

  List<Map<String, dynamic>> _getMonthsWithData(AppProvider provider) {
    final months = <Map<String, dynamic>>[];
    for (int month = 1; month <= 12; month++) {
      final monthData = provider.getMonthData(_selectedYear, month);
      months.add({
        'month': month,
        'name': DateFormat.MMMM().format(DateTime(_selectedYear, month)),
        'focusMinutes': monthData['focusMinutes'],
        'caloriesBurned': monthData['caloriesBurned'],
      });
    }
    return months;
  }

  List<DateTime> _getDaysInMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    return List.generate(
      lastDay.day,
      (index) => DateTime(year, month, index + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
              onPressed: () {
                if (_selectedDate != null) {
                  setState(() => _selectedDate = null);
                } else if (_selectedMonth != null) {
                  setState(() => _selectedMonth = null);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            title: Text(
              _selectedDate != null
                  ? DateFormat('MMMM dd, yyyy').format(_selectedDate!)
                  : _selectedMonth != null
                      ? DateFormat.MMMM().format(DateTime(_selectedYear, _selectedMonth!))
                      : 'History $_selectedYear',
              style: const TextStyle(
                color: AppColors.foreground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SafeArea(
            child: _selectedDate != null
                ? _buildDayDetail(provider)
                : _selectedMonth != null
                    ? _buildMonthView(provider)
                    : _buildYearView(provider),
          ),
        );
      },
    );
  }

  Widget _buildYearView(AppProvider provider) {
    final years = _getAvailableYears();
    
    return Column(
      children: [
        // Year Selector
        Container(
          height: 60,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: years.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final year = years[index];
              final isSelected = year == _selectedYear;
              return GestureDetector(
                onTap: () => setState(() => _selectedYear = year),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.accentBlue],
                          )
                        : null,
                    color: isSelected ? null : AppColors.muted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      year.toString(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Months Grid
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: _getMonthsWithData(provider).map((monthData) {
              return GestureDetector(
                onTap: () => setState(() => _selectedMonth = monthData['month']),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            monthData['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right, color: AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Mini Progress Chart
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.1),
                              AppColors.accentBlue.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${monthData['focusMinutes'] ~/ 60}h ${monthData['focusMinutes'] % 60}m focused',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department,
                              size: 16, color: AppColors.accentPink),
                          const SizedBox(width: 4),
                          Text(
                            '${monthData['caloriesBurned']} calories burned',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.foreground.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthView(AppProvider provider) {
    final days = _getDaysInMonth(_selectedYear, _selectedMonth!);
    
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final dayData = provider.getDayData(day);
        final hasFocus = dayData['focusMinutes'] > 0;
        
        return GestureDetector(
          onTap: () => setState(() => _selectedDate = day),
          child: Container(
            decoration: BoxDecoration(
              color: hasFocus ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFocus ? AppColors.primary : Colors.grey.shade200,
                width: hasFocus ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.day.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasFocus ? AppColors.primary : AppColors.foreground,
                  ),
                ),
                if (hasFocus)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayDetail(AppProvider provider) {
    final dayData = provider.getDayData(_selectedDate!);
    final focusSessions = dayData['sessions'] as List<FocusSession>;
    final calorieEntries = dayData['entries'] as List<CalorieEntry>;
    
    // Get habit completions for this day
    final habits = provider.allHabits.where((h) => h.isActiveInMonth(_selectedDate!)).toList();
    final habitLogs = habits.map((habit) {
      return {
        'habit': habit,
        'log': provider.getHabitLogForDate(habit.id, _selectedDate!),
      };
    }).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  '${dayData['focusMinutes'] ~/ 60}h ${dayData['focusMinutes'] % 60}m',
                  'Total Focus',
                  Icons.psychology,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  '${dayData['caloriesBurned']}',
                  'Calories Burned',
                  Icons.local_fire_department,
                  AppColors.accentPink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Focus Sessions
          const Text(
            'Focus Sessions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (focusSessions.isEmpty)
            _buildEmptyState('No focus sessions', Icons.psychology_outlined)
          else
            ...focusSessions.map((session) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.psychology, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${session.durationMinutes} minutes',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (session.subjectTags.isNotEmpty)
                              Text(
                                session.subjectTags.join(', '),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.foreground.withValues(alpha: 0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat.jm().format(session.sessionDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.foreground.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 24),

          // Habit Completions
          const Text(
            'Habits',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (habits.isEmpty)
            _buildEmptyState('No habits tracked', Icons.check_circle_outline)
          else
            ...habitLogs.map((data) {
              final habit = data['habit'] as Habit;
              final log = data['log'] as HabitLog?;
              final isCompleted = log?.completed ?? false;
              final color = _parseColor(habit.color);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCompleted ? color.withOpacity(0.5) : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? color : Colors.transparent,
                        border: Border.all(
                          color: isCompleted ? color : AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(habit.icon, style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (log?.notes != null && log!.notes!.isNotEmpty)
                            Text(
                              log.notes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.foreground.withOpacity(0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Icon(Icons.check_circle, color: color, size: 24),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),

          // Calorie Entries
          const Text(
            'Nutrition',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (calorieEntries.isEmpty)
            _buildEmptyState('No nutrition entries', Icons.apple_outlined)
          else
            ...calorieEntries.map((entry) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (entry.type == 'food'
                                  ? AppColors.accentGreen
                                  : AppColors.accentPink)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          entry.type == 'food' ? Icons.restaurant : Icons.local_fire_department,
                          color: entry.type == 'food' ? AppColors.accentGreen : AppColors.accentPink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.description,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${entry.amount} ${entry.type == 'food' ? 'calories' : 'burned'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.foreground.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.foreground.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.foreground.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.foreground.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryOrange;
    }
  }
}
