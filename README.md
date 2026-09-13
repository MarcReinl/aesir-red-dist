# AESIR Red — install

Installers and release archives for [AESIR Red](https://aesir.red), a plugin-based AI agent
harness for authorized security testing.

## Linux and macOS

```sh
curl -fsSL https://raw.githubusercontent.com/MarcReinl/aesir-red-dist/main/install.sh | sh
```

Open a new shell, then run `aesir`. For the browser UI, run `aesir --ui`; it opens in your
default browser and shares the terminal's settings, credentials and sessions.

## Windows (experimental)

```powershell
irm https://raw.githubusercontent.com/MarcReinl/aesir-red-dist/main/install.ps1 | iex
```

Windows has not been verified by continuous integration. Prefer WSL, where the Linux
installer above works unchanged.

## What the installer does

It downloads a bundled-runtime archive for your platform, verifies it against `SHA256SUMS`,
extracts it to `~/.aesir/versions/<version>`, links `aesir` onto your PATH, starts the launcher
once to prove the runtime works, and makes sure the agent's sandbox has a working backend. The
archive carries its own Node runtime, so nothing is compiled.

Published targets: `linux-x64`, `linux-arm64`, `darwin-arm64`, `darwin-x64`, `win32-x64`.

## System packages

The agent's shell and filesystem tools only run inside a sandbox, so the installer ends with one
in place:

- **Linux** probes bubblewrap and the archive's Landlock launcher exactly as the terminal does.
  When neither works, it installs `bubblewrap` with your distribution's package manager
  (`apt-get`, `dnf`, `yum`, `zypper`, `pacman` or `xbps-install`), asking for your sudo password
  on the terminal if one is needed. `bash` is installed the same way if it is missing.
- **macOS** uses the Seatbelt sandbox built into the system; nothing is installed.
- **Windows** uses a write-restricted token built into the archive; nothing is installed for the
  sandbox. PowerShell 7 is installed with `winget` when it is missing, because the shell tool runs
  commands through it and Windows PowerShell 5.1 garbles non-ASCII output.

Set `AESIR_INSTALL_SYSTEM_PACKAGES=0` to forbid every package install. The installer then reports
what is missing and the command that installs it, and the terminal refuses shell and filesystem
tool calls until a sandbox backend works.

Alpine and other musl-based distributions are not supported — the bundled runtime and its
native addons are glibc builds. macOS 13.5 is the minimum.

## First launch

A model API key is required. `aesir` opens provider setup on first launch when no credential
is configured; anything you typed stays in the composer while you configure a model. Configure
the model in the terminal once, and `aesir --ui` starts already configured.

Settings, credentials and sessions live in `~/.aesir/home`.

## Verifying a download by hand

```sh
curl -fsSLO https://github.com/MarcReinl/aesir-red-dist/releases/download/aesir-v<version>/SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing
```

## After installing

The installer puts `~/.aesir/bin` on PATH in `~/.profile` and in the startup file of every
shell you have (`.zshrc`, `.bashrc`, `.bash_profile`, fish's `config.fish`). Those apply to
the **next** shell — an installer runs as a child process and cannot change the PATH of the
shell that launched it.

If `~/.local/bin` is already on your PATH, the installer also links `aesir` there, so it
works in the current shell immediately. Otherwise, open a new terminal or run the `export`
line the installer prints.

## Uninstall

Remove `~/.aesir`, the `aesir` entry from your shell profiles, and `~/.local/bin/aesir` if
it was linked. `~/.aesir` also holds `home`, so move `~/.aesir/home` aside first if you want
to keep your sessions and settings.

## Source

The source repository is separate. Issues and discussion belong there.

MIT licensed; each archive ships `LICENSE` and `THIRD_PARTY_NOTICES.md`.
