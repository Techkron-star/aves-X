<div align="center">

<img src="assets/aves_x_logo.png" alt="Aves-X logo" width="220" />

# Aves-X

**A private Android gallery based on [Aves](https://github.com/deckerst/aves).**

`ALPHA — testing`

</div>

---

## What is Aves-X?

**Aves-X** is an experimental fork of Aves that adds an extra layer of **privacy, security, and customization** to the original gallery.

It keeps Aves' core features — media viewer, albums, metadata, tags, maps, trash, and vaults — while adding additional controls to protect your photos and videos.

> ⚠️ **Aves-X is currently in alpha.** It may contain bugs, and some features are experimental. Keep backups of your important files.

## Features

### 🔐 Security

- **Master Code** — Primary credential required to modify or remove security protections.
- **App Lock** — Protects access to the application with a PIN and optional biometrics.
- **Failed Attempt Protection** — Progressive cooldowns and an optional emergency wipe after too many failed attempts.
- **Nuke** — Manual or automatic emergency wipe for vaults and their contents.
- **Panic PIN** — Triggers an emergency wipe while displaying a fake incorrect-PIN screen.
- **Bat-Curity** — Optional credential protection using Argon2id hashing.
- **Encrypted Vaults** — Experimental AES-256 encryption for files stored inside vaults.

### 🕵️ Privacy

- **Protected Albums** — Locks entire albums and hides their thumbnails.
- **Protected Photos & Favourites** — Protects individual items without locking an entire album.
- **Advanced Vaults** — Adds an additional lock, sharing protection, and the ability to hide vaults from the album list.
- **Protected Trash** — Prevents unauthorized access to deleted files.
- **Hidden Items** — Access hidden content through a secret gesture.
- **Safe Deletion** — Additional confirmation steps help prevent accidental deletion.
- **Independent Privacy Controls** — Each privacy feature can be enabled or disabled separately.

### 🧹 Automation

- **Automatic Deletion** — Automatically removes photos and videos after a configured period.
- **Automatic Trash Cleanup** — Configure when the trash is emptied.
- **Protected Settings** — Sensitive configuration changes require the Master Code.

### 🎨 Customization

- **Custom Navigation Bar** — Multiple navigation styles to personalize the interface.
- **Bat-Lens** — Glass-lens effect over the active navigation section.
- **Bat-Glass** — Experimental theme inspired by dark glass aesthetics.
- **Glass-Everywhere** — Experimental glass effects throughout the interface.

### ⚡ Performance & Utilities

- **Performance Mode** — Reduces animations and visual effects for lower-end devices.
- **Extended Metadata Removal** — Additional metadata removal support for non-animated PNG and WebP files.
- **Viewer & Selection Controls** — Protect photos and albums directly from the viewer or selection interface.

## Project Status

Aves-X is currently in **alpha**.

The main features are implemented, but development is ongoing. Some features, especially encryption and visual effects, are still experimental.

**Do not use Aves-X as the only place where you store irreplaceable files.** Some security features, such as the Nuke, are intentionally irreversible.

## Roadmap

Planned features include:

- Photo and locked-album encryption
- Glass-Everywhere 2.0
- Bat-Glass improvements
- `.nomedia` support
- Attempt limits for trash and protected items
- Metadata removal for HEIC, AVIF, and GIF

See [ROADMAP.md](ROADMAP.md) for the full development roadmap.

## Based on Aves

Aves-X is an **experimental fork and tribute to [Aves](https://github.com/deckerst/aves)**, the open-source Android gallery created by **Thibault Deckers** and developed with its contributors.

Aves-X uses a significant part of Aves' foundation and functionality. Credit for that foundation belongs to the original project and its contributors.

If you are looking for a complete, stable, and actively maintained gallery, consider using **Aves**.

## Credits & License

- **Aves** © Thibault Deckers and contributors.
- Aves-X retains Aves' **BSD 3-Clause** license. See [LICENSE](LICENSE).
- Aves-X is not affiliated with or endorsed by the original Aves author.
- Modifications in this fork are maintained by [@Techkron-star](https://github.com/Techkron-star).
- The Aves-X logo is an original design.

---

<details>
<summary>Español</summary>

**Aves-X** es un fork experimental de [Aves](https://github.com/deckerst/aves) que añade una capa adicional de **privacidad, seguridad y personalización** a la galería de Android.

### Características

- 🔐 Código Maestro, bloqueo de aplicación y autenticación biométrica
- 💣 Borrado de emergencia manual y automático
- 🕵️ Álbumes, fotos, favoritos y papelera protegidos
- 🔒 Vaults avanzadas con cifrado opcional
- 🛡️ Bat-Curity para proteger las credenciales
- 🧹 Borrado automático de contenido y papelera
- 🎨 Estilos de navegación personalizados e interfaz experimental de cristal
- ⚡ Modo rendimiento para dispositivos modestos
- 📝 Compatibilidad ampliada para eliminar metadatos

**Estado:** Alpha — experimental y en desarrollo activo.

Mantén copias de seguridad de tus archivos importantes. Algunas funciones de seguridad, como el borrado de emergencia, son intencionalmente irreversibles.

Consulta [ROADMAP.md](ROADMAP.md) para conocer las funciones previstas.

</details>
