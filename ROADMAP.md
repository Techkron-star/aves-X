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

## 0.2b — Bloqueos de álbumes/fotos y confirmaciones
- [x] Bloquear álbumes normales y fotos sueltas (acción "Bloquear / desbloquear" en selección, álbumes y visor): miniaturas borrosas con candado, y para abrirlos se pide el bloqueo (biometría, PIN, patrón…). Se vuelven a cerrar al pasar a segundo plano.
- [x] Confirmación estricta de borrado: botón rojo con espera de 5 s y después escribir BORRAR.
- [x] Ajustes de privacidad por secciones (Bloqueos y ocultos, Vaults, Bloqueo de la app, Seguridad y destrucción), con interruptores; desactivar una protección pide el Master Code.
- [x] Durante el cooldown de 5 min no se puede escribir ninguna credencial.
- [x] Bloquear la página de Favoritos. Cristal en diálogos, menú lateral y menús. Color por defecto rojo. Avisos de riesgo (botón rojo con espera) al activar nuke, bloqueo de app y PIN de pánico.
- [ ] Al deslizar en el visor, las fotos bloqueadas vecinas aún podrían verse (pendiente).

## Principios
- **Todo es opt-in**: ninguna función nueva de privacidad ni experimental viene activada por defecto.
- Sección **EXPERIMENTAL** en Ajustes (con aviso al abrirla): Bat-Glass y efecto cristal en diálogos/menú lateral.
- Feedback háptico y visual al bloquear/desbloquear álbumes, fotos y favoritos.

- [x] Estilo de la barra de navegación (clásica, redondeada, flotante, rectangular). Botones sólidos → cristal rubí translúcido con Bat-Glass / cristal en todas partes. Acerca de actualizado (Aves-X alpha, basado en Aves).

## 0.3 — Destrucción (nuke) y Master Code
- [x] **Master Code** de 6 dígitos: se crea antes de cualquier PIN/contraseña, obligatorio para cambiar o quitar cualquier credencial (vaults, papelera, revelado, bloqueo de app, seguridad avanzada) y para el nuke manual. Sin recuperación.
- [x] Contadores de intentos independientes (App PIN, Master Code, cada vault), guardados en disco tras cada fallo (almacén seguro).
- [x] 3 fallos → espera de 5 min + vibración; 4º fallo → nuke automático (App PIN y Master Code: todo; vault: solo su contenido). Cooldown con reloj monotónico (resiste cambiar la hora; un reinicio lo reinicia).
- [x] Bandera de nuke pendiente: se ejecuta al iniciar, antes de mostrar la interfaz.
- [x] Nuke manual: Ajustes > Privacidad > "Nukear todas las vaults" (pide Master Code, sin más confirmación; fallo = intento de Master Code). No toca archivos fuera de las vaults.
- [x] Biometría en el bloqueo de inicio: cada fallo cuenta en el mismo contador; tras 3 fallos biométricos se exige el PIN.
- [x] PIN de pánico opcional: pantalla falsa "PIN incorrecto" y borrado total en segundo plano.
- [ ] Contadores de intentos también para papelera y bloqueo de revelado (hoy sin límite).
- [ ] Root shredder opcional, registro local del resultado.
- [ ] **Cifrado de los archivos de las vaults** (para que con root en `data/data` no se puedan abrir). Plan por fases:
  1. Fase 1 (at-rest): AES-256-GCM por archivo (streaming, `javax.crypto`), clave maestra aleatoria guardada en Android Keystore (mejor StrongBox/TEE; no exportable). Al desbloquear una vault se descifra a una carpeta temporal privada (`cacheDir/vault_tmp/<vault>`) y al bloquear / cerrar / arrancar se borra y sobrescribe. Mantiene compatible todo el visor (rutas de archivo, vídeo, EXIF). Límite: mientras la vault está abierta, el texto plano existe en disco.
  2. Fase 2 (clave ligada a la credencial): derivar la clave con PBKDF2/Argon2 desde PIN/contraseña de la vault, de modo que ni con root + app abierta se lean cerradas.
  3. Fase 3 (sin texto plano en disco): descifrado en memoria (proveedor de datos propio para imágenes y ExoPlayer `DataSource`), cifrado de miniaturas y de la base de datos de entradas de vault.
  4. Migración de vaults existentes (cifrar en segundo plano con marca de progreso reanudable) y limpieza segura al hacer nuke.

## 0.4 — Metadatos
- [~] Borrar metadatos desde el visor y desde selección múltiple (por lotes): **ya incluido en Aves** (menú ⋮ → quitar metadatos).
- [ ] Revisar formatos soportados (JPEG, HEIC, PNG, WebP, MP4/MOV), sobrescribir o crear copia, previsualización/resumen de lo que se elimina, selección de campos (GPS, fecha, cámara, software, copyright…).
- [ ] Comprobar que se invalidan y regeneran las thumbnails tras modificar.

## 0.5 — Sistema (.nomedia y reglas por carpeta)
- [ ] Detectar y mostrar carpetas con `.nomedia`, crear y quitar `.nomedia`, mostrar/ocultar.
- [ ] Filtro global de visibilidad y reglas por carpeta (mostrar, ocultar, ocultar de álbumes, proteger, enviar a vault, política de metadatos), herencia y prioridad.

