#!/bin/sh
# AESIR Red installer for Linux and macOS.
#
#   curl -fsSL https://raw.githubusercontent.com/MarcReinl/aesir-red-dist/main/install.sh | sh
#
# Downloads a bundled-runtime archive — an official Node runtime plus the whole
# installed plugin closure — verifies its checksum, extracts it under
# ~/.aesir/versions/<version>, links `aesir` onto PATH, checks that the
# launcher starts, and makes sure the agent's sandbox has a working backend:
# on Linux that is bubblewrap or the bundled Landlock launcher, and when
# neither works bubblewrap is installed through the distribution's package
# manager. Nothing is compiled.
#
# Environment:
#   AESIR_VERSION                  release to install (default: the one below)
#   AESIR_ROOT                     install root (default: ~/.aesir)
#   AESIR_INSTALL_SYSTEM_PACKAGES  set to 0 to never run the package manager;
#                                  the installer then only reports what is missing
#
# The whole body sits inside main(), called on the last line, so a truncated
# download cannot execute a partial script.
set -eu

AESIR_VERSION="${AESIR_VERSION:-0.1.5-rc.3}"
AESIR_REPO="${AESIR_REPO:-MarcReinl/aesir-red-dist}"
AESIR_ROOT="${AESIR_ROOT:-$HOME/.aesir}"
AESIR_INSTALL_SYSTEM_PACKAGES="${AESIR_INSTALL_SYSTEM_PACKAGES:-1}"
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

warn() {
  echo "aesir install: WARNING — $1" >&2
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
  # The archive downloaded, so it exists in the release; a checksum document
  # that does not list it is stale rather than wrong. GitHub serves release
  # assets through a cache, and SHA256SUMS is rewritten whenever a platform is
  # added, so a reader can briefly see the previous revision.
  [ -n "$expected" ] || die "$filename downloaded, but SHA256SUMS does not list it yet.
  This usually means the checksum file is a cached earlier revision. Wait a
  minute and re-run this installer; nothing was installed."
  if command -v sha256sum >/dev/null 2>&1; then
    actual=$(sha256sum "$archive_path" | cut -d' ' -f1)
  elif command -v shasum >/dev/null 2>&1; then
    actual=$(shasum -a 256 "$archive_path" | cut -d' ' -f1)
  else
    die "neither sha256sum nor shasum is available; cannot verify the download."
  fi
  [ "$actual" = "$expected" ] || die "checksum mismatch for $filename (expected $expected, got $actual)."
}

# Append one PATH line to a startup file, unless that file already mentions the
# install. Records what changed in $configured.
#
# Every supported shell is configured rather than only the one $SHELL names:
# $SHELL is unset under cron, containers and some SSH invocations, and a user
# who installs from one shell routinely starts another.
add_path_line() {
  rc=$1
  line=$2
  if [ -f "$rc" ] && grep -qF "$AESIR_ROOT/bin" "$rc"; then
    return 0
  fi
  mkdir -p "$(dirname "$rc")" 2>/dev/null || true
  printf '\n# AESIR Red\n%s\n' "$line" >> "$rc" 2>/dev/null || return 0
  configured="$configured $rc"
}

# Link the launcher onto PATH for every shell present on the machine.
link_launcher() {
  destination=$1
  mkdir -p "$AESIR_ROOT/bin"
  ln -sfn "$destination/bin/aesir" "$AESIR_ROOT/bin/aesir"

  posix_line="export PATH=\"$AESIR_ROOT/bin:\$PATH\""
  configured=''

  # ~/.profile covers sh, dash and every POSIX login shell. It is written even
  # when no such shell is installed, because it costs nothing and is what a
  # future login shell reads.
  add_path_line "$HOME/.profile" "$posix_line"

  # zsh reads .zshrc for interactive shells; ZDOTDIR relocates the whole set.
  if [ -n "${ZDOTDIR:-}" ] || command -v zsh >/dev/null 2>&1 || [ -f "${ZDOTDIR:-$HOME}/.zshrc" ]; then
    add_path_line "${ZDOTDIR:-$HOME}/.zshrc" "$posix_line"
  fi

  # bash reads .bashrc when interactive and non-login (the Linux norm) but
  # .bash_profile when login (the macOS Terminal norm), so both are needed.
  if command -v bash >/dev/null 2>&1 || [ -f "$HOME/.bashrc" ]; then
    add_path_line "$HOME/.bashrc" "$posix_line"
    if [ -f "$HOME/.bash_profile" ]; then
      add_path_line "$HOME/.bash_profile" "$posix_line"
    fi
  fi

  # fish does not read POSIX exports and has its own PATH helper.
  if command -v fish >/dev/null 2>&1 || [ -d "$HOME/.config/fish" ]; then
    add_path_line "$HOME/.config/fish/config.fish" "fish_add_path \"$AESIR_ROOT/bin\""
  fi

  case ":$PATH:" in
    *":$AESIR_ROOT/bin:"*)
      # Already reachable in this shell, so no restart is needed.
      return 0
      ;;
  esac

  # A shell profile only takes effect in the NEXT shell: this installer is a
  # child process and cannot alter the PATH of the shell that invoked it. When
  # ~/.local/bin is already on PATH the user has opted into a personal bin
  # directory, so linking there as well makes `aesir` resolve straight away.
  local_bin="$HOME/.local/bin"
  case ":$PATH:" in
    *":$local_bin:"*)
      if mkdir -p "$local_bin" 2>/dev/null && ln -sfn "$destination/bin/aesir" "$local_bin/aesir" 2>/dev/null; then
        note "Linked $local_bin/aesir — available in this shell right now."
        return 0
      fi
      ;;
  esac

  if [ -n "$configured" ]; then
    note "Added $AESIR_ROOT/bin to PATH in:${configured}"
    note "That applies to new shells. For this one: export PATH=\"$AESIR_ROOT/bin:\$PATH\""
  else
    note "Could not write a shell profile. Add this line yourself:"
    note "  $posix_line"
  fi
}

