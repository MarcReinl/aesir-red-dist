# Releases and downloads

The [GitHub releases](https://github.com/MarcReinl/aesir-red-dist/releases) are the public download index. Select a release explicitly for an RC; GitHub's **Latest** label does not necessarily identify the newest prerelease.

## 0.2.0-rc.3

**Updated RC.3 downloads.** [0.2.0-rc.3](https://github.com/MarcReinl/aesir-red-dist/releases/tag/aesir-v0.2.0-rc.3) replaces the earlier downloads with corrected Desktop and standalone TUI packages, including their engine dependencies. AESIR Term is included with its corrected AESIR Red CLI launcher.

RC.3 brings the official standalone TUI alongside Desktop. Both install the engine they need automatically; Desktop is optional for the TUI. Desktop updates include visible sidebar browser automation, workspace/UI refinements, upstream integration work, expanded OSINT and pentest skills, the LLM Security preset, and native TUI session handoff. See [features and limits](FEATURES.md).

### Choose an installation

Use the [Desktop downloads](INSTALL.md#aesir-red-desktop) or the [one-command TUI installer](INSTALL.md#install-tui). [AESIR Term](INSTALL.md#aesir-term) is an optional dedicated terminal app. Manual engine archives are for [advanced setup](ADVANCED.md#manual-runtime-and-tui-installation); the TUI installer selects and installs the correct one automatically.

AESIR Term component version is **0.1.0**, build **0.1.0+af1b13eeee99**. Its universal macOS DMG supports Apple Silicon and Intel; Linux supplies ARM64 and x86-64 DEBs. The release includes Terminal's GPL-3.0 license, notices, source catalogue, customization source archive and pinned kitty source archive.

`release-manifest.json` identifies all download files, source revisions, sizes and SHA-256 hashes. `BUILD-INFO.json` records build and test evidence. GitHub's automatic source archives contain this distribution repository, rather than application installers or Terminal's corresponding source.

### Verification and compatibility

`SHA256SUMS` covers published component artifacts. [Installation](INSTALL.md#download-and-verify) shows checksum commands. A checksum establishes that the file matches the release's recorded bytes; it is separate from Apple signing/notarization or target execution tests.

The replacement retains version `0.2.0-rc.3` and the existing download filenames. Existing RC.3 users must manually replace Desktop and rerun the TUI installer; automatic version checks do not install an equal-version replacement. Follow [refresh instructions](INSTALL.md#data-updates-and-removal), downloading fresh files and `SHA256SUMS` together. An unchanged version string alone does not identify replacement bytes; use the artifact hash and recorded source revision.

All four replacement Desktop/Host build records passed using these local environments:

| Target | Build execution | Build environment |
| --- | --- | --- |
| macOS ARM64 | Native ARM64 CPU | macOS 26.6.2 |
| macOS x64 | Rosetta translation on ARM64 | macOS 26.6.2; x64 producer Node |
| Linux ARM64 | Native ARM64 CPU in a Linux VM/container | Debian 12; macOS ARM64 physical host |
| Linux x64 | Rosetta emulation on ARM64 | Debian 12; macOS ARM64 physical host |

The replacement TUI passed one clean Node 24 package build and eight local verification jobs against the identical portable archive: each of the four targets with Node 22.19.0 and 24.21.0. Four ARM64 jobs ran without CPU translation, two macOS x64 jobs used Rosetta translation and two Linux x64 jobs used Rosetta emulation on ARM64.

Packaged GUI checks passed on all four targets using native ARM64 or Rosetta execution as described above. They covered cold/warm exact-session transfer, shared attachment leases, continued conversation and orderly final-window Host shutdown. macOS x64 GUI checks ran under Rosetta on ARM64, so physical Intel hardware remains unqualified. Linux GUI tests used Ubuntu 24.04 and virtual X11, separately from the Debian 12 build environment; physical GPU and Wayland behavior remain unqualified. Linux x64 coverage used the unchanged inner Electron application extracted with `unsquashfs` under Rosetta; its AppImage launcher and native x64 hardware GUI remain unqualified. These GUI checks used a deterministic local model provider and made no paid requests. `BUILD-INFO.json` records the exact artifacts, execution modes, evidence hashes and remaining limits.

AESIR Term's unchanged fixed build passed 310 source checks and 49 packaged-runtime checks per architecture. Its macOS universal binaries were checked natively on ARM64 and under Rosetta for Intel. Linux DEBs were installed and tested on Debian 12 with virtual X11; ARM64 was native and x86-64 used QEMU. Native Intel/Linux x86-64 GUI hardware, physical Linux GPUs and Wayland were not tested. Terminal alone requires macOS 12 or later, or a compatible glibc 2.35+/GCC 11 Linux graphical system; its TUI integration follows the TUI's requirements.


## Earlier releases

| Release | Summary |
| --- | --- |
| [0.2.0-rc.2](https://github.com/MarcReinl/aesir-red-dist/releases/tag/aesir-v0.2.0-rc.2) | Desktop release with an optional experimental decision layer, disabled by default; macOS ARM64/Intel and Linux ARM64/x86-64 assets |
| [0.2.0-rc.1](https://github.com/MarcReinl/aesir-red-dist/releases/tag/aesir-v0.2.0-rc.1) | Previous 0.2.0 release candidate |

Release tags identify the coordinated download set. Component versions and source revisions may differ; report both the release tag and exact asset filename when filing an issue. An older release's checksum file applies only to its own assets.
