# lumide_api

[![pub package](https://img.shields.io/pub/v/lumide_api.svg)](https://pub.dev/packages/lumide_api) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Powered by SoFluffy](https://img.shields.io/badge/Powered%20by-SoFluffy-orange)](https://sofluffy.io)

The official SDK for building plugins for [Lumide IDE](https://lumide.dev).

`lumide_api` provides a set of high-level abstractions to interact with the Lumide IDE, allowing you to extend the editor, manage the file system, execute shell commands, and more.

## Features

- **Plugin Lifecycle**: Seamlessly handle plugin activation and deactivation.
- **Commands API**: Register commands for the Command Palette with optional keybindings.
- **Status Bar API**: Create and manage custom status bar items.
- **Editor API**: Access active editor, selections, and handle real-time events.
- **Workspace API**: Access configurations and listen to file events (open, change, save, close).
- **FileSystem API**: Secure file operations within the workspace.
- **Window API**: UI interactions (messages, quick picks, input boxes).
- **Shell & HTTP APIs**: Controlled execution of shell commands and standardized network requests.
- **Toolbar API**: Add custom buttons to the IDE toolbar.
- **Terminal API**: Create and control integrated terminals.
- **Output API**: Write logs and data to the Output Panel.

## Getting Started

Add `lumide_api` to your `pubspec.yaml`:

```yaml
dependencies:
  lumide_api: ^0.3.0
```

## Basic Usage

Extend the `LumidePlugin` class and implement the `onActivate` method:

```dart
import 'package:lumide_api/lumide_api.dart';

void main() => MyPlugin().run();

class MyPlugin extends LumidePlugin {
  @override
  Future<void> onActivate(LumideContext context) async {
    // Show a message
    await context.window.showMessage('Plugin activated!');

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

### Activation Events

Plugins are lazy-loaded by default to improve startup performance. You can specify `activation_events` in your `plugin.yaml` to control when your plugin should be loaded.

```yaml
name: my_plugin
version: 0.0.1
activation_events:
  - onCommand:my_plugin.hello
  - workspaceContains:pubspec.yaml
```

Supported events:
- `*`: Activate immediately on startup.
- `onCommand:<commandId>`: Activate when a command is executed.
- `workspaceContains:<fileName>`: Activate if the workspace contains a specific file pattern.

### Toolbar

Add buttons to the IDE toolbar:

```dart
// Register a toolbar item
// Icons are resolved from your plugin.yaml or fall back to Lucide icons
await context.toolbar.registerItem(
  id: 'play_button',
  icon: 'play', // maps to Lucide.play if not provided in icon theme
  iconPath: 'assets/play.svg', // Optional: use custom SVG
  tooltip: 'Run App',
  alignment: 'left',
  priority: 100, // higher priority = further left
);

// Listen to taps
context.toolbar.onTap((id, position) {
  if (id == 'play_button') {
    log('Play button tapped at ${position['x']}, ${position['y']}');
  }
});
```

### Terminal

Spawn and control terminals:

```dart
// Create a new terminal
final terminalId = await context.window.createTerminal(
  name: 'My Terminal',
  shellPath: '/bin/zsh',
);

// Send text to it
await context.terminal.sendText(terminalId, 'echo "Hello from Plugin"');

// Show it to the user
await context.terminal.show(terminalId);

// Listen to output
context.terminal.onData((id, data) {
  if (id == terminalId) {
    log('Terminal Output: $data');
  }
});
```

### Output Channels

Write logs to a dedicated panel:

```dart
// Create a channel
final channelId = await context.window.createOutputChannel('My Plugin Logs');

// Write to it
await context.output.append(channelId, 'Starting build process...\n');

// Show it
await context.output.show(channelId);

// Write structured logs
await context.output.appendLog(
  channelId,
  LumideLogRecord(
    level: 'ERROR',
    message: 'Build failed',
    error: 'SyntaxError: unexpected token',
    stackTrace: '...',
  ),
);
```

> **Note**: Always use the `log()` method for debugging. `stdout` is reserved for JSON-RPC communication between the IDE and your plugin.

## Documentation & Examples

For a comprehensive walkthrough of what you can build, check out the [example directory](https://github.com/SoFluffyOS/lumide_api/tree/main/example) which exercises all 18 available APIs.

For more information about the Lumide ecosystem, visit [lumide.dev](https://lumide.dev).

---

Built with ❤️ by [SoFluffy](https://sofluffy.io).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Happy Coding 🦊
