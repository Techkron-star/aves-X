# Guía de oficio: cómo hacer un tema Nebula de calidad

Esta guía es para los agentes que trabajan en `nebula-theme`. Resume cómo están hechos los temas que
mejor han quedado (Nosferatu, Night Demon/Obsidian, Godly/Aureate, Imperial, Solar Flare, Abyssal,
Sakura y los siguientes) y qué errores rompen la build o pisan trabajo ajeno.

Léela entera antes de tocar un tema. Si algo de aquí choca con `AGENTS.md`, manda `AGENTS.md` para
reparto de carpetas y flujo de CI; esta guía manda para **cómo se dibuja un tema**.

---

## 1. Principio: un tema es una identidad, no una paleta

Cambiar colores NO es hacer un tema. Un tema terminado tiene seis cosas, todas coherentes con su
nombre en clave:

| Capa | Qué es | Dónde vive |
|---|---|---|
| Paleta | colores, `darkOnly`, botones | `lib/theme/nebula/nebula_palettes.dart` |
| Material | forma de esquinas + colores de cristal | `lib/theme/nebula/nebula_material.dart` |
| Superficie | lo que se dibuja dentro de menús, diálogos, barras, tarjetas | `lib/widgets/common/fx/nebula_surfaces.dart` (+ `demon_glass.dart`, `gold_leaf.dart`, `diamond.dart`) |
| Emblema | el candado de seguridad con su propia silueta | `lib/widgets/common/fx/lock_animation.dart` (`_paintXxx`) |
| VFX | animación de fondo de la pestaña Nebula | `lib/theme/nebula/nebula_signature_effects.dart` |
| Textos | nombre y descripción (en + es) | `lib/l10n/app_en.arb`, `app_es.arb` |

Antes de escribir una línea, decide en una frase **qué es el tema** y deja que esa frase mande en todas
las capas. Ejemplos reales:

- Night Demon → vidrio volcánico negro, grietas violeta que laten, esquinas **biseladas**, ojo de demonio, brasas que suben.
- Godly → pan de oro, rayos divinos desde un halo, esquinas **suaves**, candado con halo y alas, motas de oro.
- Imperial → placa de acero remachada, marco de latón, sello de cera, cresta alada, engranajes e incienso.
- Solar Flare → superficie de una estrella: granulación, manchas solares, prominencias, chispas.
- Abyssal → agua profunda: cáusticas, burbujas, plancton, medusa.
- Sakura → papel washi negro, rama con flores, pétalos cayendo, laca roja.

Mal ejemplo: "cristal verde" y "cristal azul" son el mismo tema con otro tinte. Cada tema debe poder
reconocerse en silueta, sin mirar el color.

Reglas de diseño:

1. **Silueta propia**: cada material define `shape()` / `topShape()` con una geometría distinta
   (bisel, superelipse, pétalo, burbuja, chaflán...). No repitas la de otro tema.
2. **Una metáfora por tema** y nada que no pertenezca a ella. Sin "destellos decorativos" genéricos.
3. **Contraste y legibilidad primero**: el contenido (texto, iconos, miniaturas) se ve a través de las
   superficies. Las superficies son semitransparentes; no pongas texturas contundentes en el centro.
   Texto blanco sobre botón crema = bug (ya pasó con Pearl/Ivory/Amber).
4. **Sutileza en el reposo, vida en el detalle**: la superficie es casi estática; el movimiento va en
   el fondo de la pestaña Nebula y en pequeños reflejos.
5. **Respeta `performanceMode` y `settings.animate`**: sin animación la escena se pinta en `t = 0`.

---

## 2. Arquitectura que debes conocer

```
NebulaTheme (enum)            lib/theme/nebula/nebula_theme.dart       id estable, nunca renombrar
NebulaPalette / nebulaPalettes lib/theme/nebula/nebula_palette(s).dart  colores + NebulaSurfaceTreatment
NebulaTokens                  lib/theme/nebula/nebula_tokens.dart      tokens de seguridad (Fail-Safe los consume)
NebulaMaterial (enum)         lib/theme/nebula/nebula_material.dart    uno por tema, + shape()/topShape()
NebulaMaterialStyle           idem                                     colores de cristal (se derivan de la paleta)
nebulaMaterialDecoration()    lib/widgets/common/fx/diamond.dart       fábrica: material -> Decoration
NebulaSurfaceDecoration       lib/widgets/common/fx/nebula_surfaces.dart  escenas dibujadas por tema
_PadlockPainter               lib/widgets/common/fx/lock_animation.dart   emblemas
nebulaEffectFor()             lib/theme/nebula/nebula_effect.dart      fábrica de VFX (delega en signature_effects)
```

Quién pinta qué: `blurred.dart`, `liquid.dart`, `nav_bar.dart`, diálogos, drawer, etc. llaman a
`settings.materialStyle` y a `nebulaMaterialDecoration(material, opacity: ...)`. **No** pongas colores
de tema a mano en esos widgets: si necesitas algo, añádelo al material.

### Archivos delicados (no los reescribas enteros)

