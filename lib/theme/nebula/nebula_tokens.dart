import 'package:aves/theme/nebula/nebula_palette.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

// Theme tokens of the Nebula Engine.
//
// They are read by `Theme.of(context).nebula` instead of hard-coded colors, so that Fail-Safe and the
// other themed surfaces follow the selected theme while keeping the same shape and meaning.
// The Fail-Safe tokens are theme-aware: the surface, border, glow and accent come from the theme,
// while the semantic ones (ok, warning, alert) stay readable across themes.
@immutable
class NebulaTokens extends ThemeExtension<NebulaTokens> {
  // Legacy Fail-Safe look (ruby crystal over black, comic paper bubble).
  // Used as the fallback for a `ThemeData` that does not carry the extension, and as the Nosferatu Glass recipe,
  // so that Nosferatu Glass keeps looking exactly as before the Nebula Engine.
  static const _legacyScrim = Color(0xFF000000);
  static const _legacySecuritySurface = Color(0xFF24060E);
  static const _legacyComicPaper = Color(0xFFFFFBF0);
  static const _legacyComicInk = Color(0xFF14121A);
  static const _ok = Color(0xFF3DDC84);
  static const _alert = Color(0xFFFF3B3B);
  static const _warning = Color(0xFFFFC107); // same as `AColors.warning`
  static const _info = Color(0xFF64B5F6);

  // Fail-Safe

  // full screen layer behind the lockdown and the blocking screens
  final Color securityScrim;
  // main surface of the Fail-Safe cards and panels
  final Color securitySurface;
  final Color securityOnSurface;
  final Color securityAccent;
  final Color securityAlert;
  final Color securityOk;
  final Color securityWarning;
  final Color securityInfo;

  // comic speech bubble of the Fail-Safe character
  final Color securityBubbleSurface;
  final Color securityBubbleBorder;
  final Color securityBubbleTail;
  final Color securityBubbleGlow;
  final Color securityBubbleShadow;
  // readable text on the comic bubble, independent from the main surface contrast
  final Color securityBubbleInk;

  // crystal material (lockdown, badges)
  final Color securityCrystalEdge;
  final Color securityCrystalHighlight;
  final List<Color> securityCrystalBody;

  // lock screen input fields
  final Color securityInputFieldBg;
  final Color securityInputFieldBorder;
  final Color securityScrimOverlay;

  const NebulaTokens({
    required this.securityScrim,
    required this.securitySurface,
    required this.securityOnSurface,
    required this.securityAccent,
    required this.securityAlert,
    required this.securityOk,
    required this.securityWarning,
    required this.securityInfo,
    required this.securityBubbleSurface,
    required this.securityBubbleBorder,
    required this.securityBubbleTail,
    required this.securityBubbleGlow,
    required this.securityBubbleShadow,
    required this.securityBubbleInk,
    required this.securityCrystalEdge,
    required this.securityCrystalHighlight,
    required this.securityCrystalBody,
    required this.securityInputFieldBg,
    required this.securityInputFieldBorder,
    required this.securityScrimOverlay,
  });

  // Values of the Fail-Safe screens as they were before the Nebula Engine (ruby/black).
  // A theme without tokens must never crash nor look unfinished.
  static const fallback = NebulaTokens(
    securityScrim: _legacyScrim,
    securitySurface: _legacySecuritySurface,
    securityOnSurface: Color(0xFFFFFFFF),
    securityAccent: Color(0xFFE0183E),
    securityAlert: _alert,
    securityOk: _ok,
    securityWarning: _warning,
    securityInfo: _info,
    securityBubbleSurface: _legacyComicPaper,
    securityBubbleBorder: _legacyComicInk,
    securityBubbleTail: _legacyComicPaper,
    securityBubbleGlow: Color(0x66E0183E),
    securityBubbleShadow: _legacyComicInk,
    securityBubbleInk: _legacyComicInk,
    securityCrystalEdge: Color(0x80FF3B5C),
    securityCrystalHighlight: Color(0x55E0183E),
    securityCrystalBody: [
      Color(0xFFFF4A66),
      Color(0xFFD81B3F),
      Color(0xFF8E0E2B),
      Color(0xFF4A0414),
    ],
    securityInputFieldBg: Color(0xFF1A0000),
    securityInputFieldBorder: Color(0xFFE0183E),
    securityScrimOverlay: Color(0xCC000000),
  );

