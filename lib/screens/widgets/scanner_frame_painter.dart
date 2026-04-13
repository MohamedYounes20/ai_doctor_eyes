import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Scanner Frame Painter
//
// Custom painter extracted from scanner_screen.dart.
// Draws classic 4-corner bracket overlays on the camera viewfinder.
//
// NO business logic — purely visual.
// ═══════════════════════════════════════════════════════════════════════════════

class ScannerFramePainter extends CustomPainter {
  final Color color;
  const ScannerFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Frame dimensions
    const frameW = 220.0;
    const frameH = 260.0;
    const cornerLen = 28.0;
    const radius = 10.0;

    final left = (size.width - frameW) / 2;
    final top = (size.height - frameH) / 2;
    final right = left + frameW;
    final bottom = top + frameH;

    // ── Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLen)
        ..lineTo(left, top + radius)
        ..quadraticBezierTo(left, top, left + radius, top)
        ..lineTo(left + cornerLen, top),
      paint,
    );
    // ── Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLen, top)
        ..lineTo(right - radius, top)
        ..quadraticBezierTo(right, top, right, top + radius)
        ..lineTo(right, top + cornerLen),
      paint,
    );
    // ── Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(right, bottom - cornerLen)
        ..lineTo(right, bottom - radius)
        ..quadraticBezierTo(right, bottom, right - radius, bottom)
        ..lineTo(right - cornerLen, bottom),
      paint,
    );
    // ── Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left + cornerLen, bottom)
        ..lineTo(left + radius, bottom)
        ..quadraticBezierTo(left, bottom, left, bottom - radius)
        ..lineTo(left, bottom - cornerLen),
      paint,
    );

    // ── Subtle centre cross-hair dot
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      3,
      paint..style = PaintingStyle.fill..color = color.withOpacity(0.6),
    );
  }

  @override
  bool shouldRepaint(ScannerFramePainter old) => old.color != color;
}
