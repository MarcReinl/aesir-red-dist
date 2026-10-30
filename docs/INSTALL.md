# Install AESIR Red

Choose **Desktop** for a graphical app or **TUI** for your terminal. Both include the engine they need; there is no separate engine installation. The TUI works without Desktop.

Supports macOS 15 or later and Linux, on ARM64 and x86-64. Linux checks used Ubuntu 24.04; see [platform compatibility](RELEASES.md#verification-and-compatibility) for tested environments and limits. Installation needs internet access. Model credentials or a local model service are configured after installation.

<a id="aesir-red-desktop"></a>

## Install Desktop

### macOS

1. Download the [Apple Silicon DMG](https://github.com/MarcReinl/aesir-red-dist/releases/download/aesir-v0.2.0-rc.3/aesir-red-0.2.0-rc.3-mac-arm64.dmg) or [Intel DMG](https://github.com/MarcReinl/aesir-red-dist/releases/download/aesir-v0.2.0-rc.3/aesir-red-0.2.0-rc.3-mac-x64.dmg). **About This Mac** identifies your chip.
2. Open the DMG, drag **AESIR Red** to **Applications**, and open the installed app.
3. Choose your project folder and configure a model in **Settings → Models**.

These release-candidate builds are not notarized by Apple. If macOS blocks the first launch, [verify your download](#download-and-verify), then use **System Settings → Privacy & Security → Open Anyway**. [Advanced setup](ADVANCED.md#macos-first-launch) includes the terminal alternative.

### Linux

Download the [x86-64 AppImage](https://github.com/MarcReinl/aesir-red-dist/releases/download/aesir-v0.2.0-rc.3/aesir-red-0.2.0-rc.3-linux-x86_64.AppImage) or [ARM64 AppImage](https://github.com/MarcReinl/aesir-red-dist/releases/download/aesir-v0.2.0-rc.3/aesir-red-0.2.0-rc.3-linux-arm64.AppImage). `uname -m` reports `x86_64` or `aarch64`, respectively.

For x86-64, run:

```sh
chmod +x aesir-red-0.2.0-rc.3-linux-x86_64.AppImage
./aesir-red-0.2.0-rc.3-linux-x86_64.AppImage
```

Use the `linux-arm64` filename on ARM64. Choose a project folder, configure a model in **Settings → Models**, and start a conversation.

<a id="aesir-red-tui-and-host"></a>

## Install TUI

Run this in your macOS or Linux terminal:

```sh
curl -fsSL https://raw.githubusercontent.com/MarcReinl/aesir-red-dist/main/install-tui.sh | sh
```

The installer selects your computer's version and installs the TUI with its engine and Node.js automatically. You do not need Desktop, sudo, system Node/npm, a compiler or a source checkout. It checks the release downloads before activating the installation and starts no agent session during installation.

Close and reopen your terminal, then run this from your project folder:

```sh
aesir
```

If the command is not found, use the PATH command printed by the installer. The `aesir-tui` command opens the same application.

### Start your first conversation

Trust your project folder when prompted. Use `/providers` to configure your provider, `/model` to choose a model and reasoning effort, and `/permissions` to review access. Enter your task to start the conversation.

Use `/help` for commands, `/resume` for previous conversations and `/exit` to return to your shell. Model services and credentials are your choice; they are not included with the application.

Custom installation folders, client-only installation, existing engine connections and manual archives are covered in [advanced setup](ADVANCED.md).

## Move from TUI to Desktop

Run `/desktop` in the TUI to open the **same live conversation** in a native Desktop workspace window. Existing Desktop windows keep their work. Send or remove staged attachments first. Allow up to 90 seconds for a cold Desktop launch.

The TUI restores your shell and exits only after Desktop has opened that conversation. Cancelling or a failed transfer leaves the TUI usable. The conversation keeps running after your terminal closes and stops its private engine when the final attached Desktop window closes.

If Desktop is missing or needs an update, choose **Download AESIR Desktop** or **Update AESIR Desktop**. The TUI opens this installation guide and keeps your conversation, draft and attachments. Install the matching Desktop release, then run `/desktop` again.

<details>
<summary>Linux: one-time Desktop setup for /desktop</summary>

The TUI needs the extracted Desktop executable. Keep it in a permanent directory, then run:

```sh
./aesir-red-0.2.0-rc.3-linux-x86_64.AppImage --appimage-extract
AESIR_DESKTOP_PATH="$PWD/squashfs-root/aesir-red" aesir
```

Use the ARM64 filename on ARM64. Keep `squashfs-root` intact and use the executable's absolute path when starting from another folder. [Advanced handoff details](ADVANCED.md#desktop-handoff-technical-details) cover nonstandard application locations and supported connections.

</details>

## AESIR Term

AESIR Term is an optional dedicated terminal app. Its agent pane launches the AESIR Red TUI; the standalone TUI installer above supplies that CLI and its engine. Ordinary terminal use does not need the TUI or a model provider.

### macOS

Download the [AESIR Term DMG](https://github.com/MarcReinl/aesir-red-dist/releases/download/aesir-v0.2.0-rc.3/AESIR-Term-0.1.0-macos.dmg), open it, and drag **AESIR Term** to **Applications**. One DMG supports Apple Silicon and Intel. Terminal alone needs macOS 12 or later; using its AESIR TUI integration needs macOS 15 or later.

The app is signed ad hoc and is not notarized by Apple. Verify the download, then use **Privacy & Security → Open Anyway** if needed.

### Debian, Ubuntu and Kali Linux

Download the [x86-64 DEB](https://github.com/MarcReinl/aesir-red-dist/releases/download/aesir-v0.2.0-rc.3/aesir-term_0.1.0_amd64.deb) or [ARM64 DEB](https://github.com/MarcReinl/aesir-red-dist/releases/download/aesir-v0.2.0-rc.3/aesir-term_0.1.0_arm64.deb). For x86-64, install and start it with:

```sh
sudo apt install --reinstall ./aesir-term_0.1.0_amd64.deb
aesir-term
```

Use the `arm64` filename on ARM64. Apt installs the declared system dependencies. A graphical X11 or Wayland session with OpenGL is required; Debian 12 installation and virtual X11 were tested. See [release compatibility](RELEASES.md#verification-and-compatibility) for the other limits.

### Open the agent pane

Install the TUI using the curl command above, then open AESIR Term with `aesir-tui` available on its PATH. Press **Cmd+I** on macOS or **Ctrl+Alt+I** on Linux to open the agent pane in your current project. The Conversations view lets you resume an AESIR conversation. Configure its model in the TUI as described above.

## Download and verify

The TUI installer verifies its release downloads automatically. For manually downloaded Desktop or Terminal files, get a fresh `SHA256SUMS` from [RC.3](https://github.com/MarcReinl/aesir-red-dist/releases/tag/aesir-v0.2.0-rc.3).

For example, on macOS:

```sh
shasum -a 256 aesir-red-0.2.0-rc.3-mac-arm64.dmg
```

On Linux:

```sh
sha256sum aesir-red-0.2.0-rc.3-linux-x86_64.AppImage
```

Replace the filename with your download and compare the complete hash with its line in `SHA256SUMS`. Download the file again if they differ. GitHub's automatic **Source code** ZIP/tarball contains this distribution repository; it is not an installer.

## Data, updates and removal

**Update TUI:** rerun the same curl command. Your sessions, settings and TUI preferences are preserved. A failed installation leaves the active version unchanged.

**Update Desktop:** quit the app, download and verify the replacement, then replace your installed app or AppImage.

**Existing RC.3 users:** the Desktop refresh keeps version `0.2.0-rc.3`. Manually replace Desktop; automatic version checks do not install an equal-version replacement. Download fresh files and `SHA256SUMS` together. Rerun the TUI installer only if you have not installed its corrected RC.3 package. To replace an earlier AESIR Term `0.1.0`, replace the macOS app or use the Linux `--reinstall` command above.

**Remove an app:** quit it and delete its Desktop/Terminal application or AppImage; Linux Terminal packages can be removed with `sudo apt remove aesir-term`. To remove the curl-installed TUI, close it and its attached Desktop windows, delete `~/.local/share/aesir-cli` (or your custom installation folder), and remove its PATH entry from your shell startup file. Removing application files leaves conversation data and preferences intact. [Advanced data locations](ADVANCED.md#data-updates-and-manual-removal) cover custom installations and deliberate data removal.