  // Tokens of a palette applied on top of the effective color scheme.
  factory NebulaTokens.fromPalette(NebulaPalette palette, ColorScheme colors) => switch (palette.treatment) {
    NebulaSurfaceTreatment.nosferatuGlass => _nosferatu(palette),
    NebulaSurfaceTreatment.obsidianGlass => _obsidian(palette),
    NebulaSurfaceTreatment.aureateGlass => _aureate(palette),
    NebulaSurfaceTreatment.forgeGlass => _forge(palette),
    NebulaSurfaceTreatment.hermeticGlass => _hermetic(palette),
    NebulaSurfaceTreatment.eclipseGlass => _eclipse(palette),
    NebulaSurfaceTreatment.solarFlareGlass => _solarFlare(palette),
    NebulaSurfaceTreatment.voidGlass => _void(palette),
    NebulaSurfaceTreatment.crimsonGlass => _crimson(palette),
    NebulaSurfaceTreatment.neonGlass => _neon(palette),
    NebulaSurfaceTreatment.emeraldGlass => _emerald(palette),
    NebulaSurfaceTreatment.flat || NebulaSurfaceTreatment.frosted => _fromScheme(palette, colors),
  };

  // Nosferatu Glass (former Bat-Glass): the current Fail-Safe look, with the palette accent/edges/body.
  // Values are intentionally identical to the pre-Nebula Bat-Glass recipe.
  static NebulaTokens _nosferatu(NebulaPalette palette) => NebulaTokens(
    securityScrim: _legacyScrim,
    securitySurface: _legacySecuritySurface,
    securityOnSurface: const Color(0xFFFFFFFF),
    securityAccent: palette.accent,
    securityAlert: _alert,
    securityOk: _ok,
    securityWarning: _warning,
    securityInfo: _info,
    securityBubbleSurface: _legacyComicPaper,
    securityBubbleBorder: _legacyComicInk,
    securityBubbleTail: _legacyComicPaper,
    securityBubbleGlow: palette.glow.withValues(alpha: .4),
    securityBubbleShadow: _legacyComicInk,
    securityBubbleInk: _legacyComicInk,
    securityCrystalEdge: palette.crystalEdge,
    securityCrystalHighlight: palette.crystalHighlight,
    securityCrystalBody: palette.crystalBody,
    securityInputFieldBg: _legacySecuritySurface,
    securityInputFieldBorder: palette.accent,
    securityScrimOverlay: _legacyScrim.withValues(alpha: .8),
  );

  // Obsidian Glass (former Night Demon): near-black violet crystal, dark bubble with white ink.
  // Distinct from Nosferatu Glass: purple instead of ruby.
  static NebulaTokens _obsidian(NebulaPalette palette) => NebulaTokens(
    securityScrim: const Color(0xFF000000),
    securitySurface: const Color(0xFF12001A),
    securityOnSurface: const Color(0xFFFFFFFF),
    securityAccent: const Color(0xFF9B5DE5),
    securityAlert: const Color(0xFFFF6E8A),
    securityOk: _ok,
    securityWarning: _warning,
    securityInfo: _info,
    securityBubbleSurface: const Color(0xFF1A002A),
    securityBubbleBorder: const Color(0xFF9B5DE5),
    securityBubbleTail: const Color(0xFF1A002A),
    securityBubbleGlow: const Color(0x669B5DE5),
    securityBubbleShadow: const Color(0xFF000000),
    securityBubbleInk: const Color(0xFFFFFFFF),
    securityCrystalEdge: const Color(0x806A1B9A),
    securityCrystalHighlight: const Color(0x559B5DE5),
    securityCrystalBody: palette.crystalBody,
    securityInputFieldBg: const Color(0xFF12001A),
    securityInputFieldBorder: const Color(0xFF9B5DE5),
    securityScrimOverlay: const Color(0xCC000000),
  );

