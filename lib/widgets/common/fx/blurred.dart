import 'dart:ui';

import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/fx/diamond.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// stronger blur than before, for a frosted "liquid glass" look
const _blurConfig = ImageFilterConfig.blur(sigmaX: 14, sigmaY: 14);
// Glass-Everywhere 2.0: heavy frost, neutral milky tint (content behind is only a soft colour field)
const _frostConfig = ImageFilterConfig.blur(sigmaX: 26, sigmaY: 26);
// Bat-Glass 2.0: light blur, so the ruby crystal stays see-through
const _crystalConfig = ImageFilterConfig.blur(sigmaX: 7, sigmaY: 7);
const _frostHighlight = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0x40FFFFFF), Color(0x14FFFFFF), Color(0x08FFFFFF)],
  stops: [0, .5, 1],
);
const _frostEdgeColor = Color(0x55FFFFFF);

ImageFilterConfig _configFor(bool bat, bool frost) => bat ? _crystalConfig : (frost ? _frostConfig : _blurConfig);
Gradient _gradientFor(bool bat, bool frost) => bat ? _rubyHighlight : (frost ? _frostHighlight : _glassHighlight);
Color _edgeFor(bool bat, bool frost) => bat ? _rubyEdgeColor : (frost ? _frostEdgeColor : _glassEdgeColor);
// when the effect is disabled, no `BackdropFilter` is installed at all: an identity filter
// (or `ColorFilter.matrix`) would still force a backdrop layer and a per-frame sample
// without changing a single pixel.

// subtle light reflection and edge highlight painted over the blurred content
const _glassHighlight = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0x26FFFFFF), Color(0x03FFFFFF)],
);
const _glassEdgeColor = Color(0x38FFFFFF);
// "Bat glass" ruby variant
const _rubyHighlight = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0x55E0183E), Color(0x14400010)],
);
const _rubyEdgeColor = Color(0x80FF3B5C);

class BlurredRect extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const new({
    super.key,
    this.enabled = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return ClipRect(child: child);
    return ClipRect(
      child: BackdropFilter.grouped(
        filter: null,
        filterConfig: _blurConfig,
        child: child,
      ),
    );
  }
}

class BlurredRRect extends StatelessWidget {
  final bool enabled;
  final BorderRadius? borderRadius;
  final Widget child;

  const new({
    super.key,
    this.enabled = true,
    required this.borderRadius,
    required this.child,
  });

  factory all({
    Key? key,
    bool enabled = true,
    required double borderRadius,
    required Widget child,
  }) {
    return BlurredRRect(
      key: key,
      enabled: enabled,
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    // disabling the effect must not install a backdrop layer, as the identity filter is a no-op that still costs a sample per frame
    if (!enabled) return ClipRRect(borderRadius: radius, child: child);
    final bat = context.select<Settings, bool>((v) => v.batGlass);
    final frost = context.select<Settings, bool>((v) => v.glassEverywhere);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter.grouped(
        filter: null,
        filterConfig: _configFor(bat, frost),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: _gradientFor(bat, frost),
            border: Border.all(color: _edgeFor(bat, frost), width: .8),
          ),
          // Bat-Glass: the surface itself becomes a see-through ruby crystal
          child: bat ? DecoratedBox(decoration: const DiamondDecoration(opacity: .34), child: child) : child,
        ),
      ),
    );
  }
}

class BlurredOval extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const new({
    super.key,
    this.enabled = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // disabling the effect must not install a backdrop layer, as the identity filter is a no-op that still costs a sample per frame
    if (!enabled) return ClipOval(child: child);
    final bat = context.select<Settings, bool>((v) => v.batGlass);
    final frost = context.select<Settings, bool>((v) => v.glassEverywhere);
    return ClipOval(
      child: BackdropFilter.grouped(
        filter: null,
        filterConfig: _configFor(bat, frost),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _gradientFor(bat, frost),
            border: Border.fromBorderSide(BorderSide(color: _edgeFor(bat, frost), width: .8)),
          ),
          // Bat-Glass: the surface itself becomes a see-through ruby crystal
          child: bat ? DecoratedBox(decoration: const DiamondDecoration(opacity: .34), child: child) : child,
        ),
      ),
    );
  }
}
