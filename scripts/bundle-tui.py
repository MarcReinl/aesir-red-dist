#!/usr/bin/env python3
"""Build aesir-tui-VERSION-bundled.tgz from a published aesir-tui-VERSION.tgz.

The output holds the npm package's files plus its production node_modules under
one `package/` directory, so install-tui.sh extracts it without npm or registry
access. One archive serves every target only while no installed dependency
declares os/cpu restrictions, install scripts or a node-gyp build; the build
fails otherwise. Identical inputs and dependency versions produce identical bytes.
"""
import argparse
import gzip
import hashlib
import io
import json
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile


PACKAGE_NAME = '@aesir-red/tui-client'
INSTALL_SCRIPTS = ('preinstall', 'install', 'postinstall')


def install(package, npm, folder):
    """Install the package's production dependencies with npm, as install-tui.sh's npm path does."""
    for name in ('npmrc', 'global-npmrc'):
        (folder / name).write_text('')
    env = {key: value for key, value in os.environ.items() if key not in ('NODE_OPTIONS', 'NODE_PATH')}
    env['npm_config_cache'] = str(folder / 'npm-cache')
    subprocess.run([npm, 'install', '--global', '--prefix', str(folder / 'client'), '--omit=dev', '--ignore-scripts',
                    '--no-audit', '--no-fund', '--userconfig', str(folder / 'npmrc'),
                    '--globalconfig', str(folder / 'global-npmrc'), str(package)], env=env, check=True)
    return folder / 'client/lib/node_modules' / PACKAGE_NAME


def package_roots(node_modules):
    """Yield every installed package directory, including scoped and nested ones."""
    for child in sorted(node_modules.iterdir(), key=lambda path: path.name):
        if child.name.startswith('.') or child.is_symlink() or not child.is_dir():
            continue
        for root in sorted(child.iterdir(), key=lambda path: path.name) if child.name.startswith('@') else [child]:
            if root.is_dir() and not root.is_symlink():
                yield root
                if (root / 'node_modules').is_dir():
                    yield from package_roots(root / 'node_modules')


def require_portable(root):
    """Reject dependencies that npm would select, build or configure per host."""
    for package in package_roots(root / 'node_modules'):
        value = json.loads((package / 'package.json').read_text())
        scripts = value.get('scripts') or {}
        reasons = [field for field in ('os', 'cpu', 'libc') if field in value]
        reasons += [name for name in INSTALL_SCRIPTS if name in scripts]
        if (package / 'binding.gyp').exists():
            reasons.append('binding.gyp')
        if reasons:
            raise SystemExit(f'{value.get("name", package.name)} is host-specific ({", ".join(reasons)}); a portable bundle cannot carry it.')


def entries(directory, name):
    """Yield (path, archive name) in sorted order, omitting npm's generated .bin links and lock cache."""
    yield directory, name
    for child in sorted(directory.iterdir(), key=lambda path: path.name):
        if directory.name == 'node_modules' and child.name in ('.bin', '.package-lock.json'):
            continue
        if child.is_symlink():
            raise SystemExit(f'Refusing link {name}/{child.name}; install-tui.sh rejects links.')
        if child.is_dir():
            yield from entries(child, f'{name}/{child.name}')
        else:
            yield child, f'{name}/{child.name}'


def write_archive(root, output):
    """Write a gzip tarball with fixed owners, modes and timestamps."""
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open('wb') as raw, gzip.GzipFile(filename='', mode='wb', fileobj=raw, mtime=0, compresslevel=9) as compressed, \
            tarfile.open(fileobj=compressed, mode='w', format=tarfile.PAX_FORMAT) as archive:
        for path, name in entries(root, 'package'):
            info = tarfile.TarInfo(name)
            info.mtime, info.uid, info.gid, info.uname, info.gname = 0, 0, 0, '', ''
            if path.is_dir():
                info.type, info.mode = tarfile.DIRTYPE, 0o755
                archive.addfile(info)
            else:
                data = path.read_bytes()
                info.size, info.mode = len(data), 0o755 if os.access(path, os.X_OK) else 0o644
                archive.addfile(info, io.BytesIO(data))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('package', type=Path, help='verified aesir-tui-VERSION.tgz from the release')
    parser.add_argument('--output', type=Path, help='default: aesir-tui-VERSION-bundled.tgz beside the package')
    parser.add_argument('--npm', default='npm', help='npm executable (default: npm on PATH)')
    options = parser.parse_args()
    package = options.package.resolve(strict=True)
    with tempfile.TemporaryDirectory(prefix='aesir-tui-bundle-') as folder:
        root = install(package, options.npm, Path(folder))
        manifest = json.loads((root / 'package.json').read_text())
        if manifest.get('name') != PACKAGE_NAME:
            raise SystemExit(f'{package.name} is not {PACKAGE_NAME}.')
        output = options.output or package.with_name(f'aesir-tui-{manifest["version"]}-bundled.tgz')
        if (root / 'node_modules').is_dir():
            require_portable(root)
        write_archive(root, output)
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    print(f'{digest}  {output.name}')


if __name__ == '__main__':
    main()
