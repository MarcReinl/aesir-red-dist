# AESIR Red — desktop app

Desktop builds of [AESIR Red](https://aesir.red), a plugin-based AI agent harness for
authorized security testing.

Download the build for your machine from the
[latest release](https://github.com/MarcReinl/aesir-red-dist/releases/latest). Each app
carries its own Node runtime and agent, so nothing is installed alongside it and nothing
is compiled.

| Platform | File |
| --- | --- |
| macOS (Apple Silicon) | `aesir-red-<version>-mac-arm64.dmg` |
| Linux x86-64 | `aesir-red-<version>-linux-x86_64.AppImage` |
| Linux arm64 | `aesir-red-<version>-linux-arm64.AppImage` |

## macOS

Open the DMG and drag **AESIR Red** to Applications.

These builds are not signed with an Apple Developer certificate, so the first launch needs
one extra step: **right-click the app and choose Open**, then confirm. Double-clicking it
the usual way shows "cannot be opened because it is from an unidentified developer" with no
way through. You only do this once.

From a terminal, clearing the quarantine attribute does the same thing:

```sh
xattr -d com.apple.quarantine "/Applications/AESIR Red.app"
```

## Linux

The AppImage needs no installation and no FUSE.

```sh
chmod +x aesir-red-*-linux-*.AppImage
./aesir-red-*-linux-*.AppImage
```

Pick `x86_64` for an Intel or AMD machine and `arm64` for an ARM one; `uname -m` reports
which you have.

## Verify a download

Each release publishes `SHA256SUMS-desktop`. Download it next to the app and check:

```sh
sha256sum --ignore-missing -c SHA256SUMS-desktop
```

On macOS, `shasum -a 256 -c SHA256SUMS-desktop --ignore-missing`.

## Windows

There is no Windows desktop build yet. Windows users can run the terminal release through
WSL, where the Linux path above works unchanged.

## Reporting a problem

Open an issue at [MarcReinl/aesir-red-dist](https://github.com/MarcReinl/aesir-red-dist/issues).
Include the version from the release you downloaded and your platform. The desktop and
terminal artifacts in a release can be built from different revisions, so say which one you
ran.
