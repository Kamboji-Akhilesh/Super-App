import 'package:flutter/material.dart';

class TriangleTabIndicator extends Decoration {
  final BoxPainter _painter;

  TriangleTabIndicator({required Color color}) : _painter = DrawTriangle(color);

  @override
  BoxPainter createBoxPainter([void Function()? onChanged]) => _painter;
}

class DrawTriangle extends BoxPainter {
  final Paint _paint;

  DrawTriangle(Color color)
      : _paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Offset triangleOffset = offset +
        Offset(configuration.size!.width / 2, configuration.size!.height - 10);
    var path = Path()
      ..moveTo(triangleOffset.dx, triangleOffset.dy)
      ..lineTo(triangleOffset.dx + 10, triangleOffset.dy + 10)
      ..lineTo(triangleOffset.dx - 10, triangleOffset.dy + 10);
    path.close();
    canvas.drawPath(path, _paint);
  }
}
