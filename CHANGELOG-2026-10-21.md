# Changelog — Aves-X (21 de octubre de 2026)

Resumen de cambios realizados hoy, organizados por tipo. Todos los commits están en la rama `develop` (HEAD: `af5e974`).

## ✨ Características nuevas

- **Nebula Engine v1** (`9b20586`): motor de temas visuales con `NebulaTheme`, `NebulaPalette` y `NebulaTokens`; 5 temas (Nosferatu Glass, Obsidian Glass, Aureate Glass, Forge Glass, Hermetic Glass) con paletas y tokens de Fail-Safe; pestaña Nebula dedicada con fondo galáctico, estrellas y partículas; selector de tema con nombre, descripción y pegatina de función; Item Lock Screen con tokens del tema y animación de desbloqueo; logo Material You/M3 Expressive.
- **Registro de la clave de ajuste Nebula** (`fbbe456`): `nebula_theme` registrado en `SettingKeys` con wiring de import/export y 3 tokens de pantalla de bloqueo.
- **Gargantua fase 1** (`e5372ba`): política de salidas agregada (5 categorías + interruptor maestro + regla de Master Code = 7 interruptores); compartir fotos/vídeos pide el Master Code; página de ajustes propia; comportamiento fail-closed.
- **Renombrado a nombres propios** (`798a89b`): Bat-Glass → Nosferatu Glass, Bat-Lens → Nav Lens, Bat-Curity → Master Guard, Bat-Mark → App Mark; `bat_curity.dart` → `master_guard.dart` (claves de almacenamiento intactas).

## 🐛 Correcciones (fixes)

- **Cuadro gris en la pestaña Nebula** (`359a567`): `Tooltip(message: null)` en el selector de temas lanzaba `richMessage!` sobre null en release, renderizando el `ErrorWidget` gris. Las pills de Fase 1 ya no envuelven en `Tooltip`; solo las de Fase 2 (con mensaje) lo usan.
- **Barra gris infinita / altura infinita del selector Nebula** (`6e5cfdf`, `afba094`): fix de `SingleChildScrollView`/`ConstrainedBox` que causaba layout infinito en el selector de temas.
- **Tile de Nebula dedicado** (`12687b3`): la entrada Ajustes → Pantalla → Tema Nebula ahora abre la pestaña `NebulaTab` vía `SettingsSubPageTile` en lugar de dibujar el selector inline.
- **Builds** (`fea9d24`, `819347b`, `60167fa`, `0e26c5b`): imports faltantes en `nebula_theme_tile.dart`, `reportService` en seguridad, imports ambiguos de material y errores en `lock_animation.dart`.
- **Logo** (`0a090f9`, `908018e`): orden de declaración de variables e imports de `AvesLogo`; logo exacto de `aves_logo.svg` (155 trazados) en launcher, splash, bienvenida, cajón y Acerca de.
- **Master Code en lockdown** (`52200ae`): un código maestro correcto durante el lockdown nunca cuenta como intento fallido, por lo que no puede disparar el borrado de emergencia (nuke).
- **Android** (`81714d3`): firma `stopPcm` para el compilador de Kotlin.

## 🔧 Scripts y documentación

- **`scripts/ci-build.ps1`**: dispatch y espera del build remoto de GitHub Actions (workflow `385000599`, rama `develop`).
- **`scripts/check-secrets.ps1`** (`0bb96e9`): escanea tracked files en busca de API keys, tokens y claves privadas (forzado `-e` para patrones que empiezan con guiones).
- **`scripts/publish-release.ps1`** (`af5e974`): descarga el artefacto `aves-x-libre-apks`, mueve el tag, crea la release y sube los 3 APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`). `make_latest` corregido a booleano.
- **README / ROADMAP**: reescritos (español para roadmap/UI; código y comentarios técnicos en inglés; sin secciones de build/CI/versión; nota de "Privacy by design"; no hay API keys ni secretos).
- **`.gitignore`**: endurecido con patrones de secretos y firmas (`.env`, `*.jks`, `*.keystore`, `*.p12`, `*.pem`, `*.key`, `*.p8`, `*.asc`, `*.gpg`, `google-services.json`, `GoogleService-Info.plist`, `android/key.properties`, `local.properties`, `scripts/*.local.ps1`).
- **Limpieza**: se eliminaron archivos accidentales (`COMMIT_MSG.txt`, `ORCHESTRATOR_README.md`, `aves-x-libre-apks.zip`, `orchestrator.py`, `workflow.yaml`).
- **Versión**: `pubspec.yaml` bumped a `0.5.0+500`; `release_body.md` actualizado para v0.5.0.

## 🧹 Reorganización de ajustes (esta tanda)

- **Nebula Engine como ajuste principal**: nueva sección `NebulaSection` en Ajustes (entre Fail-Safe y Accesibilidad) con una **tarjeta visual especial** al estilo Black Hole (borde brillante, gradiente oscurecido, logo Aves-X) que abre la pestaña Nebula. Ya no es un tile secundario dentro de Display.
- **Quitar duplicados**:
  - `Bat-Glass` / Nosferatu eliminado de `Experimental` (ya vive solo en el selector de temas Nebula).
  - `Rendimiento` / Performance Mode eliminado de la pestaña Nebula (ya vive solo en Display como ajuste global).
- **l10n**: nuevos strings `nebulaEngineSectionTitle`, `nebulaEngineTitle`, `nebulaEngineSubtitle` (EN + ES).

## 🎨 Pulido de colores Nebula — cada tema con huella única (esta tanda)

- **Obsidian Glass**: negro con tono violeta oscuro (`0xFF0A050F` surface, acento `0xFF9B5DE5`, cristal `0xFF9B5DE5`/`0x806A1B9A`). Diferenciado de Forge y de Nosferatu.
- **Forge Glass**: naranja fundido/molten (`0xFFFF7A18` glow y accent, cristal `0xFFFFD87A`→`0xFF8A2A00`). Ya no comparte cristal violeta con Obsidian.
- **Aureate Glass**: oro cálido (`0xFFD4AF37` seed, `0xFFF5C542` glow, cristal `0xFFE08A`). Único.
- **Hermetic Glass**: esmeralda-violeta (`0xFF1FBF8F` seed, `0xFF35E0A1` glow, cristal `0xFF9B7BFF`). Único.
- **Nosferatu Glass**: ruby/negro sin cambios (paridad exacta con el Bat-Glass original, por requisitos del proyecto).
- Tokens de Fail-Safe de Obsidian y Forge actualizados a sus respectivos colores únicos (`_obsidian` y `_forge` en `nebula_tokens.dart`).

## 🚧 Estado

- Build remoto lanzado para verificar el pulido de colores (pendiente de resultado).
- Build verde previo: run `39703725520` (commit `359a567`, incluye el fix del cuadro gris).
- Release v0.5.0 **no publicada** (pendiente en local; el tag `v0.5.0` aún apunta al commit antiguo `81714d3`).
- Custom Nebula themes (import/export/template/store/tile) y Forge/Hermetic phase 2 pendientes de próxima tanda.
