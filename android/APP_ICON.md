# Aves-X — Icono de app y splash (Material 3 / Material You)

Resumen de cómo está montado el icono y qué hay que tocar (y qué no) para cambiarlo.

## Capas del icono

| Archivo | Rol |
| --- | --- |
| `app/src/main/res/drawable/ic_launcher_foreground.xml` | Vector del murciélago (solo formas planas, sin gradientes). Vive dentro de la zona segura de 66/108 dp. |
| `app/src/main/res/drawable/ic_launcher_monochrome.xml` | Silueta monocroma para los **themed icons** de Android 13+. Todo blanco: el sistema la tiñe. |
| `app/src/main/res/values/colors.xml` | `ic_launcher_background` y los 4 colores de marca del vector. |
| `app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | Icono adaptativo: `background` + `foreground` + `monochrome`. |
| `app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml` | Igual que el anterior (los launchers redondos aplican su máscara). |
| `app/src/main/res/drawable/launch_background.xml` | Fondo de arranque de Flutter: superficie + logo vectorial centrado. |
| `app/src/main/res/values/styles.xml`, `values-night/styles.xml` | Splash de Android 12+ (`windowSplashScreen*`). |

Los `mipmap-*/ic_launcher.png` y `ic_launcher_round.png` son el **fallback para API < 26**
(antes de los iconos adaptativos) y siguen siendo los PNG antiguos. Para regenerarlos,
parte de un render cuadrado de 1024 px del logo y exporta 48/72/96/144/192 px
(mdpi→xxxhdpi), con la misma superficie que `ic_launcher_background`.

## Material You: qué se puede y qué no

- **Themed icons (Android 13+)**: se controlan con la capa `monochrome`. El launcher
  aplica el tinte derivado del fondo de pantalla. Es la vía real de Material You para
  iconos de app. No añadir color a `ic_launcher_monochrome.xml`.
- **Fondo dinámico**: un `<adaptive-icon>` se infla en el proceso del launcher, con el
  tema del launcher, así que **no** es fiable usar `?attr/colorSurfaceContainer` en
  `background`. Un atributo no resuelto rompería el icono. Por eso el fondo es un color
  de marca (`ic_launcher_background`) y el dinamismo se delega a `monochrome`.
- No se usa `flutter_native_splash` (no es dependencia del proyecto y añadirla
  obligaría a `pub get` + PNGs generados). El splash nativo ya está configurado:
  `windowBackground` (pre-Android 12) y `windowSplashScreen*` (Android 12+).

## Logo dentro de la app (Flutter)

`lib/widgets/common/basic/app_logo.dart` expone `AppLogo` con variantes Material 3:

```dart
const AppLogo.primary(size: 48),
const AppLogo.secondary(size: 48),
const AppLogo.tonal(size: 48),
const AppLogo.outline(size: 48),
const AppLogo.monochrome(size: 48), // usa IconTheme.of(context).color
```

Todos los colores salen de `Theme.of(context).colorScheme` (respeta semilla dinámica y
`brightness`) y el tamaño por defecto sale de `IconTheme.of(context).size`. El widget
se espeja solo en RTL. `AvesLogo` (el logo de marca con PNG) no se ha modificado para
no cambiar la identidad de las pantallas existentes.
