# Install AESIR Red

Choose the graphical Desktop application or install the TUI with its private local Host. Run the TUI in AESIR Term or another terminal emulator. AESIR Term's agent pane uses the separately installed TUI.

## Requirements

Desktop and the bundled Host require **macOS 15 or later**, on both Apple Silicon and Intel. Installing a different system Node.js does not lower that requirement: the application also includes native dependencies.

Linux release qualification targets **Ubuntu 24.04**, on ARM64 and x86-64. Other distributions need compatible system libraries and their own qualification. The TUI installer and manual archive extraction do not install system packages. Shell tools need `bash` on `PATH`; confined Linux shell operations also need a usable sandbox backend. AESIR tries bubblewrap first, then its bundled Landlock launcher. On Ubuntu, install the standard packages with:

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

### Recommended: curl installer

```sh
curl -fsSL https://raw.githubusercontent.com/MarcReinl/aesir-red-dist/main/install-tui.sh | sh
```

The installer detects macOS/Linux and ARM64/x64, downloads the coordinated `0.2.0-rc.3` TUI and matching private Host/Node runtime, and checks the official release assets against `SHA256SUMS`. It installs production TUI dependencies from the npm registry with lifecycle scripts disabled. Internet access to GitHub and the registry is required; sudo, a system Node/npm, a compiler and a source checkout are unnecessary. Installation starts no Host and makes no model request.

Packages are installed under `${XDG_DATA_HOME:-$HOME/.local/share}/aesir-cli`. Its `bin` directory exposes `aesir` and `aesir-tui`; existing commands elsewhere are preserved. The installer adds this directory to bash/zsh PATH once and names the updated startup files. Close and reopen the shell, reload the named profile, or run the printed PATH command, then start the client:

```sh
aesir --cwd /absolute/path/to/project
```

The client preserves your preferences and honors an explicit connection, `AESIR_HOST_URL`, or a saved connection before falling back to its private Host. A managed launch asks you to trust the workspace and normally stops its Host when the client exits. Installing does not connect to or discover an already running Desktop automatically.

Pass installer options after `sh -s --`:

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

`--client-only` downloads no Host and needs an existing compatible Host connection or launcher. It retains the client's normal connection chooser. Its local Node requirement is independent of the macOS 15 requirement for the bundled Host. You can combine the options above. Unknown shells receive explicit PATH instructions instead of a startup-file edit.

Rerun the same curl command to update, retaining any custom prefix or client-only option. Installation is staged and checked before changing the active version; earlier versions remain installed. Session data, credentials, model settings and TUI preferences are preserved. A failed download, checksum check or dependency installation leaves the active installation unchanged.

### Alternative: install release archives manually

The TUI is a client of an AESIR Host. The portable `aesir-tui-0.2.0-rc.3.tgz` is shared by all four supported targets. It contains neither Node.js nor the Host. npm fetches its runtime dependencies during installation, so this step requires registry access. Download and verify the archives as described above.

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

### Alternative: existing Node/npm and Host

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

This explicit URL route also works with the curl installation. It does not automatically find a Desktop Host or select a conversation in Desktop's ordinary main window.

### First conversation and shortcuts

Use `/help` to discover commands, `/model` to select a model, `/providers` for provider setup, `/config` for settings, and `/permissions` to review permissions. Type `/` to filter commands and `@` to find Host workspace files. `/resume` opens previous conversations; `/exit` restores your shell.

`aesir-tui --danger` selects full access. `aesir-tui --auto` selects the Auto reviewer when the Host provides it. These modes do not install missing Host capabilities. Without an explicit mode flag, the Host default or resumed session's permissions apply.

Linux text operation needs a UTF-8 terminal. Clipboard image paste and code copying additionally need `wl-clipboard` on Wayland or `xclip` on X11. macOS uses its standard clipboard tools. Use **Ctrl+V** in the TUI to stage a clipboard image; the terminal's normal text-paste shortcut remains separate.

### Move from TUI to Desktop

With a compatible RC Desktop installed, `/desktop` opens the current conversation in a window attached to the same local Host. Send or remove staged attachments first. The TUI exits only after Desktop confirms that exact conversation is loaded; cancellation or failure leaves the TUI connected. A managed Host stays alive until its final attached Desktop window closes.

This handoff supports local macOS/Linux Hosts. Remote Hosts and reverse-proxy mounts are not supported. The handoff window has restricted native capabilities; full native browser operations need the same conversation selected in Desktop's ordinary main window. A separately opened Desktop application runs its own Host and does not automatically attach to the TUI. Use `AESIR_DESKTOP_PATH` for a nonstandard Desktop installation; on macOS it names the `.app` root.

On Linux, handoff needs an unpacked Desktop directory so the TUI can read its capability file. Pointing `AESIR_DESKTOP_PATH` at the AppImage itself is insufficient. Extract it into a permanent directory, then select the inner executable:

```sh
./aesir-red-0.2.0-rc.3-linux-x86_64.AppImage --appimage-extract
AESIR_DESKTOP_PATH="$PWD/squashfs-root/aesir-red" aesir-tui
```

Use the ARM64 filename on ARM64. Keep `squashfs-root` intact and preserve the absolute path when launching from another directory. The selected release's evidence records whether Linux native handoff has been qualified.

## AESIR Term

AESIR Term bundles kitty, its Python packages, ripgrep, micro and zsh syntax highlighting. For its agent pane and Conversations view, use the TUI curl installer above: it supplies both the client and private Host, with no extra manual Host download. Alternatively, configure the TUI with an existing compatible Host. Ordinary terminal use needs neither a Host nor a model provider.

### macOS

