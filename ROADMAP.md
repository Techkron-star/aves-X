# Ideas pendientes

Notas para futuras sesiones. Nada de esto está hecho todavía.

## 1. Blur estilo "liquid glass"
- Mejorar el desenfoque de las barras y paneles de la app para acercarlo al efecto liquid glass (translucidez, refracción suave, brillo en los bordes).
- Revisar dónde se usa hoy el blur (barra inferior flotante, overlays del visor) y unificarlo en un solo widget reutilizable.

## 2. Compatibilidad con Monet / Material You
- Comprobar primero si Aves ya soporta color dinámico en sus ajustes de tema, y qué le falta.
- Que los colores de la app sigan la paleta del fondo de pantalla (Monet) o equivalentes.

## 3. Borrar metadatos de las fotos
- Individual: desde el visor, borrar los metadatos de una foto (EXIF, ubicación, etc.).
- En lote: desde la selección múltiple, borrar los metadatos de varias fotos a la vez.
- Revisar si Aves ya tiene una acción de eliminar metadatos que se pueda reutilizar o extender, y definir qué pasa con el archivo original (sobrescribir o crear copia).

## Notas de trabajo
- No se puede compilar en el entorno de Claude: se sube a `develop`, se lanza el workflow *Build libre APK* y se pasa el error si falla.
