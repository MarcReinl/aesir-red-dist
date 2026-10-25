# AESIR Red

An AI agent for authorized security work. Choose the **Desktop app** for a graphical workspace or the **TUI** to work in your terminal. Either works on its own.

[Install Desktop](#install-desktop) · [Install TUI](#install-tui)

Desktop and TUI support macOS 15 or later and Linux, on ARM64 and x86-64.

## Install Desktop

Download [0.2.0-rc.3](https://github.com/MarcReinl/aesir-red-dist/releases/tag/aesir-v0.2.0-rc.3) for your computer:

| System | Download |
| --- | --- |
| macOS · Apple Silicon | [Download DMG](https://github.com/MarcReinl/aesir-red-dist/releases/download/aesir-v0.2.0-rc.3/aesir-red-0.2.0-rc.3-mac-arm64.dmg) |
| macOS · Intel | [Download DMG](https://github.com/MarcReinl/aesir-red-dist/releases/download/aesir-v0.2.0-rc.3/aesir-red-0.2.0-rc.3-mac-x64.dmg) |
| Linux · x86-64 | [Download AppImage](https://github.com/MarcReinl/aesir-red-dist/releases/download/aesir-v0.2.0-rc.3/aesir-red-0.2.0-rc.3-linux-x86_64.AppImage) |
| Linux · ARM64 | [Download AppImage](https://github.com/MarcReinl/aesir-red-dist/releases/download/aesir-v0.2.0-rc.3/aesir-red-0.2.0-rc.3-linux-arm64.AppImage) |

On macOS, open the DMG and drag **AESIR Red** to **Applications**. For Linux commands or help with the first launch, follow the [Desktop installation guide](docs/INSTALL.md#aesir-red-desktop).

Open the app, choose a project folder, and configure your model in **Settings → Models**. The app includes its engine and dependencies.

## Install TUI

Run this in your macOS or Linux terminal:

```sh
curl -fsSL https://raw.githubusercontent.com/MarcReinl/aesir-red-dist/main/install-tui.sh | sh
```

Reopen your terminal, then run this from your project folder:

```sh
aesir
```

The TUI works standalone. Desktop is optional, and the installer automatically installs the engine and Node.js it needs. You do not need sudo, a separate runtime installation or a source checkout. On first use, trust your project folder, configure a provider with `/providers`, and choose a model with `/model`.

### Continue in Desktop

Run `/desktop` in the TUI to continue the **same live session** in the native Desktop app. Existing Desktop windows keep their work. If Desktop is missing, the TUI directs you to download it. [Handoff instructions](docs/INSTALL.md#move-from-tui-to-desktop) include the one-time Linux setup.

## Optional: AESIR Term

[AESIR Term](docs/INSTALL.md#aesir-term) is our dedicated terminal app, with an AESIR TUI agent pane and conversation navigation. It launches the AESIR Red CLI. You can also use the TUI in your existing terminal.

## Updates and help

**Already using RC.3?** Download and replace Desktop, and rerun the TUI installer. If you use AESIR Term, replace it too: it was updated on 25 October. The corrected release keeps the same version number, so an automatic version check will not install these replacement files. See [updates and removal](docs/INSTALL.md#data-updates-and-removal).

- [Installation and first conversation](docs/INSTALL.md)
- [Features](docs/FEATURES.md)
- [Release notes and platform compatibility](docs/RELEASES.md)
- [Advanced setup](docs/ADVANCED.md) — custom installations, existing connections and headless use

This repository provides public downloads and guides; no private source checkout is needed. AESIR Red and its TUI are MIT-licensed. AESIR Term is GPL-3.0; bundled dependencies retain their own licenses and notices.
