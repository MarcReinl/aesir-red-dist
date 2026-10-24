#!/usr/bin/env python3
"""Install public release assets without system Node and probe the bundled Host."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import signal
import subprocess
import tempfile
import time


PUBLIC_INSTALLER = "https://raw.githubusercontent.com/MarcReinl/aesir-red-dist/main/install-tui.sh"


def run(command, *, env, cwd, timeout=240):
    process = subprocess.Popen(
        command, env=env, cwd=cwd, text=True, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, start_new_session=True,
    )
    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        process.send_signal(signal.SIGTERM)
        try:
            stdout, stderr = process.communicate(timeout=30)
        except subprocess.TimeoutExpired:
            process.kill()
            stdout, stderr = process.communicate()
        raise RuntimeError(f"Timed out: {command[0]}\n{stdout}\n{stderr}") from None
    if process.returncode:
        raise RuntimeError(f"Exit {process.returncode}: {command[0]}\n{stdout}\n{stderr}")
    return stdout


def owned_processes(prefix):
    result = subprocess.run(
        ["/bin/ps", "-axo", "pid=,args="], text=True,
        capture_output=True, check=True,
    )
    return [int(line.split(None, 1)[0]) for line in result.stdout.splitlines()
            if str(prefix) in line]


def runtime_inventory(root):
    """Compare installed runtime bytes and links with a qualified archive extraction."""
    inventory = {}
    for path in root.rglob("*"):
        name = str(path.relative_to(root))
        if path.is_symlink():
            inventory[name] = ("link", os.readlink(path))
        elif path.is_file():
            with path.open("rb") as source:
                inventory[name] = ("file", hashlib.file_digest(source, "sha256").hexdigest())
    return inventory


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--target", choices=("darwin-arm64", "darwin-x64", "linux-arm64", "linux-x64"))
    parser.add_argument("--expected-host-root", type=Path, help="Qualified Host extraction to compare with both public installations.")
    parser.add_argument("--expected-harness-revision", help="Required installed TUI catalog source revision.")
    options = parser.parse_args()
    expected_runtime = runtime_inventory(options.expected_host_root) if options.expected_host_root else None
    architecture = {"arm64": "arm64", "aarch64": "arm64", "x86_64": "x64", "amd64": "x64"}[platform.machine().lower()]
    target = platform.system().lower() + "-" + architecture
    if options.target and options.target != target:
        raise RuntimeError(f"Expected native {options.target}, running {target}")
    installer = Path(__file__).resolve().parents[1] / "install-tui.sh"
    installer_sha256 = hashlib.sha256(installer.read_bytes()).hexdigest()
    root = Path(tempfile.mkdtemp(prefix="aesir-installer-live-"))
    home = root / "home"
    workspace = root / "workspace"
    temporary = root / "tmp"
    for directory in (home, workspace, temporary):
        directory.mkdir(mode=0o700)
    prefix = home / "installation with spaces"
    env = {
        "HOME": str(home), "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
        "SHELL": "/bin/sh", "TERM": "xterm-256color", "LANG": "en_US.UTF-8",
        "TMPDIR": str(temporary), "XDG_CONFIG_HOME": str(home / ".config"),
        "XDG_DATA_HOME": str(home / ".local/share"),
        "XDG_CACHE_HOME": str(home / ".cache"),
        "DSH_HOME": str(home / "harness-data"), "DSH_TELEMETRY_MODE": "DISABLED",
    }
    assert shutil.which("node", path=env["PATH"]) is None, "This smoke requires a PATH without system Node"
    assert shutil.which("npm", path=env["PATH"]) is None, "This smoke requires a PATH without system npm"
    passed = False
    try:
        downloaded_installer = root / "install-tui.sh"
        run(["/usr/bin/curl", "--fail", "--silent", "--show-error", "--location",
             "--proto", "=https", "--proto-redir", "=https", "--output",
             str(downloaded_installer), PUBLIC_INSTALLER], env=env, cwd=workspace)
        assert hashlib.sha256(downloaded_installer.read_bytes()).hexdigest() == installer_sha256, "Public installer differs from the reviewed file"
        print("Installing actual public assets with system Node/npm absent from PATH…", flush=True)
        install_output = run(
            ["/bin/sh", str(downloaded_installer), "--prefix", str(prefix), "--no-modify-path"],
            env=env, cwd=workspace, timeout=1200,
        )
        print(install_output, flush=True)
        binary = prefix / "bin/aesir"
        alias = prefix / "bin/aesir-tui"
        version = run([str(binary), "--version"], env=env, cwd=workspace).strip()
        assert "aesir-red-tui 0.2.0-rc.3" in version, version
        assert run([str(alias), "--version"], env=env, cwd=workspace).strip() == version
        catalog = run([str(binary), "--list-operations"], env=env, cwd=workspace)
        assert "session/list(" in catalog and len(catalog.splitlines()) == 141
        previous_install = (prefix / "current").resolve(strict=True)
        if expected_runtime is not None:
            assert expected_runtime and runtime_inventory(previous_install / "runtime") == expected_runtime, "Public runtime differs from qualified archive"
        previous_inventory = runtime_inventory(previous_install)
        preserved_data = home / "harness-data/reinstall-marker"
        preserved_data.parent.mkdir(parents=True, exist_ok=True)
        preserved_data.write_text("preserve existing session data\n")
        print("Repeating the same-version public installation…", flush=True)
        run(["/bin/sh", str(downloaded_installer), "--prefix", str(prefix), "--no-modify-path"],
            env=env, cwd=workspace, timeout=1200)
        assert (prefix / "current").resolve(strict=True) != previous_install, "Same-version install did not activate a fresh directory"
        active_install = (prefix / "current").resolve(strict=True)
        if expected_runtime is not None:
            assert runtime_inventory(active_install / "runtime") == expected_runtime, "Repeated public install differs from qualified runtime"
        installed_catalog = json.loads((active_install / "client/lib/node_modules/@aesir-red/tui-client/dist/generated/catalog.json").read_text())
        catalog_revision = installed_catalog["metadata"]["sourceRevision"]
        if options.expected_harness_revision:
            assert catalog_revision == options.expected_harness_revision, "Public TUI catalog describes a different Host revision"
        assert runtime_inventory(previous_install) == previous_inventory, "Reinstall changed the previous installation"
        assert preserved_data.read_text() == "preserve existing session data\n", "Reinstall changed user data"
        assert run([str(binary), "--version"], env=env, cwd=workspace).strip() == version
        print("Installed aliases and 141 catalog endpoints verified; probing local Host…", flush=True)
        report = json.loads(run(
            [str(binary), "--trust-folder", "--cwd", str(workspace), "--smoke"],
            env=env, cwd=workspace,
        ))
        assert report["connected"] and report["catalogEndpoints"] == 141, report
        for category in ("sessions", "settings", "permissions", "presets"):
            assert report[category]["ok"], report
        deadline = time.monotonic() + 10
        remaining = owned_processes(prefix)
        while remaining and time.monotonic() < deadline:
            time.sleep(0.05)
            remaining = owned_processes(prefix)
        assert not remaining, f"Installed test processes survived CLI shutdown: {remaining}"
        assert not (home / ".config/aesir-red-tui/client.json").exists(), "Read-only smoke saved preferences"
        assert not (home / ".profile").exists(), "--no-modify-path changed shell startup"
        assert hashlib.sha256(installer.read_bytes()).hexdigest() == installer_sha256, "Installer changed during the smoke"
        result = {"status": "passed", "target": target,
                  "publicInstallerUrl": PUBLIC_INSTALLER,
                  "installerSha256": installer_sha256,
                  "version": version, "catalogEndpoints": 141, "hostSmoke": report,
                  "ownedProcessesAfterExit": [], "systemNodeRequired": False,
                  "sameVersionReinstall": "passed", "previousInstallationPreserved": True,
                  "userDataPreserved": True, "catalogHarnessRevision": catalog_revision,
                  "qualifiedRuntimeInventoryMatched": expected_runtime is not None,
                  "runtimeInventoryEntries": len(expected_runtime) if expected_runtime is not None else None}
        if options.report:
            options.report.parent.mkdir(parents=True, exist_ok=True)
            options.report.write_text(json.dumps(result, indent=2) + "\n")
        print(json.dumps(result, indent=2), flush=True)
        passed = True
    finally:
        if passed:
            shutil.rmtree(root)
        else:
            print(f"Failed test files preserved at {root}", flush=True)


if __name__ == "__main__":
    main()