  // Aureate Glass (former Godly): warm gold crystal with a parchment comic bubble.
  static NebulaTokens _aureate(NebulaPalette palette) => NebulaTokens(
    securityScrim: const Color(0xFF000000),
    securitySurface: const Color(0xFF1A1409),
    securityOnSurface: const Color(0xFFFFF8E7),
    securityAccent: const Color(0xFFE8C547),
    securityAlert: _alert,
    securityOk: _ok,
    securityWarning: _warning,
    securityInfo: _info,
    securityBubbleSurface: const Color(0xFFFFF4D6),
    securityBubbleBorder: const Color(0xFF8A6A1F),
    securityBubbleTail: const Color(0xFFFFF4D6),
    securityBubbleGlow: const Color(0x66E8C547),
    securityBubbleShadow: const Color(0xFF3A2A08),
    securityBubbleInk: const Color(0xFF20180A),
    securityCrystalEdge: const Color(0x80FFE08A),
    securityCrystalHighlight: const Color(0x55FFF2C0),
    securityCrystalBody: palette.crystalBody,
    securityInputFieldBg: const Color(0xFF2C2312),
    securityInputFieldBorder: const Color(0xFFE8C547),
    securityScrimOverlay: const Color(0xCC000000),
  );

  // Forge Glass (former Cosmic Forge): cosmic violet crystal with molten-orange accents.
  static NebulaTokens _forge(NebulaPalette palette) => NebulaTokens(
    securityScrim: const Color(0xFF000000),
    securitySurface: const Color(0xFF1B1533),
    securityOnSurface: const Color(0xFFF3EEFF),
    securityAccent: const Color(0xFFFF7A18),
    securityAlert: const Color(0xFFFF4D4D),
    securityOk: _ok,
    securityWarning: _warning,
    securityInfo: _info,
    securityBubbleSurface: const Color(0xFF241B44),
    securityBubbleBorder: const Color(0xFFFF7A18),
    securityBubbleTail: const Color(0xFF241B44),
    securityBubbleGlow: const Color(0x66FF7A18),
    securityBubbleShadow: const Color(0xFF000000),
    securityBubbleInk: const Color(0xFFF3EEFF),
    securityCrystalEdge: const Color(0x80FF7A18),
    securityCrystalHighlight: const Color(0x55FFB067),
    securityCrystalBody: palette.crystalBody,
    securityInputFieldBg: const Color(0xFF1B1533),
    securityInputFieldBorder: const Color(0xFFFF7A18),
    securityScrimOverlay: const Color(0xCC000000),
  );

  // Hermetic Glass (former Hermetisc): emerald crystal with violet edges.
  static NebulaTokens _hermetic(NebulaPalette palette) => NebulaTokens(
    securityScrim: const Color(0xFF000000),
    securitySurface: const Color(0xFF112B21),
    securityOnSurface: const Color(0xFFEAFBF3),
    securityAccent: const Color(0xFF35E0A1),
    securityAlert: const Color(0xFFFF5252),
    securityOk: _ok,
    securityWarning: _warning,
    securityInfo: _info,
    securityBubbleSurface: const Color(0xFF17382B),
    securityBubbleBorder: const Color(0x809B7BFF),
    securityBubbleTail: const Color(0xFF17382B),
    securityBubbleGlow: const Color(0x6635E0A1),
    securityBubbleShadow: const Color(0xFF000000),
    securityBubbleInk: const Color(0xFFEAFBF3),
    securityCrystalEdge: const Color(0x809B7BFF),
    securityCrystalHighlight: const Color(0x5535E0A1),
    securityCrystalBody: palette.crystalBody,
    securityInputFieldBg: const Color(0xFF112B21),
    securityInputFieldBorder: const Color(0x809B7BFF),
    securityScrimOverlay: const Color(0xCC000000),
  );

