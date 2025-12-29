import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/utils/responsive.dart';

class ProgressGraph extends StatefulWidget {
  const ProgressGraph({super.key});

  @override
  State<ProgressGraph> createState() => _ProgressGraphState();
}

class _ProgressGraphState extends State<ProgressGraph> {
  String _selectedPeriod = 'week';
  String _dataType = 'focus'; // 'focus' or 'calories'

  List<FlSpot> _getGraphData(AppProvider provider) {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'today':
        return _getTodayData(provider, now);
      case 'yesterday':
        return _getYesterdayData(provider, now);
      case 'week':
        return _getWeekData(provider, now);
      case 'month':
        return _getMonthData(provider, now);
      case 'year':
        return _getYearData(provider, now);
      default:
        return [];
    }
  }

  List<FlSpot> _getTodayData(AppProvider provider, DateTime now) {
    if (_dataType == 'focus') {
      final sessions = provider.focusSessions.where((s) =>
        s.sessionDate.year == now.year &&
        s.sessionDate.month == now.month &&
        s.sessionDate.day == now.day
      ).toList();

      final hourlyData = List.generate(24, (i) => 0.0);
      for (var session in sessions) {
        final hour = session.sessionDate.hour;
        hourlyData[hour] += session.durationMinutes.toDouble();
      }
      return List.generate(24, (i) => FlSpot(i.toDouble(), hourlyData[i]));
    } else {
      final entries = provider.calorieEntries.where((e) =>
        e.entryDate.year == now.year &&
        e.entryDate.month == now.month &&
        e.entryDate.day == now.day &&
        e.type == 'burn'
      ).toList();

      final hourlyData = List.generate(24, (i) => 0.0);
      for (var entry in entries) {
        final hour = entry.entryDate.hour;
        hourlyData[hour] += entry.amount.toDouble();
      }
      return List.generate(24, (i) => FlSpot(i.toDouble(), hourlyData[i]));
    }
  }

  List<FlSpot> _getYesterdayData(AppProvider provider, DateTime now) {
    final yesterday = now.subtract(const Duration(days: 1));
    
    if (_dataType == 'focus') {
      final sessions = provider.focusSessions.where((s) =>
        s.sessionDate.year == yesterday.year &&
        s.sessionDate.month == yesterday.month &&
        s.sessionDate.day == yesterday.day
      ).toList();

      final hourlyData = List.generate(24, (i) => 0.0);
      for (var session in sessions) {
        final hour = session.sessionDate.hour;
        hourlyData[hour] += session.durationMinutes.toDouble();
      }
      return List.generate(24, (i) => FlSpot(i.toDouble(), hourlyData[i]));
    } else {
      final entries = provider.calorieEntries.where((e) =>
        e.entryDate.year == yesterday.year &&
        e.entryDate.month == yesterday.month &&
        e.entryDate.day == yesterday.day &&
        e.type == 'burn'
      ).toList();

      final hourlyData = List.generate(24, (i) => 0.0);
      for (var entry in entries) {
        final hour = entry.entryDate.hour;
        hourlyData[hour] += entry.amount.toDouble();
      }
      return List.generate(24, (i) => FlSpot(i.toDouble(), hourlyData[i]));
    }
  }

  List<FlSpot> _getWeekData(AppProvider provider, DateTime now) {
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final dailyData = List.generate(7, (i) => 0.0);

    if (_dataType == 'focus') {
      for (var session in provider.focusSessions) {
        final daysSinceStart = session.sessionDate.difference(weekStart).inDays;
        if (daysSinceStart >= 0 && daysSinceStart < 7) {
          dailyData[daysSinceStart] += session.durationMinutes.toDouble();
        }
      }
    } else {
      for (var entry in provider.calorieEntries.where((e) => e.type == 'burn')) {
        final daysSinceStart = entry.entryDate.difference(weekStart).inDays;
        if (daysSinceStart >= 0 && daysSinceStart < 7) {
          dailyData[daysSinceStart] += entry.amount.toDouble();
        }
      }
    }

    return List.generate(7, (i) => FlSpot(i.toDouble(), dailyData[i]));
  }

  List<FlSpot> _getMonthData(AppProvider provider, DateTime now) {
    final monthStart = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyData = List.generate(daysInMonth, (i) => 0.0);

    if (_dataType == 'focus') {
      for (var session in provider.focusSessions) {
        if (session.sessionDate.year == now.year && session.sessionDate.month == now.month) {
          final day = session.sessionDate.day - 1;
          if (day >= 0 && day < daysInMonth) {
            dailyData[day] += session.durationMinutes.toDouble();
          }
        }
      }
    } else {
      for (var entry in provider.calorieEntries.where((e) => e.type == 'burn')) {
        if (entry.entryDate.year == now.year && entry.entryDate.month == now.month) {
          final day = entry.entryDate.day - 1;
          if (day >= 0 && day < daysInMonth) {
            dailyData[day] += entry.amount.toDouble();
          }
        }
      }
    }

    return List.generate(daysInMonth, (i) => FlSpot(i.toDouble(), dailyData[i]));
  }

  List<FlSpot> _getYearData(AppProvider provider, DateTime now) {
    final monthlyData = List.generate(12, (i) => 0.0);

    if (_dataType == 'focus') {
      for (var session in provider.focusSessions) {
        if (session.sessionDate.year == now.year) {
          final month = session.sessionDate.month - 1;
          monthlyData[month] += session.durationMinutes.toDouble();
        }
      }
    } else {
      for (var entry in provider.calorieEntries.where((e) => e.type == 'burn')) {
        if (entry.entryDate.year == now.year) {
          final month = entry.entryDate.month - 1;
          monthlyData[month] += entry.amount.toDouble();
        }
      }
    }

    return List.generate(12, (i) => FlSpot(i.toDouble(), monthlyData[i]));
  }

  String _getXAxisLabel(int index) {
    switch (_selectedPeriod) {
      case 'today':
      case 'yesterday':
        if (index % 6 == 0) return '${index}h';
        return '';
      case 'week':
        return ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
      case 'month':
        if (index % 5 == 0) return '${index + 1}';
        return '';
      case 'year':
        return ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'][index];
      default:
        return '';
    }
  }

  double _getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;
    final max = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return max == 0 ? 100 : max * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final spots = _getGraphData(provider);
    final padding = Responsive.getPadding(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.accentBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.primary, AppColors.accentBlue],
                    ).createShader(bounds),
                    child: Text(
                      'Progress Analytics',
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, 20),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dataType == 'focus' ? 'Track your focus journey' : 'Track your calories',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, 12),
                      color: AppColors.foreground.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accentBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Data Type Toggle
          Row(
            children: [
              _buildDataTypeButton('Focus', 'focus', Icons.timer_outlined),
              const SizedBox(width: 8),
              _buildDataTypeButton('Calories', 'calories', Icons.local_fire_department),
            ],
          ),
          const SizedBox(height: 12),

          // Time Period Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodButton('Today', 'today'),
                const SizedBox(width: 8),
                _buildPeriodButton('Yesterday', 'yesterday'),
                const SizedBox(width: 8),
                _buildPeriodButton('Week', 'week'),
                const SizedBox(width: 8),
                _buildPeriodButton('Month', 'month'),
                const SizedBox(width: 8),
                _buildPeriodButton('Year', 'year'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Graph
          SizedBox(
            height: 200,
            child: spots.isEmpty || spots.every((s) => s.y == 0)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insights_outlined,
                          size: 48,
                          color: AppColors.foreground.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No data for this period',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.foreground.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _getMaxY(spots) / 4,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.foreground.withValues(alpha: 0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: _getMaxY(spots) / 4,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}m',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.foreground.withValues(alpha: 0.5),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _getXAxisLabel(value.toInt()),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.foreground.withValues(alpha: 0.6),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: spots.length.toDouble() - 1,
                      minY: 0,
                      maxY: _getMaxY(spots),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: _dataType == 'focus' 
                                ? [AppColors.primary, AppColors.accentBlue]
                                : [AppColors.accentPink, const Color(0xFFEF4444)],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: _dataType == 'focus' 
                                    ? AppColors.primary 
                                    : AppColors.accentPink,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: _dataType == 'focus'
                                  ? [
                                      AppColors.primary.withValues(alpha: 0.3),
                                      AppColors.accentBlue.withValues(alpha: 0.1),
                                    ]
                                  : [
                                      AppColors.accentPink.withValues(alpha: 0.3),
                                      const Color(0xFFEF4444).withValues(alpha: 0.1),
                                    ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: _dataType == 'focus' 
                              ? AppColors.primary 
                              : AppColors.accentPink,
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final unit = _dataType == 'focus' ? 'min' : 'cal';
                              return LineTooltipItem(
                                '${spot.y.toInt()} $unit',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // Stats Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                'Total',
                '${spots.fold<double>(0, (sum, s) => sum + s.y).toInt()} ${_dataType == 'focus' ? 'min' : 'cal'}',
                Icons.timer_outlined,
                AppColors.primary,
              ),
              _buildStat(
                'Average',
                '${spots.isEmpty ? 0 : (spots.fold<double>(0, (sum, s) => sum + s.y) / spots.length).toInt()} ${_dataType == 'focus' ? 'min' : 'cal'}',
                Icons.show_chart,
                AppColors.accentBlue,
              ),
              _buildStat(
                'Peak',
                '${spots.isEmpty ? 0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b).toInt()} ${_dataType == 'focus' ? 'min' : 'cal'}',
                Icons.trending_up,
                AppColors.accentPink,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataTypeButton(String label, String value, IconData icon) {
    final isSelected = _dataType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _dataType = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.accentBlue],
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.foreground.withValues(alpha: 0.7),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.foreground.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.accentBlue],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.foreground.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.foreground.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
