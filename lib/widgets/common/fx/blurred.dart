import 'dart:ui';

import 'package:aves/model/settings/settings.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// stronger blur than before, for a frosted "liquid glass" look
const _blurConfig = ImageFilterConfig.blur(sigmaX: 14, sigmaY: 14);
// do not use `ColorFilter.matrix` for identity,
// as it yields performance issues when there are other layers on top
final _identity = ImageFilter.matrix(Matrix4.identity().storage);

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
    return ClipRect(
      child: BackdropFilter.grouped(
        // do not modify tree when disabling filter
        filter: enabled ? null : _identity,
        filterConfig: enabled ? _blurConfig : null,
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
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter.grouped(
        // do not modify tree when disabling filter
        filter: enabled ? null : _identity,
        filterConfig: enabled ? _blurConfig : null,
        child: DecoratedBox(
          // the decoration is always present so that the tree does not change when toggling the effect
          position: DecorationPosition.foreground,
          decoration: enabled
              ? BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: context.select<Settings, bool>((v) => v.batGlass) ? _rubyHighlight : _glassHighlight,
                  border: Border.all(color: context.select<Settings, bool>((v) => v.batGlass) ? _rubyEdgeColor : _glassEdgeColor, width: .8),
                )
              : const BoxDecoration(),
          child: child,
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
    return ClipOval(
      child: BackdropFilter.grouped(
        // do not modify tree when disabling filter
        filter: enabled ? null : _identity,
        filterConfig: enabled ? _blurConfig : null,
        child: DecoratedBox(
          // the decoration is always present so that the tree does not change when toggling the effect
          position: DecorationPosition.foreground,
          decoration: enabled
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: context.select<Settings, bool>((v) => v.batGlass) ? _rubyHighlight : _glassHighlight,
                  border: Border.fromBorderSide(BorderSide(color: context.select<Settings, bool>((v) => v.batGlass) ? _rubyEdgeColor : _glassEdgeColor, width: .8)),
                )
              : const BoxDecoration(),
          child: child,
        ),
      ),
    );
  }
}
