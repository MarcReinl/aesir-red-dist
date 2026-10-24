# Install AESIR Red

Choose the graphical Desktop application or the TUI with a local Host. Run the TUI in your terminal emulator.

## Requirements

Desktop and the bundled Host require **macOS 15 or later**, on both Apple Silicon and Intel. Installing a different system Node.js does not lower that requirement: the application also includes native dependencies.

Linux release qualification targets **Ubuntu 24.04**, on ARM64 and x86-64. Other distributions need compatible system libraries and their own qualification. Manual archive extraction does not install system packages. Shell tools need `bash` on `PATH`; confined Linux shell operations also need a usable sandbox backend. AESIR tries bubblewrap first, then its bundled Landlock launcher. On Ubuntu, install the standard packages with:

```sh
sudo apt install bash bubblewrap
```

The kernel must permit the selected backend. If neither backend works, confined operations report `SANDBOX_UNAVAILABLE`. A TUI client attached to a Host on another machine follows its local Node.js requirements; the Host machine must meet the Host's requirements.

## Download and verify

Open [Releases](https://github.com/MarcReinl/aesir-red-dist/releases), select the desired release, and download your files plus its `SHA256SUMS`. Use files from the same release for a coordinated setup.

On macOS, **About This Mac** identifies an Apple chip or an Intel processor. On Linux, run `uname -m`: `aarch64` means ARM64; `x86_64` means Intel/AMD 64-bit. The runtime archives call the latter CPU `x64`.

Check one downloaded file on macOS:

```sh
shasum -a 256 aesir-red-0.2.0-rc.3-mac-arm64.dmg
```

On Linux:

```sh
sha256sum aesir-red-0.2.0-rc.3-linux-x86_64.AppImage
```

Replace the filename with your download and compare the complete hash with its line in `SHA256SUMS`. If you downloaded every listed file, `shasum -a 256 -c SHA256SUMS` on macOS or `sha256sum -c SHA256SUMS` on Linux checks the complete set. A mismatch means the file should be downloaded again before installation.

## AESIR Red Desktop

Desktop includes the application, its local Host, Node.js and supporting runtimes. You do not need a system Node.js, npm, Python or source checkout to start it. A model provider and the tools needed for your work are configured separately.

### macOS

Download `aesir-red-0.2.0-rc.3-mac-arm64.dmg` for Apple Silicon or `aesir-red-0.2.0-rc.3-mac-x64.dmg` for Intel. Open the DMG, drag **AESIR Red** to **Applications**, eject the disk image, and open the installed application.

These RC builds are not notarized by Apple. After verifying the download, use **System Settings → Privacy & Security → Open Anyway** if macOS blocks the first launch. Where the shortcut menu offers it, right-clicking the installed app and choosing **Open** also permits the first launch. The terminal alternative is:

```sh
xattr -dr com.apple.quarantine "/Applications/AESIR Red.app"
```

### Linux

Download the AppImage for your CPU, mark that file executable, and launch it:

```sh
chmod +x aesir-red-0.2.0-rc.3-linux-x86_64.AppImage
./aesir-red-0.2.0-rc.3-linux-x86_64.AppImage
```

Use the `linux-arm64` filename on ARM64. Keep the AppImage in a permanent directory if you create a launcher for it.

### Configure your model

Open **Settings → Models** to select or configure a provider, API key, model and reasoning effort. A local Ollama route needs a running Ollama service with a usable model. Cloud routes need the selected provider's credentials and network access. Opening the workspace does not establish that a model is available.

Choose a workspace directory, review the current permission mode, and start a conversation. Desktop does not require a DeepSeek account sign-in in its default configuration. Skills that invoke external tools need those tools available in the selected execution environment.

## AESIR Red TUI and Host

The TUI is a client of an AESIR Host. The portable `aesir-tui-0.2.0-rc.3.tgz` is shared by all four supported targets. It contains neither Node.js nor the Host. npm fetches its runtime dependencies during installation, so this step requires registry access.

The coordinated Host archives carry Node.js 24.21.0 and npm. They are named `aesir-0.2.0-rc.3-<target>.tar.gz`, where `<target>` is `darwin-arm64`, `darwin-x64`, `linux-arm64` or `linux-x64`. Create a directory and extract the archive into it, removing the archive's top directory. For example, on Apple Silicon:

```sh
mkdir -p "$HOME/.local/share/aesir/0.2.0-rc.3"
tar -xzf aesir-0.2.0-rc.3-darwin-arm64.tar.gz \
  -C "$HOME/.local/share/aesir/0.2.0-rc.3" --strip-components=1
```

Substitute your target's filename on Intel macOS or Linux. Keep the extracted directory intact.

Install the TUI with the archive's Node/npm, then select this Host once:

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

Replace the project path with your workspace. The client remembers the selected Host launcher; later runs can use `aesir-tui` or `aesir`. Add both bin directories to your shell startup file so new terminals can find the client and its Node runtime. Keep the Host's `bin/aesir` separate from the TUI's command with the same name. A separate system Node installation is unnecessary for this route.

### Existing Node/npm and Host

Install architecture-matched [Node.js with npm](https://nodejs.org/en/download). Use Node 22.19 or later in the 22.x line, or Node 24 or later supported by the chosen Host. Node 22.19 and 24 are the TUI's release qualification versions. Verify your tools:

```sh
node --version
npm --version
node -p 'process.platform + " " + process.arch'
```

Install the reviewed archive into a user-owned prefix:

```sh
npm install --global --prefix "$HOME/.local" --omit=dev --ignore-scripts ./aesir-tui-0.2.0-rc.3.tgz
export PATH="$HOME/.local/bin:$PATH"
aesir-tui --version
```

Add that `PATH` setting to your shell startup file to keep it across terminal sessions. `aesir` is an alias for the same client. Use `aesir-tui` to distinguish the client from a Host launcher also named `aesir`; if an executable already exists in that prefix, choose a separate prefix.

Select a compatible Host launcher in the startup chooser or explicitly:

```sh
aesir-tui --dsh /absolute/path/to/your/host-launcher --cwd /absolute/path/to/project
```

The launcher must support AESIR's `dsh --profile web` entry. A managed launch asks you to trust its workspace, starts the Host on an available loopback port, and normally shuts that Host down when the TUI exits. Installing Desktop does not add a `dsh` command to your shell; use the separate Host runtime for a managed TUI launch.

### Attach to an existing Host

Use the authenticated launch URL printed by a compatible `dsh --profile web --no-open` process:

```sh
AESIR_HOST_URL='http://127.0.0.1:3080/?token=YOUR_LAUNCH_TOKEN' aesir-tui
```

Use the actual port and token from that Host. Treat this URL as a credential. Attaching leaves the existing Host running when the TUI closes. The TUI's menus and file operations refer to that Host's machine and workspace; local clipboard and attachment selection refer to the machine running the TUI.

### First conversation and shortcuts

Use `/help` to discover commands, `/model` to select a model, `/providers` for provider setup, `/config` for settings, and `/permissions` to review permissions. Type `/` to filter commands and `@` to find Host workspace files. `/resume` opens previous conversations; `/exit` restores your shell.

`aesir-tui --danger` selects full access. `aesir-tui --auto` selects the Auto reviewer when the Host provides it. These modes do not install missing Host capabilities. Without an explicit mode flag, the Host default or resumed session's permissions apply.

Linux text operation needs a UTF-8 terminal. Clipboard image paste and code copying additionally need `wl-clipboard` on Wayland or `xclip` on X11. macOS uses its standard clipboard tools. Use **Ctrl+V** in the TUI to stage a clipboard image; the terminal's normal text-paste shortcut remains separate.

### Move from TUI to Desktop

With a compatible RC Desktop installed, `/desktop` opens the current conversation in a window attached to the same local Host. Send or remove staged attachments first. The TUI exits only after Desktop confirms that exact conversation is loaded; cancellation or failure leaves the TUI connected. A managed Host stays alive until its final attached Desktop window closes.

This handoff supports local macOS/Linux Hosts. Remote Hosts and reverse-proxy mounts are not supported. A separately opened Desktop application runs its own Host and does not automatically attach to the TUI. Use `AESIR_DESKTOP_PATH` for a nonstandard Desktop installation.

On Linux, handoff needs an unpacked Desktop directory so the TUI can read its capability file. Pointing `AESIR_DESKTOP_PATH` at the AppImage itself is insufficient. Extract it into a permanent directory, then select the inner executable:

```sh
./aesir-red-0.2.0-rc.3-linux-x86_64.AppImage --appimage-extract
AESIR_DESKTOP_PATH="$PWD/squashfs-root/aesir-red" aesir-tui
```

Use the ARM64 filename on ARM64. Keep `squashfs-root` intact and preserve the absolute path when launching from another directory. The selected release's evidence records whether Linux native handoff has been qualified.

## Data, updates and removal

| Component | Local data |
| --- | --- |
| Host release archive | `DSH_HOME`, defaulting to `~/.aesir/home` in the archive launcher |
| Desktop | `DSH_HOME`, normally `~/.dsh`; Desktop owns a separate runtime/plugin profile |
| TUI | `$XDG_CONFIG_HOME/aesir-red-tui/client.json`, normally `~/.config/aesir-red-tui/client.json`; client preferences and drafts |

TUI clients on the same running Host share its sessions, settings, credentials and plugins. The release archive and Desktop use different data directories by default. Setting the same `DSH_HOME` does not attach two Hosts to each other; their processes, runtime packages and plugin activation remain separate. `/desktop` preserves the running Host instead of copying a session between them.

For an RC upgrade, export important sessions and back up your Harness data first. Quit the component, verify the replacement download, and replace the Desktop app, AppImage or extracted Host directory. Reinstall a newer TUI archive with the same npm command; update your PATH and select its new Host path with `--dsh` when the runtime directory changes. Do not assume an older runtime can read data written by a newer release. Use the release assets for manual updates; these instructions do not depend on an automatic updater.

To remove Desktop, delete its macOS application or Linux AppImage. Uninstall the TUI with `npm uninstall --global --prefix "$HOME/.local/share/aesir-tui" @aesir-red/tui-client` before removing the Host that supplies Node/npm; use `"$HOME/.local"` instead if you chose the system-Node installation prefix. Remove the extracted Host directory when it is no longer running and remove its PATH entries from your shell startup file. Application removal leaves your Harness data and TUI preferences; remove those directories separately only if you intend to erase that data.
