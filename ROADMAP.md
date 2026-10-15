# Ideas y estado

## Hecho
- **Gesto secreto para mostrar ocultos**: mantener pulsado 5 s el botón *Álbumes* de la barra inferior y confirmar el bloqueo (Ajustes → Privacidad → "Bloqueo para mostrar elementos ocultos"). Sin bloqueo configurado no pasa nada. Mantener otros 5 s vuelve a ocultar. Se apaga solo al pasar la app a segundo plano.
- **Bloqueo de la papelera** (biometría, patrón, PIN o contraseña) en Ajustes → Privacidad.
- **Seguridad avanzada de cajas fuertes** (Ajustes → Privacidad):
  - segundo bloqueo opcional por caja fuerte (doble contraseña: p. ej. huella + PIN, PIN + contraseña…),
  - bloqueo de compartir: ningún elemento de la caja puede enviarse a otras apps (compartir, abrir con, usar como, imprimir, copiar al portapapeles, editar fuera, convertir) salvo que el usuario lo saque manualmente,
  - opción para ocultar las cajas fuertes de la lista de álbumes hasta revelar los ocultos.
- **Borrar metadatos**: ya incluido en Aves (visor: menú ⋮ → quitar metadatos; selección múltiple en la colección: menú ⋮ → quitar metadatos).
- **Monet / color dinámico**: ya incluido en Aves (Ajustes → Pantalla); ahora viene activado por defecto en instalaciones nuevas.
- **Blur más "liquid glass"**: desenfoque más fuerte y reflejo/borde suave en botones y barras flotantes.

## Pendiente
- Ver y gestionar carpetas con `.nomedia` (ignorarlas como "ocultas" de otras galerías). Complejo: depende de cómo MediaStore trata esas carpetas.
- Crear y quitar archivos `.nomedia` desde la app.
- Contraseña para entrar a la app.
- Borrado de emergencia ("nuke"): borrar todas las cajas fuertes de golpe confirmando con un PIN.
- Liquid glass más avanzado: saturación y refracción del fondo, no solo desenfoque.
- Ocultar las cajas fuertes también del cajón lateral y de los buscadores, no solo de la lista de álbumes.

## Notas de trabajo
- No se puede compilar en el entorno de Claude: se sube a `develop`, se lanza el workflow *Build libre APK* y se leen los errores en las anotaciones.
- Los archivos de `flavors/` del proyecto original están desactualizados; el workflow genera la variante libre a partir de `pubspec.yaml`.
