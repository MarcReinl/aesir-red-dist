# Releases and downloads

The [GitHub releases](https://github.com/MarcReinl/aesir-red-dist/releases) are the public download index. Select a release explicitly for an RC; GitHub's **Latest** label does not necessarily identify the newest prerelease.

## 0.2.0-rc.3

**Status: release candidate.** Download [0.2.0-rc.3](https://github.com/MarcReinl/aesir-red-dist/releases/tag/aesir-v0.2.0-rc.3) for the four platforms below. Its `release-manifest.json` identifies every artifact, component version, size and SHA-256; `BUILD-INFO.json` records source revisions and qualification results.

RC.3 adds the official TUI and AESIR Term alongside Desktop, with a standalone local Host runtime for terminal use. AESIR Term's agent pane and Conversations view use the AESIR TUI and Host. Desktop updates include visible sidebar browser automation, workspace/UI refinements, upstream integration work, expanded OSINT and pentest skills, the LLM Security preset, and native TUI session handoff. See [features and limits](FEATURES.md).

### Artifact names

| Platform | Desktop | Host runtime |
| --- | --- | --- |
| macOS Apple Silicon | `aesir-red-0.2.0-rc.3-mac-arm64.dmg` | `aesir-0.2.0-rc.3-darwin-arm64.tar.gz` |
| macOS Intel | `aesir-red-0.2.0-rc.3-mac-x64.dmg` | `aesir-0.2.0-rc.3-darwin-x64.tar.gz` |
| Linux ARM64 | `aesir-red-0.2.0-rc.3-linux-arm64.AppImage` | `aesir-0.2.0-rc.3-linux-arm64.tar.gz` |
| Linux x86-64 | `aesir-red-0.2.0-rc.3-linux-x86_64.AppImage` | `aesir-0.2.0-rc.3-linux-x64.tar.gz` |

The TUI uses one portable asset, `aesir-tui-0.2.0-rc.3.tgz`, on all four targets. Runtime dependencies are fetched by npm; Node.js and a compatible Host are prerequisites. The coordinated Host archive supplies Node/npm for this installation.

AESIR Term retains its own component version, **0.1.0**. Four targets use three binary assets:

| Platform | AESIR Term asset |
| --- | --- |
| macOS Apple Silicon and Intel | `AESIR-Term-0.1.0-macos.dmg` — universal application |
| Debian-family Linux ARM64 | `aesir-term_0.1.0_arm64.deb` |
| Debian-family Linux x86-64 | `aesir-term_0.1.0_amd64.deb` |

The Terminal build in this release is **0.1.0+af1b13eeee99**, with the AESIR TUI agent and Host Conversations integration. Use the assets and checksums attached to this release when replacing an earlier `0.1.0` build.

Terminal source delivery includes `aesir-term-0.1.0-source.tar.gz` for the customization, launchers and build scripts, and pinned `kitty-0.49.2.tar.xz` for the native terminal. `AESIR-Term-UPSTREAM-SOURCES.json` provides pinned source locations and hashes for bundled dependencies. `AESIR-Term-LICENSE.txt` and `AESIR-Term-NOTICES.md` accompany the GPL-3.0 Terminal; component notices also remain in the source archive and installed packages. GitHub's automatic distribution-repository source archives are neither installers nor the Terminal's corresponding source.

The release also supplies checksum and component attribution material. Use the files named in `SHA256SUMS`.

### Verification and compatibility

`SHA256SUMS` covers published component artifacts. [Installation](INSTALL.md#download-and-verify) shows checksum commands. A checksum establishes that the file matches the release's recorded bytes; it is separate from Apple signing/notarization or target execution tests.

The TUI passed its eight native package jobs: macOS ARM64, macOS Intel, Linux ARM64 and Linux x86-64 with Node 22.19 and 24. Installation using the actual macOS ARM Host archive's Node/npm and its session, settings, preset and permission APIs also passed without model requests. The package is a portable client rather than four standalone binaries. Optional Host capabilities and provider access require separate setup.

AESIR Term passed 310 source checks and 49 bundled-runtime checks per architecture. Its universal macOS build is signed ad hoc and is not notarized; Intel execution was checked through Rosetta. Linux package installation, bundled-runtime and virtual-display GUI checks passed in Debian 12 containers, with x86-64 emulated on ARM64. These checks do not establish native Intel GUI, physical GPU or Wayland behavior.

Desktop and Host packages have native build, startup and installation checks for each target. `BUILD-INFO.json` records the exact build and qualification revisions, handoff checks and remaining limits. The Desktop source snapshot includes the current product integrations; the qualification update corrects stale shared-editor assertions and the new pentest skill inventory without changing production code.

## Earlier releases

| Release | Summary |
| --- | --- |
| [0.2.0-rc.2](https://github.com/MarcReinl/aesir-red-dist/releases/tag/aesir-v0.2.0-rc.2) | Desktop release with an optional experimental decision layer, disabled by default; macOS ARM64/Intel and Linux ARM64/x86-64 assets |
| [0.2.0-rc.1](https://github.com/MarcReinl/aesir-red-dist/releases/tag/aesir-v0.2.0-rc.1) | Previous 0.2.0 release candidate |

Release tags identify the coordinated download set. Component versions and source revisions may differ; report both the release tag and exact asset filename when filing an issue. An older release's checksum file applies only to its own assets.