  // Eclipse Glass: deep midnight blue crystal with electric cyan accents.
  static NebulaTokens _eclipse(NebulaPalette palette) => NebulaTokens(
    securityScrim: const Color(0xFF000000),
    securitySurface: const Color(0xFF0A0E26),
    securityOnSurface: const Color(0xFFFFFFFF),
    securityAccent: const Color(0xFF00B0FF),
    securityAlert: const Color(0xFFFF6E8A),
    securityOk: _ok,
    securityWarning: _warning,
    securityInfo: _info,
    securityBubbleSurface: const Color(0xFF0A163A),
    securityBubbleBorder: const Color(0xFF00B0FF),
    securityBubbleTail: const Color(0xFF0A0E26),
    securityBubbleGlow: const Color(0x6600B0FF),
    securityBubbleShadow: const Color(0xFF000000),
    securityBubbleInk: const Color(0xFFFFFFFF),
    securityCrystalEdge: const Color(0x8000E5FF),
    securityCrystalHighlight: const Color(0x554FB3FF),
    securityCrystalBody: palette.crystalBody,
    securityInputFieldBg: const Color(0xFF0A0E26),
    securityInputFieldBorder: const Color(0xFF00B0FF),
    securityScrimOverlay: const Color(0xCC000000),
  );

  // Solar Flare Glass: molten orange crystal with gold accents.
  static NebulaTokens _solarFlare(NebulaPalette palette) => NebulaTokens(
    securityScrim: const Color(0xFF000000),
    securitySurface: const Color(0xFF1A0A00),
    securityOnSurface: const Color(0xFFFFFFFF),
    securityAccent: const Color(0xFFFFB300),
    securityAlert: const Color(0xFFFF6E8A),
    securityOk: _ok,
    securityWarning: _warning,
    securityInfo: _info,
    securityBubbleSurface: const Color(0xFF241000),
    securityBubbleBorder: const Color(0xFFFFB300),
    securityBubbleTail: const Color(0xFF1A0A00),
    securityBubbleGlow: const Color(0x66FFB300),
    securityBubbleShadow: const Color(0xFF000000),
    securityBubbleInk: const Color(0xFFFFFFFF),
    securityCrystalEdge: const Color(0x80FFF176),
    securityCrystalHighlight: const Color(0x55FFF59D),
    securityCrystalBody: palette.crystalBody,
    securityInputFieldBg: const Color(0xFF1A0A00),
    securityInputFieldBorder: const Color(0xFFFFB300),
    securityScrimOverlay: const Color(0xCC000000),
  );

  // Void Glass: neon green crystal on graphite black.
  static NebulaTokens _void(NebulaPalette palette) => NebulaTokens(
    securityScrim: const Color(0xFF000000),
    securitySurface: const Color(0xFF121212),
    securityOnSurface: const Color(0xFFFFFFFF),
    securityAccent: const Color(0xFF00E676),
    securityAlert: const Color(0xFFFF6E8A),
    securityOk: _ok,
    securityWarning: _warning,
    securityInfo: _info,
    securityBubbleSurface: const Color(0xFF1A1A1A),
    securityBubbleBorder: const Color(0xFF00E676),
    securityBubbleTail: const Color(0xFF121212),
    securityBubbleGlow: const Color(0x6600E676),
    securityBubbleShadow: const Color(0xFF000000),
    securityBubbleInk: const Color(0xFFFFFFFF),
    securityCrystalEdge: const Color(0x8069F0AE),
    securityCrystalHighlight: const Color(0x55A5FF91),
    securityCrystalBody: palette.crystalBody,
    securityInputFieldBg: const Color(0xFF121212),
    securityInputFieldBorder: const Color(0xFF00E676),
    securityScrimOverlay: const Color(0xCC000000),
  );

