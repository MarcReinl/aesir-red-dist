# TUI Curl Installer Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Publish a tested one-command TUI installer for macOS/Linux ARM64 and x64.

**Architecture:** A POSIX shell bootstrap downloads checksummed coordinated release assets into a private user prefix. A small launcher uses the released TUI's connection helpers, preserving explicit and saved connections while making the bundled Host available for a fresh standalone installation. Activation changes one current-version pointer after validation.

**Tech Stack:** POSIX sh, curl, tar, SHA-256 utilities, bundled Node/npm; Python standard-library tests and native GitHub Actions runners.

---

### Task 1: Regression tests

Create `tests/test_installer.py` with offline release fixtures and isolated HOME/PATH. Run it before creating `install-tui.sh`; confirm installation fails because the installer is absent. Cover platform selection, private runtime execution, aliases, connection precedence, repeat installation, PATH setup, spaces, failed checksums/npm, conflicting commands and concurrent-prefix protection. Tests must inspect resulting files and behavior rather than copy installer decisions.

### Task 2: Installer and launcher

Create `install-tui.sh`. Options: `--version VERSION`, `--prefix ABSOLUTE_DIRECTORY`, `--client-only`, `--no-modify-path`, `--help`. Default prefix is `${XDG_DATA_HOME:-$HOME/.local/share}/aesir-cli`; aliases live in its `bin` subdirectory. Support the four released target names and validate exact checksum entries. Use the bundled runtime for full installs and existing Node/npm for client-only mode. Keep bootstrap and launcher templates inside the script so the public entry point is a single file. Use the installed TUI's `loadPreferences`/`selectConnection` helpers and stable `current/runtime/bin/aesir` for a fresh managed selection. Run regression tests and shell syntax checks, then review the diff.

### Task 3: Live public artifact smoke and CI

Create `tests/live_install.sh`, using a disposable HOME, prefix and workspace, with inherited Host/model credentials removed. Install actual public artifacts through the script, verify both aliases and the generated catalog, and run the keyless Host smoke with folder trust scoped to that workspace. Check teardown. Create `.github/workflows/test-installer.yml` for native macOS ARM64/Intel and Ubuntu 24.04 ARM64/x64. Run the local live smoke once after regressions pass. Do not claim foreign targets passed until their jobs finish.

### Task 4: Public instructions and delivery

Update `README.md` and `docs/INSTALL.md` with the curl command first, flags, PATH/restart behavior, prerequisites, updates and removal. Retain the manual archive route and explain that installation does not implement automatic Desktop Host discovery. Review checksum/download/activation safety and run the relevant checks. Commit the implementation, publish to the already-authorized public distribution repository after checking remote movement, retrieve the served installer, and verify its exact bytes and public command. Do not modify frozen RC.3 binary assets or the private source checkouts.
