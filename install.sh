#!/bin/sh
# AESIR Red installer for Linux and macOS.
#
#   curl -fsSL https://raw.githubusercontent.com/MarcReinl/aesir-red-dist/main/install.sh | sh
#
# Downloads a bundled-runtime archive — an official Node runtime plus the whole
# installed plugin closure — verifies its checksum, extracts it under
# ~/.aesir/versions/<version>, and links `aesir` onto PATH. Nothing is compiled
# and no package manager runs on this machine.
#
# The whole body sits inside main(), called on the last line, so a truncated
# download cannot execute a partial script.
set -eu

AESIR_VERSION="${AESIR_VERSION:-0.1.1-rc.2}"
AESIR_REPO="${AESIR_REPO:-MarcReinl/aesir-red-dist}"
AESIR_ROOT="${AESIR_ROOT:-$HOME/.aesir}"
# The lowest macOS the bundled Node runtime declares support for.
MACOS_FLOOR='13.5'
# node-pty's Linux prebuilds reference this glibc symbol version.
GLIBC_FLOOR='2.28'

die() {
  echo "aesir install: $1" >&2
  exit 1
}

note() {
  echo "  $1"
}

# Refuse a C library the archive was never built for, by name, rather than
# letting it fail later as a loader or symbol error.
detect_linux_libc() {
  musl_reason="musl libc (Alpine and similar) is not supported. The bundled Node runtime and the
  node-pty and node-addon-require-builtin addons are glibc builds, and no musl
  build is published. Use a glibc distribution, or run AESIR Red from source."

  # Ask which C library is actually in use, rather than whether a musl loader
  # exists on disk. A glibc machine with musl-tools installed for
  # cross-compilation carries /lib/ld-musl-*.so.1 and still runs glibc
  # binaries, so a file-presence probe refuses a perfectly supported system.
  if command -v ldd >/dev/null 2>&1; then
    if ldd --version 2>&1 | head -1 | grep -qi musl; then die "$musl_reason"; fi
  else
    # Without ldd, fall back to file presence: a musl system has no glibc
    # loader alongside it.
    for loader in /lib/ld-musl-*.so.1; do
      if [ -e "$loader" ] && ! ls /lib*/ld-linux*.so* >/dev/null 2>&1; then die "$musl_reason"; fi
    done
  fi

  # `ldd --version` opens with "ldd (Debian GLIBC 2.36-9+deb12u14) 2.36": the
  # bare release is the last field. The parenthesised distribution package
  # version is not comparable with sort -V.
  glibc=$(ldd --version 2>&1 | head -1 | awk '{ print $NF }')
  case "$glibc" in
    [0-9]*.[0-9]*) ;;
    *) glibc='' ;;
  esac
  if [ -n "$glibc" ] && [ "$(printf '%s\n%s\n' "$GLIBC_FLOOR" "$glibc" | sort -V | head -1)" != "$GLIBC_FLOOR" ]; then
    die "glibc $glibc is older than the required $GLIBC_FLOOR."
  fi
}

# Compare macOS versions with sort -V, never a numeric parse: the string is
# '26.6.2' today and '10.15.7' on legacy releases.
detect_macos_floor() {
  current=$(sw_vers -productVersion)
  if [ "$(printf '%s\n%s\n' "$MACOS_FLOOR" "$current" | sort -V | head -1)" != "$MACOS_FLOOR" ]; then
    die "macOS $current is older than the required $MACOS_FLOOR."
  fi
}

# Resolve the hardware architecture. On macOS this must not come from uname -m,
# which reports x86_64 inside a Rosetta shell; every x64 Mach-O in the closure
# is unsigned and dyld refuses it on Apple silicon.
detect_target() {
  case "$(uname -s)" in
    Linux)
      detect_linux_libc
      platform=linux
      case "$(uname -m)" in
        x86_64) arch=x64 ;;
        aarch64 | arm64) arch=arm64 ;;
        *) die "unsupported Linux architecture $(uname -m); only x86_64 and aarch64 are published." ;;
      esac
      ;;
    Darwin)
      detect_macos_floor
      platform=darwin
      if [ "$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)" = "1" ]; then arch=arm64; else arch=x64; fi
      ;;
    MINGW* | MSYS* | CYGWIN*)
      die "this installer is for Linux and macOS. On Windows, install WSL and re-run it inside
  your Linux distribution, or use install.ps1 for the experimental native build."
      ;;
    *)
      die "unsupported operating system $(uname -s)."
      ;;
  esac
}