  // Crimson Glass: burgundy crystal with dark red accents.
  static NebulaTokens _crimson(NebulaPalette palette) => NebulaTokens(
    securityScrim: const Color(0xFF000000),
    securitySurface: const Color(0xFF1A000A),
    securityOnSurface: const Color(0xFFFFFFFF),
    securityAccent: const Color(0xFFAD1457),
    securityAlert: const Color(0xFFFF6E8A),
    securityOk: _ok,
    securityWarning: _warning,
    securityInfo: _info,
    securityBubbleSurface: const Color(0xFF240010),
    securityBubbleBorder: const Color(0xFFAD1457),
    securityBubbleTail: const Color(0xFF1A000A),
    securityBubbleGlow: const Color(0x66AD1457),
    securityBubbleShadow: const Color(0xFF000000),
    securityBubbleInk: const Color(0xFFFFFFFF),
    securityCrystalEdge: const Color(0x80F48FB1),
    securityCrystalHighlight: const Color(0x55F06292),
    securityCrystalBody: palette.crystalBody,
    securityInputFieldBg: const Color(0xFF1A000A),
    securityInputFieldBorder: const Color(0xFFAD1457),
    securityScrimOverlay: const Color(0xCC000000),
  );

  // Neon Glass: hot pink crystal with electric blue accents on black.
  static NebulaTokens _neon(NebulaPalette palette) => NebulaTokens(
    securityScrim: const Color(0xFF000000),
    securitySurface: const Color(0xFF1A001A),
    securityOnSurface: const Color(0xFFFFFFFF),
    securityAccent: const Color(0xFF00FFFF),
    securityAlert: const Color(0xFFFF6E8A),
    securityOk: _ok,
    securityWarning: _warning,
    securityInfo: _info,
    securityBubbleSurface: const Color(0xFF240024),
    securityBubbleBorder: const Color(0xFFFF00FF),
    securityBubbleTail: const Color(0xFF1A001A),
    securityBubbleGlow: const Color(0x66FF00FF),
    securityBubbleShadow: const Color(0xFF000000),
    securityBubbleInk: const Color(0xFFFFFFFF),
    securityCrystalEdge: const Color(0x8000FFFF),
    securityCrystalHighlight: const Color(0x5500FFFF),
    securityCrystalBody: palette.crystalBody,
    securityInputFieldBg: const Color(0xFF1A001A),
    securityInputFieldBorder: const Color(0xFFFF00FF),
    securityScrimOverlay: const Color(0xCC000000),
  );

  // Emerald Glass: deep forest emerald crystal with gold veins.
  static NebulaTokens _emerald(NebulaPalette palette) => NebulaTokens(
    securityScrim: const Color(0xFF000000),
    securitySurface: const Color(0xFF001A14),
    securityOnSurface: const Color(0xFFFFFFFF),
    securityAccent: const Color(0xFF00C853),
    securityAlert: const Color(0xFFFF6E8A),
    securityOk: _ok,
    securityWarning: _warning,
    securityInfo: _info,
    securityBubbleSurface: const Color(0xFF00221C),
    securityBubbleBorder: const Color(0xFF00C853),
    securityBubbleTail: const Color(0xFF001A14),
    securityBubbleGlow: const Color(0x6600C853),
    securityBubbleShadow: const Color(0xFF000000),
    securityBubbleInk: const Color(0xFFFFFFFF),
    securityCrystalEdge: const Color(0x8069F0AE),
    securityCrystalHighlight: const Color(0x55A5FF91),
    securityCrystalBody: palette.crystalBody,
    securityInputFieldBg: const Color(0xFF001A14),
    securityInputFieldBorder: const Color(0xFF00C853),
    securityScrimOverlay: const Color(0xCC000000),
  );

