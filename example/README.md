# Lumide Demo Plugin

A reference plugin showcasing **every** Lumide Plugin API. Use this as a starting point when building your own plugin.

---

## Quick Start

### 1. Create the project

```bash
mkdir my_plugin && cd my_plugin
dart create -t console .
```

### 2. Add the SDK dependency

```yaml
# pubspec.yaml
dependencies:
  lumide_api:
    path: ../../pub_packages/lumide_api  # or a published version
```

### 3. Create `plugin.yaml`

```yaml
id: my_plugin                    # unique identifier
name: 'My Plugin'
description: 'What the plugin does.'
version: '0.1.0'
author: 'Your Name'
license: 'MIT'
entry_point: 'bin/main.dart'     # relative to plugin root

permissions:
  - fileSystem:
      - '${workspace}/**'       # read/write workspace files
  - network:
      - 'https://api.example.com/*'
  - shell:
      - echo
      - git

configuration:                   # shown in Settings → Plugins
  - key: my_plugin.maxResults
    type: integer
    description: 'Maximum results to show.'
    default: 10

contributes:                     # commands & keybindings
  commands:
    - id: my_plugin.doSomething
      title: 'My Plugin: Do Something'
      category: 'My Plugin'
  keybindings:
    - command: my_plugin.doSomething
      key: 'ctrl+shift+d'
```

### 4. Write `bin/main.dart`

```dart
import 'package:lumide_api/lumide_api.dart';

void main() => MyPlugin().run();

class MyPlugin extends LumidePlugin {
  @override
  Future<void> onActivate(LumideContext context) async {
    log('Plugin activated!');
    final uri = await context.editor.getActiveDocumentUri();
    log('Active file: $uri');

    // Register a command
    await context.commands.registerCommand(
      id: 'my_plugin.doSomething',
      title: 'My Plugin: Do Something',
      callback: () async {
        await context.window.showMessage('Doing something!');
      },
    );

    // Show a status bar item
    await context.statusBar.createItem(
      id: 'status',
      text: '✅ My Plugin',
      tooltip: 'My Plugin is running',
      alignment: 'left',
    );
  }

  @override
  Future<void> onDeactivate() async {
    log('Plugin deactivated');
  }
}
```

### 5. Load in Lumide

Open Lumide → **Plugins pane** (sidebar) → **Load Local Plugin** → select your plugin directory.

---

## Plugin Lifecycle

```
IDE starts plugin process (dart run bin/main.dart)
         │
         ▼
   ┌─────────────┐
   │  initialize  │  ← IDE sends JSON-RPC "initialize" request
   └──────┬──────┘
          │
          ▼
   ┌─────────────┐
   │  onActivate  │  ← your setup code runs here
   └──────┬──────┘
          │
          ▼
     Plugin runs...  ← respond to events, make API calls
          │
          ▼
   ┌─────────────┐
   │  onDeactivate│  ← cleanup (cancel timers, close streams)
   └──────┬──────┘
          │
          ▼
   ┌─────────────┐
   │   shutdown   │  ← process exits
   └─────────────┘
```

> **Important:** `stdout` is reserved for JSON-RPC communication. Use `log()` (writes to `stderr`) for all debug output.

---

## API Reference

All APIs are accessed through the `LumideContext` passed to `onActivate`.

### Editor — `context.editor`

| Method | Description |
|--------|-------------|
| `getActiveDocumentUri()` | Returns the URI of the currently focused file, or `null` |
| `insertText(String text)` | Inserts text at the current cursor position |
| `replaceText({startLine, startColumn, endLine, endColumn, newText})` | Replaces text in a line/column range |
| `getSelections()` | Returns all cursors/selections as `[{anchor: {line, column}, focus: {line, column}}]` |
| `setSelections(List<Map>)` | Sets the editor's cursors/selections |
| `onDidChangeSelections(callback)` | Called when cursor/selection position changes |
| `onDidChangeActiveDocument(callback)` | Called when the user switches to a different file |

```dart
// Get cursor position
final selections = await context.editor.getSelections();
for (final sel in selections) {
  final focus = sel['focus'] as Map<String, dynamic>;
  log('Cursor at line ${focus['line']}, column ${focus['column']}');
}

// React to cursor changes instantly
context.editor.onDidChangeSelections((selections) {
  final focus = selections.first['focus'] as Map<String, dynamic>;
  log('Cursor moved to L${focus['line']}:${focus['column']}');
});

// React to file switches
context.editor.onDidChangeActiveDocument((uri) {
  log('Switched to: $uri');
});
```

