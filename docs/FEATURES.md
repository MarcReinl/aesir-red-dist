# Features and current state

Use AESIR Red in the graphical Desktop app or the standalone TUI in your terminal. Each installs its engine automatically. The optional AESIR Term app provides a dedicated terminal for the TUI. [Get started](INSTALL.md) or read the [release notes](RELEASES.md).

## AESIR Red Desktop

Desktop brings the agent, conversations and workspaces into a native window, with its engine and document tools included. It supports streaming responses, model/provider settings, tool approvals, files and deliverables, skills, plugins, persistent terminals and delegated agents. Available capabilities depend on the selected preset and configuration.

Recent work includes:

- **Visible browser tools.** Desktop agents can open pages in the right sidebar, inspect page text, click, type, scroll and take screenshots while you watch the same page. An agent controls its own tabs, and its conversation must be selected. Web's iframe browser remains user-operated.
- **Workspace navigation.** Grouped, flat and workspace-tree views, session search, pinning, ordering, rename, completed-turn forks and archiving. Registering a directory gives conversations a workspace; deleting its registration retains its files and conversations.
- **Updated interface.** Neutral light/dark surfaces with a red accent, smoother panel transitions and transcript layout improvements.
- **OSINT guidance.** Dedicated skills cover investigation planning, evidence logs, public-source collection, Kali infrastructure and username tools, SpiderFoot, image metadata, reverse image search, analysis and reporting. They provide guidance; they do not install the external tools.
- **Security assessment workflows.** Pentest skills organize engagement setup, discovery, triage and evidence capture into recorded phases. The new LLM Security preset adds system mapping, prompt-injection and guardrail evaluation, tool-abuse and data-exposure checks, and reproducible findings for authorized assessments.
- **Built-in security presets.** Desktop includes the updated Pentest, OSINT, Reporting, Security Code Review, Pentest Assistant and LLM Security instructions and skill guidance. No separate local preset overlay is required.
- **Native TUI handoff.** A compatible TUI can open its exact running conversation in another native Desktop workspace window. Existing Desktop windows retain their connections and work. See [handoff setup](INSTALL.md#move-from-tui-to-desktop) and [advanced limits](ADVANCED.md#desktop-handoff-technical-details).

The optional experimental decision layer remains disabled by default. It uses a separately configured decision backend for bounded tasks such as selection, ranking and progress assessment; installing this release does not enable it. The default application also leaves account sign-in and scheduled-task capabilities disabled.

## Official AESIR Red TUI

The TUI is a full-screen terminal application, launched as `aesir-tui` or `aesir`. The curl installer supplies the engine and dependencies automatically; Desktop is optional. It provides conversations, model settings, credentials, tools and plugins on macOS Apple Silicon/Intel and Linux ARM64/x86-64.

Its dedicated menus cover conversation/workspace navigation, provider and model setup, reasoning effort, permissions, skills, plugins, configuration, files and persistent terminals. It streams Markdown and code blocks, pairs tool calls with readable results, shows approvals and structured questions, and supports queued and steering messages.

Delegated conversations have live activity and navigation controls. Files can be referenced from your project or attached from the local machine; clipboard images and completed-code copying are available with the OS clipboard helpers. Local drafts, prompt history and optional animated companions are client preferences. `/desktop` transfers the current local conversation to a compatible native Desktop window after it confirms the requested session is open.

Browser pages and documents open in an external viewer or a native Desktop window. [Advanced setup](ADVANCED.md) covers existing engine connections and configuration-specific capabilities.

## AESIR Term

AESIR Term is an optional dedicated terminal application for macOS and Debian-family Linux. Its agent pane launches the AESIR Red TUI, and its Conversations view resumes AESIR sessions. It also includes projects, notebooks, search, a command palette and shell extras. Install the TUI with the curl command, then open the agent pane with Cmd+I on macOS or Ctrl+Alt+I on Linux. Ordinary terminal use does not require the TUI or a model provider. [Install AESIR Term](INSTALL.md#aesir-term).

## Release limits

This is a release candidate. Check the selected release's notes for final artifact and qualification status.

- The coordinated targets are macOS ARM64/Intel and Linux ARM64/x86-64. No native Windows artifacts are supplied by this release. WSL is not a separately qualified target.
- The normal Desktop and TUI installations include their engines. Custom and client-only installations are [advanced options](ADVANCED.md).
- Desktop provides native browser automation. Installing Desktop does not add model-facing browser tools to an existing TUI conversation; its configured engine determines those tools.
- Browser guest downloads, permission prompts and native popups are restricted. Screenshot use also depends on an image-capable model.
- TUI-to-Desktop handoff currently supports local macOS/Linux conversations. Linux needs an unpacked Desktop directory with `AESIR_DESKTOP_PATH` pointing to its executable; the AppImage alone is insufficient. Remote Hosts, reverse-proxy mounts and Windows are unsupported.
- Replacement Desktop/Host builds distinguish native ARM64 execution from translated x64 execution. The portable TUI has separate installation checks for each target and Node version; see [qualification coverage](RELEASES.md#verification-and-compatibility). Other Linux distributions and libc variants need their own qualification.
- API availability is pre-stable. Read [advanced compatibility guidance](ADVANCED.md) before changing a separately managed engine used by existing clients.