  // other themes: surface, border, glow and accent come from the effective scheme,
  // until their own surface recipe is designed
  static NebulaTokens _fromScheme(NebulaPalette palette, ColorScheme colors) {
    final surface = colors.surfaceContainerHigh;
    return NebulaTokens(
      securityScrim: _legacyScrim,
      securitySurface: surface,
      securityOnSurface: colors.onSurface,
      securityAccent: colors.primary,
      securityAlert: colors.error,
      securityOk: _ok,
      securityWarning: _warning,
      securityInfo: _info,
      securityBubbleSurface: surface,
      securityBubbleBorder: colors.outlineVariant,
      securityBubbleTail: surface,
      securityBubbleGlow: colors.primary.withValues(alpha: .35),
      securityBubbleShadow: colors.shadow,
      securityBubbleInk: colors.onSurface,
      securityCrystalEdge: palette.crystalEdge,
      securityCrystalHighlight: palette.crystalHighlight,
      securityCrystalBody: palette.crystalBody,
      securityInputFieldBg: colors.surfaceContainerHighest,
      securityInputFieldBorder: colors.outline,
      securityScrimOverlay: colors.shadow.withValues(alpha: .8),
    );
  }

  @override
  NebulaTokens copyWith({
    Color? securityScrim,
    Color? securitySurface,
    Color? securityOnSurface,
    Color? securityAccent,
    Color? securityAlert,
    Color? securityOk,
    Color? securityWarning,
    Color? securityInfo,
    Color? securityBubbleSurface,
    Color? securityBubbleBorder,
    Color? securityBubbleTail,
    Color? securityBubbleGlow,
    Color? securityBubbleShadow,
    Color? securityBubbleInk,
    Color? securityCrystalEdge,
    Color? securityCrystalHighlight,
    List<Color>? securityCrystalBody,
    Color? securityInputFieldBg,
    Color? securityInputFieldBorder,
    Color? securityScrimOverlay,
  }) {
    return NebulaTokens(
      securityScrim: securityScrim ?? this.securityScrim,
      securitySurface: securitySurface ?? this.securitySurface,
      securityOnSurface: securityOnSurface ?? this.securityOnSurface,
      securityAccent: securityAccent ?? this.securityAccent,
      securityAlert: securityAlert ?? this.securityAlert,
      securityOk: securityOk ?? this.securityOk,
      securityWarning: securityWarning ?? this.securityWarning,
      securityInfo: securityInfo ?? this.securityInfo,
      securityBubbleSurface: securityBubbleSurface ?? this.securityBubbleSurface,
      securityBubbleBorder: securityBubbleBorder ?? this.securityBubbleBorder,
      securityBubbleTail: securityBubbleTail ?? this.securityBubbleTail,
      securityBubbleGlow: securityBubbleGlow ?? this.securityBubbleGlow,
      securityBubbleShadow: securityBubbleShadow ?? this.securityBubbleShadow,
      securityBubbleInk: securityBubbleInk ?? this.securityBubbleInk,
      securityCrystalEdge: securityCrystalEdge ?? this.securityCrystalEdge,
      securityCrystalHighlight: securityCrystalHighlight ?? this.securityCrystalHighlight,
      securityCrystalBody: securityCrystalBody ?? this.securityCrystalBody,
      securityInputFieldBg: securityInputFieldBg ?? this.securityInputFieldBg,
      securityInputFieldBorder: securityInputFieldBorder ?? this.securityInputFieldBorder,
      securityScrimOverlay: securityScrimOverlay ?? this.securityScrimOverlay,
    );
  }

