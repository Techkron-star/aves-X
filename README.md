<div align="center">

<img src="assets/aves_x_logo.png" alt="Aves-X logo" width="220" />

# Aves-X

**Una galería privada para Android, basada en Aves.**

`ALPHA — en pruebas`

</div>

---

## Un tributo

Aves-X es un **tributo personal a [Aves](https://github.com/deckerst/aves)**, la galería libre de Android que uso desde hace más de un año y de la que estoy enamorado. Todo el trabajo de base —el visor, el explorador de metadatos, los álbumes, el rendimiento, la calidad general— es de su creador, **Thibault Deckers ([@deckerst](https://github.com/deckerst))**, y de quienes han contribuido al proyecto. Aves-X no existiría sin ese trabajo: mi aportación es una capa de privacidad encima, hecha a mi gusto.

Si buscas una galería completa, estable y mantenida, **usa Aves**. Aves-X es un fork experimental y personal.

## Qué es

Aves-X conserva todo lo que hace Aves (galería, visor de imágenes y vídeo, mapas, metadatos, etiquetas, vaults, papelera, etc.) y añade herramientas de privacidad y seguridad:

### Seguridad
- **Código Maestro** de 6 dígitos: se crea antes de cualquier PIN/contraseña y es obligatorio para cambiar o quitar cualquier credencial. Sin recuperación.
- **Bloqueo de inicio** con PIN de 6 dígitos y biometría opcional; se reactiva tras 30 s en segundo plano.
- **Intentos fallidos persistentes** (PIN de la app, Código Maestro y cada vault por separado): 3 fallos → espera de 5 minutos (con vibración y sin poder escribir); 4º fallo → **nuke automático**. El cooldown resiste cambios de la hora del sistema.
- **Nuke**: manual (Ajustes → Privacidad) o automático por intentos fallidos; borra las vaults y su contenido (o todos los datos de la app según el caso).
- **PIN de pánico** opcional: pantalla falsa de "PIN incorrecto" mientras se borra todo en segundo plano.

### Privacidad
- **Bloqueo de álbumes, fotos sueltas y favoritos**: se ven borrosos con candado y piden biometría, PIN, patrón o contraseña para abrirse.
- **Vaults avanzadas**: segundo bloqueo opcional, bloqueo de compartir y opción de ocultarlas de la lista de álbumes.
- **Bloqueo de la papelera** y **gesto secreto** (mantener 5 s el botón Álbumes) para mostrar elementos ocultos.
- **Confirmación estricta de borrado**: botón rojo con espera, mantenerlo pulsado y escribir `BORRAR`.
- **Todo es opt-in**: nada viene activado por defecto. Las opciones se activan/desactivan por separado, agrupadas por secciones en Ajustes → Privacidad (desactivar una protección pide el Código Maestro). Bloquear/desbloquear da respuesta háptica y visual.

### Apariencia
- Cristal líquido más translúcido en barras, botones, diálogos y menú lateral.
- Color rojo por defecto (Material You sigue disponible).
- Logo y nombre propios.
- Sección **EXPERIMENTAL** en Ajustes (con aviso previo): tema **Bat glass** (cristal rubí sobre negro) y efecto cristal en diálogos y menú lateral. Pueden afectar al rendimiento.

> Estado: **alpha**. Compila, pero se está probando en dispositivo real. Úsalo con copias de tus fotos importantes, **no** como único lugar donde guardas algo irreemplazable. Un nuke es irreversible por diseño.

## Próximamente
Cifrado de los archivos de las vaults, pulir Bat glass, soporte de `.nomedia`, límites de intentos para papelera y bloqueo de elementos. Ver [ROADMAP.md](ROADMAP.md).

## Créditos y licencia

- **Aves** © Thibault Deckers y colaboradores — <https://github.com/deckerst/aves>. Aves-X es un fork y mantiene su licencia **BSD 3-Clause** (ver [LICENSE](LICENSE)); los avisos de copyright originales se conservan.
- Aves-X no está afiliado ni respaldado por el autor original. Las modificaciones de este fork son de [@Techkron-star](https://github.com/Techkron-star).
- El logo de Aves-X es un diseño propio; el logo original de Aves pertenece a su autor.

---

<details>
<summary>English</summary>

**Aves-X** is a personal tribute fork of [Aves](https://github.com/deckerst/aves), the open-source Android gallery by Thibault Deckers, which I've used and loved for over a year. All the foundation is his work. Aves-X adds a privacy layer: Master Code, app lock, persistent failed-attempt counters with cooldown and auto-nuke, panic PIN, locked albums/photos/favourites with blurred thumbnails, advanced vaults, strict delete confirmation, and a more translucent "liquid glass" look. Status: **alpha**. If you want a stable, maintained gallery, use Aves. License: BSD-3-Clause, inherited from Aves.

</details>
