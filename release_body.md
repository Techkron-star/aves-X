# Aves-X v0.5.0 — Nebula Engine v1

## 🏷️ Renombrado a nombres propios
- **Bat-Glass** → **Nosferatu Glass**
- **Bat-Lens** → **Nav Lens**
- **Bat-Curity** → **Master Guard**
- **Bat-Mark** → **App Mark**

## 🎨 Nebula Engine — Fase 1 completa
**5 temas** con paletas completas y tokens de Fail-Safe:
- **Nosferatu Glass** — ruby/negro (ex Bat-Glass, paridad exacta)
- **Obsidian Glass** — sangre/obsidiana, vetas naranjas
- **Aureate Glass** — dorado/hoja de oro, vetas cálidas
- **Forge Glass** (Fase 2) — nebular/naranja, vetas fundidas
- **Hermetic Glass** (Fase 2) — alquímico/esmeralda-violeta, glifos

## 🌌 Pestaña Nebula
- Nueva pestaña dedicada, con estilo galáctico: nebulosa lenta, estrellas que
  parpadean y partículas flotantes.
- Selector de tema con nombre, descripción y pegatina de función.
- Los efectos se pausan en modo rendimiento y con las animaciones desactivadas.

## 🔐 Item Lock Screen + Animación de desbloqueo
- Pantalla `ItemLockScreen` con tokens Nebula.
- Animación de desbloqueo en `LockedBadge` + `_UnlockingThumbnail`.
- Al bloquear sin opción activada, la app guía a los ajustes correspondientes.

## 🎭 Fail-Safe tokenizado
- `FailsafeComicDialog`: anti-spam narrado + `stopPcm()`.
- `FailsafeBuddy`, `FailsafeLockdown` y `AppLockGate` usan los tokens del tema activo,
  conservando el rojo de peligro.
- **Master Code en lockdown**: un código maestro correcto nunca cuenta como intento
  fallido, así que no puede disparar el borrado de emergencia.
- `MasterGuard` (ex `BatCurity`): renombrado puro, claves de almacenamiento intactas.

## 🦇 Logo e identidad
- El logo es el murciélago exacto de `aves_logo.svg`: los mismos 155 trazados se usan
  en el icono del launcher, el splash, la bienvenida, el cajón y Acerca de.
- Icono adaptativo con foreground vectorial y variante **monochrome** (Android 13+),
  compatible con Material You / Material 3 Expressive.
- El logo sigue el color semilla en los temas dinámicos; en Nosferatu Glass conserva
  el ruby y el negro originales.

## 📦 APKs
Adjuntos a esta release:
- `Aves-X-libre-arm64-v8a.apk`
- `Aves-X-libre-armeabi-v7a.apk`
- `Aves-X-libre-x86_64.apk`

> Forge Glass y Hermetic Glass ya tienen paleta, pero sus efectos propios llegan en la
> Fase 2 del Nebula Engine.
