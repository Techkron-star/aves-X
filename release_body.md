# Aves-X v0.5.0 — Nebula Engine v1

## 🏷️ Renombrado a nombres propios
- **Bat-Glass** → **Nosferatu Glass**
- **Bat-Lens** → **Nav Lens**
- **Bat-Curity** → **Master Guard**
- **Bat-Mark** → **App Mark**

## 🎨 Nebula Engine — Fase 1 completa
**4 temas nuevos** con paletas completas + tokens Fail-Safe:
- **Nosferatu Glass** — ruby/negro (ex Bat-Glass, paridad exacta)
- **Obsidian Glass** — sangre/obsidiana, vetas naranjas
- **Aureate Glass** — dorado/hoja de oro, vetas cálidas
- **Forge Glass** (Fase 2) — nebular/naranja, vetas fundidas
- **Hermetic Glass** (Fase 2) — alquímico/esmeralda-violeta, glifos

## 🔐 Item Lock Screen + Animación desbloqueo
- Pantalla `ItemLockScreen` bonita con tokens Nebula
- Animación de desbloqueo en `LockedBadge` + `_UnlockingThumbnail`
- UX mejorada: al bloquear sin opción activada → navega a ajustes

## 🎭 Fail-Safe / Seguridad tokenizado
- `FailsafeComicDialog`: anti-spam narrado + `stopPcm()`
- `FailsafeBuddy`, `FailsafeLockdown`, `AppLockGate` usan tokens Nebula
- `MasterGuard` (ex `BatCurity`): renombrado puro, claves storage intactas

## 🎭 Logo Material You / Material 3 Expressive
- Icono adaptativo: foreground vectorial + monochrome (Android 13+)
- Splash nativo claro/oscuro + widget `AppLogo` 5 variantes M3

## 📦 APKs
Disponibles en el artefacto **aves-x-libre-apks** de GitHub Actions:
- `Aves-X-libre-arm64-v8a.apk`
- `Aves-X-libre-armeabi-v7a.apk`
- `Aves-X-libre-x86_64.apk`