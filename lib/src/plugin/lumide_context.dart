/// LumideContext implementation using RPC.
library;

import 'package:lumide_api/src/plugin/lumide_plugin.dart';
import 'package:lumide_api/src/rpc/rpc.dart';

/// RPC-backed implementation of [LumideContext].
class RpcLumideContext implements LumideContext {
  RpcLumideContext(this._session);

  final RpcSession _session;

  @override
  late final LumideFileSystem fs = _RpcFileSystem(_session);

  @override
  late final LumideHttp http = _RpcHttp(_session);

  @override
  late final LumideShell shell = _RpcShell(_session);

  @override
  late final LumideWindow window = _RpcWindow(_session);

  @override
  late final LumideEditor editor = _RpcEditor(_session);

  @override
  late final LumideWorkspace workspace = _RpcWorkspace(_session);

  @override
  late final LumideCommands commands = _RpcCommands(_session);

  @override
  late final LumideStatusBar statusBar = _RpcStatusBar(_session);
}

class _RpcFileSystem implements LumideFileSystem {
  _RpcFileSystem(this._session);
  final RpcSession _session;

  @override
  Future<String> readString(String path) async {
    final result =
        await _session.sendRequest(PluginMethods.fsReadString, {'path': path});
    return result as String;
  }

  @override
  Future<void> writeString(String path, String content) async {
    await _session.sendRequest(PluginMethods.fsWriteString, {
      'path': path,
      'content': content,
    });
  }

  @override
  Future<bool> exists(String path) async {
    final result =
        await _session.sendRequest(PluginMethods.fsExists, {'path': path});
    return result as bool;
  }

  @override
  Future<List<String>> list(String path) async {
    final result =
        await _session.sendRequest(PluginMethods.fsList, {'path': path});
    return (result as List).cast<String>();
  }
}

class _RpcHttp implements LumideHttp {
  _RpcHttp(this._session);
  final RpcSession _session;

  @override
  Future<HttpResponse> get(String url, {Map<String, String>? headers}) async {
    final result = await _session.sendRequest(PluginMethods.httpGet, {
      'url': url,
      if (headers != null) 'headers': headers,
    });
    return _parseResponse(result as Map<String, dynamic>);
  }

  @override
  Future<HttpResponse> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final result = await _session.sendRequest(PluginMethods.httpPost, {
      'url': url,
      if (headers != null) 'headers': headers,
      if (body != null) 'body': body,
    });
    return _parseResponse(result as Map<String, dynamic>);
  }

  HttpResponse _parseResponse(Map<String, dynamic> json) {
    return HttpResponse(
      statusCode: json['statusCode'] as int,
      body: json['body'] as String,
      headers: (json['headers'] as Map<String, dynamic>? ?? {})
          .cast<String, String>(),
    );
  }
}

class _RpcShell implements LumideShell {
  _RpcShell(this._session);
  final RpcSession _session;

  @override
  Future<ProcessResult> run(String command, List<String> arguments) async {
    final result = await _session.sendRequest(PluginMethods.shellRun, {
      'command': command,
      'arguments': arguments,
    });
    final json = result as Map<String, dynamic>;
    return ProcessResult(
      exitCode: json['exitCode'] as int,
      stdout: json['stdout'] as String,
      stderr: json['stderr'] as String,
    );
  }
}

class _RpcWindow implements LumideWindow {
  _RpcWindow(this._session);
  final RpcSession _session;

  @override
  Future<void> showMessage(String message,
      {MessageType type = MessageType.info}) async {
    await _session.sendRequest(PluginMethods.windowShowMessage, {
      'message': message,
      'type': type.name,
    });
  }

  @override
  Future<String?> showQuickPick(List<String> items,
      {String? placeholder}) async {
    final result =
        await _session.sendRequest(PluginMethods.windowShowQuickPick, {
      'items': items,
      if (placeholder != null) 'placeholder': placeholder,
    });
    return result as String?;
  }

  @override
  Future<String?> showInputBox({String? prompt, String? value}) async {
    final result =
        await _session.sendRequest(PluginMethods.windowShowInputBox, {
      if (prompt != null) 'prompt': prompt,
      if (value != null) 'value': value,
    });
    return result as String?;
  }
}

class _RpcEditor implements LumideEditor {
  _RpcEditor(this._session);
  final RpcSession _session;

  @override
  Future<String?> getActiveDocumentUri() async {
    final result =
        await _session.sendRequest(PluginMethods.editorGetActiveDocument);
    return result as String?;
  }

  @override
  Future<void> insertText(String text) async {
    await _session.sendRequest(PluginMethods.editorInsertText, {'text': text});
  }

