import 'package:flutter/material.dart';

class BreakOptions extends StatelessWidget {
  final Function(int) onSelect;

  const BreakOptions({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final breakOptions = [
      {'duration': 2, 'label': '2 min', 'icon': Icons.local_cafe},
      {'duration': 5, 'label': '5 min', 'icon': Icons.coffee},
      {'duration': 10, 'label': '10 min', 'icon': Icons.free_breakfast},
      {'duration': 20, 'label': '20 min', 'icon': Icons.restaurant},
      {'duration': 30, 'label': '30 min', 'icon': Icons.lunch_dining},
    ];

    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.coffee, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Take a Break',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...breakOptions.map((option) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => onSelect(option['duration'] as int),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFB923C), Color(0xFFF472B6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(option['icon'] as IconData, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      option['label'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => onSelect(-1),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Center(
                child: Text(
                  'End Session',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
