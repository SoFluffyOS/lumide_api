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

## New In 1.2.0: Debug Support

`lumide_api` now includes a first-class debug bridge. A plugin can act as a debugger backend by:

- announcing a session with `context.debug.startSession(...)`
- responding to host actions like continue/pause/step/stop
- synchronizing breakpoints with `onSetBreakpoints(...)`
- serving stack frames, scopes, variables, and evaluation results
- reacting to exception filter changes with `onSetExceptionPauseMode(...)`

Minimal sketch:

```dart
final debugOutput = await context.window.createOutputChannel('Demo Debug');

context.debug.onLaunch(() async {
  await context.debug.startSession(
    LumideDebugSession(
      id: 'demo.debug',
      name: 'Demo Debugger',
      state: LumideDebugSessionState.running,
      outputChannelId: debugOutput.id,
      capabilities: const LumideDebugCapabilities(
        canContinue: true,
        canPause: true,
        canStepOver: true,
        canStepInto: true,
        canStepOut: true,
        canStop: true,
        canSetBreakpoints: true,
        canEvaluate: true,
      ),
      exceptionPauseMode: LumideDebugExceptionPauseMode.unhandled,
    ),
  );
});

context.debug.onGetStackFrames((sessionId) async => const [
      LumideDebugStackFrame(
        id: 1,
        name: 'main',
        sourceUri: 'file:///workspace/lib/main.dart',
        line: 12,
        column: 1,
      ),
    ]);

context.debug.onGetScopes((sessionId, frameId) async => const [
      LumideDebugScope(id: 10, name: 'Locals'),
    ]);

context.debug.onGetVariables((sessionId, variablesReference) async {
  if (variablesReference == 10) {
    return const [
      LumideDebugVariable(
        name: 'counter',
        value: '1',
        type: 'int',
      ),
      LumideDebugVariable(
        name: 'user',
        value: 'Instance of User',
        type: 'User',
        variablesReference: 11,
      ),
    ];
  }

  if (variablesReference == 11) {
    return const [
      LumideDebugVariable(
        name: 'name',
        value: 'Demo',
        type: 'String',
      ),
    ];
  }

  return const [];
});
```

Use `variablesReference` for lazy expansion instead of eagerly flattening large object graphs. Reuse `outputChannelId` so your debug logs stream into both the normal Output surface and the Debug panel’s embedded output view.

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
| `createDirectory(String path, {bool recursive})` | Creates a directory, optionally creating missing parents |
| `exists(String path)` | Returns `true` if the path exists |
| `isDirectory(String path)` | Returns `true` if the path is a directory |
| `list(String path)` | Lists directory contents as `List<String>` |

```dart
final content = await context.fs.readString('/path/to/file.dart');
await context.fs.createDirectory('/path/to/generated', recursive: true);
await context.fs.writeString('/path/to/output.txt', 'result');
```

> Requires `fileSystem` permission in `plugin.yaml`. Paths outside declared globs are rejected.

---

### Context Menus — `context.menus`

Register commands in Lumide context menus. Menu actions are shown only when
their command is registered.

| Method | Description |
|--------|-------------|
| `registerAction(LumideMenuAction action)` | Adds a plugin action to a context menu |
| `unregisterAction(String id)` | Removes a plugin action by its plugin-local id |

```dart
await context.commands.registerCommand(
  id: 'my_plugin.newDartFile',
  title: 'My Plugin: New Dart File',
  callback: ([args]) async {
    final menuContext = args?['context'] as Map<String, dynamic>?;
    final primary = menuContext?['primary'] as Map<String, dynamic>?;
    log('Create near: ${primary?['path']}');
  },
);

await context.menus.registerAction(
  const LumideMenuAction(
    id: 'new_dart_file',
    title: 'New Dart File',
    command: 'my_plugin.newDartFile',
    location: LumideMenuLocation.fileTreeItem,
    group: 'create',
    priority: 100,
  ),
);

await context.menus.registerAction(
  const LumideMenuAction(
    id: 'format_file',
    title: 'Format File',
    command: 'my_plugin.formatFile',
    location: LumideMenuLocation.fileTreeItem,
    group: 'tools',
    priority: 90,
  ),
);
```

Supported locations are `addPane`, `fileTreeItem`, `tabBarItem`, and `editor`.
Command callbacks receive `actionId`, `fullActionId`, `pluginId`, `location`,
and a location-specific `context`. Use `group` to insert dividers between
related actions from the same plugin.

---

### Window — `context.window`

