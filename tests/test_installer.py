"""Offline installer integration tests with real npm and tiny release archives.

Only curl, uname, sw_vers, and archive-carried Node/npm launchers are fixtures.
Every subprocess uses a private HOME, data root, config, cache, and temporary
directory. The fixture client reports connection selection instead of starting
a Host, and its install script rejects execution to exercise --ignore-scripts.
"""
import hashlib
import io
import json
import os
from pathlib import Path
import shlex
import shutil
import signal
import subprocess
import sys
import tarfile
import tempfile
import time
import unittest


INSTALLER = Path(__file__).resolve().parents[1] / 'install-tui.sh'
VERSION = '0.2.0-rc.3'
REAL_NODE = Path(shutil.which('node') or '/missing-node').resolve()
REAL_NPM = Path(shutil.which('npm') or '/missing-npm').resolve()
OFFICIAL = 'https://github.com/MarcReinl/aesir-red-dist/releases/download/'
TARGETS = {
    'darwin-arm64': ('Darwin', 'arm64'),
    'darwin-x64': ('Darwin', 'x86_64'),
    'linux-arm64': ('Linux', 'aarch64'),
    'linux-x64': ('Linux', 'x86_64'),
}

PREFERENCES = r"""
import {readFile} from 'node:fs/promises';
import {homedir} from 'node:os';
import {join} from 'node:path';
export const preferencePath=join(process.env.XDG_CONFIG_HOME??join(homedir(),'.config'),'aesir-red-tui','client.json');
export async function loadPreferences(){
  try{return JSON.parse(await readFile(preferencePath,'utf8'));}
  catch(error){if(error.code==='ENOENT')return{};throw error;}
}
export function selectConnection(explicit,environment,saved){
  if([explicit.url,explicit.source,explicit.dsh].filter(Boolean).length>1)throw new Error('Select only one connection: --url, --source or --dsh.');
  if(explicit.url)return{url:explicit.url};
  if(explicit.source)return{source:explicit.source};
  if(explicit.dsh)return{dsh:explicit.dsh};
  if(environment.AESIR_HOST_URL)return{url:environment.AESIR_HOST_URL};
  if(environment.AESIR_SOURCE)return{source:environment.AESIR_SOURCE};
  if(typeof saved.dsh==='string'&&saved.dsh.trim())return{dsh:saved.dsh};
  if(typeof saved.source==='string'&&saved.source.trim())return{source:saved.source};
  return{};
}
"""

ARGUMENTS = r"""
import {resolve} from 'node:path';
export function parseArgs(argv){
  const out={cwd:process.cwd(),help:false,version:false,patches:[]};
  const fields={'--url':'url','--source':'source','--dsh':'dsh','--cwd':'cwd','--session':'session','--home':'home','--permissions':'permissions'};
  for(let i=0;i<argv.length;i++){
    const key=argv[i];
    if(fields[key]){if(argv[i+1]===undefined)throw new Error(key+' requires a value');out[fields[key]]=argv[++i];}
    else if(key==='--version'||key==='-v')out.version=true;
    else if(key==='--help'||key==='-h')out.help=true;
  }
  out.cwd=resolve(out.cwd);if(out.source)out.source=resolve(out.source);
  return out;
}
"""

CLIENT = r"""#!/usr/bin/env node
import {readFile} from 'node:fs/promises';
import {loadPreferences,selectConnection} from './preferences.js';
import {parseArgs} from './launcher.js';
const argv=process.argv.slice(2), options=parseArgs(argv);
if(options.version){const p=JSON.parse(await readFile(new URL('../package.json',import.meta.url),'utf8'));console.log('aesir-red-tui '+p.version);}
else if(options.help)console.log('Fixture client help');
else console.log(JSON.stringify({argv,connection:selectConnection(options,process.env,await loadPreferences()),cwd:options.cwd}));
"""

