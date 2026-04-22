# lumide_api

[![pub package](https://img.shields.io/pub/v/lumide_api.svg)](https://pub.dev/packages/lumide_api) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Powered by SoFluffy](https://img.shields.io/badge/Powered%20by-SoFluffy-orange)](https://sofluffy.io)

The official SDK for building plugins for [Lumide IDE](https://lumide.dev).

`lumide_api` provides a set of high-level abstractions to interact with the Lumide IDE, allowing you to extend the editor, manage the file system, execute shell commands, and more.

## Features

- **Plugin Lifecycle**: Seamlessly handle plugin activation and deactivation.
- **Commands API**: Register commands for the Command Palette with optional keybindings.
- **Status Bar API**: Create and manage custom status bar items.
- **Editor API**: Access active editor, selections, navigate to locations, and handle real-time events.
- **Workspace API**: Access configurations, get workspace root, find files by glob, and listen to file events. **(New: `updateConfiguration`)**
- **FileSystem API**: Secure file operations within the workspace, including directory checks.
- **Window API**: UI interactions (messages with titles, quick picks, input boxes, confirm dialogs). **(New: `showDeviceAuthDialog`)**
- **Shell & HTTP APIs**: Controlled execution of shell commands (with working directory support) and standardized network requests.
- **Toolbar API**: Add custom buttons to the IDE toolbar.
- **Terminal API**: Create and control integrated terminals.
- **Output API**: Write logs and data to the Output Panel.
- **Languages API**: Register custom language servers for LSP support. **(New: Inline Completion, Custom LSP Requests)**
- **Debug API**: Start debugger sessions, synchronize breakpoints, inspect stack frames/scopes/variables, evaluate expressions, and control exception pause mode.

## Getting Started

Add `lumide_api` to your `pubspec.yaml`:

```yaml
dependencies:
  lumide_api: ^1.2.0
```

## Basic Usage

Extend the `LumidePlugin` class and implement the `onActivate` method:

```dart
import 'package:lumide_api/lumide_api.dart';

void main() => MyPlugin().run();

class MyPlugin extends LumidePlugin {
  @override
  Future<void> onActivate(LumideContext context) async {
    // Show a message with a title
    await context.window.showMessage(
      'Plugin activated!',
      title: 'My Plugin',
    );

    // Register a command
    await context.commands.registerCommand(
      id: 'my_plugin.hello',
      title: 'Hello World',
      callback: () async => log('Command executed!'),
    );

    // Create a status bar item with an icon
    await context.statusBar.createItem(
      id: 'status',
      text: 'Ready',
      alignment: 'right',
      iconPath: 'assets/my_icon.svg', // Optional SVG icon
    );
  }
}
```

### Activation Events

Plugins are lazy-loaded by default to improve startup performance. Specify `activation_events` in your `plugin.yaml` to control when your plugin should be loaded.

> [!NOTE]
> If `activation_events` is empty or omitted, the plugin will NOT be started as a process. This is useful for plugins that only provide static assets like icon themes or color themes.

```yaml
name: my_plugin
version: 0.0.1
activation_events:
  - onStartup
  - onCommand:my_plugin.hello
  - workspaceContains:pubspec.yaml
```

Supported events:
- `onStartup`: Activate immediately on IDE startup.
- `onCommand:<commandId>`: Activate when a specific command is executed.
- `workspaceContains:<fileName>`: Activate if the workspace contains a specific file pattern.

### Workspace

Query the workspace root and search for files:

```dart
// Get the workspace root path
final root = await context.workspace.getRootUri();

// Find all pubspec.yaml files in the workspace
final pubspecs = await context.workspace.findFiles(
  '**/pubspec.yaml',
  maxResults: 50,
);

// Read a configuration value
final tabSize = await context.workspace.getConfiguration('editor.tabSize');

// Listen to file events
context.workspace.onDidSaveTextDocument((uri) {
  log('File saved: $uri');
});
```

### Editor

Navigate, read, and manipulate documents:

```dart
// Open a document
await context.editor.openDocument('file:///path/to/file.dart');

// Navigate to a specific line
await context.editor.revealRange(
  uri: 'file:///path/to/file.dart',
  line: 42,
  column: 10,
);

// Read the full text of an open document
final text = await context.editor.getDocumentText(
  'file:///path/to/file.dart',
);

// Get or set selections
final selections = await context.editor.getSelections();
final selectedText = await context.editor.getSelectedText();
await context.editor.insertText('Hello!');
```

### File System

Read, write, and inspect files:

```dart
// Check if a path is a directory
if (await context.fs.isDirectory('/some/path')) {
  final entries = await context.fs.list('/some/path');
}

// Read and write files
final content = await context.fs.readString('/path/to/file.txt');
await context.fs.writeString('/path/to/output.txt', content);

// Download and extract an archive natively via the IDE
await context.fs.downloadFile(
  'https://example.com/file.tar.gz',
  '/path/to/dest',
  label: 'Downloading dependency',
  extract: true,
);
```

### Shell

Execute commands with optional working directory:

```dart
// Run a command in a specific directory
final result = await context.shell.run(
  'flutter',
  ['pub', 'get'],
  workingDirectory: '/path/to/project',
);

if (result.exitCode == 0) {
  log('stdout: ${result.stdout}');
}
```

### Window & Dialogs

Show messages, confirmations, quick picks, and input boxes:

```dart
// Message with a title
await context.window.showMessage(
  'Build completed successfully',
  title: 'Flutter',
);

// Confirmation dialog
final confirmed = await context.window.showConfirmDialog(
  'Are you sure you want to clean the build?',
  title: 'Flutter Clean',
);

// Quick pick
final selected = await context.window.showQuickPick([
  QuickPickItem(label: 'Option A', payload: 'a'),
  QuickPickItem(label: 'Option B', payload: 'b'),
], placeholder: 'Choose an option');

// Input box
final name = await context.window.showInputBox(
  prompt: 'Enter project name',
);

// Device authentication dialog (OAuth2)
await context.window.showDeviceAuthDialog(
  userCode: 'ABCD-1234',
  verificationUri: 'https://github.com/login/device',
);
```

### Toolbar

Add buttons to the IDE toolbar:

```dart
await context.toolbar.registerItem(
  id: 'play_button',
  icon: 'play',
  tooltip: 'Run App',
  alignment: ToolbarItemAlignment.right,
  priority: 100,
);

context.toolbar.onTap((id, position) {
  if (id == 'play_button') {
    log('Play button tapped');
  }
});
```

### Terminal

Spawn and control terminals:

```dart
final terminal = await context.window.createTerminal(
  name: 'My Terminal',
  shellPath: '/bin/zsh',
);

await terminal.sendText('echo "Hello from Plugin"');
await terminal.show();

terminal.onData((data) {
  log('Terminal Output: $data');
});
```

### Output Channels

Write logs to a dedicated panel:

```dart
final channel = await context.window.createOutputChannel('My Plugin Logs');

await channel.append('Starting build process...\n');
await channel.show();

// Structured records can be streamed too
await channel.appendLog(
  LumideLogRecord(
    level: 'INFO',
    message: 'Build finished',
  ),
);
```

### Debug Sessions

Plugins can expose a custom debugger backend through `context.debug`.

```dart
class MyPlugin extends LumidePlugin {
  @override
  Future<void> onActivate(LumideContext context) async {
    final output = await context.window.createOutputChannel('My Debugger');

    context.debug.onLaunch(() async {
      await context.debug.startSession(
        LumideDebugSession(
          id: 'my.debug.session',
          name: 'My Debugger',
          state: LumideDebugSessionState.launching,
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
          outputChannelId: output.id,
        ),
      );

      await context.debug.updateSession(
        LumideDebugSession(
          id: 'my.debug.session',
          name: 'My Debugger',
          state: LumideDebugSessionState.running,
          outputChannelId: output.id,
          exceptionPauseMode: LumideDebugExceptionPauseMode.unhandled,
        ),
      );
    });

    context.debug.onSetBreakpoints((sessionId, breakpoints) async {
      log('Host requested ${breakpoints.length} breakpoints');
    });

    context.debug.onSetExceptionPauseMode((sessionId, mode) async {
      log('Exception pause mode: ${mode.name}');
    });

    context.debug.onGetStackFrames((sessionId) async {
      return const [
        LumideDebugStackFrame(
          id: 1,
          name: 'main',
          sourceUri: 'file:///workspace/lib/main.dart',
          line: 10,
          column: 1,
        ),
      ];
    });

    context.debug.onGetScopes((sessionId, frameId) async {
      return const [
        LumideDebugScope(id: 100, name: 'Locals'),
      ];
    });

    context.debug.onGetVariables((sessionId, variablesReference) async {
      if (variablesReference == 100) {
        return const [
          LumideDebugVariable(
            name: 'user',
            value: 'Instance of User',
            type: 'User',
            variablesReference: 101,
          ),
        ];
      }

      if (variablesReference == 101) {
        return const [
          LumideDebugVariable(
            name: 'name',
            value: 'Simon',
            type: 'String',
          ),
        ];
      }

      return const [];
    });

    context.debug.onEvaluate((sessionId, expression, {frameId}) async {
      return const LumideDebugEvaluationResult(
        result: '42',
        type: 'int',
      );
    });
  }
}
```

Key debug concepts:

- `startSession()` / `updateSession()` / `endSession()` drive the lifecycle of the active debugger.
- `outputChannelId` binds the debug UI to an existing output channel instead of duplicating logs.
- `onSetBreakpoints()` and `updateBreakpoints()` keep host and backend breakpoint state aligned.
- `onGetVariables()` is reference-based: top-level scopes and nested children both flow through the same callback.
- `variablesReference` enables lazy tree expansion for large objects, collections, and maps.
- `exceptionPauseMode` reports the current filter and `onSetExceptionPauseMode()` lets the host change it.

// Write structured logs
await channel.appendLog(
  LumideLogRecord(
    level: 'ERROR',
    message: 'Build failed',
    error: 'SyntaxError: unexpected token',
    stackTrace: '...',
  ),
);

await channel.clear();
```

### Languages

Register a language server for custom file types or provide advanced LSP features:

```dart
// Register a language server with custom icon and authentication
await context.languages.registerLanguageServer(
  id: 'swift-lsp',
  languageId: 'swift',
  fileExtensions: ['.swift'],
  command: 'sourcekit-lsp',
  iconPath: 'assets/swift.svg',
  checkStatus: () async => 'ok', // Optional auth callbacks
);

// Register an inline completion provider (AI Ghost Text)
await context.languages.registerInlineCompletionProvider(
  id: 'my-ai',
  displayName: 'My AI Provider',
  onProvideCompletions: (request) async {
    // request.documentText contains <CURSOR> marker
    return [InlineCompletion(text: 'suggested code')];
  },
);

// Send custom JSON-RPC requests to an active language server
final response = await context.languages.sendLspRequest(
  'swift-lsp',
  'custom/checkStatus',
  {'id': '123'},
);
```

Once registered, the IDE automatically starts the language server when a matching file is opened, providing diagnostics, completions, and other LSP features.

### WebViews

Create custom UI panels using WebViews:

```dart
final panel = await context.window.createWebviewPanel(
  'my_plugin.dashboard',
  'My Dashboard',
  options: {'url': 'https://lumide.dev'},
);
```

### Utilities

Open external URLs:

```dart
await context.window.openUrl('https://lumide.dev');
```

> **Note**: Always use the `log()` method for debugging. `stdout` is reserved for JSON-RPC communication between the IDE and your plugin.

## Documentation & Examples

For a comprehensive walkthrough of what you can build, check out the [example directory](https://github.com/SoFluffyOS/lumide_api/tree/main/example) which exercises all available APIs.

For more information about the Lumide ecosystem, visit [lumide.dev](https://lumide.dev).

---

Built with ❤️ by [SoFluffy](https://sofluffy.io).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Happy Coding 🦊
