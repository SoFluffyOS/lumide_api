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

## Getting Started

Add `lumide_api` to your `pubspec.yaml`:

```yaml
dependencies:
  lumide_api: ^0.2.0+1
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

    // Create a status bar item
    await context.statusBar.createItem(
      id: 'status',
      text: 'Ready',
      alignment: 'right',
    );
  }
}
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