CURL = r"""import json,os,pathlib,shutil,sys,time
from urllib.parse import urlparse,unquote
args=sys.argv[1:];out=None;urls=[];i=0
value_options={'--retry','--retry-delay','--retry-max-time','--connect-timeout','--max-time','--proto','--proto-redir','--tls-max','--user-agent','-A'}
while i<len(args):
 a=args[i]
 if a in ('-o','--output'):
  i+=1;out=args[i]
 elif a.startswith('--output='):out=a.split('=',1)[1]
 elif a.startswith('-o') and len(a)>2:out=a[2:]
 elif a in value_options:i+=1
 elif a.startswith('https://'):urls.append(a)
 i+=1
if len(urls)!=1:sys.exit('fixture curl requires one official HTTPS URL')
u=urlparse(urls[0]);parts=u.path.split('/')
if u.scheme!='https' or u.netloc!='github.com' or parts[1:5]!=['MarcReinl','aesir-red-dist','releases','download'] or len(parts)!=7 or not parts[5].startswith('aesir-v'):
 sys.exit('fixture refused non-release download: '+urls[0])
version=parts[5][len('aesir-v'):];name=unquote(parts[6])
if '/' in name or name in ('.','..'):sys.exit('invalid fixture asset')
with open(os.environ['FIXTURE_CURL_LOG'],'a') as log:log.write(json.dumps({'url':urls[0],'filename':name,'version':version})+'\n')
ready=os.environ.get('FIXTURE_CURL_READY');release=os.environ.get('FIXTURE_CURL_RELEASE')
if ready and release:
 pathlib.Path(ready).touch();deadline=time.monotonic()+40
 while not pathlib.Path(release).exists():
  if time.monotonic()>deadline:sys.exit('fixture download barrier timed out')
  time.sleep(.01)
source=pathlib.Path(os.environ['FIXTURE_RELEASES'])/version/name
if not source.is_file():sys.exit('fixture release asset missing: '+name)
if out:shutil.copyfile(source,out)
else:sys.stdout.buffer.write(source.read_bytes())
"""


def clean_environment(home):
    """Remove inherited credentials and package/application configuration."""
    return {key: value for key, value in os.environ.items()
            if not any(word in key.upper() for word in ('KEY', 'SECRET', 'TOKEN', 'PASSWORD'))
            and not key.startswith(('AESIR_', 'DSH_', 'KITTY_', 'XDG_', 'NPM_', 'npm_', 'PNPM_'))
            and key not in ('HOME', 'PATH', 'ZDOTDIR', 'NODE_OPTIONS', 'NODE_PATH', 'TMPDIR')}


def write_file(path, value, executable=False):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    path.write_text(value)
    path.chmod(0o755 if executable else 0o600)


def make_archive(path, files):
    """Create an archive with one removable top directory and explicit modes."""
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    with tarfile.open(path, 'w:gz') as archive:
        for name, value in files.items():
            content, mode = value if isinstance(value, tuple) else (value, 0o644)
            data = content.encode()
            entry = tarfile.TarInfo(name)
            entry.size, entry.mode, entry.mtime = len(data), mode, 0
            archive.addfile(entry, io.BytesIO(data))


def tree_snapshot(root):
    """Observe names, link targets and file bytes without following directory links."""
    if not root.exists():
        return {}
    result = {}
    for path in root.rglob('*'):
        name = str(path.relative_to(root))
        if path.is_symlink():
            result[name] = ('link', os.readlink(path))
        elif path.is_file():
            result[name] = ('file', hashlib.sha256(path.read_bytes()).hexdigest())
        else:
            result[name] = ('directory',)
    return result


