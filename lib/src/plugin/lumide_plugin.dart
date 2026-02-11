/// Abstract base class for Lumide plugins.
library;

import 'dart:async';
import 'dart:io';

import 'package:lumide_api/src/plugin/lumide_context.dart';
import 'package:lumide_api/src/rpc/rpc.dart';

/// Abstract base class for external Lumide plugins.
///
/// Plugin authors extend this class and implement [onActivate].
///
/// Example:
/// ```dart
/// class MyPlugin extends LumidePlugin {
///   @override
///   Future<void> onActivate(LumideContext context) async {
///     final content = await context.fs.readString('/some/file.txt');
///     await context.window.showMessage('File content: $content');
///   }
/// }
/// ```
abstract class LumidePlugin {
  /// Called when the IDE initializes this plugin.
  Future<void> onActivate(LumideContext context);

  /// Called when the IDE is shutting down this plugin.
  Future<void> onDeactivate() async {}

  /// Logs a message to stderr (stdout is reserved for JSON-RPC).
  void log(String message) {
    stderr.writeln(message);
  }

  /// Runs the plugin, connecting to the IDE via stdio.
  ///
  /// This is typically called from the plugin's main function:
  /// ```dart
  /// void main() => MyPlugin().run();
  /// ```
  Future<void> run() async {
    final session = RpcSession.fromStdio(stdin, stdout);
    final context = RpcLumideContext(session);

    session.registerMethod(HostMethods.initialize, (params) async {
      log('Plugin initialized');
      await onActivate(context);
      return null;
    });

    session.registerMethod(HostMethods.shutdown, (params) async {
      log('Plugin shutting down');
      await onDeactivate();
      return null;
    });

    await session.listen();
  }
}

/// Context provided to plugins for IDE interaction.
///
/// All operations are mediated through this context and
/// checked against declared permissions.
abstract class LumideContext {
  /// File system operations.
  LumideFileSystem get fs;

  /// HTTP client operations.
  LumideHttp get http;

  /// Shell command operations.
  LumideShell get shell;

  /// Window/UI operations.
  LumideWindow get window;

  /// Editor operations.
  LumideEditor get editor;

  /// Workspace operations (configuration, events).
  LumideWorkspace get workspace;

  /// Command registration.
  LumideCommands get commands;
}

/// File system operations.
abstract class LumideFileSystem {
  /// Reads a file as a string.
  Future<String> readString(String path);

  /// Writes a string to a file.
  Future<void> writeString(String path, String content);

  /// Checks if a path exists.
  Future<bool> exists(String path);

  /// Lists directory contents.
  Future<List<String>> list(String path);
}

/// HTTP client operations.
abstract class LumideHttp {
  /// Performs a GET request.
  Future<HttpResponse> get(String url, {Map<String, String>? headers});

  /// Performs a POST request.
  Future<HttpResponse> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
  });
}

/// HTTP response.
class HttpResponse {
  const HttpResponse({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;
}

/// Shell command operations.
abstract class LumideShell {
  /// Runs a shell command.
  Future<ProcessResult> run(String command, List<String> arguments);
}

/// Process execution result.
class ProcessResult {
  const ProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

/// Window/UI operations.
abstract class LumideWindow {
  /// Shows a message to the user.
  Future<void> showMessage(String message, {MessageType type});

  /// Shows a quick pick dialog.
  Future<String?> showQuickPick(List<String> items, {String? placeholder});

  /// Shows an input box.
  Future<String?> showInputBox({String? prompt, String? value});
}

/// Message types for window messages.
enum MessageType { info, warning, error }

/// Editor operations.
abstract class LumideEditor {
  /// Gets the currently active document URI.
  Future<String?> getActiveDocumentUri();

  /// Inserts text at the current cursor position.
  Future<void> insertText(String text);

  /// Replaces text in a range.
  Future<void> replaceText({
    required int startLine,
    required int startColumn,
    required int endLine,
    required int endColumn,
    required String newText,
  });

  /// Gets all current selections/cursors.
  ///
  /// Returns a list of selections, each with anchor and focus positions
  /// as `{anchor: {line, column}, focus: {line, column}}`.
  Future<List<Map<String, dynamic>>> getSelections();

  /// Sets the editor's selections/cursors.
  ///
  /// Each selection should be `{anchor: {line, column}, focus: {line, column}}`.
  Future<void> setSelections(List<Map<String, dynamic>> selections);
}

/// Workspace operations (configuration, project context).
abstract class LumideWorkspace {
  /// Gets a configuration value for the given section/key.
  ///
  /// Example: `getConfiguration('prettier.printWidth')` → `80`
  Future<Object?> getConfiguration(String section);

  /// Registers a callback for when a text document is opened.
  void onDidOpenTextDocument(void Function(String uri) callback);

  /// Registers a callback for when a text document is closed.
  void onDidCloseTextDocument(void Function(String uri) callback);

  /// Registers a callback for when a text document changes.
  void onDidChangeTextDocument(
    void Function(DocumentChangeEvent event) callback,
  );
}

/// Event fired when a document's content changes.
class DocumentChangeEvent {
  const DocumentChangeEvent({required this.uri, required this.changes});

  /// The document URI.
  final String uri;

  /// List of content changes.
  final List<DocumentContentChange> changes;
}

/// A single content change within a document.
class DocumentContentChange {
  const DocumentContentChange({
    required this.text,
    this.startLine,
    this.startColumn,
    this.endLine,
    this.endColumn,
  });

  /// The new text for the range (or full document if range is null).
  final String text;

  /// Start line of the changed range (null = full document replacement).
  final int? startLine;

  /// Start column of the changed range.
  final int? startColumn;

  /// End line of the changed range.
  final int? endLine;

  /// End column of the changed range.
  final int? endColumn;
}

/// Command registration API.
abstract class LumideCommands {
  /// Registers a command that can be invoked from the Command Palette.
  ///
  /// [id] must be a unique command identifier (e.g. 'myPlugin.formatCode').
  /// [title] is the human-readable name shown in the Command Palette.
  /// [callback] is called when the command is executed.
  Future<void> registerCommand({
    required String id,
    required String title,
    String? category,
    required Future<void> Function() callback,
  });
}
