# 🦇 Aves-X — Roadmap

Estado actualizado para **Beta 0.5**. Este documento distingue funciones implementadas de funciones experimentales o pendientes de validación; no marca como terminado trabajo de seguridad que aún no está completo.

**Principios:** privacidad local, sin telemetría añadida por Aves-X y nuevas protecciones opcionales. Aves-X es un fork personal de [Aves](https://github.com/deckerst/aves), licencia BSD-3-Clause con créditos preservados.

## ✅ Incluido en Beta 0.5

### Galería y privacidad
- Visor y reproducción de fotos/vídeos, álbumes, favoritos, etiquetas, búsqueda, mapas, explorador y papelera.
- Bloqueos para álbumes, fotos/favoritos, papelera, elementos ocultos y vaults, con controles de credenciales.
- Código Maestro, bloqueo de aplicación, biometría opcional, hashing Argon2id opt-in, contador persistente de intentos y espera escalonada.
- Borrado de emergencia manual y opción de borrado por intentos fallidos; el borrado es irreversible y requiere una configuración explícita.
- Fail-Safe con diagnóstico local, modo seguro después de cierres inesperados, lockdown, voz sintetizada y burbuja de diálogo con límite anti-spam.
- Vaults con opciones de cifrado experimental; revisar las advertencias y conservar copias de seguridad independientes.
- Captions locales, eliminación de metadatos para formatos compatibles, control `.nomedia` y limpieza automática configurable.

### Gargantua y Gargantuan
- **Gargantua:** política y ajustes para limitar la entrega/compartición de elementos, con protección del Código Maestro y bloqueo ante errores de almacenamiento seguro.
- **Gargantuan / Black Hole:** opción root experimental y estética animada de horizonte de sucesos, con pausa en modo rendimiento.
- **Límite actual:** no todas las rutas de salida están interceptadas de extremo a extremo. Compartir/entregar contenido es la ruta más integrada; no se afirma cobertura universal.

### Nebula Engine e interfaz
- Temas con paleta y materiales propios: Aves, Nosferatu Glass, Nox Terroris, Obsidian, Aureate, Forge, Hermetic, Eclipse, Solar Flare, Void, Crimson, Neon, Emerald, Aurora, Sapphire, Amber, Onyx, Pearl, Ivory, Imperial, Abyssal y Sakura.
- Glass-Everywhere, Nav Lens con cadenas animadas durante el desbloqueo, modos de navegación y modo rendimiento.
- Importación/exportación local de temas personalizados.
- Ajustes separados en General y Aves-X; contraste de los botones del encabezado adaptado a temas claros/oscuros.
- Versión visual y documental Beta 0.5.

## 🧪 Validación todavía necesaria en dispositivos reales
- Recorrer bloqueos, contadores y flujos Fail-Safe con interrupciones, reinicio forzado, poco almacenamiento y distintas versiones de Android.
- Medir FPS, uso de memoria y batería de Nosferatu Glass/Nebula y la nueva animación Black Hole en dispositivos modestos.
- Verificar instalación, actualización y migración de datos de Beta 0.5 en más de un dispositivo.
- Comprobar gestos de navegación, modo tablet/TV, pantalla dividida y retorno desde segundo plano.

## 🔧 Pendiente antes de considerar una 1.0 centrada en privacidad

### Endurecimiento de medios
- Revisar previews, miniaturas, cachés, temporales, logs, recientes, backups, intents externos, rotación, pantalla dividida y captura/grabación de pantalla.
- Mover elementos bloqueados individuales a almacenamiento privado cuando corresponda, conservando metadatos y controlando copias temporales.
- Añadir vista previa/selección de campos de metadatos y ampliar la cobertura de formatos que aún falten (por ejemplo HEIC/AVIF).
- Auditar cifrado en reposo de vaults, migración de archivos existentes, temporales descifrados, base de datos y miniaturas, y recuperación tras fallos.

### Gargantua
- Completar políticas y enforcement de exportar/guardar, portapapeles, abrir con/editar, cast/superficies y otras rutas de salida.
- Proteger las rutas de compartir antes de abrir el selector del sistema cuando sea técnicamente viable.
- Definir el comportamiento por defecto para vaults y elementos bloqueados, revisar backups y probar denegación segura de cada ruta.
- Documentar limitaciones del modo root y no prometer borrado forense garantizado.

### Producto y rendimiento
- Optimizar blur y animaciones fuera de pantalla sin cambiar la identidad visual; probar equipos de gama baja.
- Completar accesibilidad, contraste, movimiento reducido, traducciones y ergonomía de tablet/TV.
- Ampliar pruebas automáticas de políticas de seguridad, importación/exportación, versiones, medios grandes y miles de elementos.
- Mantener documentación, changelog y builds sincronizados, y confirmar que el flujo de publicación sólo empaqueta Aves-X.

## 📦 Criterio de cierre de Beta 0.5
- [x] Etiqueta visible **BETA 0.5**, versionado de app y nombre de artefactos APK.
- [x] Contraste de botones del cajón en función del color predominante del tema.
- [x] Ajustes estándar separados de los sistemas propios de Aves-X.
- [x] Voz de Fail-Safe con protección contra repetición rápida.
- [x] Animación de Gargantuan / Black Hole pulida y respetuosa del modo rendimiento.
- [x] README, changelog y roadmap revisados.
- [ ] Confirmar el build y las pruebas automáticas de este commit, revisar el APK final y probarlo en dispositivo real.

La última casilla no se marca hasta que el CI del commit final termine. Esta beta no representa una auditoría formal de seguridad.
