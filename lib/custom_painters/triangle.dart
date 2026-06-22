import 'package:flutter/material.dart';

/// Triangular tab indicator used by the currency converter's [TabBar].
class TriangleTabIndicator extends Decoration {
  const TriangleTabIndicator({required this.color});

  final Color color;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _TrianglePainter(color);
}

class _TrianglePainter extends BoxPainter {
  _TrianglePainter(Color color)
      : _paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

  final Paint _paint;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final tip = offset + Offset(size.width / 2, size.height - 10);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + 10, tip.dy + 10)
      ..lineTo(tip.dx - 10, tip.dy + 10)
      ..close();
    canvas.drawPath(path, _paint);
  }
}
