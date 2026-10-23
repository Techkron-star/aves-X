import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_effect.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/aves_logo_art.dart';
import 'package:aves/widgets/settings/nebula/nebula_theme_selector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// Pestaña Nebula: el escaparate del Nebula Engine.
//
// Estilo galáctico, siempre oscuro (independiente del tema elegido, porque aquí se enseñan
// los temas): gradiente radial negro → #0A001A → negro, nebulosa animada con un
// `CustomPainter`, estrellas que parpadean con `AnimatedOpacity` y partículas que
// flotan con `AnimatedPositioned`.
//
// Rendimiento: un único `AnimationController` mueve la nebulosa, un único `Timer`
// cambia las opacidades de las estrellas y otro recoloca las partículas. Todo se
// para en modo rendimiento o con las animaciones de accesibilidad desactivadas
// (`settings.animate` ya combina ambas), y el desenfoque de las tarjetas sigue
// `settings.enableBlurEffect`.
//
// El logo de la cabecera es el SVG exacto (`aves_logo.svg`) vía `AvesLogoArt`.

const _galaxyBlack = Color(0xFF000000);
const _galaxyDeep = Color(0xFF0A001A);
const _galaxyHalo = Color(0xFF1A0A33);
const _galaxyAccent = Color(0xFFB388FF);
const _galaxyMist = Color(0xFF6C3BB8);
const _galaxyRose = Color(0xFFE040FB);

class NebulaTab extends StatefulWidget {
  static const routeName = '/settings/nebula';

  const NebulaTab({super.key});

  @override
  State<NebulaTab> createState() => _NebulaTabState();
}

class _NebulaTabState extends State<NebulaTab> with SingleTickerProviderStateMixin {
  late final AnimationController _drift;
  late final Settings _settings;
  bool _ticking = false;

  @override
  void initState() {
    super.initState();
    _settings = context.read<Settings>();
    _drift = AnimationController(vsync: this, duration: const Duration(seconds: 18));
    _settings.addListener(_syncMotion);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMotion());
  }

  @override
  void dispose() {
    _settings.removeListener(_syncMotion);
    _drift.dispose();
    super.dispose();
  }

  /// Starts or parks the nebula ticker. `settings.animate` is false in
  /// performance mode and when the accessibility setting disables motion.
  void _syncMotion() {
    final animate = _settings.animate;
    if (animate == _ticking) return;
    _ticking = animate;
    if (animate) {
      _drift.repeat();
    } else {
      // Freeze the current frame. Resetting to a hard-coded phase made the
      // whole nebula jump when reduced-motion/performance mode was enabled.
      _drift.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    final animate = settings.animate;
    final blur = settings.enableBlurEffect && settings.glassEverywhere;

    return Theme(
      data: _galaxyTheme(context),
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          return AvesScaffold(
            backgroundColor: _galaxyBlack,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text(l10n.nebulaTabTitle),
            ),
            body: Stack(
              fit: StackFit.expand,
              children: [
                _GalaxyBackdrop(drift: _drift, animate: animate),

                // Efecto visual propio del tema activo (Night Demon, Godly, Forge, Hermetic,
                // Eclipse, Solar Flare, Void, Crimson, Neon, Emerald). Se pinta
                // sobre el fondo galáctico y se detiene en modo rendimiento.
                if (settings.nebulaTheme != NebulaTheme.aves && settings.nebulaTheme != NebulaTheme.nosferatuGlass)
                  nebulaEffectFor(settings.nebulaTheme, animate: animate) ??
                      const SizedBox(),

                SafeArea(
                  top: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    children: [
                      const _NebulaHeroCard(),
                      const SizedBox(height: 16),
                      _GlassCard(
                        blur: blur,
                        title: l10n.settingsNebulaTheme,
                        subtitle: l10n.settingsNebulaThemeSubtitle,
                        child: const NebulaThemeSelector(),
                      ),
                      const SizedBox(height: 16),
                      _GlassCard(
                        blur: blur,
                        title: l10n.nebulaGalaxyEffectsTitle,
                        subtitle: l10n.nebulaGalaxyEffectsBody,
                        child: _EffectsList(animate: animate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Theme used inside the tab: a dark galactic scheme, so the cards stay readable
// whatever the app theme is (this page is a showcase of the Nebula themes).
ThemeData _galaxyTheme(BuildContext context) {
  final base = Theme.of(context);
  final accent = settings.materialStyle?.accent ?? _galaxyAccent;
  final scheme = ColorScheme.dark(
    primary: accent,
    onPrimary: Color(0xFF1B0038),
    primaryContainer: Color.lerp(accent, const Color(0xFF120726), .55)!,
    onPrimaryContainer: Color(0xFFEDE7F6),
    secondary: Color(0xFF9FA8DA),
    onSecondary: Color(0xFF0A001A),
    tertiary: Color(0xFFFFB3E8),
    onTertiary: Color(0xFF2A0021),
    error: Color(0xFFFF6E8A),
    onError: Color(0xFF2A0007),
    surface: _galaxyDeep,
    onSurface: Color(0xFFEDE7F6),
    onSurfaceVariant: Color(0xFFB9B2CE),
    surfaceContainerLowest: _galaxyBlack,
    surfaceContainerLow: Color(0xFF120726),
    surfaceContainer: Color(0xFF180B31),
    surfaceContainerHigh: Color(0xFF1F0F3D),
    surfaceContainerHighest: Color(0xFF271246),
    outline: Color(0xFF7A68A3),
    outlineVariant: Color(0xFF4A3A6B),
  );
  return base.copyWith(brightness: Brightness.dark, colorScheme: scheme);
}

// ---------------------------------------------------------------- backdrop ---

class _GalaxyBackdrop extends StatelessWidget {
  final AnimationController drift;
  final bool animate;

  const _GalaxyBackdrop({required this.drift, required this.animate});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -.4),
                  radius: 1.15,
                  colors: [_galaxyHalo, _galaxyDeep, _galaxyBlack],
                  stops: [0, .5, 1],
                ),
              ),
            ),
            CustomPaint(
              painter: _NebulaPainter(drift: drift, animate: animate),
              isComplex: true,
              willChange: false,
            ),
            _StarField(animate: animate),
            _ParticleField(animate: animate),
          ],
        ),
      ),
    );
  }
}

