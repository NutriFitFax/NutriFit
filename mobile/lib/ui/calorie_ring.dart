import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/nutri_colors.dart';

/// A circular calorie progress ring with an ease-out sweep animation. Centre
/// content shows "kcal remaining" against [goal].
class CalorieRing extends StatefulWidget {
  /// Calories consumed so far (the ring fills proportionally to [goal]).
  final double value;

  /// Daily goal.
  final double goal;

  /// Outer ring size in logical pixels. Pick something between 100 and 220.
  final double size;

  /// Ring stroke width.
  final double stroke;

  /// Label rendered above the numeric ("REMAINING", "EATEN", etc).
  final String overline;

  const CalorieRing({
    super.key,
    required this.value,
    required this.goal,
    this.size = 200,
    this.stroke = 14,
    this.overline = 'Remaining',
  });

  @override
  State<CalorieRing> createState() => _CalorieRingState();
}

class _CalorieRingState extends State<CalorieRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..forward();
  }

  @override
  void didUpdateWidget(CalorieRing old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || old.goal != widget.goal) {
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final remaining = math.max(0, (widget.goal - widget.value).round());
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = Curves.easeOutCubic.transform(_ctrl.value);
          return CustomPaint(
            painter: _RingPainter(
              progress: math.min(1.05, widget.value / widget.goal) * t,
              track: c.line,
              fillStart: c.primary,
              fillEnd: const Color(0xFF5A9A6E),
              stroke: widget.stroke,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.overline.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: c.ink2,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$remaining',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: widget.size * 0.26,
                          height: 1.0,
                          color: c.ink,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'kcal of ${widget.goal.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12, color: c.ink2, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double stroke;
  final Color track;
  final Color fillStart;
  final Color fillEnd;

  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.track,
    required this.fillStart,
    required this.fillEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    // Sweep
    final sweep = 2 * math.pi * progress;
    if (sweep <= 0) return;
    final shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + 2 * math.pi,
      colors: [fillStart, fillEnd, fillStart],
      stops: const [0.0, 0.6, 1.0],
    ).createShader(rect);

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.stroke != stroke || old.fillStart != fillStart;
}