- `nebula_effect.dart` contiene el `NebulaEffect` base, el host del `AnimationController` y la fábrica.
  **No lo reformatees ni lo comprimas.** Un agente lo reescribió y dejó Obsidian y Aureate sin VFX
  (la fábrica devolvía `null`). Añade casos a la fábrica; no la rehagas.
- Los VFX de autor viven en `nebula_signature_effects.dart`. Un tema nuevo con animación propia va
  ahí y se enchufa en `nebulaEffectFor`. Nunca borres una clase de ese archivo sin pedirlo el usuario.
- Antes de editar un archivo compartido: `git pull --rebase`, lee el diff reciente
  (`git log -5 --stat -- <archivo>`) y haz cambios **aditivos y pequeños**.

---

## 3. Cómo se añade un tema nuevo (checklist completa)

Rompe la compilación si falta una: casi todo son `switch` exhaustivos.

1. `nebula_theme.dart`: valor en el enum, `id` (único, estable), `phase`.
2. `nebula_palette.dart`: valor en `NebulaSurfaceTreatment`.
3. `nebula_palettes.dart`: entrada con `darkOnly`, superficies, `crystalBody` (4 colores de brillante a
   profundo), `filledButtonBackground/Border` **con contraste real contra texto blanco**.
4. `nebula_tokens.dart`: añade el treatment al `switch` de `NebulaTokens.fromPalette` (por defecto cae a
   `_fromScheme`; haz un `_nombre()` propio solo si necesitas tokens de seguridad distintos).
5. `nebula_material.dart`: valor en `NebulaMaterial`, casos en `shape()` y `topShape()`,
   `_materialForTheme` y `_customMaterialByTreatment`.
6. Superficie: nueva arte en `nebula_surfaces.dart` (enum `NebulaSurfaceArt`, función `_nombre`,
   caso en el `switch` de `_record`) y caso en `nebulaMaterialDecoration()` de `diamond.dart`.
7. Emblema: `_paintNombre` en `lock_animation.dart` + rama en `_PadlockPainter.paint`. Añade el caso
   a los `switch` exhaustivos de ese archivo si el compilador lo pide.
8. VFX: clase `NombreGlassEffect` en `nebula_signature_effects.dart` + caso en `nebulaEffectFor`.
9. `nebula_theme_selector.dart`: nombre y descripción (dos `switch`).
10. `app_en.arb` y `app_es.arb`: `nebulaThemeNombreGlass` y `...Desc`. **Sin "(coming soon)"**.
    Los `.arb` están en CRLF: conserva los finales de línea y valida el JSON.
11. `CHANGELOG.md`: una línea en "Added".
12. `app_mark.dart`: si no te vale el color derivado de la paleta, añade tinta propia.

---

## 4. Cómo se dibuja bien (técnica)

### 4.1 Superficies (`Decoration` + `BoxPainter`)

- Graba **una vez** con `ui.PictureRecorder` y reproduce con `canvas.drawPicture`. Cachea por
  `(arte, Size, opacity)` en un `Map` estático y límpialo cuando crezca (`dispose()` de cada
  `Picture`). Nunca generes `Random`, gradientes pesados ni paths grandes en cada frame.
- Usa `Random(semilla)` **fijo**: el dibujo debe ser idéntico entre repintados y ejecuciones.
- Dibuja en coordenadas reales de `Size` (no en 100x100 estirado: se deforma en barras anchas).
- Respeta `opacity`: aplícala a los rellenos base (`color.withValues(alpha: opacity)`); los adornos
  finos pueden ir con alfa propio bajo.
- Recorta con `canvas.clipRect(offset & size)` y traslada a `offset`.
- Estructura de una buena escena, en este orden: base en degradado → textura de material →
  elementos de la metáfora (sol, rama, rejilla...) → sombras/vignette → **borde de luz**
  (arriba/izquierda claro, abajo oscuro).
- Mantén el centro limpio: lo importante va a bordes y esquinas.
- `MaskFilter.blur` solo en la grabación, jamás en el repintado.

### 4.2 Emblemas de candado (lienzo 100x100)

- Todos comparten `_shackle()` (el arco) y `_keyhole()` (el ojo de cerradura); úsalos para que
  el estado abierto/cerrado funcione (`open`), y respeta `keyhole`.
- La silueta del cuerpo es lo que distingue el tema (cola de ojo, corazón, yunque, gota, esfera...).
- Compón con 2-3 capas: resplandor difuso, cuerpo con degradado, contorno + un brillo.
- Comprueba mentalmente tamaños pequeños (22-64 px): evita detalle menor de 1 px.

### 4.3 VFX animados

- Extienden `NebulaEffect` y solo implementan `painter(double t)`, `duration` y `reverse`.
  El host ya gestiona el `AnimationController`; no crees controladores propios.
- **Bucles sin costura (obligatorio):** `reverse => false` y todo movimiento periódico usa un número
  **entero** de ciclos por bucle: `sin(t * 2π * k)` con `k` entero; partículas con
  `p = (t * viajes + fase) % 1.0` con `viajes` entero; rotaciones de `2π/n` por bucle si hay
  `n` dientes/marcas. Si `t` salta de 1 a 0 y algo "salta", está mal.
