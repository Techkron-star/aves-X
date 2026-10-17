import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

// Semi-translucent faceted ruby, like a red diamond: a deep gradient with a lattice of light and dark facets.
// Static (no animation), so it costs almost nothing.
class DiamondDecoration extends Decoration {
  const DiamondDecoration();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _DiamondPainter();
}

class _DiamondPainter extends BoxPainter {
  static const _cell = 30.0;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    final rect = offset & size;

    canvas.save();
    canvas.clipRect(rect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE6D81B3F), Color(0xE67A0B22), Color(0xE6B01232)],
          stops: [0, .55, 1],
        ).createShader(rect),
    );

    final fill = Paint()..style = PaintingStyle.fill;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = const Color(0x22FFFFFF);
    final rows = (size.height / (_cell / 2)).ceil() + 1;
    final cols = (size.width / _cell).ceil() + 1;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        // rhombus lattice, every other row shifted by half a cell
        final cx = rect.left + c * _cell + (r.isOdd ? _cell / 2 : 0);
        final cy = rect.top + r * (_cell / 2);
        final h = ((r * 73856093) ^ (c * 19349663)) & 0xFF;
        final strength = .05 + (h / 255) * .2;
        fill.color = (h.isEven ? Colors.white : Colors.black).withValues(alpha: strength);
        final path = Path()
          ..moveTo(cx, cy - _cell / 2)
          ..lineTo(cx + _cell / 2, cy)
          ..lineTo(cx, cy + _cell / 2)
          ..lineTo(cx - _cell / 2, cy)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, line);
      }
    }

    // soft light from the top left corner
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment.topLeft,
          radius: 1.1,
          colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)],
        ).createShader(rect),
    );
    canvas.restore();
  }
}
