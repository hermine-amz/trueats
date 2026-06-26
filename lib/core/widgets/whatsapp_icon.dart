import 'dart:math';
import 'package:flutter/material.dart';

class WhatsAppBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28; // Fits within the outer green circle

    // Draw main bubble circle
    path.addOval(Rect.fromCircle(center: center, radius: radius));

    // Draw tail at the bottom-left of the circle (~135 degrees / 2.35 rad)
    final tailStart = Offset(
      center.dx + radius * cos(2.1),
      center.dy + radius * sin(2.1),
    );
    final tailEnd = Offset(
      center.dx + radius * cos(2.6),
      center.dy + radius * sin(2.6),
    );
    final tailTip = Offset(
      center.dx + radius * 1.5 * cos(2.35),
      center.dy + radius * 1.5 * sin(2.35),
    );

    path.moveTo(tailStart.dx, tailStart.dy);
    path.lineTo(tailTip.dx, tailTip.dy);
    path.lineTo(tailEnd.dx, tailEnd.dy);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WhatsAppIcon extends StatelessWidget {
  final double size;

  const WhatsAppIcon({this.size = 40.0, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF25D366), // Official WhatsApp Green
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: WhatsAppBubblePainter(),
          ),
          Padding(
            // Slight padding to center the phone handset inside the bubble (accounting for the tail)
            padding: EdgeInsets.only(
              bottom: size * 0.05,
              left: size * 0.05,
            ),
            child: Icon(
              Icons.phone,
              color: const Color(0xFF25D366),
              size: size * 0.38,
            ),
          ),
        ],
      ),
    );
  }
}