class _NebulaBlob {
  final Color color;
  final Alignment alignment;
  final double radiusFactor;
  final double phase;
  final double drift;

  const _NebulaBlob({
    required this.color,
    required this.alignment,
    required this.radiusFactor,
    required this.phase,
    required this.drift,
  });
}

// Slow nebula: three radial gradients drifting on top of each other. One
// `AnimationController` drives the whole painter (`repaint:`), so no widget
// rebuilds while it moves.
class _NebulaPainter extends CustomPainter {
  static const _blobs = <_NebulaBlob>[
    _NebulaBlob(color: Color(0x666C3BB8), alignment: Alignment(-.55, -.45), radiusFactor: .85, phase: 0, drift: .16),
    _NebulaBlob(color: Color(0x4D3B1E7A), alignment: Alignment(.6, .1), radiusFactor: .95, phase: 2.1, drift: .12),
    _NebulaBlob(color: Color(0x4DE040FB), alignment: Alignment(.05, .75), radiusFactor: .55, phase: 4.2, drift: .2),
  ];

  final Animation<double> drift;
  final bool animate;

  _NebulaPainter({required this.drift, required this.animate}) : super(repaint: animate ? drift : null);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = animate ? drift.value * math.pi * 2 : .7;
    for (final blob in _blobs) {
      final base = blob.alignment.alongSize(size);
      final center = base +
          Offset(
            math.cos(t + blob.phase) * size.width * blob.drift,
            math.sin(t * .8 + blob.phase) * size.height * blob.drift,
          );
      final radius = size.shortestSide * blob.radiusFactor;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [blob.color, blob.color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..blendMode = BlendMode.plus;
      canvas.drawCircle(center, radius, paint);
    }
    // a faint dust lane crossing the nebula, to avoid a flat wash of color
    final lane = Paint()
      ..shader = RadialGradient(
        colors: [_galaxyMist.withValues(alpha: .22), _galaxyMist.withValues(alpha: 0)],
      ).createShader(
        Rect.fromCircle(center: Offset(size.width * .5, size.height * .55), radius: size.shortestSide * .75),
      );
    canvas.drawCircle(Offset(size.width * .5, size.height * .55), size.shortestSide * .75, lane);
  }

  @override
  bool shouldRepaint(covariant _NebulaPainter old) => old.animate != animate || old.drift != drift;
}

class _Star {
  final double left;
  final double top;
  final double size;
  final double phase;
  final double speed;
  final Duration duration;

  const _Star({
    required this.left,
    required this.top,
    required this.size,
    required this.phase,
    required this.speed,
    required this.duration,
  });
}

// Twinkling stars: positions are fixed, only the `AnimatedOpacity` targets change.
// A single `Timer` walks the field, so there is one timer for the whole page.
class _StarField extends StatefulWidget {
  final bool animate;

  const _StarField({required this.animate});

