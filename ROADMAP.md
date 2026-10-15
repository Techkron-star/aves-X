# 🦇 Aves-X — Roadmap

Guía de trabajo, no un plan rígido. `[x]` = hecho en el fork (compila; pendiente de probar en el teléfono), `[~]` = parcial o ya existía en Aves, `[ ]` = pendiente.

## 0.1 — Fundación de privacidad (credenciales + ocultos)
- [x] Sistema central de credenciales reutilizable (`SecretLock`: sistema/biometría, patrón, PIN, contraseña).
- [x] PIN, patrón y contraseña configurables; integración con la credencial del sistema.
- [x] Bloqueo de papelera (Ajustes → Privacidad).
- [x] Gesto secreto: mantener pulsado 5 s el botón **Álbumes** y confirmar el bloqueo de revelado. (Sustituye al gesto de 5 toques, imposible por la animación de la barra.)
- [x] Autenticación después de la pulsación larga. Sin bloqueo configurado, no pasa nada. Hide sin pedir credencial.
- [ ] Pulsación larga configurable (2–5 s) y ubicación del gesto elegible (Favoritos / Álbumes). Hoy: fijo en 5 s sobre Álbumes.
- [~] Ocultar archivos/álbumes de la vista normal: ya lo hace Aves ("Ocultar"); el gesto los vuelve a mostrar.
- [ ] Pestaña "Ocultos" al final de Álbumes (se sustituyó por el revelado con gesto).
- [x] Evitar compartir desde vaults protegidas (ver 0.2). [ ] Extracción manual específica desde "Ocultos".
- [~] Bloqueo automático: las vaults ya se bloquean al apagar pantalla; los ocultos se vuelven a ocultar al pasar a segundo plano.
- [x] Decidido: la papelera y el revelado usan credenciales **independientes**.

## 0.2 — Vault-X + autenticación avanzada
- [x] Doble autenticación opcional por vault (segundo bloqueo de otro tipo: huella + PIN, PIN + contraseña, etc.).
- [x] Desactivar compartir desde una vault (compartir, abrir con, usar como, imprimir, portapapeles, editar fuera, convertir). La salida es mover manualmente.
- [x] Ocultar las vaults de la lista de álbumes (se muestran al revelar). Solo en la lista de álbumes.
- [~] Crear/administrar vaults, importar/extraer manualmente, bloqueo automático: ya existen en Aves.
- [ ] Limpieza de sesión al salir, protección de thumbnails, contenido en recientes, comportamiento tras reinicio / al quitar de recientes.
- [ ] Separar conceptualmente "Ocultos" y "Vaults" en la interfaz.

## 0.3 — Destrucción (nuke + root shredder)
- [ ] Nuke global de vaults protegido solo por PIN (nunca solo biometría), con doble confirmación y aviso de irreversibilidad.
- [ ] Limpieza de archivos, referencias, thumbnails, cachés e índices; comprobar que no queda nada visible.
- [ ] Detección opcional de root, shredder con root, fallback a borrado normal si no hay root o falla.
- [ ] Registro local del resultado.

## 0.4 — Metadatos
- [~] Borrar metadatos desde el visor y desde selección múltiple (por lotes): **ya incluido en Aves** (menú ⋮ → quitar metadatos).
- [ ] Revisar formatos soportados (JPEG, HEIC, PNG, WebP, MP4/MOV), sobrescribir o crear copia, previsualización/resumen de lo que se elimina, selección de campos (GPS, fecha, cámara, software, copyright…).
- [ ] Comprobar que se invalidan y regeneran las thumbnails tras modificar.

## 0.5 — Sistema (.nomedia y reglas por carpeta)
- [ ] Detectar y mostrar carpetas con `.nomedia`, crear y quitar `.nomedia`, mostrar/ocultar.
- [ ] Filtro global de visibilidad y reglas por carpeta (mostrar, ocultar, ocultar de álbumes, proteger, enviar a vault, política de metadatos), herencia y prioridad.

## 0.6 — App lock
- [ ] Contraseña / PIN / biometría / credencial del sistema para entrar a la app; bloqueo inmediato, tras X minutos, al apagar pantalla o al salir.
- [ ] Ocultar contenido en multitarea y notificaciones; integrar con `SecretLock`.

## 0.7 — Privacidad avanzada (hardening)
- [ ] Revisar todas las rutas de compartir e intents externos, previews, thumbnails, cachés, logs, archivos temporales, backups, recientes, rotación, pantalla dividida, grabación de pantalla y reinicio.
- [ ] Ocultar las vaults también del cajón lateral y de los buscadores.

## 0.8 — Interfaz
- [~] Monet / Material You: ya incluido en Aves; ahora **activado por defecto**.
- [x] Blur más fuerte y reutilizable (`Blurred*`) con reflejo y borde de cristal en barras y botones flotantes.
- [ ] Liquid glass avanzado (saturación y refracción del fondo), blur específico en el visor, animaciones.
- [ ] Rediseño de Ajustes en niveles (básico / avanzado / experimental), gestos configurables.
- [ ] Indicadores visuales de oculto / vault / bloqueado / protegido.

## 0.9 — Identidad
- [ ] Nombre Aves-X, logo de murciélago, adaptive icon (foreground 108 dp, zona segura 66 dp), strings, manifest, gradle, canal de notificaciones, "Acerca de".
- [ ] Créditos a Aves y licencia BSD-3-Clause (mantener el aviso), licencia del icono, decidir `applicationId` y package name definitivos (hoy: `deckers.thibault.aves.mio`).

## 1.0 — Privacy Gallery
- [ ] Funciones críticas terminadas, auditorías (permisos, almacenamiento, autenticación, vault, nuke, metadatos, `.nomedia`), pruebas (archivos grandes, vídeos, miles de archivos, almacenamiento lleno, con/sin root, reinicio, actualización), README, changelog y build release.

## Después de 1.0 — Experimental
- Reglas avanzadas por carpeta, más funciones con root, políticas de privacidad por carpeta, automatización de metadatos y vaults, nuevas estrategias de ocultación, opciones avanzadas de almacenamiento.

## Notas de trabajo
- No se compila en el entorno de Claude: se sube a `develop`, se lanza el workflow *Build libre APK* y los errores se leen de las anotaciones.
- Los archivos de `flavors/` del proyecto original están desactualizados; el workflow genera la variante libre a partir de `pubspec.yaml`.
- El chequeo `Quality check` del fork marca avisos de estilo en análisis estático (no afectan al APK).