  // `MaterialApp` interpolates the theme extensions when switching themes
  @override
  NebulaTokens lerp(covariant ThemeExtension<NebulaTokens>? other, double t) {
    if (other is! NebulaTokens) return this;
    return NebulaTokens(
      securityScrim: Color.lerp(securityScrim, other.securityScrim, t)!,
      securitySurface: Color.lerp(securitySurface, other.securitySurface, t)!,
      securityOnSurface: Color.lerp(securityOnSurface, other.securityOnSurface, t)!,
      securityAccent: Color.lerp(securityAccent, other.securityAccent, t)!,
      securityAlert: Color.lerp(securityAlert, other.securityAlert, t)!,
      securityOk: Color.lerp(securityOk, other.securityOk, t)!,
      securityWarning: Color.lerp(securityWarning, other.securityWarning, t)!,
      securityInfo: Color.lerp(securityInfo, other.securityInfo, t)!,
      securityBubbleSurface: Color.lerp(securityBubbleSurface, other.securityBubbleSurface, t)!,
      securityBubbleBorder: Color.lerp(securityBubbleBorder, other.securityBubbleBorder, t)!,
      securityBubbleTail: Color.lerp(securityBubbleTail, other.securityBubbleTail, t)!,
      securityBubbleGlow: Color.lerp(securityBubbleGlow, other.securityBubbleGlow, t)!,
      securityBubbleShadow: Color.lerp(securityBubbleShadow, other.securityBubbleShadow, t)!,
      securityBubbleInk: Color.lerp(securityBubbleInk, other.securityBubbleInk, t)!,
      securityCrystalEdge: Color.lerp(securityCrystalEdge, other.securityCrystalEdge, t)!,
      securityCrystalHighlight: Color.lerp(securityCrystalHighlight, other.securityCrystalHighlight, t)!,
      securityCrystalBody: _lerpColors(securityCrystalBody, other.securityCrystalBody, t),
      securityInputFieldBg: Color.lerp(securityInputFieldBg, other.securityInputFieldBg, t)!,
      securityInputFieldBorder: Color.lerp(securityInputFieldBorder, other.securityInputFieldBorder, t)!,
      securityScrimOverlay: Color.lerp(securityScrimOverlay, other.securityScrimOverlay, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NebulaTokens &&
      other.securityScrim == securityScrim &&
      other.securitySurface == securitySurface &&
      other.securityOnSurface == securityOnSurface &&
      other.securityAccent == securityAccent &&
      other.securityAlert == securityAlert &&
      other.securityOk == securityOk &&
      other.securityWarning == securityWarning &&
      other.securityInfo == securityInfo &&
      other.securityBubbleSurface == securityBubbleSurface &&
      other.securityBubbleBorder == securityBubbleBorder &&
      other.securityBubbleTail == securityBubbleTail &&
      other.securityBubbleGlow == securityBubbleGlow &&
      other.securityBubbleShadow == securityBubbleShadow &&
      other.securityBubbleInk == securityBubbleInk &&
      other.securityCrystalEdge == securityCrystalEdge &&
      other.securityCrystalHighlight == securityCrystalHighlight &&
      listEquals(other.securityCrystalBody, securityCrystalBody) &&
      other.securityInputFieldBg == securityInputFieldBg &&
      other.securityInputFieldBorder == securityInputFieldBorder &&
      other.securityScrimOverlay == securityScrimOverlay;

  @override
  int get hashCode => Object.hashAll([
    securityScrim,
    securitySurface,
    securityOnSurface,
    securityAccent,
    securityAlert,
    securityOk,
    securityWarning,
    securityInfo,
    securityBubbleSurface,
    securityBubbleBorder,
    securityBubbleTail,
    securityBubbleGlow,
    securityBubbleShadow,
    securityBubbleInk,
    securityCrystalEdge,
    securityCrystalHighlight,
    Object.hashAll(securityCrystalBody),
    securityInputFieldBg,
    securityInputFieldBorder,
    securityScrimOverlay,
  ]);
}

List<Color> _lerpColors(List<Color> from, List<Color> to, double t) {
  if (from.length != to.length) return t < .5 ? from : to;
  return [
    for (var i = 0; i < from.length; i++) Color.lerp(from[i], to[i], t)!,
  ];
}

extension NebulaThemeData on ThemeData {
  // tokens of the current theme, or the legacy Fail-Safe values when the theme does not provide any
  NebulaTokens get nebula => extension<NebulaTokens>() ?? NebulaTokens.fallback;
}
