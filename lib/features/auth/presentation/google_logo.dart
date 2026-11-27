import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final rect = Rect.fromLTWH(2 * s, 2 * s, 20 * s, 20 * s);

    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * s
      ..strokeCap = StrokeCap.butt;

    // Google G's four color arcs.
    p.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.45, 1.25, false, p);

    p.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.80, 1.45, false, p);

    p.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.25, 1.40, false, p);

    p.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.65, 1.75, false, p);

    p.color = const Color(0xFF4285F4);
    p.strokeWidth = 4 * s;

    canvas.drawLine(
      Offset(12 * s, 12 * s),
      Offset(22 * s, 12 * s),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}