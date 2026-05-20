import 'package:flutter/material.dart';

class BarcodeIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const BarcodeIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ??
        IconTheme.of(context).color ??
        Theme.of(context).iconTheme.color ??
        Colors.black;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BarcodePainter(color: c)),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  final Color color;
  const _BarcodePainter({required this.color});

  // Each entry is [xFraction, widthFraction] — bars at these relative positions.
  static const _bars = [
    [0.00, 0.08], [0.12, 0.04], [0.20, 0.13], [0.37, 0.04],
    [0.45, 0.08], [0.57, 0.04], [0.65, 0.13], [0.82, 0.04],
    [0.90, 0.08],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final bar in _bars) {
      canvas.drawRect(
        Rect.fromLTWH(size.width * bar[0], 0, size.width * bar[1], size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => old.color != color;
}
