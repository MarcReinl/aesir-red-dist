# Features and current state

AESIR Red offers a graphical Desktop application and an official TUI over the same Host APIs. AESIR Term provides a dedicated terminal environment with a TUI agent pane. [Installation](INSTALL.md) explains these setups.

## AESIR Red Desktop

Desktop brings the agent, conversations and workspaces into a native window, with bundled runtimes for startup and document work. It supports streaming responses, model/provider settings, tool approvals, files and deliverables, skills, plugins, persistent terminals and delegated agents. Capabilities depend on the active Host profile and preset.

Recent work includes:

- **Visible browser tools.** Desktop agents can open pages in the right sidebar, inspect page text, click, type, scroll and take screenshots while you watch the same page. An agent controls its own tabs, and its conversation must be selected. Web's iframe browser remains user-operated.
- **Workspace navigation.** Grouped, flat and workspace-tree views, session search, pinning, ordering, rename, completed-turn forks and archiving. Registering a directory gives conversations a workspace; deleting its registration retains its files and conversations.
- **Updated interface.** Neutral light/dark surfaces with a red accent, smoother panel transitions and transcript layout improvements.
- **OSINT guidance.** Dedicated skills cover investigation planning, evidence logs, public-source collection, Kali infrastructure and username tools, SpiderFoot, image metadata, reverse image search, analysis and reporting. They provide guidance; they do not install the external tools.
- **Security assessment workflows.** Pentest skills organize engagement setup, discovery, triage and evidence capture into recorded phases. The new LLM Security preset adds system mapping, prompt-injection and guardrail evaluation, tool-abuse and data-exposure checks, and reproducible findings for authorized assessments.
- **Native TUI handoff.** A compatible TUI can open its exact running conversation in a Desktop window attached to the same local Host.

The optional experimental decision layer remains disabled by default. It uses a separately configured decision backend for bounded tasks such as selection, ranking and progress assessment; installing this release does not enable it. The default application also leaves account sign-in and scheduled-task capabilities disabled.

## Official AESIR Red TUI

The TUI is a full-screen terminal application, launched as `aesir-tui` or `aesir`. It uses a compatible Host's sessions, settings, credentials, tools and plugins. The same portable package serves macOS Apple Silicon/Intel and Linux ARM64/x86-64.

Its dedicated menus cover conversation/workspace navigation, provider and model setup, reasoning effort, permissions, skills, plugins, configuration, files and persistent terminals. It streams Markdown and code blocks, pairs tool calls with readable results, shows approvals and structured questions, and supports queued and steering messages.

Delegated conversations have live activity and navigation controls. Files can be referenced from the Host workspace or attached from the local machine; clipboard images and completed-code copying are available with the OS clipboard helpers. Local drafts, prompt history and optional animated companions are client preferences. `/desktop` transfers the current local conversation to a compatible native Desktop window after it confirms the requested session is open.

The TUI's advanced operation browser exposes the generated Host API catalog. An operation being listed does not mean every Host profile enables its capability. Browser pages and document viewers open through explicit external/native actions; graphical widgets do not render inside the terminal.

## AESIR Term

AESIR Term is a kitty-based terminal emulator with its own settings and component version. It adds resizable split panes, pane navigation, a command palette, right-click actions and themes. Its Tools panel offers project browsing, file-content search and Markdown notebooks with explicit command execution. Shell additions provide zsh command coloring, selection, completion menus and prompt status.

The agent pane launches the separately installed **AESIR Red TUI**, using its configured Host, models, credentials and permissions. It follows the active shell's working directory and reopens selected AESIR Host conversations. The Conversations view reads the Host catalog through the TUI without sending a model request. The launcher recognizes the previous stock OpenCode command during upgrades and uses the AESIR TUI instead; custom commands remain configurable.

Explain/fix is a separate optional overlay using an Ollama or API provider configured in Terminal settings. It shows the destination before sending command/output context and inserts a suggested command into the shell prompt for review. Ordinary terminal use does not require a model provider. AESIR Term is GPL-3.0 and carries kitty and bundled-component attribution.

## Release limits

This is a release candidate. Check the selected release's notes for final artifact and qualification status.

- The coordinated targets are macOS ARM64/Intel and Linux ARM64/x86-64. No native Windows artifacts are supplied by this release. WSL is not a separately qualified target.
- The TUI needs Node/npm and a Host; the Host archive carries its own runtime.
- AESIR Term does not bundle the TUI or Host. Its Linux delivery uses Debian packages requiring a graphical X11/Wayland session and OpenGL; Alpine/musl and 32-bit systems are unsupported.
- Desktop browser control requires the Electron-backed Desktop Host. A TUI-managed Web Host does not acquire that capability merely because Desktop is installed.
- Browser guest downloads, permission prompts and native popups are restricted. Screenshot use also depends on an image-capable model.
- TUI-to-Desktop handoff currently requires a compatible local macOS/Linux Host. Linux needs an unpacked Desktop directory with `AESIR_DESKTOP_PATH` pointing to its executable; the AppImage alone is insufficient. Remote Hosts, reverse-proxy mounts and Windows are unsupported.
- Linux TUI installation is qualified on Ubuntu 24.04. Other distributions and libc variants need their own qualification.
- API availability is pre-stable. Keep coordinated components together and read the release notes before upgrading a Host that serves existing clients.
