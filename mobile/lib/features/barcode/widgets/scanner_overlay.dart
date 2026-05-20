import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  static const double _cornerThick = 4;
  static const Color _cornerColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackW = constraints.maxWidth;
        final stackH = constraints.maxHeight;
        final isLandscape = stackW > stackH;

        // Keep the frame below the AppBar, which is overlaid on this body
        // because extendBodyBehindAppBar is true. MediaQuery.padding.top is
        // already 0 here (consumed by the outer AppShell SafeArea).
        const appBarH = kToolbarHeight;
        final usableH = stackH - appBarH;

        final frameW = isLandscape ? (stackW * 0.60).clamp(260.0, 480.0) : 280.0;
        final frameH = isLandscape
            ? (usableH * 0.55).clamp(100.0, 160.0)
            : 180.0;
        final cornerLen = isLandscape ? 18.0 : 24.0;

        final frameLeft = (stackW - frameW) / 2;
        final frameTop = appBarH + (usableH - frameH) / 2;
        final hintTop = (frameTop + frameH + 14).clamp(0.0, stackH - 24.0);

        return Stack(
          children: [
            // Dimmed overlay with transparent cutout at the frame position.
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.55),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(decoration: const BoxDecoration(color: Colors.black)),
                  Positioned(
                    left: frameLeft,
                    top: frameTop,
                    child: Container(
                      width: frameW,
                      height: frameH,
                      decoration: const BoxDecoration(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            // Corner brackets.
            Positioned(
              left: frameLeft,
              top: frameTop,
              child: SizedBox(
                width: frameW,
                height: frameH,
                child: CustomPaint(
                  painter: _CornerPainter(
                    cornerLen: cornerLen,
                    thickness: _cornerThick,
                    color: _cornerColor,
                  ),
                ),
              ),
            ),
            // Hint text below the frame.
            Positioned(
              top: hintTop,
              left: 0,
              right: 0,
              child: const Text(
                'Point your camera at a product barcode',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double cornerLen;
  final double thickness;
  final Color color;

  _CornerPainter({
    required this.cornerLen,
    required this.thickness,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final w = size.width;
    final h = size.height;
    final l = cornerLen;

    // Top-left
    canvas.drawPath(Path()..moveTo(0, l)..lineTo(0, 0)..lineTo(l, 0), paint);
    // Top-right
    canvas.drawPath(Path()..moveTo(w - l, 0)..lineTo(w, 0)..lineTo(w, l), paint);
    // Bottom-left
    canvas.drawPath(Path()..moveTo(0, h - l)..lineTo(0, h)..lineTo(l, h), paint);
    // Bottom-right
    canvas.drawPath(Path()..moveTo(w - l, h)..lineTo(w, h)..lineTo(w, h - l), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