- Envuelve apariciones/desapariciones con `sin(π·p)` para que las partículas nazcan y mueran en 0.
- Determinismo: `Random(seed)` fijo dentro de `paint`, mismo orden de llamadas siempre.
- Presupuesto: ~20-40 partículas, 1-3 gradientes grandes, como mucho 2-3 `MaskFilter.blur` por frame.
  Sin `saveLayer` salvo que no haya alternativa.
- Haz que el movimiento signifique algo del tema (chispas con gravedad en Forge, latido doble en
  Crimson, anillo de diamante recorriendo el borde en Eclipse), no ruido.
- Con `animate == false` no avanza: el host pinta `t = 0` y debe verse bien.

---

## 5. Errores de compilación que ya hemos sufrido

No hay Flutter local: la única verificación es la build de CI. Evita esto:

- **`package:material_ui/material_ui.dart` vs `package:flutter/material.dart`**: importar los dos en el
  mismo archivo da errores "imported from both" (`Icons`, `Theme`, `ScaffoldMessenger`...). Usa **solo**
  `material_ui` (más `flutter/services.dart` o `flutter/rendering.dart` si hace falta). La excepción
  histórica es `nebula_effect.dart`/`nebula_signature_effects.dart`, que usan `flutter/material.dart`:
  respeta lo que ya tenga cada archivo.
- `switch` exhaustivos sobre enums: al añadir un valor de `NebulaTheme`, `NebulaMaterial` o
  `NebulaSurfaceTreatment`, busca **todos** los `switch` (`grep -rn "NebulaMaterial.ivory" lib`).
- `Paint.maskFilter` espera `MaskFilter`, no `ImageFilter`.
- `const` en constructores no constantes; parámetros requeridos sin usar; coma sobrante.
- Imports sin usar: el analizador es estricto. Quita los que dejes huérfanos.
- Cascadas: `paint..strokeWidth = 3..color = c;` es válido como sentencia; ojo con encadenar sobre
  expresiones que ya devuelven otro tipo.
- Sintaxis nueva de Dart del repo (shorthand de enums `.imperialGlass`, records, patrones) está
  permitida; úsala solo donde ya se usa.
- Revisión rápida sin compilador: cuenta `{ } ( ) [ ]` del archivo que editaste y confirma que cada
  símbolo nuevo existe (`grep`).

---

## 6. Flujo de trabajo y CI

1. `git pull --rebase` antes de empezar y antes de cada push (los demás agentes empujan sin avisar).
2. Cambios pequeños y commits temáticos (`feat(nebula): ...`). Un tema por commit cuando sea posible.
3. `git push`, **cancela las builds en curso y lanza una nueva**:
   `gh workflow run build-libre-apk.yml --ref develop`. No esperes a que termine: sigue con el
   siguiente trabajo y revisa el resultado después.
4. Si la build falla, lee los errores por anotaciones:
   `gh api repos/Techkron-star/aves-x/check-runs/<job_id>/annotations --jq '.[].message'`
   (los logs completos devuelven 403). Arregla el primer error real; suelen encadenarse.
5. No subas nada con la última build en rojo sin arreglar primero lo que rompiste.
6. Conserva CRLF en los `.arb`; valida el JSON tras editarlos.
7. Nunca borres ni "simplifiques" trabajo de otro tema para hacer sitio al tuyo.

---

## 7. Lista de verificación de calidad (marca todo antes de dar un tema por terminado)

- [ ] Se reconoce por la **silueta** (esquinas + emblema), sin mirar el color.
- [ ] La superficie se ve bien a 3 tamaños: barra baja, tarjeta mediana, diálogo grande.
- [ ] El texto sobre botones, chips y diálogos es legible (contraste >= 4.5:1).
- [ ] El emblema se lee a 22 px y a 64 px, abierto y cerrado.
- [ ] El VFX hace bucle sin salto, se detiene con `animate == false` y no pasa de ~40 partículas.
- [ ] No hay colores de tema escritos a mano fuera del material/paleta/arte del tema.
- [ ] Nombre y descripción en en/es, sin "(próximamente)"; `.arb` válidos y en CRLF.
- [ ] La build libre APK está en verde y no se perdió ningún VFX de otro tema.

---

## 8. Mapa de referencia: dónde mirar para copiar el nivel

- Superficie con escena completa: `nebula_surfaces.dart` (`_imperial`, `_solar`, `_abyssal`, `_sakura`).
- Superficie con grietas procedurales y pulso: `demon_glass.dart`.
- Superficie con rayos y destello barriendo: `gold_leaf.dart`.
- Emblema con partes móviles (cuernos, halo): `_paintDemon`, `_paintHalo` en `lock_animation.dart`.
- VFX con partículas y bucle perfecto: `NightDemonEffect`, `GodlyEffect`, `SolarFlareGlassEffect`.
- VFX con física: `ForgeGlassEffect` (chispas con gravedad por golpe).
- VFX con rotación por capas: `HermeticGlassEffect`.

Copia la **estructura y la disciplina**, no los elementos: cada tema nuevo debe aportar su propia
metáfora, no una variante de otra.
