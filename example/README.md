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

```dart
// Get cursor position
final selections = await context.editor.getSelections();
for (final sel in selections) {
  final focus = sel['focus'] as Map<String, dynamic>;
  log('Cursor at line ${focus['line']}, column ${focus['column']}');
}

// Move cursor to start of file
await context.editor.setSelections([
  {'anchor': {'line': 0, 'column': 0}, 'focus': {'line': 0, 'column': 0}},
]);
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

```dart
// Read config
final maxResults = await context.workspace.getConfiguration('my_plugin.maxResults');

// Listen for file events
context.workspace.onDidOpenTextDocument((uri) {
  log('Opened: $uri');
});

context.workspace.onDidChangeTextDocument((event) {
  log('Changed: ${event.uri} (${event.changes.length} edits)');
  for (final change in event.changes) {
    log('  Text: ${change.text}');
  }
});
```

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
```

---

## Tips & Best Practices

1. **Never write to `stdout`** — it's the JSON-RPC transport. Use `log()` instead.
2. **Dispose everything in `onDeactivate`** — cancel timers, close streams, release resources.
3. **Declare minimal permissions** — only request access to paths/commands you actually need.
4. **Use config defaults wisely** — the manifest `default` value is used when the user hasn't changed the setting.
5. **Handle errors gracefully** — wrap API calls in `try/catch` to avoid crashing the plugin process.
6. **Keep activation fast** — do heavy work asynchronously after `onActivate` returns.

---

## Project Structure

```
my_plugin/
├── bin/
│   └── main.dart          # entry point — extends LumidePlugin
├── lib/                   # optional — shared code
│   └── src/
├── plugin.yaml            # manifest — id, permissions, config
├── pubspec.yaml           # Dart dependencies
└── README.md
```

## Happy Coding 🦊
