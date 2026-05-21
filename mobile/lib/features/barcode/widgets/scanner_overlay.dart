import 'package:flutter/material.dart';

/// Overlay that draws a dimmed background with a transparent rectangle in the
/// centre, white corner brackets, and a hint label. Sized responsively for
/// portrait & landscape orientations.
class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  static const _cornerColor = Colors.white;
  static const _cornerThick = 3.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackW = constraints.maxWidth;
        final stackH = constraints.maxHeight;
        final isLandscape = stackW > stackH;

        final frameW = isLandscape ? (stackW * 0.6).clamp(260.0, 480.0) : 280.0;
        final frameH = isLandscape ? (stackH * 0.55).clamp(100.0, 180.0) : 180.0;
        final cornerLen = isLandscape ? 22.0 : 26.0;

        final frameLeft = (stackW - frameW) / 2;
        final frameTop = (stackH - frameH) / 2 - 20;

        return Stack(
          children: [
            // Dimmed background with transparent cutout via SrcOut blend.
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.55),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(color: Colors.black),
                  Positioned(
                    left: frameLeft,
                    top: frameTop,
                    child: Container(
                      width: frameW, height: frameH,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Corner brackets.
            Positioned(
              left: frameLeft, top: frameTop,
              width: frameW, height: frameH,
              child: CustomPaint(
                painter: _CornerPainter(
                  cornerLen: cornerLen,
                  thickness: _cornerThick,
                  color: _cornerColor,
                  radius: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double cornerLen, thickness, radius;
  final Color color;
  _CornerPainter({
    required this.cornerLen,
    required this.thickness,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height, l = cornerLen, r = radius;

    // Top-left
    canvas.drawPath(Path()
      ..moveTo(0, l)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(l, 0), p);
    // Top-right
    canvas.drawPath(Path()
      ..moveTo(w - l, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, l), p);
    // Bottom-left
    canvas.drawPath(Path()
      ..moveTo(0, h - l)
      ..lineTo(0, h - r)
      ..arcToPoint(Offset(r, h), radius: Radius.circular(r), clockwise: false)
      ..lineTo(l, h), p);
    // Bottom-right
    canvas.drawPath(Path()
      ..moveTo(w - l, h)
      ..lineTo(w - r, h)
      ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r), clockwise: false)
      ..lineTo(w, h - l), p);
  }

  @override
  bool shouldRepaint(_CornerPainter o) => false;
}
