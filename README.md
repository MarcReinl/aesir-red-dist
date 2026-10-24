# AESIR Red

Public downloads and installation guides for [AESIR Red](https://aesir.red), a plugin-based AI agent harness for authorized security work.

Download the updated [**0.2.0-rc.3**](https://github.com/MarcReinl/aesir-red-dist/releases/tag/aesir-v0.2.0-rc.3) for the graphical application, official terminal client and local Host runtime. This release candidate replaces the earlier RC.3 downloads; existing users should follow the [refresh instructions](docs/INSTALL.md#data-updates-and-removal). AESIR Term is deferred and excluded from this release.

## Choose your setup

| Component | What it does | What to install |
| --- | --- | --- |
| **AESIR Red Desktop** | Graphical conversations, workspaces, tools, files and visible browser automation | A macOS DMG or Linux AppImage; its Host and runtimes are bundled |
| **AESIR Red TUI** | Full-screen terminal client for the AESIR Host | The curl installer below supplies the client and a private Node/Host runtime |
| **AESIR Host runtime** | Runs the local agent and serves its Web/TUI APIs | The archive matching your OS and CPU |

Desktop is the shortest route to the graphical application. For a standalone terminal workflow, install the TUI below and run it in your terminal emulator. Desktop is optional.

## Install the TUI

On macOS or Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/MarcReinl/aesir-red-dist/main/install-tui.sh | sh
```

The installer selects the matching `0.2.0-rc.3` client and private Node/Host runtime for your OS and CPU. It needs no sudo, system Node/npm or source checkout, and installation starts no Host. Close and reopen your shell, or run the PATH command printed by the installer, then run:

```sh
aesir
```

It installs `aesir` and `aesir-tui` under `${XDG_DATA_HOME:-$HOME/.local/share}/aesir-cli/bin` and adds that directory to bash/zsh PATH once. Existing explicit, environment and saved Host connections keep precedence; otherwise the client uses its private Host and asks you to trust the workspace. A running Desktop is not discovered automatically.

[Installation options, manual alternatives, updates and removal](docs/INSTALL.md#aesir-red-tui-and-host) cover custom prefixes and client-only installation with an existing Node/npm and Host connection. Rerun the curl command to update; your sessions and TUI preferences are preserved.

## Platforms

| Platform | Desktop | Host runtime | TUI |
| --- | --- | --- | --- |
| macOS Apple Silicon | `mac-arm64.dmg` | `darwin-arm64.tar.gz` | Same portable `.tgz` |
| macOS Intel | `mac-x64.dmg` | `darwin-x64.tar.gz` | Same portable `.tgz` |
| Linux ARM64 / aarch64 | `linux-arm64.AppImage` | `linux-arm64.tar.gz` | Same portable `.tgz` |
| Linux x86-64 / amd64 | `linux-x86_64.AppImage` | `linux-x64.tar.gz` | Same portable `.tgz` |

Desktop and the bundled Host require **macOS 15 or later** on Apple Silicon and Intel. Replacement qualification uses local macOS builders and Debian 12 Linux containers, with native ARM64 execution and translated x64 execution. Check [installation requirements](docs/INSTALL.md) and [qualification coverage](docs/RELEASES.md#verification-and-compatibility) for your system.

- [Install, configure, update and uninstall](docs/INSTALL.md)
- [Features and current limitations](docs/FEATURES.md)
- [Release history, artifact names and verification](docs/RELEASES.md)

Download binaries from a release's **Assets** section. GitHub's automatic **Source code** ZIP/tarball contains this distribution repository and is not an application installer. Verify downloads against that release's `SHA256SUMS` before installing. An RC may be marked as a prerelease, so GitHub's **Latest** label can still point to an older release.

## Repository and licenses

This repository hosts public distribution documentation and release assets. The AESIR Red and TUI development repositories are private; building either from private source is not required for the published installation routes.

AESIR Red and its TUI are MIT-licensed. Bundled dependencies retain their own licenses; consult each component's license and notices.

Report problems through [this repository's issues](https://github.com/MarcReinl/aesir-red-dist/issues). Include the release tag, component, operating system, CPU architecture, exact asset filename and the error. Remove API keys and tokenized Host URLs from reports.
