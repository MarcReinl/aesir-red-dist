#!/bin/sh
# Install reviewed public release assets without starting an AESIR Host.
main() (
  set -eu
  umask 077
  version=0.2.0-rc.3
  prefix=${XDG_DATA_HOME:-${HOME:?HOME is required}/.local/share}/aesir-cli
  client_only=0
  modify_path=1
  stage=
  locked=0

  fail() { printf 'AESIR installer: %s\n' "$*" >&2; exit 1; }
  # shellcheck disable=SC2329 # Invoked by the exit trap.
  cleanup() {
    result=$?
    trap - 0
    if [ -n "$stage" ]; then rm -rf "$stage"; fi
    if [ "$locked" = 1 ]; then rmdir "$prefix/.install.lock" 2>/dev/null || :; fi
    exit "$result"
  }
  download() {
    curl -q --proto '=https' --proto-redir '=https' --tlsv1.2 \
      --fail --show-error --location --retry 3 --retry-delay 1 \
      --connect-timeout 20 --max-time 900 --output "$2" "$release_url/$1" \
      || fail "Could not download release asset $1."
  }
  verify() {
    expected=$(awk -v file="$1" '
      $2 == file { count++; if (NF != 2 || length($1) != 64 || $1 ~ /[^0-9a-fA-F]/) bad=1; hash=tolower($1) }
      END { if (count != 1 || bad) exit 1; print hash }
    ' "$stage/SHA256SUMS") || fail "Missing, duplicate or invalid SHA-256 entry for $1."
    if command -v sha256sum >/dev/null 2>&1; then
      actual=$(sha256sum "$stage/$1" | awk '{print $1}')
    else
      actual=$(shasum -a 256 "$stage/$1" | awk '{print $1}')
    fi
    [ "$actual" = "$expected" ] || fail "SHA-256 checksum mismatch for $1."
  }

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --version|--prefix)
        option=$1
        [ "$#" -ge 2 ] && [ -n "$2" ] || fail "$option requires a value."
        case "$2" in --*) fail "$option requires a value.";; esac
        if [ "$option" = --version ]; then version=$2; else prefix=$2; fi
        shift 2 ;;
      --client-only) client_only=1; shift ;;
      --no-modify-path) modify_path=0; shift ;;
      --help|-h)
        cat <<'HELP'
Usage: install-tui.sh [options]
  --version VERSION          Coordinated release (default: 0.2.0-rc.3)
  --prefix ABSOLUTE_DIRECTORY Install directory (default: $XDG_DATA_HOME/aesir-cli
                             or $HOME/.local/share/aesir-cli)
  --client-only              Use existing Node 22.19+ and npm; download no Host
  --no-modify-path           Leave shell profiles unchanged
  --help                     Show this help

