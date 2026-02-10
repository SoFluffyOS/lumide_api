# lumide_api

[![pub package](https://img.shields.io/pub/v/lumide_api.svg)](https://pub.dev/packages/lumide_api) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Powered by SoFluffy](https://img.shields.io/badge/Powered%20by-SoFluffy-orange)](https://sofluffy.io)

The official SDK for building plugins for [Lumide IDE](https://lumide.dev).

`lumide_api` provides a set of high-level abstractions to interact with the Lumide IDE, allowing you to extend the editor, manage the file system, execute shell commands, and more.

## Features

- **Plugin Lifecycle**: Seamlessly handle plugin activation and deactivation.
- **Editor API**: Full access to the active editor, selections, and real-time text manipulation.
- **FileSystem API**: Secure file and directory operations within the user's workspace.
- **Window API**: Rich UI interactions including messages, quick picks, and custom input boxes.
- **Workspace API**: Access user configurations and listen to global document events.
- **Shell API**: Controlled execution of host shell commands.
- **HTTP API**: Built-in standardized network request handling.

## Getting Started

Add `lumide_api` to your `pubspec.yaml`:

```yaml
dependencies:
  lumide_api: ^0.1.0
```

## Basic Usage

Extend the `LumidePlugin` class and implement the `onActivate` method:

```dart
import 'package:lumide_api/lumide_api.dart';

void main() => MyPlugin().run();

class MyPlugin extends LumidePlugin {
  @override
  Future<void> onActivate(LumideContext context) async {
    log('Hello from my plugin!');
    
    // Show a message to the user
    await context.window.showMessage('Plugin activated!');
    
    // Read the active document URI
    final uri = await context.editor.getActiveDocumentUri();
    log('Currently editing: $uri');
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
