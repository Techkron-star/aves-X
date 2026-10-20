# 🦇 Aves-X — Roadmap

Guía de trabajo, no un plan rígido. Organizado por **estado**: primero lo que ya está hecho, luego lo que está en curso y por último lo que falta, por prioridad.

Leyenda: ✅ hecho (compila; se prueba en el teléfono) · 🔧 en curso o parcial · ⬜ pendiente

**Principios:** todo lo nuevo de privacidad y lo experimental es *opt-in* (nunca activado por defecto). Nada se envía a ningún sitio: sin telemetría. Aves-X es un homenaje y fork personal de [Aves](https://github.com/deckerst/aves) (licencia BSD-3-Clause, créditos mantenidos).

---

## ✅ Hecho (Beta)

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

### Master Code, intentos y nuke
- ✅ Master Code de 6 dígitos (obligatorio para cambiar o quitar credenciales y para el nuke manual; sin recuperación).
- ✅ Contadores de intentos independientes (App PIN, Master Code, cada vault, papelera, revelado, bloqueos), guardados en almacén seguro tras cada fallo.
- ✅ Espera escalonada con reloj monotónico (no se evade cambiando la hora de del teléfono), máximo configurable (recomendado 5 min; aviso por encima de 2 h).
- ✅ Nuke automático opcional tras 4 fallos; nuke manual; PIN de pánico (pantalla falsa + borrado en segundo plano); biometría contada en el mismo contador.
- ✅ Borrado criptográfico primero: se destruyen claves y credenciales antes de borrar archivos.

### Fail-Safe (manejo local de errores)
- ✅ Captura local de fallos con informe que el usuario puede compartir si quiere (copiar); diagnóstico por reglas.
- ✅ Modo seguro tras un cierre inesperado: no se pueden bajar protecciones, abrir ni borrar vaults, ni borrar nada; salida manual con Master Code.
- ✅ Lockdown: con el nuke por intentos desactivado, los fallos repetidos bloquean la app con "Protocolo Lockdown activado".
- ✅ Sección de ajustes de Fail-Safe y asistente de bienvenida que sustituye a los términos y condiciones (deslizable, texto saltable con un toque, aceptar manteniendo pulsado).

### Metadatos y sistema
- ✅ Quitar metadatos (JPEG, PNG, WebP) desde visor y selección múltiple; borrado automático.
- ✅ `.nomedia`: crear/quitar desde el Explorador, mostrar todas las carpetas (botón visible) y marca en las carpetas con `.nomedia`.
- ✅ Etiquetas/subtítulos libres en fotos y vídeos, buscables.

### Interfaz y efectos
- ✅ Nombre y logo Aves-X (murciélago), Monet por defecto, modo rendimiento, pegatinas de funciones ("experimental").
- ✅ Barra de navegación: estilos (clásica, redondeada, flotante, rectangular), **Bat-Lens** deslizante con efecto gota, deslizar entre pestañas con el dedo y transición tipo Instagram.
- ✅ **Bat-Glass 2.0** (primera fase): cristal de diamante rojo facetado y translúcido con destello animado en el menú lateral, cristal en botones y barras difuminadas, íconos líquidos, animación de candado con cadenas.
- ✅ **Glass-Everywhere**: vidrio esmerilado neutro (desenfoque fuerte) en diálogos, menús y superficies; separado de Bat-Glass.
- ✅ Progreso de operaciones (mover/copiar/borrar) enviable a segundo plano.

### Reproductor (Bat-Player)
- ✅ Gestos tipo YouTube (brillo/volumen, doble toque para saltar) y botón de bucle de tres modos con icono propio.
- ✅ Decodificación: desactivada, activada, forzada, copia, híbrida y opciones mpv personalizadas.

### Privacidad general
- ✅ Sin telemetría: se eliminaron Firebase/Crashlytics y servicios de Google.

---

## 🔧 En curso

- 🔧 **Bat-Glass 2.0 / Nebula Engine** (Glass-Everywhere 2.0: menús, hojas, avisos, tarjetas y cajón ya son cristal translúcido con borde; falta blur real en ellos) (motor propio de cristal y efectos): extender el cristal facetado a más pantallas (barras de búsqueda y filtros, diálogos, tarjetas, selector de pestañas), mejores animaciones de íconos y transiciones (cristal que se rompe o se condensa), ajustes separados que se noten entre Bat-Glass y Glass-Everywhere. Posible renombrar Glass-Everywhere a **Bat-Cave**.
- 🔧 Diálogos de Fail-Safe con efectos visuales (el Lockdown ya tiene fondo de cristal rubí).
- 🔧 Reproductor: 4K/HD a ~10 fps en algunos vídeos (probar modos de hardware), barajar (shuffle).

---

## ⬜ Pendiente — próxima versión

1. ✅ **Personalidad de Fail-Safe**: personaje con comentarios y voz sintetizada (balbuceo procedural, sin muestras ni licencias) en Lockdown y bloqueo de la app; opción para desactivar la voz.
2. ⬜ **Bat-Curity fase 2**: fotos bloqueadas individualmente conservan metadatos y se mueven al almacenamiento privado de la app.
3. ⬜ **Cifrado de archivos de las vaults** (que con root en `data/data` no se abran):
   1. At-rest: AES-256-GCM por archivo con clave en Android Keystore; descifrado temporal al abrir y borrado/sobrescritura al cerrar.
   2. Clave ligada a la credencial (PBKDF2/Argon2).
   3. Sin texto plano en disco (descifrado en memoria; miniaturas y base de datos cifradas).
   4. Migración de vaults existentes y limpieza segura tras el nuke.
4. 🔧 Metadatos: GIF hecho (conserva la animación); faltan HEIC y AVIF; previsualización de lo que se elimina y selección de campos (GPS, fecha, cámara…); regenerar miniaturas.
5. ⬜ Transferencia más rápida entre álbumes (separar límite de la plataforma de lo optimizable).
6. ⬜ Aviso de escaneo de medios que a veces no desaparece.
7. ⬜ App lock: bloqueo inmediato o por tiempo configurable; ocultar contenido en multitarea y notificaciones.
8. ⬜ Gesto secreto configurable (2–5 s, ubicación elegible) y pestaña "Ocultos" opcional; separar visualmente "Ocultos" y "Vaults"; indicadores visuales de oculto/vault/bloqueado.
9. ⬜ Reproductor: ecualizador y opciones de subtítulos.
10. ⬜ Más pegatinas para funciones nuevas.

---

## ⬜ Pendiente — hacia 1.0 (Privacy Gallery)

- ⬜ Hardening: revisar rutas de compartir e intents externos, previews, miniaturas, cachés, logs, temporales, backups, recientes, rotación, pantalla dividida y grabación de pantalla; ocultar vaults del cajón y de los buscadores; limpieza de sesión al salir.

- ⬜ Rediseño de Ajustes en niveles (básico / avanzado / experimental).
- ⬜ Identidad definitiva: adaptive icon, `applicationId` y package final (ahora `dev.techkron.avesx`; el namespace del código sigue siendo el de Aves), créditos y licencias.
- ⬜ Auditorías y pruebas (archivos grandes, vídeos, miles de archivos, almacenamiento lleno, con/sin root, reinicio, actualización), README, changelog y build release.
- ⬜ Optimización de código y compatibilidad amplia.

---

## 🌌 Futuro (ideas, sin prioridad)

### Sistema Gargantua
Las apps de seguridad suelen impedir que otros entren a tus fotos; Gargantua evita que tus archivos **salgan** sin permiso. Nombre del agujero negro de Interstellar: lo que entra en una zona protegida de Aves-X no sale a menos que el dueño lo ordene. Estética cósmica.
- ⬜ Interceptar "Compartir" antes de que aparezca el menú de Android (WhatsApp, Telegram, correo…).
- 🔧 Autenticación de salida: compartir una foto o álbum bloqueado pide la credencial de bloqueos (hecho); falta Master Code por regla y otras salidas (abrir con, copiar, etc.)
- ⬜ Vaults y bloqueados bajo Gargantua por defecto.
- ⬜ Con root, capacidades potenciadas (alcance aún por definir).

### Black Hole (modo root opcional)
- ⬜ Demonio root: nuke y borrado automático que siguen aunque se cierre o mate la app.
- 🔧 Borrado más fuerte: sobrescritura antes de borrar (nuke) y TRIM con root hechos; falta sellado y cifrado de carpetas en `data/data`.
- ⬜ Se integrará con Gargantua.

### Modo tablet y ergonomía (Bubble Navigation)
- 🔧 Navegación flotante para pantallas grandes (**Modo tablet**, Ajustes → Pantalla, bajo el modo TV): burbuja grande al borde que abre hasta 6 burbujas en arco; deslizar de la grande a una pequeña cambia de pestaña. Sin Bat-Lens; el editor limita a 6 acciones. Primera versión, sin probar. Ya incluye el ajuste "Burbuja a la izquierda" (zurdos) y el gesto secreto de Álbumes (mantener 5 s la burbuja de Álbumes con el menú abierto); ambos sin probar.
- ⬜ Animaciones de escala y desvanecimiento de las burbujas, con la estética de Bat-Glass.
- ✅ Detección automática de tablet (lado menor ≥ 600 dp) para activar este modo sin pasar por Ajustes: se aplica solo la primera vez, si el usuario aún no ha elegido; después manda el ajuste. Sin probar.
- 🔧 Detección automática de Android TV: ahora también se considera TV cuando el `uiMode` del sistema es televisión (cajas que no declaran `leanback`). Sin probar; falta revisar errores de estado al cambiar de interfaz.
- ⬜ Cambio en caliente: al rotar el dispositivo o conectarlo a una pantalla externa, la interfaz se adapta en tiempo real.

### Otras ideas
- ⬜ Estrategias nuevas de ocultación, automatización de metadatos y vaults, opciones avanzadas de almacenamiento.

---

## Notas de trabajo
- No se compila en el entorno de desarrollo: se sube a `develop`, se lanza el workflow *Build libre APK* y los errores se leen de las anotaciones.
- Los archivos de `flavors/` del proyecto original están desactualizados; el workflow genera la variante libre a partir de `pubspec.yaml`.
- El chequeo `Quality check` marca avisos de estilo en análisis estático (no afectan al APK).
- Pendiente del lado del usuario: avisar a Aves (upstream) del fallo de la barra de navegación en el diseño TV.
