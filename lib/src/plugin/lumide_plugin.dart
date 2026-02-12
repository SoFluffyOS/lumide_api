/// Abstract base class for Lumide plugins.
library;

import 'dart:async';
import 'dart:io';

import 'package:lumide_api/lumide_api.dart';

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

  /// Status bar operations.
  LumideStatusBar get statusBar;

  /// Toolbar operations.
  LumideToolbar get toolbar;
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

  /// Spawns a persistent shell process.
  ///
  /// Returns the process ID (pid) of the spawned process.
  Future<int> spawn(String command, List<String> arguments);

  /// Writes data to the stdin of the process with the given [pid].
  Future<void> writeStdin(int pid, String text);

  /// Kills the process with the given [pid].
  Future<bool> kill(int pid);

  /// Registers a callback for process stdout.
  void onStdout(void Function(int pid, String data) callback);

  /// Registers a callback for process stderr.
  void onStderr(void Function(int pid, String data) callback);

  /// Registers a callback for process exit.
  void onExit(void Function(int pid, int exitCode) callback);
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

/// Message types for window messages.
enum MessageType { info, warning, error }

/// An item in a quick pick list.
class QuickPickItem {
  const QuickPickItem({
    required this.label,
    this.description,
    this.detail,
    this.picked = false,
    this.payload,
    this.iconPath,
    this.icon,
    this.enabled = true,
    this.isSeparator = false,
  });

  /// The label to display.
  final String label;

  /// A short description to display below the label.
  final String? description;

  /// A longer description to display (often to the right).
  final String? detail;

  /// Whether this item is selected by default.
  final bool picked;

  /// Custom payload to return when selected.
  final Object? payload;

  /// Path to a custom icon (e.g. SVG).
  final String? iconPath;

  /// Name of a themed icon (e.g. 'search').
  final String? icon;

  /// Whether the item is enabled.
  final bool enabled;

  /// Whether the item is a separator.
  final bool isSeparator;

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      if (description != null) 'description': description,
      if (detail != null) 'detail': detail,
      if (picked) 'picked': picked,
      if (payload != null) 'payload': payload,
      if (iconPath != null) 'iconPath': iconPath,
      if (icon != null) 'icon': icon,
      if (!enabled) 'enabled': enabled,
      if (isSeparator) 'isSeparator': isSeparator,
    };
  }
}

/// Window/UI operations.
abstract class LumideWindow {
  /// Shows a message to the user.
  Future<void> showMessage(String message, {MessageType type});

  /// Shows a quick pick dialog.
  ///
  /// Returns the selected [QuickPickItem], or `null` if dismissed.
  /// If [items] contains simple strings, they are wrapped in [QuickPickItem].
  Future<QuickPickItem?> showQuickPick(
    List<QuickPickItem> items, {
    String? placeholder,
    bool matchOnDescription = true,
    bool matchOnDetail = true,
    Map<String, int>? position,
  });

  /// Shows an input box.
  Future<String?> showInputBox({
    String? prompt,
    String? value,
    String? placeHolder,
    bool password = false,
    String? title,
  });

  /// Creates a new output channel.
  Future<LumideOutputChannel> createOutputChannel(String name);

  /// Creates a new terminal.
  ///
  /// [name] is the title of the terminal.
  /// [shellPath] is the path to the shell executable (optional).
  /// [shellArgs] are arguments for the shell (optional).
  Future<LumideTerminal> createTerminal({
    String? name,
    String? shellPath,
    List<String>? shellArgs,
  });
}

/// A terminal instance in the IDE.
abstract class LumideTerminal {
  /// Sends text to the terminal.
  ///
  /// [addNewLine] determines whether to append a newline character (default true).
  Future<void> sendText(String text, {bool addNewLine = true});

  /// Shows the terminal panel.
  Future<void> show({bool preserveFocus = false});

  /// Disposes the terminal.
  Future<void> dispose();

  /// Registers a callback for data received from the terminal process (if supported).
  void onData(void Function(String data) callback);
}

/// A channel for streaming output (logs) to the UI.
abstract class LumideOutputChannel {
  /// Appends text to the channel.
  Future<void> append(String value);

  /// Appends a line of text to the channel.
  Future<void> appendLine(String value);

  /// Appends a structured log record to the channel.
  Future<void> appendLog(LumideLogRecord record);

  /// Shows the channel in the UI.
  Future<void> show({bool preserveFocus = false});

  /// Disposes the channel.
  Future<void> dispose();
}

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

  /// Registers a callback for when selections/cursors change.
  ///
  /// The callback receives the list of current selections in the same format
  /// as [getSelections].
  void onDidChangeSelections(
    void Function(List<Map<String, dynamic>> selections) callback,
  );

  /// Registers a callback for when the active document changes.
  ///
  /// The callback receives the URI of the newly active document, or `null`
  /// if no document is active.
  void onDidChangeActiveDocument(void Function(String? uri) callback);

  /// Gets the text currently selected in the active editor.
  ///
  /// Returns `null` if no editor is active or no selection is made (though usually returns empty string if just cursor).
  Future<String?> getSelectedText();

  /// Replaces the current selection with [text].
  Future<void> replaceSelection(String text);
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

  /// Registers a callback for when plugin configuration changes.
  ///
  /// The callback receives a map of changed configuration keys and their
  /// new values.
  void onDidChangeConfiguration(
    void Function(Map<String, Object?> settings) callback,
  );

  /// Registers a callback for when a text document is saved.
  void onDidSaveTextDocument(void Function(String uri) callback);
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
    required Future<void> Function([Map<String, dynamic>? args]) callback,
  });
}

/// Status bar operations API.
abstract class LumideStatusBar {
  /// Creates a status bar item.
  ///
  /// [id] must be unique for this plugin.
  /// [alignment] is either 'left' or 'right' (defaults to 'right').
  /// [priority] controls ordering (higher = further from center).
  Future<void> createItem({
    required String id,
    required String text,
    String? tooltip,
    String? command,
    String? color,
    String? iconName,
    String? iconPath,
    String alignment,
    int priority,
  });

  /// Updates properties of an existing status bar item.
  Future<void> updateItem(
    String id, {
    String? text,
    String? tooltip,
    String? command,
    String? color,
    String? iconName,
    String? iconPath,
  });

  /// Removes a status bar item.
  Future<void> disposeItem(String id);

  /// Shows a previously hidden status bar item.
  Future<void> show(String id);

  /// Hides a status bar item without removing it.
  Future<void> hide(String id);
}

/// Alignment for toolbar items.
enum ToolbarItemAlignment {
  left,
  center,
  right,
}

/// Toolbar operations API.
abstract class LumideToolbar {
  /// Registers a toolbar item.
  ///
  /// [id] must be unique for this plugin.
  /// [icon] is the name of the icon (e.g. 'play', 'stop', 'refresh').
  /// [tooltip] is the text shown on hover.
  /// [alignment] controls horizontal position (defaults to right).
  /// [priority] controls ordering (higher = further from center).
  Future<void> registerItem({
    required String id,
    required String icon,
    String? iconPath,
    String? label,
    String? tooltip,
    ToolbarItemAlignment alignment = ToolbarItemAlignment.right,
    int priority = 0,
  });

  /// Unregisters a toolbar item.
  Future<void> unregisterItem(String id);

  /// Registers a callback for when a toolbar item is tapped.
  ///
  /// The callback receives the [id] of the tapped item and screen [position].
  void onTap(void Function(String id, Map<String, int> position) callback);
}
