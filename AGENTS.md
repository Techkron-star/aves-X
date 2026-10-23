# Aves-X — instrucciones del equipo

## Proyecto
- Fork de Aves: `Techkron-star/aves-X`, rama de trabajo `develop`.
- Paquete Android: `dev.techkron.avesx`.
- UI y roadmap en español; código, identificadores y comentarios técnicos en inglés.
- El repo está clonado localmente en este directorio. No hay Flutter/Dart instalado: la verificación real es el build remoto de GitHub Actions.

## Build
- Workflow: **Build Aves-X libre APK**, id `385000599`, rama `develop`. Artefacto: `aves-x-libre-apks` (`Aves-X-libre-<abi>.apk`).
- Solo el agente `auditor` puede lanzar builds, hacer commit o hacer push.
- El auditor usa `scripts/ci-build.ps1`; no lanzar builds a mano ni desde otros agentes.
- El build tarda varios minutos. El auditor espera, lee las anotaciones de error y corrige.
- Máximo 3 intentos por tanda. Si sigue fallando, parar y reportar el error exacto.

## Equipo
- `coordinator`: reparte tareas, decide prioridades y llama al auditor.
- `nebula-theme`: Nebula Engine, temas, selector, **Nosferatu Glass**, **Obsidian Glass**, **Aureate Glass**, **Forge Glass** y **Hermetic Glass**.
  - Antes de tocar un tema, lee `NEBULA_THEME_CRAFT_GUIDE.md` (cómo se dibuja un tema de calidad, checklist y errores conocidos). No reescribas `nebula_effect.dart` ni borres VFX de otros temas; los VFX de autor viven en `nebula_signature_effects.dart`.
- `gargantua`: Sistema Gargantua, salidas de archivos, share/export/open-with/copy, vaults y bloqueos.
- `aves-ui`: UI general, navegación, iconos y ajustes visuales.
- `failsafe-ui`: rediseño visual de Fail-Safe, sus tarjetas y sus burbujas, usando los tokens del tema.
- `reviewer`: revisión read-only de diffs; no edita.
- `auditor`: único que compila y publica.

## Propiedad de archivos
- `nebula-theme`: `lib/theme/**`, `lib/widgets/common/fx/**` (cristal, excepto `failsafe_badge.dart` y `lock_animation.dart`, que son de `failsafe-ui`), `lib/widgets/common/fx/app_mark.dart` (App Mark, antes `bat_mark.dart`), `lib/widgets/settings/display/**`, `lib/widgets/settings/experimental/**`, `lib/model/settings/modules/display.dart`, `lib/widgets/aves_app.dart`.
- `gargantua`: `lib/services/app_service.dart`, `lib/widgets/viewer/action/**`, `lib/widgets/collection/action/**`, `lib/model/security/**` (incluido `lib/model/security/master_guard.dart`, antes `bat_curity.dart`), `android/**` (intents/share).
- `aves-ui`: navegación, iconos y widgets que no sean de tema ni de seguridad; también `lib/widgets/navigation/nav_bar/nav_bar.dart` (Nav Lens) y `lib/widgets/settings/display/nebula_theme_tile.dart` (selector de tema, compartido con `nebula-theme`).
- `failsafe-ui`: `lib/widgets/security/**` (incluidos `lib/widgets/security/app_lock_gate.dart` y `lib/widgets/security/failsafe_lockdown.dart`), `lib/widgets/settings/security/**`, `lib/widgets/dialogs/failsafe_comic_dialog.dart`, `lib/widgets/common/fx/failsafe_badge.dart`, `lib/widgets/common/fx/lock_animation.dart`.
- `reviewer` y `auditor`: lectura global; el auditor puede editar cualquier archivo para arreglar un build, pero debe tocar lo mínimo.

## Reglas
- Nebula/UI no tocan la lógica de seguridad (Fail-Safe, bloqueos, vaults). Gargantua no toca temas.
- Nebula define los tokens; `failsafe-ui` los consume. Nada de colores fijos en Fail-Safe: si falta un token, se pide a `nebula-theme`.
- No debilitar la seguridad para que un test pase.
- No meter secretos en el repo. El token vive fuera (`~/.config/opencode/github-token`).
- No hacer commit ni push desde workers; el auditor publica.
- Antes de cambiar algo, leer `ROADMAP.md` y el código relacionado.
- Mantener el estilo del proyecto y el rendimiento (modo rendimiento, gama baja).
- Si un cambio necesita un archivo de otro rol, pedirlo al `coordinator`.

## Verificación
- `reviewer` revisa el diff antes de compilar, sobre todo en seguridad.
- `auditor` ejecuta `scripts/ci-build.ps1`, espera el resultado y lee las anotaciones.
- Si el build falla, el auditor corrige la causa raíz, no solo el síntoma.

## Roadmap
- Nebula Engine: post-beta. Fase 1 = paleta/superficies reutilizando Nosferatu Glass; Fase 2 = shaders/animaciones.
- Gargantua: futuro. Lo que entra en una zona protegida no sale sin permiso. Compartir ya pide credencial; faltan Master Code por regla y otras salidas.