| Method | Description |
|--------|-------------|
| `showMessage(String msg, {MessageType type})` | Shows a toast/notification |
| `showQuickPick(List<String> items, {String? placeholder})` | Shows a selection dialog, returns chosen item or `null` |
| `showInputBox({String? prompt, String? value})` | Shows a text input dialog, returns entered text or `null` |
| `showOpenDialog({String? title, String? defaultPath})` | Shows a file picker dialog, returns selected file path or `null` |
| `showOpenFolderDialog({String? title, String? defaultPath})` | Shows a folder picker dialog, returns selected folder path or `null` |

```dart
await context.window.showMessage('Build succeeded! ✅');

// Ask user to select a configuration or action
final choice = await context.window.showQuickPick(
  [
    QuickPickItem(label: 'Format Code', payload: 'format'),
    QuickPickItem(label: 'Run Tests', payload: 'test'),
  ],
  placeholder: 'Choose an action...',
);

// Native file picker dialog
final filePath = await context.window.showOpenDialog(
  title: 'Select Entry Point',
);

// Native folder picker dialog
final folderPath = await context.window.showOpenFolderDialog(
  title: 'Select SDK Folder',
);
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

Plugin settings can use `type: filePath` to open a file picker or
`type: folderPath` to open a folder picker in the generated Settings UI.



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
```

### Toolbar — `context.toolbar`

| Method | Description |
|--------|-------------|
| `registerItem({id, icon, tooltip?, alignment?, priority?})` | Adds an item to the toolbar |
| `onTap(callback)` | Called when a toolbar item is tapped |

```dart
await context.toolbar.registerItem(
  id: 'run_app',
  icon: 'play',
  tooltip: 'Run App',
  alignment: 'right',
);

context.toolbar.onTap((id, position) {
  if (id == 'run_app') {
    log('Run tapped!');
  }
});
```

### Terminal — `context.terminal`

| Method | Description |
|--------|-------------|
| `create({name?, shellPath?, shellArgs?})` | Creates a new terminal |
| `sendText(id, text, {addNewLine?})` | Sends text to a terminal |
| `show(id, {preserveFocus?})` | Focuses a terminal |
| `dispose(id)` | Closes a terminal |
| `onData(callback)` | Called when terminal emits data |

### Output — `context.output`

| Method | Description |
|--------|-------------|
| `createChannel(name)` | Creates a new output channel |
| `append(id, value)` | Appends text to a channel |
| `show(id, {preserveFocus?})` | Shows the output panel |
| `disposeChannel(id)` | Removes a channel |

---

### Launch — `context.launch`

| Method | Description |
|--------|-------------|
| `registerProvider(...)` | Registers a new launch provider (run, debug, attach, test) |
| `unregisterProvider(id)` | Unregisters a launch provider |
| `updateConfigurations(...)` | Publishes standard targets and triggers/actions (`isAction: true`) |
| `didStart(LumideLaunchEvent)` | Tells the IDE a run/debug/attach/test process has started |
| `didEnd(LumideLaunchEvent)` | Tells the IDE a run/debug/attach/test process has finished |
| `onResolveConfigurations(cb)` | Registers a callback to fetch configurations dynamically |
| `onConfigure(cb)` | Registers a callback for target configuration options and custom actions |
| `onLaunch(cb)` | Registers a callback triggered when the user starts a session |

```dart
// Register the provider
await context.launch.registerProvider(
  id: 'dart',
  title: 'Dart',
  kinds: const [LumideLaunchKind.run],
);

// Publish configurations with a trigger action
await context.launch.updateConfigurations('dart', [
  const LumideLaunchConfiguration(
    id: 'bin_main',
    label: 'bin/main.dart',
  ),
  const LumideLaunchConfiguration(
    id: 'select_entry',
    label: 'Select Custom Entrypoint...',
    isAction: true, // A non-runnable trigger action button in the dropdown
    icon: 'folder',
  ),
]);

// Handle dynamic config selection / custom actions
context.launch.onConfigure((request) async {
  if (request.configuration?.id == 'select_entry') {
    final path = await context.window.showOpenDialog(
      title: 'Select Dart Entry Point',
    );
    if (path != null) {
      return LumideLaunchConfiguration(
        id: 'custom_bin',
        label: path.split('/').last,
        arguments: {'path': path},
      );
    }
  }
  return null;
});

// Await play / run request
context.launch.onLaunch((request) async {
  final event = LumideLaunchEvent(
    providerId: request.providerId,
    kind: request.kind,
    configurationId: request.configuration.id,
  );
  
  // Notify started
  await context.launch.didStart(event);
  
  // Run process
  final entry = request.configuration.arguments['path'] ?? 'bin/main.dart';
  final result = await context.shell.run('dart', ['run', entry]);
  
  // Notify ended
  await context.launch.didEnd(event);
});
```

---

## Manifest Reference (`plugin.yaml`)

(See main `README.md` for full reference)

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
