import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  static const double _frameW = 280;
  static const double _frameH = 180;
  static const double _cornerLen = 24;
  static const double _cornerThick = 4;
  static const Color _cornerColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dimmed overlay around the frame
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.55),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(decoration: const BoxDecoration(color: Colors.black)),
              Center(
                child: Container(
                  width: _frameW,
                  height: _frameH,
                  decoration: const BoxDecoration(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
        // Corner brackets
        Center(
          child: SizedBox(
            width: _frameW,
            height: _frameH,
            child: CustomPaint(painter: _CornerPainter(
              cornerLen: _cornerLen,
              thickness: _cornerThick,
              color: _cornerColor,
            )),
          ),
        ),
        // Hint text
        Positioned(
          bottom: MediaQuery.of(context).size.height / 2 - _frameH / 2 - 40,
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
