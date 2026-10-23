import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_material.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:aves/widgets/common/fx/blurred.dart';
import 'package:aves/widgets/common/fx/diamond.dart';
import 'package:aves/widgets/common/fx/nebula_component_surfaces.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// Fondo compartido de las pantallas de bloqueo (app lock, bloqueo de ítem, Lockdown de Fail-Safe).
//
// Capas, de atrás a delante:
//   1. `securityScrimOverlay`: oscurece toda la pantalla.
//   2. `BlurredRRect` con `securitySurface`: superficie cristalina. Cuando `batGlass` y
//      `glassEverywhere` están ambos apagados no instala backdrop (gracias al fix P0-1).
//   3. Brillo suave `securityBubbleGlow` cuando hay animaciones.
//   4. `AnimatedCrystal` cuando animan y hay vidrio (Bat-Glass o Glass-Everywhere).
//
// Respeta `settings.animate`, `performanceMode`, `batGlass` y `glassEverywhere`.
// Todos los colores vienen de `Theme.of(context).nebula` (sin colores fijos).
class SecurityScreenBackground extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final NebulaComponentSurfaceRole role;

  const SecurityScreenBackground({
    super.key,
    required this.child,
    this.borderRadius,
    this.role = NebulaComponentSurfaceRole.appLockBackdrop,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<Settings, (bool, bool, bool, NebulaMaterialStyle?)>(
      selector: (context, s) => (s.materialStyle != null, s.glassEverywhere, s.animate, s.materialStyle),
      builder: (context, state, _) {
        final (nebulaGlass, glassEverywhere, animate, materialStyle) = state;
        final selectedMaterial = materialStyle?.material;
        final componentDriven = selectedMaterial == NebulaMaterial.eclipse || selectedMaterial == NebulaMaterial.hermetic;
        final glass = nebulaGlass || glassEverywhere; // los getters ya respetan performanceMode
        final nebula = Theme.of(context).extension<NebulaTokens>() ?? NebulaTokens.fallback;
        final radius = borderRadius ?? BorderRadius.zero;
        // Eclipse and Hermetic use scene-level, screen-specific linework instead of
        // stamping their material tile across the entire lock screen.
        final screenContent = componentDriven
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: NebulaComponentSurfaceAccent(
                      style: materialStyle,
                      role: role,
                      state: role == NebulaComponentSurfaceRole.lockdownBackdrop
                          ? NebulaComponentSurfaceState.warning
                          : NebulaComponentSurfaceState.idle,
                      animate: animate,
                      alertColor: nebula.securityAlert,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  child,
                ],
              )
            : child;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. scrim sobre toda la pantalla
            Positioned.fill(
              child: Container(color: nebula.securityScrimOverlay),
            ),
            // 2. superficie cristalina (blur solo cuando el vidrio está activo)
            Positioned.fill(
              child: BlurredRRect(
                enabled: glass,
                borderRadius: radius,
                child: Container(
                  decoration: BoxDecoration(
                    color: nebula.securitySurface,
                    borderRadius: radius,
                  ),
                  child: Stack(
                    children: [
                      // 3. brillo suave de la burbuja (solo con animaciones)
                      if (animate && !componentDriven)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: .7,
                                colors: [
                                  nebula.securityBubbleGlow.withValues(alpha: .55),
                                  nebula.securityBubbleGlow.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // 4. cristal animado solo cuando hay vidrio y animaciones
                      if (glass && animate && !componentDriven)
                        AnimatedCrystal(
                          animate: true,
                          material: selectedMaterial ?? NebulaMaterial.ruby,
                          opacity: .3,
                          child: screenContent,
                        )
                      else
                        screenContent,
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