class ReleaseFixture:
    """Private offline distribution server implemented only by a curl executable."""
    def __init__(self, target='darwin-arm64'):
        self.temporary = tempfile.TemporaryDirectory(prefix='aesir-installer-')
        self.root = Path(self.temporary.name).resolve()
        self.root.chmod(0o700)
        self.home = self.root / 'home with spaces'
        self.prefix = self.root / 'install prefix'
        self.releases = self.root / 'releases'
        self.shims = self.root / 'shims'
        self.tools = self.root / 'system-tools'
        self.client_tools = self.root / 'client-tools'
        self.workspace = self.root / 'workspace with spaces'
        self.temp = self.root / 'tmp'
        self.curl_log = self.root / 'curl.jsonl'
        for directory in (self.home, self.shims, self.tools, self.client_tools, self.workspace, self.temp):
            directory.mkdir(parents=True, mode=0o700)
        self.env = clean_environment(self.home)
        self.env.update({
            'HOME': str(self.home), 'SHELL': '/bin/zsh', 'ZDOTDIR': str(self.home),
            'XDG_DATA_HOME': str(self.home / '.local/share'), 'XDG_CONFIG_HOME': str(self.home / '.config'),
            'XDG_CACHE_HOME': str(self.home / '.cache'), 'XDG_STATE_HOME': str(self.home / '.local/state'),
            'DSH_HOME': str(self.home / '.fixture-dsh'), 'TMPDIR': str(self.temp),
            'FIXTURE_RELEASES': str(self.releases), 'FIXTURE_CURL_LOG': str(self.curl_log),
            'FIXTURE_HOST_STARTED': str(self.root / 'host-started'),
            'npm_config_cache': str(self.home / '.npm-cache'), 'npm_config_audit': 'false',
            'npm_config_fund': 'false', 'npm_config_update_notifier': 'false', 'npm_config_offline': 'true',
            'npm_config_registry': 'https://offline.invalid',
            'npm_config_userconfig': str(self.root / 'empty-npmrc'), 'npm_config_globalconfig': str(self.root / 'empty-global-npmrc'),
        })
        write_file(self.root / 'empty-npmrc', '')
        write_file(self.root / 'empty-global-npmrc', '')
        for command in ('sh', 'env', 'tar', 'gzip', 'sha256sum', 'shasum', 'mktemp', 'mkdir', 'rmdir', 'rm', 'mv', 'cp', 'ln', 'chmod', 'cat', 'dirname', 'basename', 'readlink', 'sed', 'awk', 'grep', 'tr', 'cut', 'head', 'tail', 'wc', 'sort', 'find', 'cmp', 'date', 'touch', 'id', 'sleep', 'ls'):
            source = shutil.which(command)
            if source:
                (self.tools / command).symlink_to(Path(source).resolve())
        write_file(self.shims / 'curl', '#!' + sys.executable + '\n' + CURL, executable=True)
        write_file(self.shims / 'uname', '#!/bin/sh\ncase "$1" in\n-m) printf "%s\\n" "$FIXTURE_MACHINE";;\n-sm|-ms) printf "%s %s\\n" "$FIXTURE_SYSTEM" "$FIXTURE_MACHINE";;\n*) printf "%s\\n" "$FIXTURE_SYSTEM";;\nesac\n', executable=True)
        write_file(self.shims / 'sw_vers', '#!/bin/sh\nprintf "15.0\\n"\n', executable=True)
        write_file(self.client_tools / 'node', '#!/bin/sh\nexec ' + shlex.quote(str(REAL_NODE)) + ' "$@"\n', executable=True)
        write_file(self.client_tools / 'npm', '#!/bin/sh\nexec ' + shlex.quote(str(REAL_NODE)) + ' ' + shlex.quote(str(REAL_NPM)) + ' "$@"\n', executable=True)
        self.env['PATH'] = os.pathsep.join(map(str, (self.shims, self.tools)))
        self.set_target(target)
        self.make_release(VERSION)

    def close(self):
        self.temporary.cleanup()

    def set_target(self, target):
        system, machine = TARGETS[target]
        self.env.update(FIXTURE_SYSTEM=system, FIXTURE_MACHINE=machine)

    def make_release(self, version, npm_failure=False):
        folder = self.releases / version
        package = {
            'name': '@aesir-red/tui-client', 'version': version, 'type': 'module',
            'bin': {'aesir': 'dist/cli.js', 'aesir-tui': 'dist/cli.js'},
            'engines': {'node': '>=22.19'}, 'scripts': {'preinstall': 'node -e "process.exit(71)"'},
        }
        make_archive(folder / ('aesir-tui-' + version + '.tgz'), {
            'package/package.json': json.dumps(package), 'package/dist/preferences.js': PREFERENCES,
            'package/dist/launcher.js': ARGUMENTS, 'package/dist/cli.js': (CLIENT, 0o755),
        })
        for target in TARGETS:
            platform, arch = target.split('-')
            probe = 'Object.defineProperty(process,"platform",{value:' + json.dumps(platform) + '});Object.defineProperty(process,"arch",{value:' + json.dumps(arch) + '});\n'
            node = '#!/bin/sh\nbin=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)\nexec ' + shlex.quote(str(REAL_NODE)) + ' --import "$bin/target-probe.mjs" "$@"\n'
            npm = 'console.error("fixture npm failure");process.exit(43);\n' if npm_failure else 'import(' + json.dumps(REAL_NPM.as_uri()) + ');\n'
            host = '#!/bin/sh\nprintf "Host must not start during installation\\n" >&2\nprintf started > "$FIXTURE_HOST_STARTED"\nexit 77\n'
            make_archive(folder / ('aesir-' + version + '-' + target + '.tar.gz'), {
                'runtime/package.json': json.dumps({'name': 'fixture-runtime', 'version': version, 'private': True}),
                'runtime/aesir-archive.json': json.dumps({'version': version, 'target': target}),
                'runtime/node/bin/node': (node, 0o755), 'runtime/node/bin/target-probe.mjs': probe,
                'runtime/node/bin/npm': ('#!/bin/sh\nbin=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)\nexec "$bin/node" "$bin/../lib/node_modules/npm/bin/npm-cli.js" "$@"\n', 0o755),
                'runtime/node/lib/node_modules/npm/bin/npm-cli.js': npm, 'runtime/bin/aesir': (host, 0o755),
            })
        self.checksums(version)

    def checksums(self, version):
        folder = self.releases / version
        (folder / 'SHA256SUMS').write_text(''.join(hashlib.sha256(path.read_bytes()).hexdigest() + '  ' + path.name + '\n' for path in sorted(folder.iterdir()) if path.name != 'SHA256SUMS'))

    def command(self, *args):
        return ['/bin/sh', str(INSTALLER), *args]

    def install(self, *args, env=None, use_prefix=True, timeout=60):
        arguments = (['--prefix', str(self.prefix)] if use_prefix else []) + list(args)
        return subprocess.run(self.command(*arguments), cwd=self.workspace, env=self.env if env is None else env,
                              stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=timeout)

    def client(self, *args, alias='aesir', env=None):
        return subprocess.run([str(self.prefix / 'bin' / alias), *args], cwd=self.workspace,
                              env=self.env if env is None else env, stdin=subprocess.DEVNULL,
                              capture_output=True, text=True, timeout=15)

    def requests(self):
        return [json.loads(line) for line in self.curl_log.read_text().splitlines()] if self.curl_log.exists() else []

    @property
    def preference(self):
        return Path(self.env['XDG_CONFIG_HOME']) / 'aesir-red-tui/client.json'

    def preferences(self, value):
        write_file(self.preference, json.dumps(value) + '\n')

    def with_client_runtime(self):
        self.env['PATH'] = os.pathsep.join(map(str, (self.shims, self.client_tools, self.tools)))