  @override
  Future<void> replaceText({
    required int startLine,
    required int startColumn,
    required int endLine,
    required int endColumn,
    required String newText,
  }) async {
    await _session.sendRequest(PluginMethods.editorReplaceText, {
      'startLine': startLine,
      'startColumn': startColumn,
      'endLine': endLine,
      'endColumn': endColumn,
      'newText': newText,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getSelections() async {
    final result = await _session.sendRequest(
      PluginMethods.editorGetSelections,
    );
    return (result as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> setSelections(List<Map<String, dynamic>> selections) async {
    await _session.sendRequest(PluginMethods.editorSetSelections, {
      'selections': selections,
    });
  }
}

class _RpcWorkspace implements LumideWorkspace {
  _RpcWorkspace(this._session) {
    // Register handlers for incoming document event notifications.
    _session.registerMethod(HostMethods.didOpenTextDocument, (params) async {
      final uri = (params.value as Map<String, dynamic>)['uri'] as String;
      for (final cb in _openCallbacks) {
        cb(uri);
      }
      return null;
    });
    _session.registerMethod(HostMethods.didCloseTextDocument, (params) async {
      final uri = (params.value as Map<String, dynamic>)['uri'] as String;
      for (final cb in _closeCallbacks) {
        cb(uri);
      }
      return null;
    });
    _session.registerMethod(HostMethods.didChangeTextDocument, (params) async {
      final data = params.value as Map<String, dynamic>;
      final uri = data['uri'] as String;
      final rawChanges = data['changes'] as List? ?? [];
      final changes = rawChanges.map((c) {
        final change = c as Map<String, dynamic>;
        return DocumentContentChange(
          text: change['text'] as String,
          startLine: change['startLine'] as int?,
          startColumn: change['startColumn'] as int?,
          endLine: change['endLine'] as int?,
          endColumn: change['endColumn'] as int?,
        );
      }).toList();
      final event = DocumentChangeEvent(uri: uri, changes: changes);
      for (final cb in _changeCallbacks) {
        cb(event);
      }
      return null;
    });
  }

  final RpcSession _session;
  final _openCallbacks = <void Function(String)>[];
  final _closeCallbacks = <void Function(String)>[];
  final _changeCallbacks = <void Function(DocumentChangeEvent)>[];

  @override
  Future<Object?> getConfiguration(String section) async {
    final result = await _session.sendRequest(
      PluginMethods.workspaceGetConfiguration,
      {'section': section},
    );
    return result;
  }

  @override
  void onDidOpenTextDocument(void Function(String uri) callback) {
    _openCallbacks.add(callback);
  }

  @override
  void onDidCloseTextDocument(void Function(String uri) callback) {
    _closeCallbacks.add(callback);
  }

  @override
  void onDidChangeTextDocument(
    void Function(DocumentChangeEvent event) callback,
  ) {
    _changeCallbacks.add(callback);
  }
}

class _RpcCommands implements LumideCommands {
  _RpcCommands(this._session) {
    _session.registerMethod(HostMethods.commandsExecute, (params) async {
      final data = params.value as Map<String, dynamic>;
      final commandId = data['id'] as String;
      final callback = _callbacks[commandId];
      if (callback != null) {
        await callback();
      }
      return null;
    });
  }

  final RpcSession _session;
  final _callbacks = <String, Future<void> Function()>{};

  @override
  Future<void> registerCommand({
    required String id,
    required String title,
    String? category,
    required Future<void> Function() callback,
  }) async {
    _callbacks[id] = callback;
    await _session.sendRequest(PluginMethods.commandsRegister, {
      'id': id,
      'title': title,
      if (category != null) 'category': category,
    });
  }
}

class _RpcStatusBar implements LumideStatusBar {
  _RpcStatusBar(this._session);
  final RpcSession _session;

  @override
  Future<void> createItem({
    required String id,
    required String text,
    String? tooltip,
    String? command,
    String? color,
    String? iconName,
    String alignment = 'right',
    int priority = 0,
  }) async {
    await _session.sendRequest(PluginMethods.statusBarCreate, {
      'id': id,
      'text': text,
      if (tooltip != null) 'tooltip': tooltip,
      if (command != null) 'command': command,
      if (color != null) 'color': color,
      if (iconName != null) 'iconName': iconName,
      'alignment': alignment,
      'priority': priority,
    });
  }

  @override
  Future<void> updateItem(
    String id, {
    String? text,
    String? tooltip,
    String? command,
    String? color,
    String? iconName,
  }) async {
    await _session.sendRequest(PluginMethods.statusBarUpdate, {
      'id': id,
      if (text != null) 'text': text,
      if (tooltip != null) 'tooltip': tooltip,
      if (command != null) 'command': command,
      if (color != null) 'color': color,
      if (iconName != null) 'iconName': iconName,
    });
  }

  @override
  Future<void> disposeItem(String id) async {
    await _session.sendRequest(PluginMethods.statusBarDispose, {'id': id});
  }

  @override
  Future<void> show(String id) async {
    await _session.sendRequest(PluginMethods.statusBarUpdate, {
      'id': id,
      'visible': true,
    });
  }

  @override
  Future<void> hide(String id) async {
    await _session.sendRequest(PluginMethods.statusBarUpdate, {
      'id': id,
      'visible': false,
    });
  }
}
