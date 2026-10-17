import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/themes.dart';
import 'package:material_ui/material_ui.dart';

// "Bat glass": icons get a slow liquid highlight flowing inside them.
// No-op without Bat glass, or when animations are disabled (e.g. performance mode).
class LiquidIcon extends StatefulWidget {
  final Widget child;

  const LiquidIcon({super.key, required this.child});

  @override
  State<LiquidIcon> createState() => _LiquidIconState();
}

class _LiquidIconState extends State<LiquidIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));

  @override
  void initState() {
    super.initState();
    if (_active) _controller.repeat();
  }

  bool get _active => settings.batGlass && settings.animate;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) {
      _controller.stop();
      return widget.child;
    }
    if (!_controller.isAnimating) _controller.repeat();

    final base = IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    final highlight = Color.lerp(base, const Color(0xFFFF8A9B), .9)!.withValues(alpha: base.a);
    final deep = Color.lerp(base, Themes.batGlassRuby, .35)!.withValues(alpha: base.a);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [deep, highlight, base, deep],
            stops: const [0, .35, .65, 1],
            tileMode: TileMode.repeated,
            transform: _LiquidSlide(_controller.value),
          ).createShader(bounds),
          child: child,
        ),
      ),
    );
  }
}

class _LiquidSlide extends GradientTransform {
  final double t;

  const _LiquidSlide(this.t);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // slide diagonally by one full period, with a slight vertical wobble
    final wobble = (t * 2 - 1).abs() * bounds.height * .15;
    return Matrix4.translationValues(bounds.width * (t * 2 - 1), bounds.height * (t * 2 - 1) * .6 + wobble, 0);
  }
}

// Glass look for selectable controls (switches, tiles, checkboxes) when
// "Glass everywhere" or "Bat glass" is on.
class GlassThemeScope extends StatelessWidget {
  final Widget? child;

  const GlassThemeScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final child = this.child ?? const SizedBox();
        if (!(settings.glassEverywhere || settings.batGlass)) return child;

        final theme = Theme.of(context);
        final bat = settings.batGlass;
        final isDark = theme.brightness == Brightness.dark;
        final accent = bat ? Themes.batGlassRuby : theme.colorScheme.primary;
        final edge = bat ? const Color(0x80FF3B5C) : (isDark ? const Color(0x55FFFFFF) : const Color(0x55000000));
        final tint = isDark ? const Color(0x12FFFFFF) : const Color(0x0C000000);
        return Theme(
          data: theme.copyWith(
            switchTheme: SwitchThemeData(
              trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accent.withValues(alpha: .55) : tint),
              trackOutlineColor: WidgetStateProperty.all(edge),
              thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white.withValues(alpha: .92) : edge),
            ),
            checkboxTheme: CheckboxThemeData(
              fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accent.withValues(alpha: .7) : tint),
              side: BorderSide(color: edge, width: 1.4),
            ),
            radioTheme: RadioThemeData(
              fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accent : edge),
            ),
            listTileTheme: theme.listTileTheme.copyWith(
              selectedTileColor: accent.withValues(alpha: .18),
            ),
          ),
          child: child,
        );
      },
    );
  }
}
