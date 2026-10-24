# Releases and downloads

The [GitHub releases](https://github.com/MarcReinl/aesir-red-dist/releases) are the public download index. Select a release explicitly for an RC; GitHub's **Latest** label does not necessarily identify the newest prerelease.

## 0.2.0-rc.3

**Updated RC.3 downloads.** [0.2.0-rc.3](https://github.com/MarcReinl/aesir-red-dist/releases/tag/aesir-v0.2.0-rc.3) replaces the earlier downloads with coordinated Desktop, standalone TUI and Host runtime fixes. AESIR Term is deferred and excluded from this release.

RC.3 brings the official standalone TUI alongside Desktop, with a private local Host runtime for terminal use. Desktop updates include visible sidebar browser automation, workspace/UI refinements, upstream integration work, expanded OSINT and pentest skills, the LLM Security preset, and native TUI session handoff. See [features and limits](FEATURES.md).

### Artifact names

| Platform | Desktop | Host runtime |
| --- | --- | --- |
| macOS Apple Silicon | `aesir-red-0.2.0-rc.3-mac-arm64.dmg` | `aesir-0.2.0-rc.3-darwin-arm64.tar.gz` |
| macOS Intel | `aesir-red-0.2.0-rc.3-mac-x64.dmg` | `aesir-0.2.0-rc.3-darwin-x64.tar.gz` |
| Linux ARM64 | `aesir-red-0.2.0-rc.3-linux-arm64.AppImage` | `aesir-0.2.0-rc.3-linux-arm64.tar.gz` |
| Linux x86-64 | `aesir-red-0.2.0-rc.3-linux-x86_64.AppImage` | `aesir-0.2.0-rc.3-linux-x64.tar.gz` |

macOS also supplies a ZIP for each CPU architecture. The TUI uses one portable asset, `aesir-tui-0.2.0-rc.3.tgz`, on all four targets. The curl installer supplies the client and matching Node/Host runtime. Manual client-only installation needs compatible Node/npm and a Host connection.

`release-manifest.json` identifies each component artifact, source revision, size and SHA-256. `BUILD-INFO.json` records build revisions, checks and qualification limits. Use the matching files named in `SHA256SUMS`.

### Verification and compatibility

`SHA256SUMS` covers published component artifacts. [Installation](INSTALL.md#download-and-verify) shows checksum commands. A checksum establishes that the file matches the release's recorded bytes; it is separate from Apple signing/notarization or target execution tests.

The replacement retains version `0.2.0-rc.3` and the artifact names above. Existing RC.3 users must manually replace Desktop and rerun the TUI installer; automatic version checks do not install an equal-version replacement. Follow [refresh instructions](INSTALL.md#data-updates-and-removal), downloading fresh files and `SHA256SUMS` together. An unchanged version string alone does not identify replacement bytes; use the artifact hash and recorded source revision.

All four replacement Desktop/Host build records passed using these local environments:

| Target | Build execution | Build environment |
| --- | --- | --- |
| macOS ARM64 | Native ARM64 CPU | macOS 26.6.2 |
| macOS x64 | Rosetta translation on ARM64 | macOS 26.6.2; x64 producer Node |
| Linux ARM64 | Native ARM64 CPU in a Linux VM/container | Debian 12; macOS ARM64 physical host |
| Linux x64 | Rosetta emulation on ARM64 | Debian 12; macOS ARM64 physical host |

The replacement TUI passed one clean Node 24 package build and eight local verification jobs against the identical portable archive: each of the four targets with Node 22.19.0 and 24.21.0. Four ARM64 jobs ran without CPU translation, two macOS x64 jobs used Rosetta translation and two Linux x64 jobs used Rosetta emulation on ARM64.

Packaged GUI checks passed on all four targets using native ARM64 or Rosetta execution as described above. They covered cold/warm exact-session transfer, shared attachment leases, continued conversation and orderly final-window Host shutdown. macOS x64 GUI checks ran under Rosetta on ARM64, so physical Intel hardware remains unqualified. Linux GUI tests used Ubuntu 24.04 and virtual X11, separately from the Debian 12 build environment; physical GPU and Wayland behavior remain unqualified. Linux x64 coverage used the unchanged inner Electron application extracted with `unsquashfs` under Rosetta; its AppImage launcher and native x64 hardware GUI remain unqualified. These GUI checks used a deterministic local model provider and made no paid requests. `BUILD-INFO.json` records the exact artifacts, execution modes, evidence hashes and remaining limits.

The original RC.3 assets had their own build and client checks. Those historical results do not qualify the replacement bytes.

## Earlier releases

| Release | Summary |
| --- | --- |
| [0.2.0-rc.2](https://github.com/MarcReinl/aesir-red-dist/releases/tag/aesir-v0.2.0-rc.2) | Desktop release with an optional experimental decision layer, disabled by default; macOS ARM64/Intel and Linux ARM64/x86-64 assets |
| [0.2.0-rc.1](https://github.com/MarcReinl/aesir-red-dist/releases/tag/aesir-v0.2.0-rc.1) | Previous 0.2.0 release candidate |

Release tags identify the coordinated download set. Component versions and source revisions may differ; report both the release tag and exact asset filename when filing an issue. An older release's checksum file applies only to its own assets.