# Whether a terminal is attached to answer a sudo prompt. The script's own
# stdin is the curl pipe, and sudo reads the password from the controlling
# terminal, not from stdin, so the pipe is not what decides.
have_tty() {
  ( exec </dev/tty ) 2>/dev/null
}

# Run one command as root: directly when already root, through sudo otherwise.
# Fails without running anything when sudo is absent or would need a password
# no terminal can answer.
run_as_root() {
  if [ "$(id -u)" = "0" ]; then "$@"; return; fi
  command -v sudo >/dev/null 2>&1 || return 127
  if sudo -n true 2>/dev/null; then sudo "$@"; return; fi
  have_tty || return 126
  note "sudo needs your password to install system packages."
  sudo "$@"
}

# Install packages with whichever package manager the distribution has. The
# package names are the same across every manager listed. musl distributions
# were already refused, so apk is deliberately absent. The manager's own
# output goes to a log that is shown only when it fails; sudo's password
# prompt goes to the terminal and is unaffected.
install_packages() {
  [ "$AESIR_INSTALL_SYSTEM_PACKAGES" != "0" ] || return 1
  log="$tmp/packages.log"
  if command -v apt-get >/dev/null 2>&1; then
    run_as_root apt-get update -qq >"$log" 2>&1 || true
    run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@" >"$log" 2>&1
  elif command -v dnf >/dev/null 2>&1; then
    run_as_root dnf install -y -q "$@" >"$log" 2>&1
  elif command -v yum >/dev/null 2>&1; then
    run_as_root yum install -y -q "$@" >"$log" 2>&1
  elif command -v zypper >/dev/null 2>&1; then
    run_as_root zypper --non-interactive --quiet install "$@" >"$log" 2>&1
  elif command -v pacman >/dev/null 2>&1; then
    run_as_root pacman -Sy --noconfirm --needed --quiet "$@" >"$log" 2>&1
  elif command -v xbps-install >/dev/null 2>&1; then
    run_as_root xbps-install -Sy "$@" >"$log" 2>&1
  else
    return 1
  fi || { cat "$log" >&2; return 1; }
}

# Bound a probe so a hung backend cannot hang the installer; coreutils'
# timeout is absent on macOS, where the probes have no way to hang.
bounded() {
  if command -v timeout >/dev/null 2>&1; then timeout 10 "$@"; else "$@"; fi
}

# The terminal's own bubblewrap probe: the read-only profile it confines shell
# tools with, run around `true`. A distribution that ships bwrap but forbids
# unprivileged user namespaces fails here exactly as it would at first use.
bwrap_usable() {
  command -v bwrap >/dev/null 2>&1 || return 1
  bounded bwrap --ro-bind / / --dev /dev --unshare-pid --proc /proc --die-with-parent -- true >/dev/null 2>&1
}

# The terminal's own Landlock probe: the archive's launcher enforces a ruleset
# on itself and exits 0 only when the running kernel honours it.
landlock_usable() {
  launcher="$1/node_modules/@aesir-red/node-addon-system-linux-$arch/bin/landlock-run"
  [ -x "$launcher" ] || return 1
  bounded "$launcher" --probe >/dev/null 2>&1
}

