# Advanced setup and runtime configuration

For normal installation, choose [Desktop](INSTALL.md#aesir-red-desktop) or the standalone TUI from the [main setup guide](../README.md). Desktop includes its dependencies, and the standard TUI curl installer supplies its private engine and Node.js automatically. The options below are for custom installations, existing connections and direct runtime use.

## macOS first launch

These RC builds are not notarized by Apple. After [verifying the download](INSTALL.md#download-and-verify), use **System Settings → Privacy & Security → Open Anyway** if macOS blocks the first launch. Where the shortcut menu offers it, right-clicking the installed app and choosing **Open** also permits the first launch. The terminal alternative for Desktop is:

```sh
xattr -dr com.apple.quarantine "/Applications/AESIR Red.app"
```

## Custom TUI installer options

The standard installer uses `${XDG_DATA_HOME:-$HOME/.local/share}/aesir-cli`. Its `bin` directory exposes `aesir` and `aesir-tui`, and existing commands elsewhere are preserved. It adds this directory to bash/zsh PATH once and names the updated startup files. Unknown shells receive explicit PATH instructions.

Pass options after `sh -s --`:

```sh
# Choose an absolute installation prefix.
curl -fsSL https://raw.githubusercontent.com/MarcReinl/aesir-red-dist/main/install-tui.sh | sh -s -- --prefix "$HOME/Applications/aesir-cli"

# Select a coordinated release version explicitly.
curl -fsSL https://raw.githubusercontent.com/MarcReinl/aesir-red-dist/main/install-tui.sh | sh -s -- --version 0.2.0-rc.3

# Keep shell startup files unchanged; add the printed PATH yourself.
curl -fsSL https://raw.githubusercontent.com/MarcReinl/aesir-red-dist/main/install-tui.sh | sh -s -- --no-modify-path

# Install only the client using your existing Node >=22.19 and npm.
curl -fsSL https://raw.githubusercontent.com/MarcReinl/aesir-red-dist/main/install-tui.sh | sh -s -- --client-only
```

`--client-only` downloads no engine and needs an existing compatible Host connection or launcher. It retains the client's connection chooser. Its local Node requirement is independent of the macOS 15 requirement for the bundled engine. The options can be combined.

Rerun the same command to update, retaining your custom prefix or client-only option. Installation is staged and checked before changing the active version; earlier versions remain installed. Session data, credentials, model settings and TUI preferences are preserved. A failed download, checksum check or dependency installation leaves the active installation unchanged.

## Manual runtime and TUI installation

The Host is the engine behind the clients. Downloading it separately is an advanced alternative to the standard installer. Download the matching archive, portable `aesir-tui-0.2.0-rc.3.tgz` and fresh `SHA256SUMS` from the [RC.3 release](https://github.com/MarcReinl/aesir-red-dist/releases/tag/aesir-v0.2.0-rc.3), then verify the downloads as described in the [installation guide](INSTALL.md).

| OS and CPU | Engine archive |
| --- | --- |
| macOS Apple Silicon | `aesir-0.2.0-rc.3-darwin-arm64.tar.gz` |
| macOS Intel | `aesir-0.2.0-rc.3-darwin-x64.tar.gz` |
| Linux ARM64 / aarch64 | `aesir-0.2.0-rc.3-linux-arm64.tar.gz` |
| Linux x86-64 / amd64 | `aesir-0.2.0-rc.3-linux-x64.tar.gz` |

These archives include Node.js 24.21.0 and npm. The portable TUI archive is shared by all four targets and contains neither Node nor the engine. npm fetches its production dependencies from the registry during installation, with lifecycle scripts disabled.

Create a directory and extract the engine archive, removing its top directory. For example, on Apple Silicon:

```sh
mkdir -p "$HOME/.local/share/aesir/0.2.0-rc.3"
tar -xzf aesir-0.2.0-rc.3-darwin-arm64.tar.gz \
  -C "$HOME/.local/share/aesir/0.2.0-rc.3" --strip-components=1
```

Substitute your target's filename on Intel macOS or Linux. Keep the extracted directory intact. Install the TUI with the archive's Node/npm, then select this launcher once:

```sh
aesir_runtime="$HOME/.local/share/aesir/0.2.0-rc.3"
aesir_tui_prefix="$HOME/.local/share/aesir-tui"
export PATH="$aesir_runtime/node/bin:$aesir_tui_prefix/bin:$PATH"
"$aesir_runtime/node/bin/node" \
  "$aesir_runtime/node/lib/node_modules/npm/bin/npm-cli.js" \
  install --global --prefix "$aesir_tui_prefix" --omit=dev --ignore-scripts \
  ./aesir-tui-0.2.0-rc.3.tgz
aesir-tui --dsh "$aesir_runtime/bin/aesir" --cwd /absolute/path/to/project
```

Replace the project path with your workspace. The client remembers the launcher; later runs can use `aesir-tui` or `aesir`. Add both bin directories to your shell startup file so new terminals can find the client and Node. Keep the engine's `bin/aesir` separate from the TUI command with the same name. This route needs no separate system Node installation.

## Existing Node/npm and engine

For a client-only installation, use architecture-matched [Node.js with npm](https://nodejs.org/en/download). Supported choices are Node 22.19 or later in the 22.x line, or Node 24 or later supported by the chosen Host. The replacement's local package checks used Node 22.19.0 and 24.21.0. Verify your tools:

```sh
node --version
npm --version
node -p 'process.platform + " " + process.arch'
```

Install the verified archive into a user-owned prefix:

```sh
npm install --global --prefix "$HOME/.local" --omit=dev --ignore-scripts ./aesir-tui-0.2.0-rc.3.tgz
export PATH="$HOME/.local/bin:$PATH"
aesir-tui --version
```

Keep that PATH setting in your shell startup file. Both aliases start the same client; `aesir-tui` distinguishes it from an engine launcher also named `aesir`. Choose a separate prefix if an executable already exists there.

Select a compatible launcher in the startup chooser or explicitly:

```sh
aesir-tui --dsh /absolute/path/to/your/host-launcher --cwd /absolute/path/to/project
```

The launcher must support AESIR's `dsh --profile web` entry. A managed launch asks you to trust the workspace, starts the Host on an available loopback port, and normally stops it when the TUI exits. Installing Desktop does not add a `dsh` command to the shell.

## Existing connections and direct profiles

An explicit connection, `AESIR_HOST_URL`, or a saved connection takes precedence over the curl installation's private engine. The TUI does not discover a running Desktop Host automatically.

Use the authenticated launch URL printed by a compatible `dsh --profile web --no-open` process:

```sh
AESIR_HOST_URL='http://127.0.0.1:3080/?token=YOUR_LAUNCH_TOKEN' aesir-tui
```

Use that Host's actual port and token, and treat the URL as a credential. Attaching leaves an existing Host running when the TUI closes. Menus and file operations refer to the Host's machine and workspace; local clipboard and attachment selection refer to the machine running the TUI. This explicit URL route also works with the standard curl installation and does not select a conversation in Desktop's ordinary main window.

For direct runtime use, the launcher supports named profiles. `--profile web --no-open` serves the Web/TUI APIs without opening a browser; `--profile headless "task"` runs a fresh persisted session, prints the final answer and exits. These advanced launches use their profile's model settings and credentials. The invoking directory is the default workspace.

## Desktop handoff: technical details

Follow [Move from TUI to Desktop](INSTALL.md#move-from-tui-to-desktop) for the normal workflow. Handoff retains the exact live root or child session on the same local Host. The client exits after authenticated readiness and a committed attachment lease; its supervisor retains a managed Host until the last attached window finishes closing and releases its lease.

The attached workspace provides native window chrome, its own folder picker and local file-path references. When the source Host enables Browser, manual tabs use native guests isolated to that window. Shortcuts use Web defaults and DOM delivery; their window-local preferences are discarded on closure. Account, updater and ordinary Host management remain ordinary-window operations, along with saved native shortcuts, menu bindings and Browser-guest accelerators.

Model-facing browser tools depend on the source Host's configured providers. Installing Desktop does not add an Electron-backed browser provider to a TUI-managed Web Host. A separately opened Desktop application runs its own Host and does not automatically attach to the TUI.

Handoff supports local macOS/Linux Hosts. Remote Hosts, reverse-proxy mounts and Windows are unsupported. For a nonstandard installation, `AESIR_DESKTOP_PATH` names the `.app` root on macOS. On Linux, the TUI needs an unpacked Desktop directory to read its capability file; the AppImage path alone is insufficient. Extract it into a permanent directory and select the inner executable:

```sh
./aesir-red-0.2.0-rc.3-linux-x86_64.AppImage --appimage-extract
AESIR_DESKTOP_PATH="$PWD/squashfs-root/aesir-red" aesir-tui
```

Use the ARM64 filename on ARM64. Keep `squashfs-root` intact and preserve the absolute path when launching from another directory. See [Desktop installation](INSTALL.md#aesir-red-desktop) for the standard application setup and [qualification coverage](RELEASES.md#verification-and-compatibility) for execution limits.

## Linux shell sandbox

Shell tools need `bash` on PATH. Confined Linux operations also need a usable sandbox backend: AESIR tries bubblewrap first, then its bundled Landlock launcher. On Debian or Ubuntu, install the standard packages with:

```sh
sudo apt install bash bubblewrap
```

The kernel must permit the selected backend. If neither backend works, confined operations report `SANDBOX_UNAVAILABLE`. A TUI attached to another machine follows its local Node requirements; the remote machine must meet the Host requirements.

## Data, updates and manual removal

| Component | Local data |
| --- | --- |
| Curl-installed packages | `${XDG_DATA_HOME:-$HOME/.local/share}/aesir-cli`, or your `--prefix`; versioned packages and aliases |
| Extracted engine launcher | `DSH_HOME`, defaulting to `~/.aesir/home` |
| Desktop | `DSH_HOME`, normally `~/.dsh`; a separate runtime/plugin profile |
| TUI preferences and drafts | `$XDG_CONFIG_HOME/aesir-red-tui/client.json`, normally `~/.config/aesir-red-tui/client.json` |

Clients on the same running Host share its sessions, settings, credentials and plugins. The release archive and Desktop use different data directories by default. Setting the same `DSH_HOME` does not attach two Hosts to each other; their processes, runtime packages and plugin activation remain separate. `/desktop` retains the running Host instead of copying a session between them.

For a manual upgrade, export important sessions and back up your Harness data first. Quit the component, verify the new download, and replace the extracted runtime directory. Reinstall the TUI archive with the same npm command, update PATH and use `--dsh` again if the launcher path changes. An older runtime is not guaranteed to read data written by a newer release.

RC.3 replacements retain the same version and filenames. Manually replace a separately extracted runtime or reinstall the TUI only when its artifact hash changes; automatic version checks do not install an equal-version replacement. The 30 October Desktop refresh leaves Host and TUI archives unchanged. Download fresh payloads and `SHA256SUMS` together. `release-manifest.json` records the exact hashes and source revisions; `BUILD-INFO.json` records the checks for each artifact set. See [release notes](RELEASES.md).

For a curl installation, rerun the installer with the same prefix and desired version. Close the TUI and any Desktop windows attached to its private engine before removing that prefix or an older installed version. Removing the package prefix leaves `DSH_HOME` and TUI preferences intact; remove its PATH entry separately if needed.

For a manually installed TUI, run `npm uninstall --global --prefix "$HOME/.local/share/aesir-tui" @aesir-red/tui-client` before removing the runtime that supplies Node/npm; use `"$HOME/.local"` for the system-Node prefix shown above. Remove the extracted runtime directory when it is no longer running, then remove its PATH entries. Removing application packages leaves Harness data and TUI preferences; erase those directories separately only if you intend to delete the data.