# Verify the download before anything is extracted.
verify_checksum() {
  archive_path=$1
  sums_path=$2
  filename=$3
  expected=$(awk -v want="$filename" '$2 == want || $2 == "*" want { print $1 }' "$sums_path" | head -1)
  [ -n "$expected" ] || die "$filename is absent from SHA256SUMS."
  if command -v sha256sum >/dev/null 2>&1; then
    actual=$(sha256sum "$archive_path" | cut -d' ' -f1)
  elif command -v shasum >/dev/null 2>&1; then
    actual=$(shasum -a 256 "$archive_path" | cut -d' ' -f1)
  else
    die "neither sha256sum nor shasum is available; cannot verify the download."
  fi
  [ "$actual" = "$expected" ] || die "checksum mismatch for $filename (expected $expected, got $actual)."
}

# Link the launcher onto PATH, telling the user what to add when it is not
# already there. An unrecognized shell gets the line to paste rather than
# silence.
link_launcher() {
  destination=$1
  mkdir -p "$AESIR_ROOT/bin"
  ln -sfn "$destination/bin/aesir" "$AESIR_ROOT/bin/aesir"
  case ":$PATH:" in
    *":$AESIR_ROOT/bin:"*) return 0 ;;
  esac
  export_line="export PATH=\"$AESIR_ROOT/bin:\$PATH\""
  case "${SHELL:-}" in
    */zsh) rc="${ZDOTDIR:-$HOME}/.zshrc" ;;
    */bash) rc="$HOME/.bashrc" ;;
    *) rc='' ;;
  esac
  if [ -n "$rc" ]; then
    if [ ! -f "$rc" ] || ! grep -qF "$AESIR_ROOT/bin" "$rc"; then
      printf '\n# AESIR Red\n%s\n' "$export_line" >> "$rc"
      note "Added $AESIR_ROOT/bin to PATH in $rc — run: exec \$SHELL"
    fi
  else
    note "Add this to your shell profile:"
    note "  $export_line"
  fi
}

main() {
  detect_target
  filename="aesir-$AESIR_VERSION-$platform-$arch.tar.gz"
  base="https://github.com/$AESIR_REPO/releases/download/aesir-v$AESIR_VERSION"
  destination="$AESIR_ROOT/versions/$AESIR_VERSION"

  echo "aesir install: $filename"
  if [ "${AESIR_INSTALL_DRY_RUN:-}" = "1" ]; then
    echo "aesir install: dry run — would download $base/$filename into $destination"
    return 0
  fi

  command -v curl >/dev/null 2>&1 || die "curl is required."
  command -v tar >/dev/null 2>&1 || die "tar is required."

  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT INT TERM

  # A missing asset is the one failure a user is most likely to hit, so it
  # reports which platform is unavailable and what is published, rather than a
  # bare HTTP error.
  if ! curl -fsL "$base/$filename" -o "$tmp/$filename" 2>/dev/null; then
    published=$(curl -fsSL "$base/SHA256SUMS" 2>/dev/null | awk '{ sub(/^\*/, "", $2); print $2 }' \
      | sed -e "s/^aesir-$AESIR_VERSION-//" -e 's/\.tar\.gz$//' -e 's/\.zip$//' | paste -sd', ' -)
    die "no $platform-$arch archive in release aesir-v$AESIR_VERSION.
  Published for this release: ${published:-none}
  Set AESIR_VERSION to pick another release, or open an issue at
  https://github.com/$AESIR_REPO/issues to ask for this platform."
  fi
  curl -fsSL "$base/SHA256SUMS" -o "$tmp/SHA256SUMS" || die "could not download $base/SHA256SUMS"
  verify_checksum "$tmp/$filename" "$tmp/SHA256SUMS" "$filename"

  rm -rf "$destination"
  mkdir -p "$destination"
  # Mode bits are load-bearing: node, rg, spawn-helper and landlock-run must
  # stay executable, so --no-same-permissions must never be added here.
  tar -xzf "$tmp/$filename" -C "$destination" --strip-components=1
  [ "$platform" = "darwin" ] && xattr -dr com.apple.quarantine "$destination" 2>/dev/null || true

  link_launcher "$destination"

  echo ""
  echo "AESIR Red $AESIR_VERSION is installed. Start it with:  aesir"
  echo ""
  note "A model API key is required — the terminal opens a provider setup on first launch."
  note "Settings and sessions live in $AESIR_ROOT/home, separate from a source checkout's ~/.dsh."
  if [ "$platform" = "linux" ]; then
    note "Shell tools need a sandbox: install bubblewrap (apt install bubblewrap /"
    note "  dnf install bubblewrap) for the preferred rung. The bundled Landlock launcher"
    note "  is the automatic fallback on kernel 5.13+. Without either, tool calls are refused."
    note "'bash' must be on PATH for the shell tool to work."
  else
    note "On macOS below 15.0, 'aesir --profile headless' and 'aesir web' fail at boot."
    note "  The default 'aesir' terminal is unaffected."
  fi
}

main "$@"
