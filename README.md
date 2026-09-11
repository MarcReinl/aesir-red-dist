# AESIR Red — install

Installers and release archives for [AESIR Red](https://aesir.red), a plugin-based AI agent
harness for authorized security testing.

## Linux and macOS

```sh
curl -fsSL https://raw.githubusercontent.com/MarcReinl/aesir-red-dist/main/install.sh | sh
```

Open a new shell, then run `aesir`.

## Windows (experimental)

```powershell
irm https://raw.githubusercontent.com/MarcReinl/aesir-red-dist/main/install.ps1 | iex
```

Windows has not been verified by continuous integration. Prefer WSL, where the Linux
installer above works unchanged.

## What the installer does

It downloads a bundled-runtime archive for your platform, verifies it against `SHA256SUMS`,
extracts it to `~/.aesir/versions/<version>`, and links `aesir` onto your PATH. The archive
carries its own Node runtime, so nothing is compiled and no package manager runs.

Published targets: `linux-x64`, `linux-arm64`, `darwin-arm64`, `darwin-x64`, `win32-x64`.

Alpine and other musl-based distributions are not supported — the bundled runtime and its
native addons are glibc builds. macOS 13.5 is the minimum.

## First launch

A model API key is required. `aesir` opens provider setup on first launch when no credential
is configured; anything you typed stays in the composer while you configure a model.

Settings, credentials and sessions live in `~/.aesir/home`.

## Verifying a download by hand

```sh
curl -fsSLO https://github.com/MarcReinl/aesir-red-dist/releases/download/aesir-v<version>/SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing
```

## Uninstall

Remove `~/.aesir` and the `aesir` entry from your shell profile. That directory also holds
`home`, so move `~/.aesir/home` aside first if you want to keep your sessions and settings.

## Source

The source repository is separate. Issues and discussion belong there.

MIT licensed; each archive ships `LICENSE` and `THIRD_PARTY_NOTICES.md`.