---

### File System — `context.fs`

| Method | Description |
|--------|-------------|
| `readString(String path)` | Reads a file as UTF-8 string |
| `writeString(String path, String content)` | Writes a string to a file |
| `exists(String path)` | Returns `true` if the path exists |
| `list(String path)` | Lists directory contents as `List<String>` |

```dart
final content = await context.fs.readString('/path/to/file.dart');
await context.fs.writeString('/path/to/output.txt', 'result');
```

> Requires `fileSystem` permission in `plugin.yaml`. Paths outside declared globs are rejected.

---

### Window — `context.window`

| Method | Description |
|--------|-------------|
| `showMessage(String msg, {MessageType type})` | Shows a toast/notification |
| `showQuickPick(List<String> items, {String? placeholder})` | Shows a selection dialog, returns chosen item or `null` |
| `showInputBox({String? prompt, String? value})` | Shows a text input dialog, returns entered text or `null` |

```dart
await context.window.showMessage('Build succeeded! ✅');

final choice = await context.window.showQuickPick(
  ['Format', 'Lint', 'Test'],
  placeholder: 'Choose an action...',
);
if (choice == 'Format') { /* ... */ }
```

---

### Shell — `context.shell`

| Method | Description |
|--------|-------------|
| `run(String command, List<String> args)` | Runs a command, returns `ProcessResult` with `exitCode`, `stdout`, `stderr` |

```dart
final result = await context.shell.run('git', ['status', '--short']);
log('Git output: ${result.stdout}');
```

> Requires `shell` permission. Only commands listed in the permission array are allowed.

---

### HTTP — `context.http`

| Method | Description |
|--------|-------------|
| `get(String url, {Map<String, String>? headers})` | HTTP GET, returns `HttpResponse` |
| `post(String url, {Map<String, String>? headers, Object? body})` | HTTP POST, returns `HttpResponse` |

```dart
final resp = await context.http.get('https://api.example.com/data');
if (resp.statusCode == 200) {
  log('Body: ${resp.body}');
}
```

> Requires `network` permission. Only URLs matching declared patterns are allowed.

---

### Workspace — `context.workspace`

| Method | Description |
|--------|-------------|
| `getConfiguration(String key)` | Reads a plugin config value (falls back to manifest default) |
| `onDidOpenTextDocument(callback)` | Called when a file is opened in the editor |
| `onDidCloseTextDocument(callback)` | Called when a file tab is closed |
| `onDidChangeTextDocument(callback)` | Called when file content changes |
| `onDidChangeConfiguration(callback)` | Called when plugin settings change in the Settings UI |
| `onDidSaveTextDocument(callback)` | Called when a document is saved |

```dart
// Read config
final maxResults = await context.workspace.getConfiguration('my_plugin.maxResults');

// React to config changes in real-time
context.workspace.onDidChangeConfiguration((settings) {
  if (settings['my_plugin.maxResults'] case final int val) {
    log('maxResults changed to $val');
  }
});

// Listen for file events
context.workspace.onDidOpenTextDocument((uri) {
  log('Opened: $uri');
});

context.workspace.onDidChangeTextDocument((event) {
  log('Changed: ${event.uri} (${event.changes.length} edits)');
});

// Listen for saves (useful for WakaTime-style plugins)
context.workspace.onDidSaveTextDocument((uri) {
  log('Saved: $uri');
});
```

---

### Commands — `context.commands`

| Method | Description |
|--------|-------------|
| `registerCommand({id, title, category?, callback})` | Registers a command shown in the Command Palette (`Cmd+Shift+P`) |

```dart
await context.commands.registerCommand(
  id: 'my_plugin.formatCode',
  title: 'My Plugin: Format Code',
  category: 'My Plugin',
  callback: () async {
    // Run formatting logic
    await context.window.showMessage('Code formatted! ✅');
  },
);
```

Commands declared in `plugin.yaml` under `contributes.commands` appear in the Command Palette automatically. Keybindings from `contributes.keybindings` are registered when the plugin loads.

```yaml
contributes:
  commands:
    - id: my_plugin.formatCode
      title: 'My Plugin: Format Code'
      category: 'My Plugin'
  keybindings:
    - command: my_plugin.formatCode
      key: 'ctrl+shift+f'    # key format: "mod+mod+key"
```

