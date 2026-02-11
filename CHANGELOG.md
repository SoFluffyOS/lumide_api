# 0.2.0

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
