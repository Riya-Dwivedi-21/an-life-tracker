import 'dart:math';
import 'package:flutter/material.dart';

class DecorativeTimer extends StatefulWidget {
  final double progress;
  final String mode;
  final Widget child;

  const DecorativeTimer({
    super.key,
    required this.progress,
    required this.mode,
    required this.child,
  });

  @override
  State<DecorativeTimer> createState() => _DecorativeTimerState();
}

class _DecorativeTimerState extends State<DecorativeTimer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _outerColor {
    switch (widget.mode) {
      case 'mid':
        return const Color(0xFFFFB6C1);
      case 'high':
        return const Color(0xFFFFD700);
      default:
        return const Color(0xFF8BBDDD);
    }
  }

  Color get _innerColor {
    switch (widget.mode) {
      case 'mid':
        return const Color(0xFFFFDAB9);
      case 'high':
        return const Color(0xFFFFA500);
      default:
        return const Color(0xFFADD8E6);
    }
  }

  @override
  Widget build(BuildContext context) {
    const size = 240.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _outerColor.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Rotating wave decoration
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * pi,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _WavePainter(
                    color: _outerColor,
                    innerColor: _innerColor,
                    waves: widget.mode == 'high' ? 16 : widget.mode == 'mid' ? 12 : 8,
                  ),
                ),
              );
            },
          ),
          // Progress circle
          SizedBox(
            width: size - 40,
            height: size - 40,
            child: CircularProgressIndicator(
              value: widget.progress / 100,
              strokeWidth: 8,
              backgroundColor: Colors.black.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(_outerColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Content
          widget.child,
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  final Color innerColor;
  final int waves;

  _WavePainter({required this.color, required this.innerColor, required this.waves});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color, innerColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 - 15;
    const waveHeight = 8.0;

    for (int i = 0; i <= waves * 2; i++) {
      final angle = (2 * pi / (waves * 2)) * i - pi / 2;
      final waveRadius = baseRadius + (i % 2 == 0 ? waveHeight : -waveHeight);
      final x = center.dx + waveRadius * cos(angle);
      final y = center.dy + waveRadius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
