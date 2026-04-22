# 1.2.0

✨ This release introduces the first public Debug API for Lumide plugins, including host-controlled sessions, breakpoints, stack inspection, variable loading, and exception pause mode support.

### New features

- **Debug API** — Added `context.debug` for starting, updating, and ending debug sessions from plugins.
- **Session State** — Added `LumideDebugSession`, `LumideDebugSessionState`, and `LumideDebugCapabilities` for describing debugger state and supported actions.
- **Breakpoint Sync** — Added `LumideDebugBreakpoint`, `updateBreakpoints`, and `onSetBreakpoints` for bidirectional breakpoint synchronization.
- **Stack / Scope / Variable Inspection** — Added `LumideDebugStackFrame`, `LumideDebugScope`, `LumideDebugVariable`, `onGetStackFrames`, `onGetScopes`, and `onGetVariables`.
- **Expression Evaluation** — Added `LumideDebugEvaluationResult` and `onEvaluate`.
- **Exception Filters** — Added `LumideDebugExceptionPauseMode` and `onSetExceptionPauseMode`.
- **Output Integration** — `LumideDebugSession.outputChannelId` can now bind a debug session to an existing output channel, so plugins can reuse one log stream in both Output and Debug surfaces.
- **Expandable Variables** — `LumideDebugVariable.variablesReference` and `LumideDebugEvaluationResult.variablesReference` now support lazy child-variable loading.

# 1.1.0

✨ This release introduces significant enhancements to the Languages API, including custom LSP requests and inline completion support, alongside new window and workspace capabilities.

### New features

- **Languages API** — Support for registering inline completion providers via `languages.registerInlineCompletionProvider`.
- **Custom LSP Requests** — Added `languages.sendLspRequest` to send non-standard JSON-RPC requests to active language servers.
- **Enhanced LSP Registration** — `languages.registerLanguageServer` now supports optional `icon`, `iconPath`, and authentication callbacks (`checkStatus`, `signIn`, `signOut`).
- **Window API** — Added `window.showDeviceAuthDialog` to streamline OAuth and device-based authentication flows for plugins.
- **Workspace Configuration** — Support for programmatically updating workspace settings via `workspace.updateConfiguration`.

# 1.0.0

🦊 Initial stable release for `lumide_api`. The API is now mostly feature-complete for Language Server Protocol (LSP) integrations and core editor extensions.

### New features

- **Languages API** — Added `languages.registerLanguageServer` to register custom Language Server Protocol (LSP) providers for specific file extensions.
- **FileSystem API** — Added `fs.downloadFile` to download files natively from the IDE with built-in progress tracking and optional `.tar.gz`/`.zip` extraction.

# 0.9.0

### New features

- **Quick Pick Improvements** — `QuickPickItem` now supports a `tooltip` field for rendering rich hover tooltips on individual options.

# 0.8.0

### New features

- **Workspace** — `getRootUri()` to get the workspace root path, `findFiles(glob)` to search files by glob pattern.
- **FileSystem** — `isDirectory(path)` to check if a path is a directory.
- **Editor** — `getDocumentText(uri)` to read open document content, `openDocument(uri)` to open files, `revealRange()` to navigate to a specific location.
- **Window** — `showConfirmDialog(message)` for OK/Cancel dialogs, `title` parameter on `showMessage()`.
- **Shell** — `workingDirectory` parameter on `run()` to execute commands in a specific directory.

# 0.7.1

### Improvements

- **Plugin lifecycle** — `LumidePlugin.run()` now guarantees `onDeactivate()` is called even when the host IDE crashes or the stdio pipe breaks unexpectedly. This prevents orphaned child processes from plugins that spawn external processes.

# 0.7.0

### New features

- **Theming system** — Support contributing color themes and icon themes via `contributes.themes` and `contributes.iconThemes` in `plugin.yaml`.
- **Manifest improvements** — Added `copyWith` to `LumideManifest` for easier state modification.

# 0.6.0

### New features

- **WebViews** — Create and manage custom UI panels via `window.createWebviewPanel`.
- **URL Opening** — Open external URLs via `window.openUrl`.
- **Output Control** — Added `LumideOutputChannel.clear()` to clear logs programmatically.

# 0.5.0

### New features

- **Activation Events** — `LumideManifest` now supports `activation_events` to control plugin loading (e.g., `onCommand`, `workspaceContains`).
- **Quick Pick Icons** — `QuickPickItem` now supports `iconPath` (SVG/Image), `enabled` state, and `isSeparator`.
- **Status Bar Icons** — `LumideStatusBar` items now support `iconPath` for rendering SVGs.
- **Toolbar Icons** — `LumideToolbar` items now support `iconPath` for rendering SVGs.

# 0.4.0

### New features

- **Structured Logging** — `LumideOutputChannel.appendLog` allows appending structured log records (`LumideLogRecord`) with levels, error details, and stack traces.

# 0.3.0

### New features

- **Toolbar API** — Register items in the top toolbar via `LumideToolbar`. Supports icons, tooltips, alignment, and priority.
- **Terminal API** — Create, control, and interact with integrated terminals via `LumideTerminal`.
- **Output API** — Create and write to output channels via `LumideOutputChannel`.
- **Editor Selection API** — `getSelectedText` and `replaceSelection` for easier text manipulation.
- **Quick Pick Improvements** — `showQuickPick` now supports rich `QuickPickItem` objects with descriptions, details, and icons.
- **Window Positioning** — `showQuickPick` accepts an optional anchor position.

### Breaking changes

- **Commands API** — `LumideCommands.registerCommand` callback now accepts an optional `Map<String, dynamic>? args` parameter. Existing callbacks must be updated.

# 0.2.0+1

### New features

- **Commands API** — Register commands for the Command Palette via `LumideCommands.registerCommand()`.
- **Keybindings** — Declare keybindings in `plugin.yaml` under `contributes.keybindings`.
- **Status Bar API** — Create, update, show/hide, and dispose status bar items via `LumideStatusBar`.
- **Editor events** — `editor.onDidChangeSelections` and `editor.onDidChangeActiveDocument` push selection and focus changes to plugins.
- **Workspace events** — `workspace.onDidSaveTextDocument` notifies when a document is saved.

### Breaking changes

- `workspace/onDidChangeConfiguration` is now a host-to-plugin method (was previously plugin-to-IDE). Plugins receive configuration updates passively instead of polling.

# 0.1.0

- Initial public release of the Lumide Plugin SDK.
- Support for core plugin lifecycle management (`onActivate`, `onDeactivate`).
- **FileSystem API**: Generic file/directory operations (read, write, list, exists).
- **Editor API**: Active document tracking, text insertion, selection management, and range replacement.
- **Workspace API**: Configuration management and document event listeners (open, close, change).
- **Window API**: UI interaction methods (showMessage, showQuickPick, showInputBox).
- **Shell API**: Controlled execution of host shell commands.
- **HTTP API**: Standardized network requests (GET, POST).
- Comprehensive JSON-RPC 2.0 based communication layer.
