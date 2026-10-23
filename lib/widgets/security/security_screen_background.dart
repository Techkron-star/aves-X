import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_material.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:aves/widgets/common/fx/blurred.dart';
import 'package:aves/widgets/common/fx/diamond.dart';
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

  const SecurityScreenBackground({super.key, required this.child, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Selector<Settings, (bool, bool, bool)>(
      selector: (context, s) => (s.materialStyle != null, s.glassEverywhere, s.animate, s.materialStyle?.material),
      builder: (context, state, _) {
        final (nebulaGlass, glassEverywhere, animate, selectedMaterial) = state;
        final glass = nebulaGlass || glassEverywhere; // los getters ya respetan performanceMode
        final nebula = Theme.of(context).extension<NebulaTokens>() ?? NebulaTokens.fallback;
        final radius = borderRadius ?? BorderRadius.zero;

        return Stack(
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
                      if (animate)
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
                      if (glass && animate)
                        AnimatedCrystal(
                          animate: true,
                          material: selectedMaterial ?? NebulaMaterial.ruby,
                          opacity: .3,
                          child: child,
                        )
                      else
                        child,
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
