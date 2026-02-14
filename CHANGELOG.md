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
