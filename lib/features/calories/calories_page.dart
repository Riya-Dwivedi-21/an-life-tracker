import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/models.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/soft_card.dart';

class CaloriesPage extends StatefulWidget {
  const CaloriesPage({super.key});

  @override
  State<CaloriesPage> createState() => _CaloriesPageState();
}

class _CaloriesPageState extends State<CaloriesPage> {
  String _activeTab = 'food';
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  void _handleSubmit() {
    if (_descriptionController.text.isEmpty || _amountController.text.isEmpty) return;

    final provider = context.read<AppProvider>();
    provider.addCalorieEntry(CalorieEntry(
      id: const Uuid().v4(),
      type: _activeTab,
      description: _descriptionController.text,
      amount: int.tryParse(_amountController.text) ?? 0,
      entryDate: DateTime.now(),
    ));

    _descriptionController.clear();
    _amountController.clear();
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _deleteEntry(CalorieEntry entry) {
    final provider = context.read<AppProvider>();
    provider.deleteCalorieEntry(entry.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entry deleted'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final caloriesIn = provider.getTodayCaloriesIn();
        final caloriesOut = provider.getTodayCaloriesBurned();
        final netCalories = caloriesIn - caloriesOut;

        final todayEntries = provider.calorieEntries.where((e) {
          final today = DateTime.now();
          return e.entryDate.year == today.year &&
              e.entryDate.month == today.month &&
              e.entryDate.day == today.day;
        }).toList();

        final recentFood = todayEntries.where((e) => e.type == 'food').take(5).toList();
        final recentBurn = todayEntries.where((e) => e.type == 'burn').take(5).toList();

        final padding = Responsive.getPadding(context);
        final spacing = Responsive.getSpacing(context, 16);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back),
                        ),
                      ),
                      Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppColors.primary, AppColors.accentPink],
                            ).createShader(bounds),
                            child: const Text(
                              'Nutrition Tracker',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(DateTime.now()),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.foreground.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Live Equation
                  SoftCard(
                    child: Column(
                      children: [
                        Text(
                          "Today's Balance",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.foreground.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatItem(
                              icon: Icons.apple,
                              value: caloriesIn,
                              label: 'Food',
                              color: AppColors.accent,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '−',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300,
                                  color: AppColors.foreground.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                            _buildStatItem(
                              icon: Icons.local_fire_department,
                              value: caloriesOut,
                              label: 'Burned',
                              color: AppColors.secondary,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '=',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300,
                                  color: AppColors.foreground.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                            _buildStatItem(
                              icon: netCalories > 0 ? Icons.trending_up : Icons.trending_down,
                              value: netCalories.abs(),
                              label: 'Net',
                              color: netCalories > 0 ? AppColors.success : AppColors.primary,
                              prefix: netCalories > 0 ? '+' : '-',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Segmented Toggle
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeTab = 'food'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: _activeTab == 'food'
                                    ? const LinearGradient(colors: [Color(0xFF4ADE80), Color(0xFF14B8A6)])
                                    : null,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: _activeTab == 'food'
                                    ? [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 8)]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '🍎 Food In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: _activeTab == 'food' ? Colors.white : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeTab = 'burn'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: _activeTab == 'burn'
                                    ? const LinearGradient(colors: [Color(0xFFFB923C), Color(0xFFEF4444)])
                                    : null,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: _activeTab == 'burn'
                                    ? [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 8)]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '🔥 Energy Out',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: _activeTab == 'burn' ? Colors.white : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input Form
                  SoftCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            hintText: _activeTab == 'food' ? 'What did you eat?' : 'What activity?',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Calories',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.muted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _handleSubmit,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _activeTab == 'food'
                                        ? [const Color(0xFF4ADE80), const Color(0xFF14B8A6)]
                                        : [const Color(0xFFFB923C), const Color(0xFFEF4444)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.add, color: Colors.white, size: 20),
                                    SizedBox(width: 4),
                                    Text(
                                      'Log',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
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
                  ),
                  const SizedBox(height: 24),

                  // Recent Entries
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SoftCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.apple, color: AppColors.accent, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Recent Food', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (recentFood.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'No entries yet',
                                      style: TextStyle(fontSize: 12, color: AppColors.foreground.withValues(alpha: 0.4)),
                                    ),
                                  ),
                                )
                              else
                                ...recentFood.map((entry) => _buildEntryItem(entry, true)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SoftCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.local_fire_department, color: AppColors.secondary, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Activity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (recentBurn.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'No activities yet',
                                      style: TextStyle(fontSize: 12, color: AppColors.foreground.withValues(alpha: 0.4)),
                                    ),
                                  ),
                                )
                              else
                                ...recentBurn.map((entry) => _buildEntryItem(entry, false)),
                            ],
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildStatItem({
    required IconData icon,
    required int value,
    required String label,
    required Color color,
    String prefix = '',
  }) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          '$prefix$value',
          style: TextStyle(
            fontSize: 28,
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
    );
  }

  Widget _buildEntryItem(CalorieEntry entry, bool isFood) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.description,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.foreground.withValues(alpha: 0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${isFood ? '+' : '-'}${entry.amount}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isFood ? AppColors.accent : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _deleteEntry(entry),
            child: Icon(
              Icons.delete_outline,
              size: 16,
              color: Colors.red.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
