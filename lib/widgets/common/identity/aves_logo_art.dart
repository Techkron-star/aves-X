import 'package:aves/widgets/common/identity/aves_logo_art_data.dart';
import 'package:aves/widgets/common/identity/svg_path_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

// The Aves-X bat artwork, exactly as drawn in `aves_logo.svg`.
//
// The source file is a traced illustration: 155 filled paths in dark ruby, black
// and light highlights, painted in a fixed order. Both the PNG-free Android
// launcher icon and the in-app marks read the same geometry, so the brand mark
// is identical everywhere and only the ink changes.
//
// Three treatments are supported:
// - artwork: the original fills, one colour per path (brand look),
// - tint: a single ink painted over every path, which yields the exact
//   silhouette because the fills are opaque and overlap (themed/Material You
//   icon, monochrome tone),
// - gradient: the same silhouette painted with a gradient, for accents.
//
// The paths are parsed lazily once per process and reused; painting is a plain
// set of `drawPath` calls, so `CustomPaint(isComplex: true)` can cache the layer
// on low-end devices and in performance mode.

/// Parsed artwork paths, in painting order. Lazily built on first use.
final List<Path> avesLogoArtPaths = List<Path>.unmodifiable(<Path>[for (final d in kAvesLogoPaths) parseSvgPath(d)]);

/// Fill of each entry of [avesLogoArtPaths].
final List<Color> avesLogoArtFills = List<Color>.unmodifiable(<Color>[for (final value in kAvesLogoPathFills) Color(value)]);

/// Ink area of the artwork, in `viewBox` units (the white canvas is excluded).
const Rect avesLogoArtInk = Rect.fromLTRB(kAvesLogoInkLeft, kAvesLogoInkTop, kAvesLogoInkRight, kAvesLogoInkBottom);

/// Paints [avesLogoArtPaths] fitted into the canvas.
class AvesLogoArtPainter extends CustomPainter {
  /// Single ink for every path. Produces the silhouette of the artwork.
  final Color? tint;

  /// Gradient for the silhouette. Ignored when [tint] is set.
  final List<Color>? gradient;

  /// Fraction of the shortest side the ink occupies. `1` fills the box.
  final double fit;

  const AvesLogoArtPainter({
    this.tint,
    this.gradient,
    this.fit = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final ink = avesLogoArtInk;
    final double side = size.shortestSide * fit.clamp(0.0, 1.0).toDouble();
    final scale = side / ink.longestSide;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-ink.center.dx, -ink.center.dy);

    final tint = this.tint;
    final gradient = this.gradient;
    if (tint != null) {
      _paintAll(canvas, Paint()..color = tint);
    } else if (gradient != null && gradient.isNotEmpty) {
      final paint = gradient.length < 2
          ? (Paint()..color = gradient.first)
          : (Paint()
              ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ).createShader(ink));
      _paintAll(canvas, paint);
    } else {
      final fills = avesLogoArtFills;
      for (var i = 0; i < avesLogoArtPaths.length; i++) {
        canvas.drawPath(
          avesLogoArtPaths[i],
          Paint()
            ..style = PaintingStyle.fill
            ..color = fills[i],
        );
      }
    }
    canvas.restore();
  }

  void _paintAll(Canvas canvas, Paint paint) {
    final paintFill = paint..style = PaintingStyle.fill;
    for (final path in avesLogoArtPaths) {
      canvas.drawPath(path, paintFill);
    }
  }

  @override
  bool shouldRepaint(covariant AvesLogoArtPainter old) => old.tint != tint || old.fit != fit || !listEquals(old.gradient, gradient);
}

/// Convenience widget: the artwork in a square box, RTL-flipped by the caller.
class AvesLogoArt extends StatelessWidget {
  final double size;
  final Color? tint;
  final List<Color>? gradient;
  final double fit;
  final String? semanticLabel;

  const AvesLogoArt({
    super.key,
    this.size = 64,
    this.tint,
    this.gradient,
    this.fit = 1,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: AvesLogoArtPainter(tint: tint, gradient: gradient, fit: fit),
          isComplex: true,
          willChange: false,
        ),
      ),
    );
  }
}