## 0.6 — App lock
- [x] Pantalla de bloqueo al abrir la app (App PIN de 6 dígitos + biometría opcional) antes de mostrar contenido; se reactiva tras 30 s en segundo plano.
- [ ] Bloqueo inmediato / por tiempo configurable, ocultar contenido en multitarea y notificaciones.

## 0.7 — Privacidad avanzada (hardening)
- [ ] Revisar todas las rutas de compartir e intents externos, previews, thumbnails, cachés, logs, archivos temporales, backups, recientes, rotación, pantalla dividida, grabación de pantalla y reinicio.
- [ ] Ocultar las vaults también del cajón lateral y de los buscadores.

## 0.8 — Interfaz
- [~] Monet / Material You: ya incluido en Aves; ahora **activado por defecto**.
- [x] Cristal más transparente (barras y botones con fondo casi translúcido).
- [x] Logo de murciélago como icono y logo dentro de la app; nombre "Aves-X".
- [x] Blur más fuerte y reutilizable (`Blurred*`) con reflejo y borde de cristal en barras y botones flotantes.
- [~] **Tema "Bat-Glass"** (experimental, Ajustes → Pantalla): negro con cristal líquido rubí. Primera versión: esquema oscuro negro/rubí y reflejos rojos en las superficies de cristal; falta pulir.
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

## Bat-Curity (in progress)

- [x] "Security" settings category (App lock, Master Code, nuke, hashing)
- [x] Argon2id + random salt hashing of all credentials (opt-in, only the Master Code can disable it; offered after creating the Master Code)
- [ ] Encryption of vault files with an Android Keystore key
- [ ] Encryption of individually locked photos and albums (moved to app-private storage)

## Other recent additions

- [x] Lock animation (chains + padlock; ruby chains + bat padlock in Bat-Glass)
- [x] Nav bar lens (rounded/rectangular), liquid icons in Bat-Glass, glass controls
- [x] Performance mode, automatic deletion, PNG/WebP metadata removal, lock from the viewer
- [x] Fix: nav bar vanishing after turning the TV layout off (inherited from Aves)

## Next

- [~] `.nomedia` (create/remove from the Explorer menu done; toggle to show hidden folders pending): a toggle to show folders that contain no media, and creating/removing `.nomedia` files so other apps do not see chosen folders
- [ ] Stickers: small labels next to feature names (e.g. "experimental") in Settings
- [x] Custom tags/captions for photos and videos (e.g. "foto madre 17/11/2017") searchable instead of the file name
- [ ] Faster media transfer between albums (check what is a platform limit and what can be optimized)
- [ ] Optional root mode: real secure destruction for the nuke (overwrite/shred instead of a normal delete) and other root-only improvements
- [ ] Fix: the media scan notification sometimes never goes away
- [x] Operation progress (move/delete/copy) can be sent to the background (`close_fullscreen` button) and uses the Bat-Glass / glass look; more dialogs and animations to follow
- [ ] Glass-Everywhere 2.0 (to be renamed **Bat-Cave**): glass look for every screen, dialog and control, with a lower cost
- [ ] Bat-Curity: encryption of individually locked photos and albums
- [ ] Attempt counters for bin / hidden-items / item locks
- [ ] Metadata removal for HEIC, AVIF and GIF

## Privacy

- [x] No telemetry: Firebase/Crashlytics, Google services, their plugins, keys and settings were removed; errors are only logged on the device

## Bat-Player (video player rewrite)

- [ ] Quick controls: loop, shuffle, playback speed
- [ ] YouTube-like gestures: slide on the left/right side of the screen for brightness/volume, double tap to seek
- [ ] Codec / decoder options (hardware vs software), and investigate why some HD/4K videos play at ~10 fps
- [ ] Equalizer-like and subtitle options as in other players

## Bat-Cave (Glass-Everywhere 2.0) and Bat-Glass 2.0

- [x] Side menu header with a translucent red diamond texture in the glass modes
- [ ] Glass look for the search / filter area, the app bars and more screens
- [ ] Bat-Lens: sliding effect when switching tabs
- [x] Swipe horizontally to change between the main tabs (favourites, albums, ...)

## Tags for photos (stickers)

- [x] Free text labels / captions on photos and videos (e.g. "foto madre 17/11/2017"), searchable from the search page, not only file names and types

## Major update (later)

- [ ] Code optimization and wider compatibility

## Failsafe (crash handling, replaces any crash reporting)

- [x] Local crash capture: after a crash, show the log as a text the user can share if they want (nothing is sent anywhere)
- [x] Safe mode after a crash: banner "Safe mode"; security options cannot be lowered, vaults cannot be opened or deleted, nothing can be deleted; back to normal after a clean launch
- [x] Crypto-erase first nuke: destroy keys and credentials before deleting files, so an interrupted nuke still leaves nothing readable

## Black Hole (optional root mode)

- [ ] Root daemon: nuke and automatic deletion that keep running with the app closed or killed
- [ ] Stronger deletion, sealing and encrypting folders in the app data