@unittest.skipUnless(REAL_NODE.is_file() and REAL_NPM.is_file(), 'Fixture tests require Node and npm on the test runner')
class InstallerIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.fixture = ReleaseFixture()
        self.addCleanup(self.fixture.close)

    def install_ok(self, *args, **kwargs):
        result = self.fixture.install(*args, **kwargs)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse((self.fixture.root / 'host-started').exists(), 'Installation started its Host')
        return result

    def client_json(self, *args, **kwargs):
        result = self.fixture.client(*args, **kwargs)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return json.loads(result.stdout)

    def test_four_platform_mappings_choose_exact_runtime_and_portable_client(self):
        for target in TARGETS:
            with self.subTest(target=target):
                fixture = ReleaseFixture(target)
                try:
                    result = fixture.install('--no-modify-path')
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    names = [row['filename'] for row in fixture.requests()]
                    self.assertIn('aesir-' + VERSION + '-' + target + '.tar.gz', names)
                    self.assertIn('aesir-tui-' + VERSION + '.tgz', names)
                    self.assertIn('SHA256SUMS', names)
                    self.assertEqual({row['version'] for row in fixture.requests()}, {VERSION})
                    self.assertFalse((fixture.root / 'host-started').exists())
                finally:
                    fixture.close()

    def test_full_install_runs_both_aliases_without_global_node_or_npm(self):
        self.assertIsNone(shutil.which('node', path=self.fixture.env['PATH']))
        self.assertIsNone(shutil.which('npm', path=self.fixture.env['PATH']))
        self.install_ok('--no-modify-path')
        for alias in ('aesir', 'aesir-tui'):
            result = self.fixture.client('--version', alias=alias)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(VERSION, result.stdout)
        value = self.client_json('--cwd', str(self.fixture.workspace), '--session', 'fixture-session', '--permissions', 'read-only')
        self.assertEqual(value['connection'], {'dsh': str(self.fixture.prefix / 'current/runtime/bin/aesir')})
        for flag, expected in [('--cwd', str(self.fixture.workspace)), ('--session', 'fixture-session'), ('--permissions', 'read-only')]:
            self.assertEqual(value['argv'][value['argv'].index(flag) + 1], expected)
        self.assertEqual(value['cwd'], str(self.fixture.workspace))
        self.assertFalse(self.fixture.preference.exists(), 'Installing or inspecting a version must not create client preferences')
        self.assertEqual(list(self.fixture.temp.iterdir()), [], 'Private staging directory leaked')

    def test_default_prefix_uses_xdg_data_home_and_pins_rc3(self):
        result = self.install_ok('--no-modify-path', use_prefix=False)
        prefix = Path(self.fixture.env['XDG_DATA_HOME']) / 'aesir-cli'
        self.assertTrue((prefix / 'bin/aesir-tui').is_file(), result.stdout)
        self.assertTrue((prefix / 'current/runtime/bin/aesir').is_file())
        self.assertEqual({row['version'] for row in self.fixture.requests()}, {VERSION})
        self.assertNotIn('/latest/', '\n'.join(row['url'] for row in self.fixture.requests()))

    def test_default_prefix_falls_back_to_home_when_xdg_data_home_is_absent(self):
        env = dict(self.fixture.env)
        env.pop('XDG_DATA_HOME')
        self.install_ok('--no-modify-path', use_prefix=False, env=env)
        self.assertTrue((self.fixture.home / '.local/share/aesir-cli/bin/aesir').is_file())

    def test_explicit_environment_and_saved_connections_keep_their_precedence(self):
        self.fixture.preferences({'source': '/saved source', 'dsh': '/saved host', 'drafts': {'old': 'keep draft'}})
        original = self.fixture.preference.read_bytes()
        self.install_ok('--no-modify-path')
        cases = [
            ([], {}, {'dsh': '/saved host'}),
            ([], {'AESIR_HOST_URL': 'http://127.0.0.1:1234/?token=fixture'}, {'url': 'http://127.0.0.1:1234/?token=fixture'}),
            ([], {'AESIR_SOURCE': '/environment source'}, {'source': '/environment source'}),
            (['--url', 'http://127.0.0.1:2345/?token=explicit'], {'AESIR_HOST_URL': 'http://127.0.0.1:1234/?token=fixture'}, {'url': 'http://127.0.0.1:2345/?token=explicit'}),
            (['--source', '/explicit source'], {'AESIR_HOST_URL': 'http://127.0.0.1:1234/?token=fixture'}, {'source': '/explicit source'}),
            (['--dsh', '/explicit host'], {'AESIR_SOURCE': '/environment source'}, {'dsh': '/explicit host'}),
        ]
        for argv, extra, expected in cases:
            with self.subTest(argv=argv, environment=list(extra)):
                env = {**self.fixture.env, **extra}
                self.assertEqual(self.client_json(*argv, env=env)['connection'], expected)
        self.assertEqual(self.fixture.preference.read_bytes(), original)
        self.fixture.preferences({'source': '/source only'})
        self.assertEqual(self.client_json()['connection'], {'source': '/source only'})

    def test_multiple_explicit_connections_are_not_silently_replaced(self):
        self.install_ok('--no-modify-path')
        result = self.fixture.client('--source', '/source', '--dsh', '/host')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('only one connection', result.stderr)

    def test_version_upgrade_switches_current_and_retains_the_previous_files(self):
        self.install_ok('--no-modify-path')
        previous = (self.fixture.prefix / 'current').resolve()
        previous_files = tree_snapshot(previous)
        version = '0.2.0-rc.4'
        self.fixture.make_release(version)
        self.install_ok('--version', version, '--no-modify-path')
        self.assertNotEqual((self.fixture.prefix / 'current').resolve(), previous)
        self.assertEqual(tree_snapshot(previous), previous_files)
        result = self.fixture.client('--version')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(version, result.stdout)
        self.assertEqual(self.client_json()['connection'], {'dsh': str(self.fixture.prefix / 'current/runtime/bin/aesir')})

    def test_client_only_downloads_no_host_and_keeps_the_normal_chooser(self):
        self.fixture.with_client_runtime()
        self.install_ok('--client-only', '--no-modify-path')
        names = [row['filename'] for row in self.fixture.requests()]
        self.assertIn('aesir-tui-' + VERSION + '.tgz', names)
        self.assertFalse(any(name.startswith('aesir-' + VERSION + '-') for name in names))
        self.assertFalse((self.fixture.prefix / 'current/runtime/bin/aesir').exists())
        self.assertEqual(self.client_json()['connection'], {})

    def test_client_only_requires_existing_node_and_npm(self):
        result = self.fixture.install('--client-only', '--no-modify-path')
        self.assertNotEqual(result.returncode, 0)
        self.assertRegex(result.stdout + result.stderr, r'(?i)node|npm')
        self.assertFalse((self.fixture.prefix / 'current').exists())

    def assert_failed_upgrade_preserves_active_install(self, corrupt):
        self.fixture.preferences({'source': '/existing source', 'drafts': {'session': 'saved text'}})
        profile = self.fixture.home / '.zshrc'
        write_file(profile, '# user configuration\n')
        self.install_ok('--no-modify-path')
        before = tree_snapshot(self.fixture.prefix)
        preference = self.fixture.preference.read_bytes()
        old_profile = profile.read_bytes()
        version = '0.2.0-rc.4'
        self.fixture.make_release(version, npm_failure=corrupt == 'npm')
        folder = self.fixture.releases / version
        if corrupt == 'checksum':
            with (folder / ('aesir-tui-' + version + '.tgz')).open('ab') as archive:
                archive.write(b'changed after checksum')
        elif corrupt == 'missing-checksum':
            sums = folder / 'SHA256SUMS'
            sums.write_text(''.join(line for line in sums.read_text().splitlines(keepends=True) if 'aesir-tui-' not in line))
        elif corrupt == 'duplicate-checksum':
            sums = folder / 'SHA256SUMS'
            line = next(line for line in sums.read_text().splitlines(keepends=True) if 'aesir-tui-' in line)
            with sums.open('a') as output:
                output.write(line)
        elif corrupt in ('runtime-version', 'runtime-target'):
            path = folder / ('aesir-' + version + '-darwin-arm64.tar.gz')
            with tarfile.open(path, 'r:gz') as archive:
                files = {entry.name: (archive.extractfile(entry).read().decode(), entry.mode)
                         for entry in archive if entry.isfile()}
            metadata = {'version': version, 'target': 'darwin-arm64'}
            metadata['version' if corrupt == 'runtime-version' else 'target'] = 'wrong-value'
            files['runtime/aesir-archive.json'] = (json.dumps(metadata), 0o644)
            make_archive(path, files)
            self.fixture.checksums(version)
        result = self.fixture.install('--version', version, '--no-modify-path')
        self.assertNotEqual(result.returncode, 0, 'Broken upgrade unexpectedly activated')
        self.assertEqual(tree_snapshot(self.fixture.prefix), before, result.stdout + result.stderr)
        self.assertEqual(self.fixture.preference.read_bytes(), preference)
        self.assertEqual(profile.read_bytes(), old_profile)
        self.assertEqual(list(self.fixture.temp.iterdir()), [], 'Failed upgrade leaked staging files')
        result = self.fixture.client('--version')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(VERSION, result.stdout)

    def test_checksum_mismatch_does_not_activate_or_damage_the_previous_install(self):
        self.assert_failed_upgrade_preserves_active_install('checksum')

    def test_missing_exact_checksum_entry_does_not_activate_the_upgrade(self):
        self.assert_failed_upgrade_preserves_active_install('missing-checksum')

    def test_npm_failure_does_not_activate_or_damage_the_previous_install(self):
        self.assert_failed_upgrade_preserves_active_install('npm')

    def test_duplicate_exact_checksum_entries_are_rejected(self):
        self.assert_failed_upgrade_preserves_active_install('duplicate-checksum')

    def test_wrong_runtime_metadata_with_valid_checksums_is_rejected(self):
        for field in ('runtime-version', 'runtime-target'):
            with self.subTest(field=field):
                self.assert_failed_upgrade_preserves_active_install(field)

    def test_help_and_version_work_with_malformed_preferences_without_overwriting_them(self):
        write_file(self.fixture.preference, '{not valid JSON\n')
        original = self.fixture.preference.read_bytes()
        self.install_ok('--no-modify-path')
        for option in ('--help', '--version'):
            with self.subTest(option=option):
                result = self.fixture.client(option)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        result = self.fixture.client()
        self.assertNotEqual(result.returncode, 0, 'Malformed preferences were silently ignored')
        self.assertEqual(self.fixture.preference.read_bytes(), original)

    def test_apostrophes_in_prefix_survive_launcher_and_shell_profile_quoting(self):
        self.fixture.prefix = self.fixture.root / "O'Brien's CLI prefix"
        self.install_ok()
        self.assertEqual(self.client_json()['connection'], {'dsh': str(self.fixture.prefix / 'current/runtime/bin/aesir')})
        result = subprocess.run(['/bin/sh', '-c', '. "$1"; command -v aesir-tui', 'check-profile', str(self.fixture.home / '.zshrc')],
                                env=self.fixture.env, capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(self.fixture.prefix / 'bin/aesir-tui'))

    def test_repeat_install_adds_one_path_entry_and_preserves_user_profile(self):
        for shell in ('bash', 'zsh'):
            with self.subTest(shell=shell):
                fixture = ReleaseFixture()
                try:
                    fixture.env['SHELL'] = '/bin/' + shell
                    profile = fixture.home / ('.bashrc' if shell == 'bash' else '.zshrc')
                    original = '# user content\nexport USER_SETTING=kept\n'
                    write_file(profile, original)
                    for _ in range(2):
                        result = fixture.install()
                        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    text = profile.read_text()
                    self.assertTrue(text.startswith(original))
                    exports = [line for line in text.splitlines() if 'PATH=' in line and str(fixture.prefix / 'bin') in line]
                    self.assertEqual(len(exports), 1, text)
                    result = subprocess.run(['/bin/sh', '-c', '. "$1"; printf "%s" "$PATH"', 'check-profile', str(profile)],
                                            env=fixture.env, capture_output=True, text=True, timeout=10)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(result.stdout.split(os.pathsep).count(str(fixture.prefix / 'bin')), 1)
                finally:
                    fixture.close()

    def test_no_modify_path_preserves_existing_shell_files(self):
        before = {}
        for name in ('.profile', '.bashrc', '.zshrc', '.zprofile'):
            path = self.fixture.home / name
            write_file(path, '# keep ' + name + '\n')
            before[name] = path.read_bytes()
        self.install_ok('--no-modify-path')
        self.assertEqual({name: (self.fixture.home / name).read_bytes() for name in before}, before)

    def test_existing_user_commands_outside_the_prefix_are_untouched(self):
        outside = self.fixture.home / '.local/bin/aesir-tui'
        write_file(outside, '#!/bin/sh\nprintf existing\n', executable=True)
        original = outside.read_bytes()
        self.install_ok('--no-modify-path')
        self.assertEqual(outside.read_bytes(), original)

    def test_unknown_prefix_alias_conflict_fails_without_replacing_it(self):
        conflict = self.fixture.prefix / 'bin/aesir-tui'
        write_file(conflict, '#!/bin/sh\nprintf user-owned\n', executable=True)
        before = tree_snapshot(self.fixture.prefix)
        result = self.fixture.install('--no-modify-path')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(tree_snapshot(self.fixture.prefix), before)

    def test_second_install_refuses_an_active_prefix_lock(self):
        ready, release = self.fixture.root / 'download-ready', self.fixture.root / 'download-release'
        env = {**self.fixture.env, 'FIXTURE_CURL_READY': str(ready), 'FIXTURE_CURL_RELEASE': str(release)}
        first = subprocess.Popen(self.fixture.command('--prefix', str(self.fixture.prefix), '--no-modify-path'),
                                 cwd=self.fixture.workspace, env=env, stdin=subprocess.DEVNULL,
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, start_new_session=True)
        output = None
        try:
            deadline = time.monotonic() + 20
            while not ready.exists():
                if first.poll() is not None:
                    output = first.communicate(timeout=5)
                    self.fail('First installer exited before its download barrier: ' + ''.join(output))
                if time.monotonic() > deadline:
                    self.fail('First installer did not reach the owned download barrier')
                time.sleep(.01)
            requests_before = self.fixture.requests()
            second = self.fixture.install('--no-modify-path', timeout=15)
            self.assertNotEqual(second.returncode, 0, second.stdout + second.stderr)
            self.assertRegex(second.stdout + second.stderr, r'(?i)lock|another|progress|busy')
            self.assertEqual(self.fixture.requests(), requests_before, 'Second installer fetched before refusing the lock')
        finally:
            release.touch()
            try:
                output = first.communicate(timeout=60)
            except subprocess.TimeoutExpired:
                os.killpg(first.pid, signal.SIGKILL)
                first.communicate(timeout=5)
                raise
        self.assertEqual(first.returncode, 0, ''.join(output or ()))
        self.assertEqual(list(self.fixture.temp.iterdir()), [])
        self.install_ok('--no-modify-path')

    def test_unsupported_platform_fails_before_downloading(self):
        for system, machine in [('FreeBSD', 'x86_64'), ('Linux', 'mips64')]:
            with self.subTest(system=system, machine=machine):
                env = {**self.fixture.env, 'FIXTURE_SYSTEM': system, 'FIXTURE_MACHINE': machine}
                result = self.fixture.install('--no-modify-path', env=env)
                self.assertNotEqual(result.returncode, 0)
                self.assertRegex(result.stdout + result.stderr, r'(?i)unsupported|supported (systems|architectures)')
        self.assertEqual(self.fixture.requests(), [])

    def test_relative_prefix_is_rejected(self):
        result = self.fixture.install('--prefix', 'relative-prefix', '--no-modify-path', use_prefix=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.fixture.workspace / 'relative-prefix').exists())

    def test_prefix_with_path_separator_or_line_break_is_rejected_before_activation(self):
        for name in ('colon:prefix', 'newline\nprefix', 'carriage\rprefix'):
            with self.subTest(prefix=name):
                prefix = self.fixture.root / name
                result = self.fixture.install('--prefix', str(prefix), '--no-modify-path', use_prefix=False)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertFalse((prefix / 'current').exists(), 'Invalid PATH entry was activated')


class InstallerHelpTests(unittest.TestCase):
    def test_help_documents_the_public_options(self):
        with tempfile.TemporaryDirectory(prefix='aesir-installer-help-') as folder:
            env = clean_environment(Path(folder))
            env.update(HOME=folder, PATH='/usr/bin:/bin', SHELL='/bin/sh', TMPDIR=folder)
            result = subprocess.run(['/bin/sh', str(INSTALLER), '--help'], env=env, stdin=subprocess.DEVNULL,
                                    capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        for option in ('--version', '--prefix', '--client-only', '--no-modify-path'):
            self.assertIn(option, result.stdout)


if __name__ == '__main__':
    unittest.main()