# Leave Linux with a working sandbox. The terminal refuses every shell and
# filesystem tool call without one, so this is part of installing, not advice
# for later. Sets $sandbox to the backend in use, or empty when none works.
ensure_linux_sandbox() {
  destination=$1
  sandbox=''
  if bwrap_usable; then sandbox='bubblewrap'; return 0; fi
  if landlock_usable "$destination"; then sandbox='Landlock (bundled launcher, this kernel enforces it)'; return 0; fi
  if [ "$AESIR_INSTALL_SYSTEM_PACKAGES" = "0" ]; then
    warn "no usable sandbox backend, and AESIR_INSTALL_SYSTEM_PACKAGES=0 forbids installing bubblewrap."
    return 0
  fi
  echo "aesir install: no usable sandbox backend on this kernel; installing bubblewrap."
  if install_packages bubblewrap; then
    if bwrap_usable; then sandbox='bubblewrap (installed now)'; return 0; fi
    warn "bubblewrap installed but cannot create a sandbox here (unprivileged user
  namespaces may be disabled on this host)."
  else
    warn "could not install bubblewrap. Install it yourself, then start aesir:
    Debian/Ubuntu: sudo apt-get install bubblewrap
    Fedora/RHEL:   sudo dnf install bubblewrap
    openSUSE:      sudo zypper install bubblewrap
    Arch:          sudo pacman -S bubblewrap"
  fi
}

# bash is what the shell tool runs commands in.
ensure_bash() {
  command -v bash >/dev/null 2>&1 && return 0
  echo "aesir install: bash is not installed; installing it for the shell tool."
  if ! install_packages bash || ! command -v bash >/dev/null 2>&1; then
    warn "bash is missing and could not be installed; the shell tool needs it on PATH."
  fi
}

# macOS confines shell tools with the Seatbelt sandbox that ships with the
# system; the same read-only profile the terminal uses is tried here so a
# management policy that disables sandbox-exec is reported now, not at first use.
ensure_macos_sandbox() {
  sandbox=''
  if bounded /usr/bin/sandbox-exec -p '(version 1) (allow default) (deny file-write*)' -- /usr/bin/true >/dev/null 2>&1; then
    sandbox='Seatbelt (built into macOS)'
  else
    warn "sandbox-exec is unavailable on this Mac, so shell and filesystem tool calls will be refused."
  fi
}

# Start the installed launcher once. This runs the bundled Node against the
# archive and answers before any plugin loads, so it proves the runtime and
# the launcher without needing a model or a workspace.
verify_launcher() {
  if ! installed_version=$("$1/bin/aesir" --version 2>&1); then
    die "the installed launcher failed to start:
  $installed_version
  Nothing else was changed; re-run this installer after fixing the cause."
  fi
  [ "$installed_version" = "$AESIR_VERSION" ] || die "the launcher reported '$installed_version', expected $AESIR_VERSION."
}

# Restore the previous version if the final rename fails or installation is interrupted.
cleanup_install() {
  if [ -n "$pending" ] && [ -d "$pending/previous" ] && [ ! -e "$destination" ]; then
    if ! mv "$pending/previous" "$destination"; then
      warn "could not restore the previous version; it remains at $pending/previous."
      rm -rf "$tmp"
      return
    fi
  fi
  if [ -n "$pending" ]; then rm -rf "$pending"; fi
  rm -rf "$tmp"
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
  pending=''
  trap 'cleanup_install' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM

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

  mkdir -p "$AESIR_ROOT/versions"
  pending=$(mktemp -d "$AESIR_ROOT/versions/.install-XXXXXX")
  mkdir "$pending/payload"
  # Preserve executable modes and validate the replacement before moving the installed version.
  tar -xzf "$tmp/$filename" -C "$pending/payload" --strip-components=1
  if [ "$platform" = "darwin" ]; then xattr -dr com.apple.quarantine "$pending/payload" 2>/dev/null || true; fi

  verify_launcher "$pending/payload"
  if [ -e "$destination" ]; then mv "$destination" "$pending/previous"; fi
  mv "$pending/payload" "$destination"
  link_launcher "$destination"

  if [ "$platform" = "linux" ]; then
    ensure_bash
    ensure_linux_sandbox "$destination"
  else
    ensure_macos_sandbox
  fi

  echo ""
  echo "AESIR Red $AESIR_VERSION is installed. Start it with:  aesir"
  echo ""
  note "A model API key is required — the terminal opens a provider setup on first launch."
  note "Settings and sessions default to $HOME/.aesir/home; DSH_HOME overrides that location."
  if [ -n "$sandbox" ]; then
    note "Shell and filesystem tools run sandboxed with: $sandbox."
  else
    note "Shell and filesystem tools are REFUSED until a sandbox backend works (see the warning above)."
  fi
  if [ "$platform" = "darwin" ]; then
    note "Some native addons require macOS 15.0; older macOS versions need compatibility testing."
  fi
}

main "$@"
