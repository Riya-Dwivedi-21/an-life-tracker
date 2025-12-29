import 'dart:math';
import 'package:flutter/material.dart';
import '../../../shared/widgets/soft_card.dart';
import '../../../shared/widgets/wave_chart.dart';

class MetricCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final int value;
  final String unit;
  final Color color;

  const MetricCard({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> {
  String _period = 'today';

  List<double> _generateData(int count) {
    final random = Random();
    return List.generate(count, (_) => random.nextDouble() * 50 + 20);
  }

  List<double> get _currentData {
    switch (_period) {
      case 'weekly':
        return _generateData(7);
      case 'monthly':
        return _generateData(12);
      case 'yearly':
        return _generateData(12);
      default:
        return _generateData(12);
    }
  }

  void _cycleMainPeriod() {
    setState(() {
      if (_period == 'today') {
        _period = 'weekly';
      } else if (_period == 'weekly') {
        _period = 'monthly';
      } else {
        _period = 'today';
      }
    });
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.color, widget.color.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _cycleMainPeriod,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _period != 'yearly' ? widget.color : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _period == 'today' ? 'Today' : _period == 'weekly' ? 'Week' : 'Month',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _period != 'yearly' ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _period = _period == 'yearly' ? 'today' : 'yearly'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _period == 'yearly' ? widget.color : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Year',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _period == 'yearly' ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${widget.value}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  widget.unit,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          WaveChart(data: _currentData, color: widget.color),
        ],
      ),
    );
  }
}