---

### Status Bar — `context.statusBar`

| Method | Description |
|--------|-------------|
| `createItem({id, text, tooltip?, command?, color?, alignment?, priority?})` | Creates a status bar item |
| `updateItem(id, {text?, tooltip?, command?, color?})` | Updates properties of an existing item |
| `disposeItem(id)` | Removes an item from the status bar |
| `show(id)` | Shows a previously hidden item |
| `hide(id)` | Hides an item without removing it |

**Parameters:**
- `alignment`: `'left'` or `'right'` (default: `'right'`)
- `priority`: Higher values position the item further from center (default: `0`)
- `command`: Command ID to execute when the item is tapped
- `color`: Hex color string (e.g., `'#4CAF50'`)

```dart
// Create a status bar item (left side)
await context.statusBar.createItem(
  id: 'status',
  text: '✅ Ready',
  tooltip: 'My Plugin is ready',
  command: 'my_plugin.showInfo',  // runs on click
  alignment: 'left',
  priority: 10,
);

// Update the text dynamically
await context.statusBar.updateItem('status', text: '⏳ Working...');

// Hide temporarily
await context.statusBar.hide('status');

// Show again
await context.statusBar.show('status');

// Remove when no longer needed
await context.statusBar.disposeItem('status');
```

> Status bar items are automatically cleaned up when the plugin is stopped.

---

## Manifest Reference (`plugin.yaml`)

```yaml
# ─── Required ───────────────────────────────────────────────
id: unique_plugin_id          # must be unique across all plugins
name: 'Human-Readable Name'
description: 'One-line description.'
version: '1.0.0'             # semver
entry_point: 'bin/main.dart'  # relative path to main file

# ─── Optional ───────────────────────────────────────────────
author: 'Author Name'
license: 'MIT'

# ─── Permissions ────────────────────────────────────────────
permissions:
  - fileSystem:               # glob patterns for file access
      - '${workspace}/**'     # all files in workspace
      - '/tmp/my_plugin/**'   # specific external path
  - network:                  # URL patterns for HTTP access
      - 'https://api.example.com/*'
      - 'https://*.github.com/*'
  - shell:                    # allowed shell commands
      - git
      - dart
      - echo

# ─── Configuration ──────────────────────────────────────────
configuration:
  - key: my_plugin.settingName
    type: string              # string | boolean | integer | number | filePath
    description: 'What this setting controls.'
    default: 'default value'

  - key: my_plugin.enabled
    type: boolean
    description: 'Enable or disable the feature.'
    default: true

  - key: my_plugin.mode
    type: string
    description: 'Operating mode.'
    default: 'auto'
    enum:                     # renders as a dropdown in Settings UI
      - auto
      - manual
      - disabled

# ─── Contributions ──────────────────────────────────────────
contributes:
  commands:                   # appear in Command Palette (Cmd+Shift+P)
    - id: my_plugin.doThing
      title: 'My Plugin: Do Thing'
      category: 'My Plugin'  # optional, groups commands in palette

  keybindings:                # shortcut keys for commands
    - command: my_plugin.doThing
      key: 'ctrl+shift+d'    # format: "mod+mod+key"
```

---

## Tips & Best Practices

1. **Never write to `stdout`** — it's the JSON-RPC transport. Use `log()` instead.
2. **Dispose everything in `onDeactivate`** — cancel timers, close streams, release resources.
3. **Declare minimal permissions** — only request access to paths/commands you actually need.
4. **Use config defaults wisely** — the manifest `default` value is used when the user hasn't changed the setting.
5. **Handle errors gracefully** — wrap API calls in `try/catch` to avoid crashing the plugin process.
6. **Keep activation fast** — do heavy work asynchronously after `onActivate` returns.
7. **Declare commands in manifest** — commands in `contributes.commands` appear in the palette even before `registerCommand` runs.
8. **Clean up status bar items** — items are auto-cleaned on plugin stop, but dispose manually if you no longer need them.

---

## Project Structure

```
my_plugin/
├── bin/
│   └── main.dart          # entry point — extends LumidePlugin
├── lib/                   # optional — shared code
│   └── src/
├── plugin.yaml            # manifest — id, permissions, config, commands
├── pubspec.yaml           # Dart dependencies
└── README.md
```

## Happy Coding 🦊