  @override
  State<_StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<_StarField> {
  static const _count = 24;

  late final List<_Star> _stars = _buildStars();
  Timer? _timer;
  int _tick = 0;

  List<_Star> _buildStars() {
    final random = math.Random(1337);
    return List<_Star>.generate(_count, (i) {
      return _Star(
        left: random.nextDouble(),
        top: random.nextDouble(),
        size: 1.4 + random.nextDouble() * 2.2,
        phase: random.nextDouble() * math.pi * 2,
        speed: .5 + random.nextDouble() * .8,
        duration: Duration(milliseconds: 500 + random.nextInt(1500)),
      );
    }, growable: false);
  }

  @override
  void initState() {
    super.initState();
    if (widget.animate) _startTimer();
  }

  @override
  void didUpdateWidget(covariant _StarField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _startTimer();
      } else {
        _timer?.cancel();
        _timer = null;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (mounted) setState(() => _tick++);
    });
  }

  double _opacityOf(_Star star) => .12 + .88 * (math.sin(_tick * star.speed + star.phase) * .5 + .5);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (final star in _stars)
              Positioned(
                left: star.left * constraints.maxWidth,
                top: star.top * constraints.maxHeight,
                child: AnimatedOpacity(
                  duration: star.duration,
                  curve: Curves.easeInOut,
                  opacity: widget.animate ? _opacityOf(star) : .55,
                  child: Container(
                    width: star.size,
                    height: star.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: _galaxyAccent.withValues(alpha: .45), blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Particle {
  final double left;
  final double top;
  final double size;
  final Duration duration;

  const _Particle({
    required this.left,
    required this.top,
    required this.size,
    required this.duration,
  });

  _Particle movedTo(double left, double top) => _Particle(
    left: left,
    top: top,
    size: size,
    duration: duration,
  );
}

// Floating particles: `AnimatedPositioned` glides each one to a new spot every
// few seconds, so the movement is smooth without a per-frame rebuild.
class _ParticleField extends StatefulWidget {
  final bool animate;

  const _ParticleField({required this.animate});

  @override
  State<_ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<_ParticleField> {
  static const _count = 6;

  final math.Random _random = math.Random(7);
  late List<_Particle> _particles = _buildParticles();
  Timer? _timer;

  List<_Particle> _buildParticles() {
    return List<_Particle>.generate(_count, (i) {
      return _Particle(
        left: _random.nextDouble(),
        top: _random.nextDouble(),
        size: 2.0 + _random.nextDouble() * 3.5,
        duration: Duration(seconds: 6 + _random.nextInt(5)),
      );
    }, growable: false);
  }

  @override
  void initState() {
    super.initState();
    if (widget.animate) _startTimer();
  }

  @override
  void didUpdateWidget(covariant _ParticleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _startTimer();
      } else {
        _timer?.cancel();
        _timer = null;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      setState(() {
        _particles = [
          for (final particle in _particles)
            particle.movedTo(
              (particle.left + (_random.nextDouble() - .5) * .35).clamp(.02, .95).toDouble(),
              (particle.top + (_random.nextDouble() - .5) * .35).clamp(.02, .95).toDouble(),
            ),
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (final particle in _particles)
              AnimatedPositioned(
                duration: particle.duration,
                curve: Curves.easeInOutSine,
                left: particle.left * constraints.maxWidth,
                top: particle.top * constraints.maxHeight,
                child: Container(
                  width: particle.size,
                  height: particle.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _galaxyRose.withValues(alpha: .35),
                    boxShadow: [
                      BoxShadow(color: _galaxyRose.withValues(alpha: .35), blurRadius: 8, spreadRadius: 1),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------------- cards ---

class _NebulaHeroCard extends StatelessWidget {
  const _NebulaHeroCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xCC2A1052), Color(0xCC0A001A)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.primary.withValues(alpha: .45)),
          boxShadow: [
            BoxShadow(color: scheme.primary.withValues(alpha: .22), blurRadius: 30, spreadRadius: -8),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: .35),
                border: Border.all(color: scheme.primary.withValues(alpha: .35)),
              ),
              padding: const EdgeInsets.all(8),
              child: const AvesLogoArt(size: 64),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.nebulaGalaxyHeroTitle,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: .2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.nebulaGalaxyHeroBody,
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: scheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.nebulaGalaxyPhase1,
                          style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool blur;

  const _GlassCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.blur = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(20);
    final surfaceColor = Colors.black.withValues(alpha: .7);

    // Keep the rim and glow outside the clipping layer. Clipping the entire card
    // cut off the shadows of theme pills and other VFX near the card's edges.
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: scheme.primary.withValues(alpha: .5)),
        boxShadow: [
          BoxShadow(color: scheme.primary.withValues(alpha: .18), blurRadius: 26, spreadRadius: -8),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: blur
                    ? BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: ColoredBox(color: surfaceColor),
                      )
                    : ColoredBox(color: surfaceColor),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.3)),
                ],
                const SizedBox(height: 14),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EffectsList extends StatelessWidget {
  final bool animate;

  const _EffectsList({required this.animate});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Icon(animate ? Icons.blur_on : Icons.blur_off, size: 18, color: animate ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                animate ? l10n.nebulaGalaxyAnimationsOn : l10n.nebulaGalaxyAnimationsOff,
                style: TextStyle(fontSize: 12, color: animate ? scheme.primary : scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const Divider(height: 24, color: Color(0x33FFFFFF)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: settings.enableBlurEffect,
          title: Text(l10n.settingsViewerEnableOverlayBlurEffect),
          onChanged: (v) => settings.enableBlurEffect = v,
        ),
      ],
    );
  }
}