AESIR Term alone requires macOS 12 or later. Running the coordinated local Host/TUI setup requires macOS 15 or later. `AESIR-Term-0.1.0-macos.dmg` is universal for Apple Silicon and Intel. Open it and drag **AESIR Term** into **Applications**.

The build is signed ad hoc and is not notarized. After verifying the checksum, permit the first launch through macOS Privacy & Security, or run:

```sh
xattr -dr com.apple.quarantine "/Applications/AESIR Term.app"
```

### Debian-family Linux

Requires glibc 2.35 or later, libstdc++ from GCC 11 or later (`GLIBCXX_3.4.29`), and a graphical X11/Wayland session with OpenGL. Install the matching package with apt:

```sh
sudo apt install ./aesir-term_0.1.0_amd64.deb
```

Use `arm64.deb` on ARM64. Apt resolves the declared system libraries; zsh is needed for shell extras. To replace an earlier build with the same `0.1.0` package version, use `sudo apt install --reinstall ./aesir-term_0.1.0_amd64.deb`. The final release's qualification notes identify the tested distributions. The bundled Host has its own requirements; do not infer full Host compatibility from Terminal package installation.

### Agent pane and conversations

Open the TUI once, select its Host launcher or connection, and configure the model. Ensure `aesir-tui` and its Node runtime are accessible on the Terminal application's `PATH`. In `extras/settings.toml`, `[agent] command` defaults to `["aesir-tui"]`; if the app cannot find your installation, set explicit interpreter and client-script paths, for example `["/absolute/path/to/node", "/absolute/path/to/tui/dist/cli.js"]`.

Use **Cmd+I** on macOS or **Ctrl+Alt+I** on Linux to open the agent pane. The terminal passes the active shell's directory to the TUI, and workspace trust remains interactive. **Conversations** in Tools lists AESIR Host sessions; select one to resume it in the agent pane. Listing reads the catalog without creating a conversation or making a model request.

The launcher recognizes the previous stock OpenCode command and runs the AESIR TUI instead. Explicit custom commands remain configurable; this does not import OpenCode conversation history. Configure the agent's models, credentials and permissions in the TUI/Host.

### Terminal tools and optional explain/fix

Use **Cmd+P** on macOS or **Ctrl+Alt+P** on Linux for the command palette. **Cmd+B** / **Ctrl+Alt+B** opens Tools for projects, search, notebooks and conversations. Split with **Cmd+D** / **Ctrl+Shift+D**. Shell extras work in zsh without editing your `.zshrc`.

Explain/fix uses Terminal's own `[assistant]` settings, separately from the TUI's model setup. Its default cloud route needs [Ollama](https://ollama.com/download) and sign-in; you can instead configure an available local model or a DeepSeek API key. The overlay shows the destination before sending command/output context and inserts a suggestion into the prompt for review. Configure this feature only if you want it.

## Data, updates and removal

| Component | Local data |
| --- | --- |
| Curl installer packages | `${XDG_DATA_HOME:-$HOME/.local/share}/aesir-cli`, or your explicit `--prefix`; versioned packages and command aliases |
| Host release archive | `DSH_HOME`, defaulting to `~/.aesir/home` in the archive launcher |
| Desktop | `DSH_HOME`, normally `~/.dsh`; Desktop owns a separate runtime/plugin profile |
| TUI | `$XDG_CONFIG_HOME/aesir-red-tui/client.json`, normally `~/.config/aesir-red-tui/client.json`; client preferences and drafts |
| AESIR Term, macOS | `~/Library/Application Support/AESIR Term` |
| AESIR Term, Linux | `~/.config/aesir-term` |

TUI clients on the same running Host share its sessions, settings, credentials and plugins. The release archive and Desktop use different data directories by default. Setting the same `DSH_HOME` does not attach two Hosts to each other; their processes, runtime packages and plugin activation remain separate. `/desktop` preserves the running Host instead of copying a session between them.

AESIR Term's settings and notebooks remain separate from Harness data. Its agent pane uses the TUI's configured Host; opening an unrelated Desktop instance does not attach it to that Host.

For a curl-installed TUI, rerun the installer with the same prefix and desired version; it checks and activates the staged installation while retaining previous versions. Quit the client before deliberately removing an installed version. For a manual RC upgrade, export important sessions and back up your Harness data first. Quit the component, verify the replacement download, and replace the Desktop app, AppImage or extracted Host directory. Reinstall a newer TUI archive with the same npm command; update your PATH and select its new Host path with `--dsh` when the runtime directory changes. Do not assume an older runtime can read data written by a newer release. These routes do not depend on an automatic updater.

AESIR Term preserves `kitty.conf`, `extras-theme.conf` and `extras/settings.toml` across updates. Other supplied files are refreshed; edited versions are saved beside them as `NAME.edited-DATE`.

To remove a curl installation, close its TUI and any Desktop windows attached to its private Host, then delete the installation prefix: normally `~/.local/share/aesir-cli`, or the directory you selected with XDG_DATA_HOME or `--prefix`. Remove its PATH line from your shell startup file if needed. Deleting this package prefix leaves `DSH_HOME` and TUI preferences intact.

To remove Desktop, delete its macOS application or Linux AppImage. For a manually installed TUI, run `npm uninstall --global --prefix "$HOME/.local/share/aesir-tui" @aesir-red/tui-client` before removing the Host that supplies Node/npm; use `"$HOME/.local"` instead if you chose the system-Node installation prefix. Remove the extracted Host directory when it is no longer running and remove its PATH entries from your shell startup file. Delete the macOS AESIR Term application or run `sudo apt remove aesir-term` on Linux. Application removal leaves your Harness data, TUI preferences, Terminal settings and notebooks; remove those directories separately only if you intend to erase that data.