Installs aesir and aesir-tui into PREFIX/bin without sudo. Full installation
includes a private Node/Host runtime. Dependencies require npm registry access.
No Host or model starts during installation. Existing connection settings stay
unchanged. This installer does not discover or reuse Desktop's Host automatically.
Full runtime: macOS 15+; Linux qualified on Ubuntu 24.04. ARM64 and x64 only.
HELP
        exit 0 ;;
      *) fail "Unknown option $1. Use --help." ;;
    esac
  done
  case "$version" in ''|*[!0-9A-Za-z.+-]*|[!0-9]*) fail "Invalid release version.";; esac
  case "$prefix" in /*) ;; *) fail "--prefix must be an absolute directory.";; esac
  carriage_return=$(printf '\r')
  case "$prefix" in /|*:*|*'
'*|*"$carriage_return"*) fail "Invalid installation prefix.";; esac
  for tool in curl tar awk mktemp; do command -v "$tool" >/dev/null 2>&1 || fail "$tool is required."; done
  if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then
    fail "sha256sum or shasum is required."
  fi
  case "$(uname -s)" in Darwin) platform=darwin;; Linux) platform=linux;; *) fail "Unsupported system; use macOS or Linux.";; esac
  case "$(uname -m)" in arm64|aarch64) arch=arm64;; x86_64|amd64) arch=x64;; *) fail "Unsupported architecture; use ARM64 or x64.";; esac
  target=$platform-$arch
  if [ "$client_only" = 0 ] && [ "$platform" = darwin ]; then
    mac_version=$(sw_vers -productVersion) || fail "Cannot determine macOS version."
    mac_major=${mac_version%%.*}
    case "$mac_major" in ''|*[!0-9]*) fail "Cannot determine macOS version.";; esac
    [ "$mac_major" -ge 15 ] || fail "The bundled Host requires macOS 15 or newer."
  fi
  if [ "$client_only" = 1 ]; then
    node=$(command -v node) || fail "Client-only mode requires Node 22.19+ on PATH."
    npm=$(command -v npm) || fail "Client-only mode requires npm on PATH."
  fi
  [ ! -L "$prefix" ] || fail "Installation prefix must not be a symlink."
  if [ -e "$prefix" ]; then
    [ -d "$prefix" ] || fail "Installation prefix is not a directory."
    [ -n "$(find "$prefix" -prune -user "$(id -u)" -print)" ] || fail "Installation prefix is owned by another user."
    [ ! -d "$prefix/.install.lock" ] || fail "Another installation holds this prefix lock."
    if [ ! -f "$prefix/.aesir-cli-installer" ] && [ -n "$(find "$prefix/." ! -name . -prune -print)" ]; then
      fail "Installation prefix contains existing files; choose an empty directory."
    fi
  else
    mkdir -p "$prefix" || fail "Cannot create installation prefix."
  fi
  prefix=$(CDPATH='' cd "$prefix" && pwd -L)
  mkdir "$prefix/.install.lock" 2>/dev/null || fail "Another installation holds this prefix lock."
  locked=1
  trap cleanup 0
  trap 'exit 129' 1
  trap 'exit 130' 2
  trap 'exit 143' 15
  stage=$(mktemp -d "$prefix/.install.XXXXXXXX") || fail "Cannot create private staging directory."
  NODE_COMPILE_CACHE=$stage/node-compile-cache
  NODE_DISABLE_COMPILE_CACHE=1
  export NODE_COMPILE_CACHE NODE_DISABLE_COMPILE_CACHE
  release_url=https://github.com/MarcReinl/aesir-red-dist/releases/download/aesir-v$version
  tui_asset=aesir-tui-$version.tgz
  download SHA256SUMS "$stage/SHA256SUMS"
  download "$tui_asset" "$stage/$tui_asset"
  verify "$tui_asset"
  unset NODE_OPTIONS NODE_PATH
  if [ "$client_only" = 0 ]; then
    host_asset=aesir-$version-$target.tar.gz
    download "$host_asset" "$stage/$host_asset"
    verify "$host_asset"
    tar -tzf "$stage/$host_asset" > "$stage/archive-files" || fail "Invalid Host archive."
    awk '/^\// || /(^|\/)\.\.(\/|$)/ {exit 1}' "$stage/archive-files" || fail "Unsafe Host archive paths."
    mkdir "$stage/runtime"
    tar -xzf "$stage/$host_asset" -C "$stage/runtime" --strip-components=1 || fail "Cannot extract Host archive."
    node=$stage/runtime/node/bin/node
    npm=$stage/runtime/node/lib/node_modules/npm/bin/npm-cli.js
    [ -x "$node" ] && [ -f "$npm" ] && [ -x "$stage/runtime/bin/aesir" ] || fail "Host archive is missing its Node, npm or launcher."
  fi
  "$node" --input-type=module - "$platform" "$arch" "$version" "$stage" "$client_only" <<'VALIDATE_RUNTIME' || fail "Runtime validation failed; use a supported OS and architecture."
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
const [platform, arch, version, stage, clientOnly] = process.argv.slice(2);
const [major, minor] = process.versions.node.split('.').map(Number);
if (major < 22 || (major === 22 && minor < 19)) throw new Error('Node 22.19 or newer is required.');
if (process.platform !== platform || process.arch !== arch) throw new Error('Node does not match the selected target.');
if (clientOnly === '0') {
  const metadata = JSON.parse(readFileSync(join(stage, 'runtime/aesir-archive.json'), 'utf8'));
  const pkg = JSON.parse(readFileSync(join(stage, 'runtime/package.json'), 'utf8'));
  if (metadata.version !== version || metadata.target !== `${platform}-${arch}` || pkg.version !== version) throw new Error('Host archive version or target mismatch.');
}
VALIDATE_RUNTIME
  : > "$stage/npmrc"
  : > "$stage/global-npmrc"
  printf 'Installing AESIR TUI %s for %s…\n' "$version" "$target"
  if [ "$client_only" = 0 ]; then
    PATH="$stage/runtime/node/bin:$PATH" npm_config_cache="$stage/npm-cache" \
      "$node" "$npm" install --global --prefix "$stage/client" --omit=dev --ignore-scripts \
      --no-audit --no-fund --userconfig "$stage/npmrc" --globalconfig "$stage/global-npmrc" "$stage/$tui_asset" \
      || fail "npm dependency installation failed."
  else
    npm_config_cache="$stage/npm-cache" "$npm" install --global --prefix "$stage/client" \
      --omit=dev --ignore-scripts --no-audit --no-fund \
      --userconfig "$stage/npmrc" --globalconfig "$stage/global-npmrc" "$stage/$tui_asset" \
      || fail "npm dependency installation failed."
  fi
  "$node" --input-type=module - "$prefix" "$stage" "$version" "$target" "$client_only" "$modify_path" <<'ACTIVATE' || fail "Installation validation or activation failed."
import * as fs from 'node:fs';
import { join, sep } from 'node:path';
import { pathToFileURL } from 'node:url';
import { execFileSync } from 'node:child_process';
const [base, stage, version, target, clientOnly, modifyPath] = process.argv.slice(2);
const own = 'aesir-cli-installer-v1\n';
const exists = path => { try { return fs.lstatSync(path); } catch (error) { if (error.code === 'ENOENT') return undefined; throw error; } };
const marker = join(base, '.aesir-cli-installer');
if (exists(marker) && (!fs.lstatSync(marker).isFile() || fs.readFileSync(marker, 'utf8') !== own)) throw new Error('Unrecognized installer ownership marker.');
const versions = join(base, 'versions');
const current = join(base, 'current');
for (const path of [versions, join(base, 'bin')]) {
  const stat = exists(path);
  if (stat && (!stat.isDirectory() || stat.isSymbolicLink())) throw new Error(`Installation directory conflict: ${path}`);
}
if (exists(current) && (!fs.lstatSync(current).isSymbolicLink() || !fs.realpathSync(current).startsWith(fs.realpathSync(versions) + sep))) throw new Error('Current installation pointer conflicts with existing files.');
const pkgRoot = join(stage, 'client/lib/node_modules/@aesir-red/tui-client');
const pkg = JSON.parse(fs.readFileSync(join(pkgRoot, 'package.json'), 'utf8'));
if (pkg.name !== '@aesir-red/tui-client' || pkg.version !== version || pkg.bin?.aesir !== 'dist/cli.js' || pkg.bin?.['aesir-tui'] !== 'dist/cli.js') throw new Error('Installed TUI package identity or version mismatch.');
const preferences = await import(pathToFileURL(join(pkgRoot, 'dist/preferences.js')).href);
const launcher = await import(pathToFileURL(join(pkgRoot, 'dist/launcher.js')).href);
if (typeof preferences.loadPreferences !== 'function' || typeof preferences.selectConnection !== 'function' || typeof launcher.parseArgs !== 'function') throw new Error('Installed TUI is missing connection helpers.');
const reported = execFileSync(process.execPath, [join(pkgRoot, 'dist/cli.js'), '--version'], { encoding: 'utf8', timeout: 15000 });
if (reported.trim().split(' · ')[0] !== `aesir-red-tui ${version}`) throw new Error('Installed TUI version check failed.');
fs.writeFileSync(join(stage, 'node-path'), `${process.execPath}\n`, { mode: 0o600 });
fs.writeFileSync(join(stage, 'launch.mjs'), `import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
const root = dirname(fileURLToPath(import.meta.url));
const cli = join(root, 'client/lib/node_modules/@aesir-red/tui-client/dist/cli.js');
const args = process.argv.slice(2);
${clientOnly === '0' ? `const { parseArgs } = await import(pathToFileURL(join(dirname(cli), 'launcher.js')).href);
const options = parseArgs(args);
if (!options.help && !options.version && !options.listOperations) {
  const { loadPreferences, selectConnection } = await import(pathToFileURL(join(dirname(cli), 'preferences.js')).href);
  const connection = selectConnection(options, process.env, await loadPreferences());
  if (!connection.url && !connection.source && !connection.dsh) args.unshift('--dsh', ${JSON.stringify(join(base, 'current/runtime/bin/aesir'))});
}` : ''}
process.argv = [process.execPath, cli, ...args];
await import(pathToFileURL(cli).href);
`, { mode: 0o600 });
const wrapper = `#!/bin/sh
# AESIR CLI installer launcher v1
set -eu
base=$(CDPATH='' cd -P "$(dirname "$0")/.." && pwd)
active=$(CDPATH='' cd -P "$base/current" && pwd)
if [ -x "$active/runtime/node/bin/node" ]; then
  node=$active/runtime/node/bin/node
  PATH="$active/runtime/node/bin:$PATH"
  export PATH
else
  IFS= read -r node < "$active/node-path"
fi
exec "$node" "$active/launch.mjs" "$@"
`;
const aliases = ['aesir', 'aesir-tui'].map(name => join(base, 'bin', name));
for (const path of aliases) if (exists(path) && (!fs.lstatSync(path).isFile() || fs.readFileSync(path, 'utf8') !== wrapper)) throw new Error(`Command conflict: ${path}`);
fs.mkdirSync(versions, { recursive: true, mode: 0o700 });
fs.mkdirSync(join(base, 'bin'), { recursive: true, mode: 0o700 });
const destination = fs.mkdtempSync(join(versions, `${version}-${target}-${clientOnly === '1' ? 'client' : 'full'}-`));
const pending = join(base, `.current-${process.pid}`);
const created = [];
let activated = false;
let pendingCreated = false;
try {
  for (const path of aliases) if (!exists(path)) { fs.writeFileSync(path, wrapper, { flag: 'wx', mode: 0o755 }); created.push(path); }
  if (!exists(marker)) fs.writeFileSync(marker, own, { flag: 'wx', mode: 0o600 });
  for (const name of fs.readdirSync(stage)) if (!['client', 'runtime', 'launch.mjs', 'node-path'].includes(name)) fs.rmSync(join(stage, name), { recursive: true, force: true });
  fs.renameSync(stage, destination);
  fs.symlinkSync(destination, pending);
  pendingCreated = true;
  fs.renameSync(pending, current);
  pendingCreated = false;
  activated = true;
} finally {
  if (pendingCreated) fs.unlinkSync(pending);
  if (!activated) { fs.rmSync(destination, { recursive: true, force: true }); for (const path of created) fs.unlinkSync(path); }
}
const quote = value => "'" + value.replaceAll("'", "'\\''") + "'";
const pathLine = `export PATH=${quote(join(base, 'bin'))}:"$PATH"`;
const shell = (process.env.SHELL ?? '').split('/').pop();
const profiles = [];
if (shell === 'bash') {
  const login = ['.bash_profile', '.bash_login', '.profile'].map(name => join(process.env.HOME, name));
  profiles.push(join(process.env.HOME, '.bashrc'), login.find(path => exists(path)) ?? login[0]);
}
if (shell === 'zsh') profiles.push(join(process.env.ZDOTDIR || process.env.HOME, '.zshrc'));
if (modifyPath === '1' && profiles.length) {
  for (const profile of profiles) {
    try {
      const before = exists(profile) ? fs.readFileSync(profile, 'utf8') : '';
      if (!before.split('\n').includes(pathLine)) fs.appendFileSync(profile, `${before && !before.endsWith('\n') ? '\n' : ''}\n# AESIR CLI\n${pathLine}\n`, { mode: 0o600 });
      console.log(`PATH configured in ${profile}.`);
    } catch (error) { console.error(`Could not update shell PATH: ${error.message}.`); }
  }
  console.log('Restart your shell or run:');
} else console.log('Add the TUI to your shell PATH:');
console.log(pathLine);
console.log(`Installed AESIR TUI ${version} in ${base}. Run aesir to connect. No Host was started.`);
ACTIVATE
)

# Keep invocation last: a truncated curl response cannot execute a partial main.
main "$@"
