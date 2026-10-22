# 🦇 Aves-X — Roadmap

Guía de trabajo, no un plan rígido. Organizado por **estado**: primero lo que ya está hecho, luego lo que está pendiente de probar, después lo que está en curso y por último lo que falta, por prioridad.

Leyenda: ✅ hecho (integrado en la app) · 🧪 implementado, pendiente de probar en el teléfono · 🔧 en curso o parcial · ⬜ pendiente

**Principios:** todo lo nuevo de privacidad y lo experimental es *opt-in* (nunca activado por defecto). Nada se envía a ningún sitio: sin telemetría. Aves-X es un homenaje y fork personal de [Aves](https://github.com/deckerst/aves) (licencia BSD-3-Clause, créditos mantenidos).

---

## ✅ Hecho

### Privacidad y bloqueos
- ✅ Credenciales reutilizables (sistema/biometría, patrón, PIN, contraseña) para papelera, revelado, vaults, favoritos, álbumes y fotos sueltas.
- ✅ Gesto secreto: mantener pulsado 5 s **Álbumes** para revelar ocultos y vaults.
- ✅ Bloquear álbumes y fotos sueltas (miniaturas borrosas con candado; se vuelven a cerrar al pasar a segundo plano). Las fotos bloqueadas se saltan al deslizar en el visor.
- ✅ Bloqueo de papelera y de Favoritos, con credenciales independientes.
- ✅ Vaults: doble autenticación opcional, compartir desactivado desde vaults, vaults ocultas de la lista de álbumes.
- ✅ Confirmación estricta de borrado (botón rojo con espera + escribir BORRAR) y avisos de riesgo al activar nuke, bloqueo de app y PIN de pánico.
- ✅ Ajustes de privacidad por secciones; desactivar una protección pide el Master Code.
- ✅ Pantalla de bloqueo al abrir la app (PIN de 6 dígitos + biometría opcional, se reactiva a los 30 s).
- ✅ Hash Argon2id con sal aleatoria para todas las credenciales (opt-in, solo el Master Code puede desactivarlo).
- ✅ Pantalla `ItemLockScreen` con tokens del tema y animación de desbloqueo (`LockedBadge` + `_UnlockingThumbnail`).

### Master Code, intentos y nuke
- ✅ Master Code de 6 dígitos (obligatorio para cambiar o quitar credenciales y para el nuke manual; sin recuperación).
- ✅ Contadores de intentos independientes (App PIN, Master Code, cada vault, papelera, revelado, bloqueos), guardados en almacén seguro tras cada fallo.
- ✅ Espera escalonada con reloj monotónico (no se evade cambiando la hora del teléfono), máximo configurable (recomendado 5 min; aviso por encima de 2 h).
- ✅ Nuke automático opcional tras 4 fallos; nuke manual; PIN de pánico (pantalla falsa + borrado en segundo plano); biometría contada en el mismo contador.
- ✅ Borrado criptográfico primero: se destruyen claves y credenciales antes de borrar archivos.
- ✅ **Código Maestro a salvo durante el lockdown**: un acierto nunca se registra como fallo, así que no puede disparar el nuke por accidente.

### Fail-Safe (manejo local de errores)
- ✅ Captura local de fallos con informe que el usuario puede compartir si quiere (copiar); diagnóstico por reglas.
- ✅ Modo seguro tras un cierre inesperado: no se pueden bajar protecciones, abrir ni borrar vaults, ni borrar nada; salida manual con Master Code.
- ✅ Lockdown: con el nuke por intentos desactivado, los fallos repetidos bloquean la app con "Protocolo Lockdown activado".
- ✅ Sección de ajustes de Fail-Safe y asistente de bienvenida que sustituye a los términos y condiciones (deslizable, texto saltable con un toque, aceptar manteniendo pulsado).
- ✅ Ajustes: Seguridad, Fail-Safe y Experimental son secciones desplegables como Vídeo; dentro de Seguridad, hasheo/cifrado se activan al desplegar y el bloqueo de la app y la destrucción son submenús.
- ✅ Corregida la "barra gris infinita" de los menús con cristal: el tema de cristal reemplazaba el estilo de texto de los menús y el panel de Exportar/Editar fallaba al construirse.
- ✅ Voz y frases: Fail-Safe dice en voz alta una frase aleatoria (muchas por nivel, es/en, con nivel de calma) en el Lockdown y en el bloqueo de la app.
- ✅ Avisos en modo cómic (Ajustes → Fail-Safe): los avisos y confirmaciones salen como burbuja de cómic que los narra.
- ✅ Si la voz no puede sonar (volumen multimedia a cero, error del sistema de audio…), el motivo se muestra bajo la burbuja.
- ✅ Fail-Safe tokenizado: burbujas, tarjetas, campos de código y fondos usan los tokens del tema activo, conservando el rojo/ámbar de peligro.

### Gargantua — control de salidas (fase 1)
- ✅ Política agregada de salidas: 5 categorías (compartir, exportar/guardar, portapapeles, abrir con/editar, cast/superficies) + interruptor maestro + regla de Master Code = 7 interruptores.
- ✅ Compartir fotos y vídeos pide el Master Code, reutilizando el guardia de los ítems bloqueados.
- ✅ Página de ajustes propia, con accesos a los controles de salida.
- ✅ Fail-closed: si la política no se puede leer, se bloquea la salida en lugar de permitirla.

### Nebula Engine — fase 1
- ✅ Modelo `NebulaTheme` / `NebulaPalette` / `NebulaTokens`, con identificadores estables y persistencia en ajustes (incluido import/export).
- ✅ Cinco paletas: **Nosferatu Glass** (ruby/negro, paridad exacta con el antiguo Bat-Glass), **Obsidian Glass**, **Aureate Glass**, **Forge Glass** y **Hermetic Glass**. Las dos últimas ya tienen paleta; sus efectos llegan en la fase 2.
- ✅ Selector de tema con nombre propio, descripción y pegatina de función. Las opciones de fase 2 aparecen deshabilitadas con "Próximamente: Fase 2".
- ✅ **Pestaña Nebula dedicada** (Ajustes → Pantalla → Tema Nebula): fondo galáctico con nebulosa lenta, estrellas que parpadean y partículas flotantes; el selector vive ahí. Los efectos se pausan en modo rendimiento y con movimiento reducido.
- ✅ Tokens de Fail-Safe por tema (superficie, borde, glow, acento, campos de código, scrim) y semántica de peligro intacta.
- ✅ Renombrado a nombres propios: Bat-Glass → Nosferatu Glass, Bat-Lens → Nav Lens, Bat-Curity → Master Guard, Bat-Mark → App Mark.

### Identidad y logo
- ✅ Logo = murciélago exacto de `aves_logo.svg`: los mismos 155 trazados se usan en el icono del launcher, el splash, la bienvenida, el cajón y Acerca de.
- ✅ Icono adaptativo (foreground vectorial + `monochrome` para Android 13+), compatible con Material You / Material 3 Expressive.
- ✅ En temas dinámicos el logo sigue el color semilla; en Nosferatu Glass conserva ruby y negro.

### Interfaz y efectos
- ✅ Nombre y logo Aves-X, Monet por defecto y modo rendimiento.
- ✅ Barra de navegación: estilos (clásica, redondeada, flotante, rectangular), **Nav Lens** deslizante con efecto gota, deslizar entre pestañas y transición tipo Instagram.
- ✅ **Nosferatu Glass**: cristal de diamante rojo facetado y translúcido con destello animado en el menú lateral, cristal en botones y barras difuminadas, iconos líquidos, animación de candado con cadenas.
- ✅ **Glass-Everywhere**: vidrio esmerilado neutro en diálogos, menús y superficies; separado de Nosferatu Glass.
- ✅ Pegatinas de funciones ("NEW"/"Experimental") theme-aware, con variante de cristal cuando Glass-Everywhere o Nosferatu Glass están activos.
- ✅ Progreso de operaciones (mover/copiar/borrar) enviable a segundo plano.
- ✅ Estética de agujero negro (Black Hole): tarjeta en Ajustes → Fail-Safe con horizonte de sucesos y disco de acreción animado; se detiene en modo rendimiento.

### Metadatos y sistema
- ✅ Quitar metadatos (JPEG, PNG, WebP, GIF) desde visor y selección múltiple; borrado automático.
- ✅ `.nomedia`: crear/quitar desde el Explorador, mostrar todas las carpetas y marca en las carpetas con `.nomedia`.
- ✅ Etiquetas/subtítulos libres en fotos y vídeos, buscables.

### Reproductor (Bat-Player)
- ✅ Gestos tipo YouTube (brillo/volumen, doble toque para saltar) y botón de bucle de tres modos con icono propio.
- ✅ Decodificación: desactivada, activada, forzada, copia, híbrida y opciones mpv personalizadas.

### Privacidad general
- ✅ Sin telemetría: se eliminaron Firebase/Crashlytics y servicios de Google.

### Seguridad del repositorio
- ✅ Sin claves de API, tokens ni contraseñas en el código, los assets o el historial.
- ✅ Las claves de firma viven fuera del repo (`android/key_template.properties` solo contiene marcadores); los builds leen variables de entorno o secretos de CI.
- ✅ `.gitignore` cubre keystores, `.env`, `key.properties` y artefactos locales.
- ✅ `scripts/check-secrets.ps1` como guard de escaneo de secretos antes de publicar.
- ✅ `scripts/publish-release.ps1` para crear la release y subir los APKs (tag + artefacto + body de notas).

---

## 🧪 Implementado, pendiente de probar en el teléfono

- 🧪 Fail-Safe: voz, frases, modo cómic, modo seguro tras cierre inesperado y aviso del motivo cuando no hay audio.
- 🧪 Modo tablet / Bubble Navigation (burbuja, arco de hasta 6 acciones, burbuja a la izquierda, gesto secreto).
- 🧪 Detección automática de TV y cambio en caliente al plegar o usar pantalla dividida.
- 🧪 Black Hole con root: demonio que borra los datos de la app tras el nuke y TRIM; falta el borrado automático en segundo plano.
- 🧪 Selector de tema y pestaña Nebula en pantalla real, especialmente en gama baja.
- 🧪 Animación de desbloqueo de ítems y bloqueo de app con rebloqueo configurable.
- 🧪 Medición de rendimiento de Nosferatu Glass (FPS, blur, memoria) antes de añadir efectos nuevos.

---

## 🔧 En curso

- 🔧 **Nebula Engine — fase 2**: efectos visuales propios implementados (Forge, Hermetic, Eclipse, Solar Flare, Void, Crimson, Neon, Emerald); pendiente medición de rendimiento en gama baja antes de activar por defecto.
- 🔧 **Temas Nebula personalizados**: import/export, plantilla base para edición manual o asistida por IA, validación y almacenamiento local; el usuario podrá elegir sus propios temas.
- 🔧 **Nosferatu Glass — rendimiento**: dejar de renderizar lo que no se ve (blur bajo superficies opacas, animaciones fuera de pantalla, capas tapadas) sin cambiar el aspecto.
- 🔧 **Gargantua — fases 2 y 3**: portapapeles, guardar/exportar, abrir con/editar y cast/superficies; interceptar "Compartir" antes del menú de Android; vaults y bloqueados bajo Gargantua por defecto.
- 🔧 **Fail-Safe visual — fase 3**: terminar ajustes, bienvenida, lockdown y bloqueo de app con tokens del tema, sin cambiar la forma ni la semántica de seguridad.
- 🔧 **Reproductor**: 4K/HD a ~10 fps en algunos vídeos (probar modos de hardware) y barajar (shuffle).

---

## ⬜ Pendiente — próxima versión

1. ⬜ **Master Guard fase 2**: fotos bloqueadas individualmente conservan metadatos y se mueven al almacenamiento privado de la app.
2. ⬜ **Cifrado de archivos de las vaults** (que con root en `data/data` no se abran):
   1. At-rest: AES-256-GCM por archivo con clave en Android Keystore; descifrado temporal al abrir y borrado/sobrescritura al cerrar.
   2. Clave ligada a la credencial (PBKDF2/Argon2).
   3. Sin texto plano en disco (descifrado en memoria; miniaturas y base de datos cifradas).
   4. Migración de vaults existentes y limpieza segura tras el nuke.
3. ⬜ **Metadatos**: faltan HEIC y AVIF; previsualización de lo que se elimina y selección de campos (GPS, fecha, cámara…); regenerar miniaturas.
4. ⬜ **Transferencia más rápida entre álbumes** (separar el límite de la plataforma de lo optimizable).
5. 🔧 **Aviso de escaneo de medios** que a veces no desaparece: el estado "cargando" ya vuelve a "listo" aunque falle la carga; falta probarlo en dispositivo.
6. 🔧 **App lock**: ocultar contenido en multitarea y notificaciones (el tiempo de rebloqueo ya es configurable).
7. ⬜ **Gesto secreto configurable** (2–5 s, ubicación elegible) y pestaña "Ocultos" opcional; separar visualmente "Ocultos" y "Vaults"; indicadores visuales de oculto/vault/bloqueado.
8. ⬜ **Reproductor**: ecualizador y opciones de subtítulos.
9. ⬜ **Más pegatinas** para funciones nuevas.

---

## ⬜ Pendiente — hacia 1.0 (Privacy Gallery)

- ⬜ Hardening: revisar rutas de compartir e intents externos, previews, miniaturas, cachés, logs, temporales, backups, recientes, rotación, pantalla dividida y grabación de pantalla; ocultar vaults del cajón y de los buscadores; limpieza de sesión al salir.
- ⬜ Rediseño de Ajustes en niveles (básico / avanzado / experimental).
- ⬜ Identidad definitiva: package final (ahora `dev.techkron.avesx`; el namespace del código sigue siendo el de Aves), créditos y licencias.
- ⬜ Auditorías y pruebas (archivos grandes, vídeos, miles de archivos, almacenamiento lleno, con/sin root, reinicio, actualización), README, changelog y build release.
- ⬜ Optimización de código y compatibilidad amplia.

---

## 🌌 Sistemas propios

### Sistema Gargantua
Las apps de seguridad suelen impedir que otros entren a tus fotos; Gargantua evita que tus archivos **salgan** sin permiso. Nombre del agujero negro de Interstellar: lo que entra en una zona protegida de Aves-X no sale a menos que el dueño lo ordene. Estética cósmica.

- ✅ Fase 1: política agregada (5 categorías + maestro + regla de Master Code), compartir con Master Code, página de ajustes y fail-closed.
- 🔧 Fase 2: exportar/guardar, portapapeles, abrir con/editar y cast/superficies.
- ⬜ Interceptar "Compartir" antes de que aparezca el menú de Android (WhatsApp, Telegram, correo…).
- ⬜ Vaults y bloqueados bajo Gargantua por defecto, y excluir `filesDir/vault` del backup.
- ⬜ Cast y superficies de fondo (salvapantallas, widget) solo con ítems autorizados.
- ⬜ Con root, capacidades potenciadas (alcance aún por definir).

### Black Hole (modo root opcional)
- 🔧 Demonio root: en el nuke total, con el modo root activo, un proceso root independiente espera a que muera la app, borra lo que quede de sus datos (solo las rutas de esta app) y hace TRIM. Falta el borrado automático en segundo plano.
- 🔧 Borrado más fuerte: sobrescritura antes de borrar (nuke) y TRIM con root hechos; falta sellado y cifrado de carpetas en `data/data`.
- ✅ Estética de agujero negro en Ajustes → Fail-Safe.
- ⬜ Se integrará con Gargantua.

### Modo tablet y ergonomía (Bubble Navigation)
- 🔧 Navegación flotante para pantallas grandes (**Modo tablet**, Ajustes → Pantalla, bajo el modo TV): burbuja grande al borde que abre hasta 6 burbujas en arco; deslizar de la grande a una pequeña cambia de pestaña. Sin Nav Lens; el editor limita a 6 acciones. Incluye "Burbuja a la izquierda" y el gesto secreto de Álbumes.
- ⬜ Animaciones de escala y desvanecimiento de las burbujas, con la estética de Nosferatu Glass.
- ✅ Detección automática de tablet (lado menor ≥ 600 dp) para activar este modo sin pasar por Ajustes.
- 🔧 Detección automática de Android TV: también se considera TV cuando el `uiMode` del sistema es televisión.
- 🔧 Cambio en caliente cuando cambian las métricas de la ventana (plegar, pantalla externa, pantalla dividida); falta el cambio entre interfaz TV y normal.

### Nebula Engine — fase 2 y temas personalizados

Idea: que **Nebula Engine** sea el paraguas de personalización visual y que **Nosferatu Glass** sea un tema más, junto a **Obsidian Glass**, **Aureate Glass**, **Forge Glass** y **Hermetic Glass**. La fase 1 (paletas, tokens, selector y pestaña) ya está integrada; los shaders llegan después de estabilizar el rendimiento.

- ✅ Fase 2: efectos visuales propios implementados para los 8 temas de fase 2 (Forge, Hermetic, Eclipse, Solar Flare, Void, Crimson, Neon, Emerald); pendiente medición de rendimiento en gama baja.
- ⬜ Temas personalizados: esquema JSON versionado, validador con errores legibles, almacén local en `nebula_themes/`, plantilla base y import/export.
- ⬜ Persistencia por tema y respeto al modo rendimiento (sin blur/shaders) y a la accesibilidad (contraste, tamaños).
- ⬜ Los temas no tocan la lógica de seguridad: superficie, borde, glow y acento siguen el tema, y el rojo/ámbar de peligro se conserva con contraste garantizado.

**Viabilidad:** alta para el selector y los temas de paleta, porque la app ya construye `ThemeData` desde un `ColorScheme` y separa las capas de cristal. Media para los efectos únicos: el coste real es rendimiento (blur y shaders en gama baja) y coherencia visual, no la arquitectura.

### Otras ideas
- ⬜ Estrategias nuevas de ocultación, automatización de metadatos y vaults, opciones avanzadas de almacenamiento.
- ⬜ Revisar con Aves (upstream) el fallo de la barra de navegación en el diseño TV.
