/// LumideContext implementation using RPC.
library;

import 'dart:async';

import 'package:json_rpc_2/error_code.dart' as rpc_error_code;
import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;
import 'package:lumide_api/lumide_api.dart';
import 'package:lumide_api/src/plugin/lumide_disposable.dart';

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
  late final LumideMenus menus = _RpcMenus(_session);

  @override
  late final LumideStatusBar statusBar = _RpcStatusBar(_session);

  @override
  late final LumideToolbar toolbar = _RpcToolbar(_session);

  @override
  late final LumideDebug debug = _RpcDebug(_session);

  @override
  late final LumideLaunch launch = _RpcLaunch(_session);

  @override
  late final LumideSdks sdks = _RpcSdks(_session);

  @override
  late final LumideLanguages languages = _RpcLanguages(_session);

  @override
  late final LumideTests tests = _RpcTests(_session);
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
  Future<void> createDirectory(String path, {bool recursive = false}) async {
    await _session.sendRequest(PluginMethods.fsCreateDirectory, {
      'path': path,
      'recursive': recursive,
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

  @override
  Future<bool> isDirectory(String path) async {
    final result =
        await _session.sendRequest(PluginMethods.fsIsDirectory, {'path': path});
    return result as bool;
  }

  @override
  Future<void> downloadFile(
    String url,
    String destination, {
    String? label,
    bool extract = false,
  }) async {
    await _session.sendRequest(PluginMethods.fsDownloadFile, {
      'url': url,
      'destination': destination,
      if (label != null) 'label': label,
      'extract': extract,
    });
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
  _RpcShell(this._session) {
    _session.registerMethod(HostMethods.shellOnStdout, (params) async {
      final pid = params['pid'].asInt;
      final data = params['data'].asString;
      for (final cb in [..._stdoutCallbacks]) {
        cb(pid, data);
      }
      return null;
    });
    _session.registerMethod(HostMethods.shellOnStderr, (params) async {
      final pid = params['pid'].asInt;
      final data = params['data'].asString;
      for (final cb in [..._stderrCallbacks]) {
        cb(pid, data);
      }
      return null;
    });
    _session.registerMethod(HostMethods.shellOnExit, (params) async {
      final pid = params['pid'].asInt;
      final exitCode = params['exitCode'].asInt;
      for (final cb in [..._exitCallbacks]) {
        cb(pid, exitCode);
      }
      return null;
    });
  }

  final RpcSession _session;
  final _stdoutCallbacks = <void Function(int, String)>[];
  final _stderrCallbacks = <void Function(int, String)>[];
  final _exitCallbacks = <void Function(int, int)>[];

  @override
  Future<ProcessResult> run(
    String command,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    String? stdin,
  }) async {
    final result = await _session.sendRequest(PluginMethods.shellRun, {
      'command': command,
      'arguments': arguments,
      if (workingDirectory != null) 'workingDirectory': workingDirectory,
      if (environment != null) 'environment': environment,
      if (stdin != null) 'stdin': stdin,
    });
    final json = result as Map<String, dynamic>;
    return ProcessResult(
      exitCode: json['exitCode'] as int,
      stdout: json['stdout'] as String,
      stderr: json['stderr'] as String,
    );
  }

  @override
  Future<int> spawn(
    String command,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final result = await _session.sendRequest(PluginMethods.shellSpawn, {
      'command': command,
      'arguments': arguments,
      if (workingDirectory != null) 'workingDirectory': workingDirectory,
      if (environment != null) 'environment': environment,
    });
    return result as int;
  }

  @override
  Future<void> writeStdin(int pid, String text) async {
    await _session.sendRequest(PluginMethods.shellWriteStdin, {
      'pid': pid,
      'text': text,
    });
  }

  @override
  Future<bool> kill(int pid, {LumideProcessSignal? signal}) async {
    final result = await _session.sendRequest(PluginMethods.shellKill, {
      'pid': pid,
      if (signal != null) 'signal': signal.wireName,
    });
    return result as bool;
  }

  @override
  LumideDisposable onStdout(void Function(int pid, String data) callback) {
    return addListener(_stdoutCallbacks, callback);
  }

  @override
  LumideDisposable onStderr(void Function(int pid, String data) callback) {
    return addListener(_stderrCallbacks, callback);
  }

  @override
  LumideDisposable onExit(void Function(int pid, int exitCode) callback) {
    return addListener(_exitCallbacks, callback);
  }
}

class _RpcProgress implements LumideProgress {
  _RpcProgress(this.id, this._session, this._onDone);

  @override
  final String id;
  final RpcSession _session;
  final void Function() _onDone;
  final _cancelCallbacks = <void Function()>[];
  bool _isCancelled = false;
  bool _isDone = false;

  @override
  bool get isCancelled => _isCancelled;

  @override
  Future<void> report({String? message, double? percentage}) async {
    if (_isDone) return;
    await _session.sendRequest(PluginMethods.windowReportProgress, {
      'id': id,
      if (message != null) 'message': message,
      if (percentage != null) 'percentage': percentage,
    });
  }

  @override
  Future<void> done() async {
    if (_isDone) return;
    _isDone = true;
    _onDone();
    await _session.sendRequest(PluginMethods.windowEndProgress, {'id': id});
  }

  @override
  LumideDisposable onCancel(void Function() callback) {
    return addListener(_cancelCallbacks, callback);
  }

  void _cancel() {
    if (_isCancelled || _isDone) return;
    _isCancelled = true;
    for (final callback in [..._cancelCallbacks]) {
      callback();
    }
  }
}

class _RpcWindow implements LumideWindow {
  _RpcWindow(this._session) {
    _session.registerNotificationHandler(HostMethods.windowCancelProgress, (
      params,
    ) {
      _progresses[params['id'].value as String]?._cancel();
    });

    _session.registerMethod(PluginMethods.terminalOnData, (params) async {
      final id = params['id'].asString;
      final data = params['data'].asString;

      final terminal = _terminals[id];
      if (terminal != null) {
        terminal._emitData(data);
      }
      return null;
    });

    _session.registerNotificationHandler(
        PluginMethods.webviewOnDidReceiveMessage, (params) {
      final id = params['id'].value as String;
      final panel = _webviewPanels[id];
      if (panel != null) {
        panel._onMessage(params['message'].value);
      }
    });

    _session.registerNotificationHandler(PluginMethods.webviewOnDidDispose,
        (params) {
      final id = params['id'].value as String;
      final panel = _webviewPanels.remove(id);
      panel?._messageController.close();
    });

    _session.registerNotificationHandler(PluginMethods.terminalOnDidDispose,
        (params) {
      final id = params['id'].value as String;
      final terminal = _terminals.remove(id);
      terminal?._dataCallbacks.clear();
    });
  }

  final RpcSession _session;
  final _terminals = <String, _RpcTerminal>{};
  final _webviewPanels = <String, _RpcWebviewPanel>{};

  @override
  Future<void> showMessage(String message,
      {MessageType type = MessageType.info, String? title}) async {
    await _session.sendRequest(PluginMethods.windowShowMessage, {
      'message': message,
      'type': type.name,
      if (title != null) 'title': title,
    });
  }

  @override
  Future<QuickPickItem?> showQuickPick(
    List<QuickPickItem> items, {
    String? placeholder,
    bool matchOnDescription = true,
    bool matchOnDetail = true,
    Map<String, int>? position,
  }) async {
    final result =
        await _session.sendRequest(PluginMethods.windowShowQuickPick, {
      'items': items.map((e) => e.toJson()).toList(),
      if (placeholder != null) 'placeHolder': placeholder,
      'matchOnDescription': matchOnDescription,
      'matchOnDetail': matchOnDetail,
      if (position != null) 'position': position,
    });

    if (result == null) return null;

    if (result is Map) {
      return QuickPickItem(
        label: result['label'] ?? '',
        payload: result,
      );
    }
    return QuickPickItem(label: result.toString(), payload: result);
  }

  @override
  Future<String?> showInputBox({
    String? prompt,
    String? value,
    String? placeHolder,
    bool password = false,
    String? title,
  }) async {
    final result =
        await _session.sendRequest(PluginMethods.windowShowInputBox, {
      if (prompt != null) 'prompt': prompt,
      if (value != null) 'value': value,
      if (placeHolder != null) 'placeHolder': placeHolder,
      'password': password,
      if (title != null) 'title': title,
    });
    return result as String?;
  }

  @override
  Future<LumideOutputChannel> createOutputChannel(String name,
      {int? maxEntries}) async {
    final result =
        await _session.sendRequest(PluginMethods.windowCreateOutputChannel, {
      'name': name,
      if (maxEntries != null) 'maxEntries': maxEntries,
    });
    final id = result as String;
    return _RpcOutputChannel(id, _session);
  }

  @override
  Future<LumideTerminal> createTerminal({
    String? name,
    String? shellPath,
    List<String>? shellArgs,
  }) async {
    final result = await _session.sendRequest(PluginMethods.terminalCreate, {
      if (name != null) 'name': name,
      if (shellPath != null) 'shellPath': shellPath,
      if (shellArgs != null) 'shellArgs': shellArgs,
    });
    final id = result as String;
    final terminal = _RpcTerminal(id, _session, () {
      _terminals.remove(id);
    });
    _terminals[id] = terminal;
    return terminal;
  }

  @override
  Future<bool> openUrl(String url) async {
    final result = await _session.sendRequest(PluginMethods.windowOpenUrl, {
      'url': url,
    });
    return result as bool;
  }

  final _progresses = <String, _RpcProgress>{};
  int _lastProgressId = 0;

  @override
  Future<LumideProgress> createProgress({
    required String title,
    String? message,
    bool cancellable = false,
  }) async {
    final id = 'progress-${++_lastProgressId}';
    final progress = _RpcProgress(id, _session, () => _progresses.remove(id));
    _progresses[id] = progress;
    try {
      await _session.sendRequest(PluginMethods.windowCreateProgress, {
        'id': id,
        'title': title,
        if (message != null) 'message': message,
        'cancellable': cancellable,
      });
    } catch (_) {
      _progresses.remove(id);
      rethrow;
    }
    return progress;
  }

  @override
  Future<T> withProgress<T>({
    required String title,
    String? message,
    bool cancellable = false,
    required Future<T> Function(LumideProgress progress) task,
  }) async {
    final progress = await createProgress(
      title: title,
      message: message,
      cancellable: cancellable,
    );
    try {
      return await task(progress);
    } finally {
      await progress.done();
    }
  }

  @override
  Future<LumideWebviewPanel> createWebviewPanel(
    String viewType,
    String title, {
    Map<String, dynamic>? options,
  }) async {
    final result =
        await _session.sendRequest(PluginMethods.windowCreateWebviewPanel, {
      'viewType': viewType,
      'title': title,
      if (options != null) 'options': options,
    });
    final id = result as String;
    final panel = _RpcWebviewPanel(id, _session, () {
      _webviewPanels.remove(id);
    });
    _webviewPanels[id] = panel;
    return panel;
  }

  @override
  Future<bool> showConfirmDialog(String message, {String? title}) async {
    final result =
        await _session.sendRequest(PluginMethods.windowShowConfirmDialog, {
      'message': message,
      if (title != null) 'title': title,
    });
    return (result as bool?) ?? false;
  }

  @override
  Future<void> showDeviceAuthDialog({
    required String userCode,
    required String verificationUri,
  }) async {
    await _session.sendRequest(PluginMethods.windowShowDeviceAuthDialog, {
      'userCode': userCode,
      'verificationUri': verificationUri,
    });
  }

  @override
  Future<String?> showOpenDialog({
    String? title,
    String? defaultPath,
  }) async {
    final result =
        await _session.sendRequest(PluginMethods.windowShowOpenDialog, {
      if (title != null) 'title': title,
      if (defaultPath != null) 'defaultPath': defaultPath,
    });
    return result as String?;
  }

  @override
  Future<String?> showOpenFolderDialog({
    String? title,
    String? defaultPath,
  }) async {
    final result =
        await _session.sendRequest(PluginMethods.windowShowOpenFolderDialog, {
      if (title != null) 'title': title,
      if (defaultPath != null) 'defaultPath': defaultPath,
    });
    return result as String?;
  }
}

class _RpcWebviewPanel implements LumideWebviewPanel {
  _RpcWebviewPanel(this._id, this._session, this._onDispose);

  final String _id;
  final RpcSession _session;
  final void Function() _onDispose;
  final _messageController = StreamController<Object>.broadcast();

  void _onMessage(Object message) {
    _messageController.add(message);
  }

  @override
  Future<void> postMessage(Object message) async {
    await _session.sendRequest(PluginMethods.webviewPostMessage, {
      'id': _id,
      'message': message,
    });
  }

  @override
  LumideDisposable onDidReceiveMessage(void Function(Object message) callback) {
    final subscription = _messageController.stream.listen(callback);
    return LumideDisposable(() => unawaited(subscription.cancel()));
  }

  @override
  Future<void> dispose() async {
    await _session.sendRequest(PluginMethods.webviewDispose, {'id': _id});
    _onDispose();
    await _messageController.close();
  }
}

class _RpcTerminal implements LumideTerminal {
  _RpcTerminal(this._id, this._session, this._onDispose);

  final String _id;
  final RpcSession _session;
  final void Function() _onDispose;
  final _dataCallbacks = <void Function(String)>[];

  void _emitData(String data) {
    for (final cb in [..._dataCallbacks]) {
      cb(data);
    }
  }

  @override
  Future<void> sendText(String text, {bool addNewLine = true}) async {
    await _session.sendRequest(PluginMethods.terminalSendText, {
      'id': _id,
      'text': text,
      'addNewLine': addNewLine,
    });
  }

  @override
  Future<void> show({bool preserveFocus = false}) async {
    await _session.sendRequest(PluginMethods.terminalShow, {
      'id': _id,
      'preserveFocus': preserveFocus,
    });
  }

  @override
  Future<void> dispose() async {
    await _session.sendRequest(PluginMethods.terminalDispose, {'id': _id});
    _onDispose();
  }

  @override
  LumideDisposable onData(void Function(String data) callback) {
    return addListener(_dataCallbacks, callback);
  }
}

class _RpcOutputChannel implements LumideOutputChannel {
  _RpcOutputChannel(this._id, this._session);

  final String _id;
  final RpcSession _session;

  @override
  String get id => _id;

  @override
  Future<void> append(String value) async {
    await _session.sendRequest(PluginMethods.windowAppendOutput, {
      'id': _id,
      'value': value,
    });
  }

  @override
  Future<void> appendLine(String value) async {
    await _session.sendRequest(PluginMethods.windowAppendOutput, {
      'id': _id,
      'value': '$value\n',
    });
  }

  @override
  Future<void> appendLog(LumideLogRecord record) async {
    await _session.sendRequest(PluginMethods.windowAppendLog, {
      'id': _id,
      'record': record.toJson(),
    });
  }

  @override
  Future<void> clear() async {
    await _session.sendRequest(PluginMethods.windowClearOutput, {'id': _id});
  }

  @override
  Future<void> show({bool preserveFocus = false}) async {
    await _session.sendRequest(PluginMethods.windowShowOutput, {
      'id': _id,
      'preserveFocus': preserveFocus,
    });
  }

  @override
  Future<void> dispose() async {
    await _session
        .sendRequest(PluginMethods.windowDisposeOutputChannel, {'id': _id});
  }
}

class _RpcDebug implements LumideDebug {
  _RpcDebug(this._session) {
    _session.registerMethod(HostMethods.debugLaunch, (params) async {
      final callback = _launchCallback;
      if (callback == null) return null;
      await callback();
      return null;
    });
    _session.registerMethod(HostMethods.debugContinue, (params) async {
      final callback = _continueCallback;
      if (callback == null) return null;
      final sessionId = params['sessionId'].asString;
      await callback(sessionId);
      return null;
    });
    _session.registerMethod(HostMethods.debugPause, (params) async {
      final callback = _pauseCallback;
      if (callback == null) return null;
      final sessionId = params['sessionId'].asString;
      await callback(sessionId);
      return null;
    });
    _session.registerMethod(HostMethods.debugStepOver, (params) async {
      final callback = _stepOverCallback;
      if (callback == null) return null;
      final sessionId = params['sessionId'].asString;
      await callback(sessionId);
      return null;
    });
    _session.registerMethod(HostMethods.debugStepInto, (params) async {
      final callback = _stepIntoCallback;
      if (callback == null) return null;
      final sessionId = params['sessionId'].asString;
      await callback(sessionId);
      return null;
    });
    _session.registerMethod(HostMethods.debugStepOut, (params) async {
      final callback = _stepOutCallback;
      if (callback == null) return null;
      final sessionId = params['sessionId'].asString;
      await callback(sessionId);
      return null;
    });
    _session.registerMethod(HostMethods.debugStop, (params) async {
      final callback = _stopCallback;
      if (callback == null) return null;
      final sessionId = params['sessionId'].asString;
      await callback(sessionId);
      return null;
    });
    _session.registerMethod(HostMethods.debugSetBreakpoints, (params) async {
      final callback = _setBreakpointsCallback;
      if (callback == null) return null;
      final sessionId = params['sessionId'].asString;
      final rawBreakpoints = params['breakpoints'].asList;
      final breakpoints = <LumideDebugBreakpoint>[
        for (final item in rawBreakpoints)
          LumideDebugBreakpoint.fromJson(item as Map),
      ];
      await callback(sessionId, breakpoints);
      return null;
    });
    _session.registerMethod(
      HostMethods.debugSetExceptionPauseMode,
      (params) async {
        final callback = _setExceptionPauseModeCallback;
        if (callback == null) return null;
        final sessionId = params['sessionId'].asString;
        final mode = lumideDebugExceptionPauseModeFromJson(
          params['mode'].valueOr(null),
        );
        await callback(sessionId, mode);
        return null;
      },
    );
    _session.registerMethod(HostMethods.debugGetStackFrames, (params) async {
      final callback = _stackFramesCallback;
      if (callback == null) return const <Map<String, dynamic>>[];
      final sessionId = params['sessionId'].asString;
      final frames = await callback(sessionId);
      return frames.map((frame) => frame.toJson()).toList();
    });
    _session.registerMethod(HostMethods.debugGetScopes, (params) async {
      final callback = _scopesCallback;
      if (callback == null) return const <Map<String, dynamic>>[];
      final sessionId = params['sessionId'].asString;
      final frameId = params['frameId'].asInt;
      final scopes = await callback(sessionId, frameId);
      return scopes.map((scope) => scope.toJson()).toList();
    });
    _session.registerMethod(HostMethods.debugGetVariables, (params) async {
      final callback = _variablesCallback;
      if (callback == null) return const <Map<String, dynamic>>[];
      final sessionId = params['sessionId'].asString;
      final scopeId = params['scopeId'].asInt;
      final variables = await callback(sessionId, scopeId);
      return variables.map((variable) => variable.toJson()).toList();
    });
    _session.registerMethod(HostMethods.debugEvaluate, (params) async {
      final callback = _evaluateCallback;
      if (callback == null) return null;
      final sessionId = params['sessionId'].asString;
      final expression = params['expression'].asString;
      final frameId = params['frameId'].valueOr(null) as int?;
      final result = await callback(
        sessionId,
        expression,
        frameId: frameId,
      );
      return result?.toJson();
    });
  }

  final RpcSession _session;

  Future<void> Function()? _launchCallback;
  LumideDebugSessionCallback? _continueCallback;
  LumideDebugSessionCallback? _pauseCallback;
  LumideDebugSessionCallback? _stepOverCallback;
  LumideDebugSessionCallback? _stepIntoCallback;
  LumideDebugSessionCallback? _stepOutCallback;
  LumideDebugSessionCallback? _stopCallback;
  LumideDebugSetBreakpointsCallback? _setBreakpointsCallback;
  LumideDebugSetExceptionPauseModeCallback? _setExceptionPauseModeCallback;
  LumideDebugStackFramesCallback? _stackFramesCallback;
  LumideDebugScopesCallback? _scopesCallback;
  LumideDebugVariablesCallback? _variablesCallback;
  LumideDebugEvaluateCallback? _evaluateCallback;

  @override
  Future<void> startSession(LumideDebugSession session) async {
    await _session.sendRequest(PluginMethods.debugStartSession, {
      'session': session.toJson(),
    });
  }

  @override
  Future<void> updateSession(LumideDebugSession session) async {
    await _session.sendRequest(PluginMethods.debugUpdateSession, {
      'session': session.toJson(),
    });
  }

  @override
  Future<void> updateBreakpoints(
    String sessionId,
    List<LumideDebugBreakpoint> breakpoints,
  ) async {
    await _session.sendRequest(PluginMethods.debugUpdateBreakpoints, {
      'sessionId': sessionId,
      'breakpoints':
          breakpoints.map((breakpoint) => breakpoint.toJson()).toList(),
    });
  }

  @override
  Future<void> endSession(String sessionId) async {
    await _session.sendRequest(PluginMethods.debugEndSession, {
      'sessionId': sessionId,
    });
  }

  @override
  void onLaunch(Future<void> Function() callback) {
    _launchCallback = callback;
  }

  @override
  void onContinue(LumideDebugSessionCallback callback) {
    _continueCallback = callback;
  }

  @override
  void onPause(LumideDebugSessionCallback callback) {
    _pauseCallback = callback;
  }

  @override
  void onStepOver(LumideDebugSessionCallback callback) {
    _stepOverCallback = callback;
  }

  @override
  void onStepInto(LumideDebugSessionCallback callback) {
    _stepIntoCallback = callback;
  }

  @override
  void onStepOut(LumideDebugSessionCallback callback) {
    _stepOutCallback = callback;
  }

  @override
  void onStop(LumideDebugSessionCallback callback) {
    _stopCallback = callback;
  }

  @override
  void onSetBreakpoints(LumideDebugSetBreakpointsCallback callback) {
    _setBreakpointsCallback = callback;
  }

  @override
  void onSetExceptionPauseMode(
    LumideDebugSetExceptionPauseModeCallback callback,
  ) {
    _setExceptionPauseModeCallback = callback;
  }

  @override
  void onGetStackFrames(LumideDebugStackFramesCallback callback) {
    _stackFramesCallback = callback;
  }

  @override
  void onGetScopes(LumideDebugScopesCallback callback) {
    _scopesCallback = callback;
  }

  @override
  void onGetVariables(LumideDebugVariablesCallback callback) {
    _variablesCallback = callback;
  }

  @override
  void onEvaluate(LumideDebugEvaluateCallback callback) {
    _evaluateCallback = callback;
  }
}

class _RpcEditor implements LumideEditor {
  _RpcEditor(this._session) {
    _session.registerMethod(HostMethods.didChangeSelections, (params) async {
      final data = params.value as Map<String, dynamic>;
      final raw = data['selections'] as List? ?? [];
      final selections = raw.cast<Map<String, dynamic>>();
      for (final cb in [..._selectionCallbacks]) {
        cb(selections);
      }
      return null;
    });
    _session.registerMethod(
      HostMethods.didChangeActiveDocument,
      (params) async {
        final data = params.value as Map<String, dynamic>;
        final uri = data['uri'] as String?;
        for (final cb in [..._activeDocCallbacks]) {
          cb(uri);
        }
        return null;
      },
    );
  }

  final RpcSession _session;
  final _selectionCallbacks = <void Function(List<Map<String, dynamic>>)>[];
  final _activeDocCallbacks = <void Function(String?)>[];

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

  @override
  LumideDisposable onDidChangeSelections(
    void Function(List<Map<String, dynamic>> selections) callback,
  ) {
    return addListener(_selectionCallbacks, callback);
  }

  @override
  LumideDisposable onDidChangeActiveDocument(
      void Function(String? uri) callback) {
    return addListener(_activeDocCallbacks, callback);
  }

  @override
  Future<String?> getSelectedText() async {
    final result =
        await _session.sendRequest(PluginMethods.editorGetSelectedText);
    return result as String?;
  }

  @override
  Future<void> replaceSelection(String text) async {
    await _session.sendRequest(PluginMethods.editorReplaceSelection, {
      'text': text,
    });
  }

  @override
  Future<String?> getDocumentText(String uri) async {
    final result = await _session
        .sendRequest(PluginMethods.editorGetDocumentText, {'uri': uri});
    return result as String?;
  }

  @override
  Future<void> openDocument(String uri) async {
    await _session.sendRequest(PluginMethods.editorOpenDocument, {'uri': uri});
  }

  @override
  Future<void> revealRange({
    required String uri,
    required int line,
    int? column,
  }) async {
    await _session.sendRequest(PluginMethods.editorRevealRange, {
      'uri': uri,
      'line': line,
      if (column != null) 'column': column,
    });
  }
}

class _RpcWorkspace implements LumideWorkspace {
  _RpcWorkspace(this._session) {
    // Register handlers for incoming document event notifications.
    _session.registerMethod(HostMethods.didOpenTextDocument, (params) async {
      final uri = (params.value as Map<String, dynamic>)['uri'] as String;
      for (final cb in [..._openCallbacks]) {
        cb(uri);
      }
      return null;
    });
    _session.registerMethod(HostMethods.didCloseTextDocument, (params) async {
      final uri = (params.value as Map<String, dynamic>)['uri'] as String;
      for (final cb in [..._closeCallbacks]) {
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
      final event = DocumentChangeEvent(
        uri: uri,
        changes: changes,
        version: data['version'] as int?,
      );
      for (final cb in [..._changeCallbacks]) {
        cb(event);
      }
      return null;
    });
    _session.registerMethod(HostMethods.didChangeConfiguration, (params) async {
      final data = params.value as Map<String, dynamic>;
      final settings = data['settings'] as Map<String, dynamic>? ?? {};
      for (final cb in [..._configCallbacks]) {
        cb(settings);
      }
      return null;
    });
    _session.registerNotificationHandler(
      HostMethods.didChangeWorkspaceFolders,
      (params) {
        final event = LumideWorkspaceFoldersChangeEvent.fromJson(
          params.value as Map,
        );
        for (final callback in [..._workspaceFolderCallbacks]) {
          callback(event);
        }
      },
    );
    _session.registerNotificationHandler(HostMethods.didChangeFiles, (params) {
      final event = LumideFileChangeEvent.fromJson(params.value as Map);
      for (final callback in [..._fileChangeCallbacks]) {
        callback(event);
      }
    });
    _session.registerMethod(HostMethods.didSaveTextDocument, (params) async {
      final uri = (params.value as Map<String, dynamic>)['uri'] as String;
      for (final cb in [..._saveCallbacks]) {
        cb(uri);
      }
      return null;
    });
  }

  final RpcSession _session;
  final _openCallbacks = <void Function(String)>[];
  final _closeCallbacks = <void Function(String)>[];
  final _changeCallbacks = <void Function(DocumentChangeEvent)>[];
  final _configCallbacks = <void Function(Map<String, Object?>)>[];
  final _saveCallbacks = <void Function(String)>[];
  final _fileChangeCallbacks = <void Function(LumideFileChangeEvent)>[];
  final _workspaceFolderCallbacks =
      <void Function(LumideWorkspaceFoldersChangeEvent)>[];

  @override
  Future<Object?> getConfiguration(String section) async {
    final result = await _session.sendRequest(
      PluginMethods.workspaceGetConfiguration,
      {'section': section},
    );
    return result;
  }

  @override
  Future<void> updateConfiguration(String section, Object? value) async {
    await _session.sendRequest(
      PluginMethods.workspaceUpdateConfiguration,
      {'section': section, 'value': value},
    );
  }

  @override
  LumideDisposable onDidOpenTextDocument(void Function(String uri) callback) {
    return addListener(_openCallbacks, callback);
  }

  @override
  LumideDisposable onDidCloseTextDocument(void Function(String uri) callback) {
    return addListener(_closeCallbacks, callback);
  }

  @override
  LumideDisposable onDidChangeTextDocument(
    void Function(DocumentChangeEvent event) callback,
  ) {
    final isFirstListener = _changeCallbacks.isEmpty;
    final registration = addListener(_changeCallbacks, callback);
    if (isFirstListener) _setTextDocumentChangeSubscription(enabled: true);
    return LumideDisposable(() {
      registration.dispose();
      if (_changeCallbacks.isNotEmpty) return;
      _setTextDocumentChangeSubscription(enabled: false);
    });
  }

  /// Hosts older than 1.12 do not know this request and always stay silent,
  /// so failures are ignored.
  void _setTextDocumentChangeSubscription({required bool enabled}) {
    unawaited(
      _session.sendRequest(
        PluginMethods.workspaceSetTextDocumentChangeSubscription,
        {'enabled': enabled},
      ).catchError((Object _) => null),
    );
  }

  @override
  LumideDisposable onDidChangeConfiguration(
    void Function(Map<String, Object?> settings) callback,
  ) {
    return addListener(_configCallbacks, callback);
  }

  @override
  LumideDisposable onDidChangeFiles(
    void Function(LumideFileChangeEvent event) callback,
  ) {
    final isFirstListener = _fileChangeCallbacks.isEmpty;
    final registration = addListener(_fileChangeCallbacks, callback);
    if (isFirstListener) _setFileChangeSubscription(enabled: true);
    return LumideDisposable(() {
      registration.dispose();
      if (_fileChangeCallbacks.isNotEmpty) return;
      _setFileChangeSubscription(enabled: false);
    });
  }

  void _setFileChangeSubscription({required bool enabled}) {
    unawaited(
      _session.sendRequest(
        PluginMethods.workspaceSetFileChangeSubscription,
        {'enabled': enabled},
      ).catchError((Object _) => null),
    );
  }

  @override
  LumideDisposable onDidSaveTextDocument(void Function(String uri) callback) {
    return addListener(_saveCallbacks, callback);
  }

  @override
  Future<String?> getRootUri() async {
    final result =
        await _session.sendRequest(PluginMethods.workspaceGetRootUri);
    return result as String?;
  }

  @override
  Future<List<LumideWorkspaceFolder>> getWorkspaceFolders() async {
    final result = await _session.sendRequest(
      PluginMethods.workspaceGetWorkspaceFolders,
    );
    return [
      for (final folder in result as List? ?? const [])
        LumideWorkspaceFolder.fromJson(folder as Map),
    ];
  }

  @override
  LumideDisposable onDidChangeWorkspaceFolders(
    void Function(LumideWorkspaceFoldersChangeEvent event) callback,
  ) {
    return addListener(_workspaceFolderCallbacks, callback);
  }

  @override
  Future<String> getPluginStorageDir() async {
    final result = await _session.sendRequest(
      PluginMethods.workspaceGetPluginStorageDir,
    );
    return result as String;
  }

  @override
  Future<List<String>> findFiles(String glob, {int? maxResults}) async {
    final result =
        await _session.sendRequest(PluginMethods.workspaceFindFiles, {
      'glob': glob,
      if (maxResults != null) 'maxResults': maxResults,
    });
    return (result as List).cast<String>();
  }
}

class _RpcCommands implements LumideCommands {
  _RpcCommands(this._session) {
    _session.registerMethod(HostMethods.commandsExecute, (params) async {
      final data = params.value as Map<String, dynamic>;
      final commandId = data['id'] as String;
      final args = data['args'] as Map<String, dynamic>?;
      final callback = _callbacks[commandId];
      if (callback != null) {
        await callback(args);
      }
      return null;
    });
  }

  final RpcSession _session;
  final _callbacks = <String, Future<void> Function([Map<String, dynamic>?])>{};

  @override
  Future<void> registerCommand({
    required String id,
    required String title,
    String? category,
    required Future<void> Function([Map<String, dynamic>? args]) callback,
  }) async {
    _callbacks[id] = callback;
    await _session.sendRequest(PluginMethods.commandsRegister, {
      'id': id,
      'title': title,
      if (category != null) 'category': category,
    });
  }

  @override
  Future<bool> executeCommand(String id, [Map<String, dynamic>? args]) async {
    final result =
        await _session.sendRequest(PluginMethods.commandsExecuteCommand, {
      'id': id,
      if (args != null) 'args': args,
    });
    return result == true;
  }
}

class _RpcMenus implements LumideMenus {
  _RpcMenus(this._session);

  final RpcSession _session;

  @override
  Future<void> registerAction(LumideMenuAction action) async {
    await _session.sendRequest(
      PluginMethods.menusRegisterAction,
      action.toJson(),
    );
  }

  @override
  Future<void> unregisterAction(String id) async {
    await _session.sendRequest(
      PluginMethods.menusUnregisterAction,
      {'id': id},
    );
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
    String? iconPath,
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
      if (iconPath != null) 'iconPath': iconPath,
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
    String? iconPath,
  }) async {
    await _session.sendRequest(PluginMethods.statusBarUpdate, {
      'id': id,
      if (text != null) 'text': text,
      if (tooltip != null) 'tooltip': tooltip,
      if (command != null) 'command': command,
      if (color != null) 'color': color,
      if (iconName != null) 'iconName': iconName,
      if (iconPath != null) 'iconPath': iconPath,
    });
  }

  @override
  Future<void> disposeItem(String id) async {
    await _session.sendRequest(PluginMethods.statusBarDispose, {'id': id});
  }

  @override
  Future<void> show(String id) async {
    _session.sendNotification(PluginMethods.statusBarUpdate, {
      'id': id,
      'visible': true,
    });
  }

  @override
  Future<void> hide(String id) async {
    _session.sendNotification(PluginMethods.statusBarUpdate, {
      'id': id,
      'visible': false,
    });
  }
}

class _RpcToolbar implements LumideToolbar {
  _RpcToolbar(this._session) {
    _session.registerMethod(PluginMethods.toolbarOnTap, (params) async {
      final args = params.value as Map<String, dynamic>;
      final id = args['id'] as String;

      final positionMap = args['position'] as Map?;
      final position = <String, int>{};
      if (positionMap != null) {
        final x = positionMap['x'];
        final y = positionMap['y'];
        if (x is int && y is int) {
          position['x'] = x;
          position['y'] = y;
        }
      }

      for (final cb in [..._onTapCallbacks]) {
        cb(id, position);
      }
    });
  }

  final RpcSession _session;
  final _onTapCallbacks = <void Function(String, Map<String, int>)>[];

  @override
  Future<void> registerItem({
    required String id,
    required String icon,
    String? iconPath,
    String? label,
    String? tooltip,
    ToolbarItemAlignment alignment = ToolbarItemAlignment.right,
    int priority = 0,
  }) async {
    await _session.sendRequest(PluginMethods.toolbarRegisterItem, {
      'id': id,
      'icon': icon,
      if (iconPath != null) 'iconPath': iconPath,
      if (label != null) 'label': label,
      if (tooltip != null) 'tooltip': tooltip,
      'alignment': alignment.name,
      'priority': priority,
    });
  }

  @override
  Future<void> unregisterItem(String id) async {
    await _session.sendRequest(PluginMethods.toolbarUnregisterItem, {'id': id});
  }

  @override
  LumideDisposable onTap(
      void Function(String id, Map<String, int> position) callback) {
    return addListener(_onTapCallbacks, callback);
  }
}

class _RpcLaunch implements LumideLaunch {
  _RpcLaunch(this._session) {
    _session.registerMethod(HostMethods.launchDidStart, (params) async {
      final event = LumideLaunchEvent.fromJson(params.value as Map);
      for (final callback in [..._didStartCallbacks]) {
        callback(event);
      }
      return null;
    });
    _session.registerMethod(HostMethods.launchDidEnd, (params) async {
      final event = LumideLaunchEvent.fromJson(params.value as Map);
      for (final callback in [..._didEndCallbacks]) {
        callback(event);
      }
      return null;
    });
  }

  final RpcSession _session;
  final _didStartCallbacks = <void Function(LumideLaunchEvent event)>[];
  final _didEndCallbacks = <void Function(LumideLaunchEvent event)>[];

  @override
  Future<void> registerProvider({
    required String id,
    required String title,
    List<String> workspacePatterns = const [],
    List<LumideLaunchKind> kinds = const [LumideLaunchKind.run],
    List<LumideLaunchKind> defaultKinds = const [LumideLaunchKind.run],
    String? icon,
    String? iconPath,
    String? configurationSchema,
    List<Map<String, Object?>> configurationSnippets = const [],
    List<LumideLaunchImportDescriptor> configurationImports = const [],
    int priority = 0,
  }) async {
    await _session.sendRequest(PluginMethods.launchRegisterProvider, {
      'id': id,
      'title': title,
      if (workspacePatterns.isNotEmpty) 'workspacePatterns': workspacePatterns,
      'kinds': kinds.map((kind) => kind.name).toList(),
      'defaultKinds': defaultKinds.map((kind) => kind.name).toList(),
      if (icon != null) 'icon': icon,
      if (iconPath != null) 'iconPath': iconPath,
      if (configurationSchema != null)
        'configurationSchema': configurationSchema,
      if (configurationSnippets.isNotEmpty)
        'configurationSnippets': configurationSnippets,
      if (configurationImports.isNotEmpty)
        'configurationImports': configurationImports
            .map((descriptor) => descriptor.toJson())
            .toList(),
      'priority': priority,
    });
  }

  @override
  Future<void> unregisterProvider(String id) async {
    await _session.sendRequest(PluginMethods.launchUnregisterProvider, {
      'id': id,
    });
  }

  @override
  Future<void> updateConfigurations(
    String providerId,
    List<LumideLaunchConfiguration> configurations,
  ) async {
    await _session.sendRequest(PluginMethods.launchUpdateConfigurations, {
      'providerId': providerId,
      'configurations':
          configurations.map((config) => config.toJson()).toList(),
    });
  }

  @override
  Future<void> didStart(LumideLaunchEvent event) async {
    await _session.sendRequest(PluginMethods.launchDidStart, event.toJson());
  }

  @override
  Future<void> didEnd(LumideLaunchEvent event) async {
    await _session.sendRequest(PluginMethods.launchDidEnd, event.toJson());
  }

  @override
  void onResolveConfigurations(
    Future<List<LumideLaunchConfiguration>> Function(
      LumideLaunchResolveRequest request,
    ) callback,
  ) {
    _session.registerMethod(HostMethods.launchResolveConfigurations, (
      params,
    ) async {
      final request = LumideLaunchResolveRequest.fromJson(params.value as Map);
      final configurations = await callback(request);
      return configurations.map((config) => config.toJson()).toList();
    });
  }

  @override
  void onResolveConfiguration(
    Future<LumideLaunchResolution> Function(
      LumideLaunchSourceConfiguration source,
    ) callback,
  ) {
    _session.registerMethod(HostMethods.launchResolveConfiguration, (
      params,
    ) async {
      final source = LumideLaunchSourceConfiguration.fromJson(
        params.value as Map,
      );
      return (await callback(source)).toJson();
    });
  }

  @override
  void onImportConfiguration(
    Future<LumideLaunchImportResult> Function(
      LumideForeignLaunchConfiguration source,
    ) callback,
  ) {
    _session.registerMethod(HostMethods.launchImportConfiguration, (
      params,
    ) async {
      final source = LumideForeignLaunchConfiguration.fromJson(
        params.value as Map,
      );
      return (await callback(source)).toJson();
    });
  }

  @override
  void onConfigure(
    Future<LumideLaunchConfiguration?> Function(
      LumideLaunchConfigureRequest request,
    ) callback,
  ) {
    _session.registerMethod(HostMethods.launchConfigure, (params) async {
      final request =
          LumideLaunchConfigureRequest.fromJson(params.value as Map);
      final configuration = await callback(request);
      return configuration?.toJson();
    });
  }

  @override
  void onLaunch(
    Future<void> Function(LumideLaunchRequest request) callback,
  ) {
    _session.registerMethod(HostMethods.launchStart, (params) async {
      final request = LumideLaunchRequest.fromJson(params.value as Map);
      await callback(request);
      return null;
    });
  }

  @override
  LumideDisposable onDidStart(void Function(LumideLaunchEvent event) callback) {
    return addListener(_didStartCallbacks, callback);
  }

  @override
  LumideDisposable onDidEnd(void Function(LumideLaunchEvent event) callback) {
    return addListener(_didEndCallbacks, callback);
  }
}

class _RpcSdks implements LumideSdks {
  _RpcSdks(this._session) {
    _session.registerMethod(HostMethods.sdkDidChangeSelection, (params) async {
      final event = LumideSdkSelectionChangeEvent.fromJson(
        params.value as Map,
      );
      for (final callback in [..._selectionChangeCallbacks]) {
        callback(event);
      }
      return null;
    });
    _session.registerMethod(HostMethods.sdkActivateProvider, (params) async {
      final json = params.value as Map;
      final id = json['id']?.toString();
      final provider = id == null ? null : _registeredProviders[id];
      if (provider == null) return false;
      await _sendRequest(
        PluginMethods.sdkRegisterProvider,
        provider.toJson(),
      );
      return true;
    });
  }

  final RpcSession _session;
  final _registeredProviders = <String, LumideSdkProviderDescriptor>{};
  final _selectionChangeCallbacks =
      <void Function(LumideSdkSelectionChangeEvent event)>[];

  @override
  Future<void> registerProvider(LumideSdkProviderDescriptor provider) async {
    _registeredProviders[provider.id] = provider;
    await _sendRequest(
      PluginMethods.sdkRegisterProvider,
      provider.toJson(),
    );
  }

  @override
  Future<void> unregisterProvider(String id) async {
    _registeredProviders.remove(id);
    await _sendRequest(PluginMethods.sdkUnregisterProvider, {'id': id});
  }

  @override
  Future<void> didChange(String providerId) async {
    await _sendRequest(
      PluginMethods.sdkDidChange,
      {'providerId': providerId},
    );
  }

  @override
  Future<LumideSdkResolution?> resolve(LumideSdkResolveRequest request) async {
    final result = await _sendRequest(
      PluginMethods.sdkResolve,
      request.toJson(),
    );
    if (result is! Map) return null;
    return LumideSdkResolution.fromJson(result);
  }

  @override
  Future<ProcessResult> run(
    LumideSdkResolveRequest request,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final result = await _sendRequest(PluginMethods.sdkRun, {
      'request': request.toJson(),
      'arguments': arguments,
      if (workingDirectory != null) 'workingDirectory': workingDirectory,
      if (environment != null) 'environment': environment,
    });
    final json = result as Map;
    return ProcessResult(
      exitCode: json['exitCode'] as int,
      stdout: json['stdout']?.toString() ?? '',
      stderr: json['stderr']?.toString() ?? '',
    );
  }

  @override
  Future<int> spawn(
    LumideSdkResolveRequest request,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final result = await _sendRequest(PluginMethods.sdkSpawn, {
      'request': request.toJson(),
      'arguments': arguments,
      if (workingDirectory != null) 'workingDirectory': workingDirectory,
      if (environment != null) 'environment': environment,
    });
    return result as int;
  }

  @override
  LumideDisposable onDidChangeSelection(
    void Function(LumideSdkSelectionChangeEvent event) callback,
  ) {
    return addListener(_selectionChangeCallbacks, callback);
  }

  Future<dynamic> _sendRequest(String method, [dynamic params]) async {
    try {
      return await _session.sendRequest(method, params);
    } on RpcException catch (error) {
      if (error.code == rpc_error_code.METHOD_NOT_FOUND) {
        throw UnsupportedError('The Lumide host does not support SDK APIs');
      }
      rethrow;
    }
  }

  @override
  void onListAvailable(
    Future<List<LumideSdkRelease>> Function(LumideSdkListRequest request)
        callback,
  ) {
    _session.registerMethod(HostMethods.sdkListAvailable, (params) async {
      final request = LumideSdkListRequest.fromJson(params.value as Map);
      final releases = await callback(request);
      return releases.map((release) => release.toJson()).toList();
    });
  }

  @override
  void onDiscover(
    Future<List<LumideSdkInstallation>> Function(
      LumideSdkDiscoveryRequest request,
    ) callback,
  ) {
    _session.registerMethod(HostMethods.sdkDiscover, (params) async {
      final request = LumideSdkDiscoveryRequest.fromJson(params.value as Map);
      final installations = await callback(request);
      return installations
          .map((installation) => installation.toJson())
          .toList();
    });
  }

  @override
  void onResolve(
    Future<LumideSdkResolution?> Function(LumideSdkResolveRequest request)
        callback,
  ) {
    _session.registerMethod(HostMethods.sdkResolve, (params) async {
      final request = LumideSdkResolveRequest.fromJson(params.value as Map);
      return (await callback(request))?.toJson();
    });
  }

  @override
  void onGetInstallPlan(
    Future<LumideSdkInstallPlan> Function(LumideSdkInstallPlanRequest request)
        callback,
  ) {
    _session.registerMethod(HostMethods.sdkGetInstallPlan, (params) async {
      final request = LumideSdkInstallPlanRequest.fromJson(
        params.value as Map,
      );
      return (await callback(request)).toJson();
    });
  }

  @override
  void onValidate(
    Future<LumideSdkValidation> Function(LumideSdkValidationRequest request)
        callback,
  ) {
    _session.registerMethod(HostMethods.sdkValidate, (params) async {
      final request = LumideSdkValidationRequest.fromJson(
        params.value as Map,
      );
      return (await callback(request)).toJson();
    });
  }
}

typedef _ProviderHandler = Future<dynamic> Function(Map<String, dynamic> data);

class _RpcLanguages implements LumideLanguages {
  _RpcLanguages(this._session) {
    _session.registerMethod(HostMethods.languagesProvideFormatting, (
      params,
    ) async {
      final data = params.value as Map<String, dynamic>;
      final formatter = _formatters[data['id']];
      if (formatter == null) return null;
      final formatted = await formatter(LumideFormattingRequest.fromJson(data));
      return {'text': formatted};
    });
    for (final method in _providerMethods) {
      _session.registerMethod(method, (params) async {
        final data = params.value as Map<String, dynamic>;
        final handler = _providerHandlers[method]?[data['id']];
        if (handler == null) return null;
        return await handler(data);
      });
    }
  }

  /// Host requests shared by every provider, routed by provider `id`.
  static const _providerMethods = [
    HostMethods.aiCheckStatus,
    HostMethods.aiSignIn,
    HostMethods.aiSignOut,
    HostMethods.inlineCompletionRequest,
  ];

  final RpcSession _session;
  final _formatters =
      <String, Future<String?> Function(LumideFormattingRequest)>{};
  final _providerHandlers = <String, Map<String, _ProviderHandler>>{};

  /// Routes [method] requests for provider [id] to [handler], replacing a
  /// previous registration. A null [handler] removes it.
  void _setProviderHandler(
      String method, String id, _ProviderHandler? handler) {
    final handlers = _providerHandlers.putIfAbsent(method, () => {});
    if (handler == null) {
      handlers.remove(id);
      return;
    }
    handlers[id] = handler;
  }

  void _setAuthHandlers(
    String id, {
    Future<String> Function()? checkStatus,
    Future<Map<String, dynamic>> Function()? signIn,
    Future<void> Function()? signOut,
  }) {
    _setProviderHandler(
      HostMethods.aiCheckStatus,
      id,
      switch (checkStatus) {
        final check? => (_) => check(),
        null => null,
      },
    );
    _setProviderHandler(
      HostMethods.aiSignIn,
      id,
      switch (signIn) {
        final signInHandler? => (_) => signInHandler(),
        null => null,
      },
    );
    _setProviderHandler(
      HostMethods.aiSignOut,
      id,
      switch (signOut) {
        final signOutHandler? => (_) async {
            await signOutHandler();
            return null;
          },
        null => null,
      },
    );
  }

  @override
  Future<void> setDiagnostics(
    String collection,
    String uri,
    List<LumideDiagnostic> diagnostics,
  ) async {
    await _session.sendRequest(PluginMethods.languagesSetDiagnostics, {
      'collection': collection,
      'uri': uri,
      'diagnostics': [
        for (final diagnostic in diagnostics) diagnostic.toJson()
      ],
    });
  }

  @override
  Future<void> clearDiagnostics(String collection, {String? uri}) async {
    await _session.sendRequest(PluginMethods.languagesClearDiagnostics, {
      'collection': collection,
      if (uri != null) 'uri': uri,
    });
  }

  @override
  Future<void> registerFormattingProvider({
    required String id,
    List<String> fileExtensions = const [],
    List<String> languageIds = const [],
    required Future<String?> Function(LumideFormattingRequest request)
        provideFormatting,
  }) async {
    _formatters[id] = provideFormatting;
    await _session.sendRequest(
      PluginMethods.languagesRegisterFormattingProvider,
      {'id': id, 'fileExtensions': fileExtensions, 'languageIds': languageIds},
    );
  }

  @override
  Future<void> unregisterFormattingProvider(String id) async {
    _formatters.remove(id);
    await _session.sendRequest(
      PluginMethods.languagesUnregisterFormattingProvider,
      {'id': id},
    );
  }

  @override
  Future<void> registerLanguageServer({
    required String id,
    required String languageId,
    String? displayName,
    String? icon,
    String? iconPath,
    required List<String> fileExtensions,
    required String command,
    List<String> args = const [],
    Map<String, String> extensionLanguageMap = const {},
    Map<String, dynamic>? initializationOptions,
    Future<String> Function()? checkStatus,
    Future<Map<String, dynamic>> Function()? signIn,
    Future<void> Function()? signOut,
  }) async {
    _setAuthHandlers(
      id,
      checkStatus: checkStatus,
      signIn: signIn,
      signOut: signOut,
    );

    await _session.sendRequest(PluginMethods.languagesRegisterServer, {
      'id': id,
      'languageId': languageId,
      if (displayName != null) 'displayName': displayName,
      if (icon != null) 'icon': icon,
      if (iconPath != null) 'iconPath': iconPath,
      'fileExtensions': fileExtensions,
      'command': command,
      'args': args,
      if (extensionLanguageMap.isNotEmpty)
        'extensionLanguageMap': extensionLanguageMap,
      if (initializationOptions != null)
        'initializationOptions': initializationOptions,
      'supportsAuth': checkStatus != null || signIn != null || signOut != null,
    });
  }

  @override
  Future<dynamic> sendLspRequest(
    String providerId,
    String method, [
    Map<String, dynamic>? params,
  ]) async {
    return await _session.sendRequest(PluginMethods.languagesSendLspRequest, {
      'providerId': providerId,
      'method': method,
      if (params != null) 'params': params,
    });
  }

  @override
  Future<void> registerInlineCompletionProvider({
    required String id,
    required String displayName,
    String? processName,
    int? processId,
    String? icon,
    String? iconPath,
    required Future<List<InlineCompletion>> Function(
      InlineCompletionRequest request,
    ) onProvideCompletions,
    bool supportsAuth = false,
    Future<String> Function()? checkStatus,
    Future<Map<String, dynamic>> Function()? signIn,
    Future<void> Function()? signOut,
  }) async {
    _setProviderHandler(HostMethods.inlineCompletionRequest, id, (data) async {
      final request = InlineCompletionRequest(
        uri: data['uri'] as String,
        line: data['line'] as int,
        column: data['column'] as int,
        documentText: data['documentText'] as String,
        instructions: data['instructions'] as String?,
      );
      final completions = await onProvideCompletions(request);
      return completions.map((c) => {'text': c.text}).toList();
    });
    _setAuthHandlers(
      id,
      checkStatus: checkStatus,
      signIn: signIn,
      signOut: signOut,
    );

    await _session.sendRequest(PluginMethods.languagesRegisterInlineProvider, {
      'id': id,
      'displayName': displayName,
      if (processName != null) 'processName': processName,
      if (processId != null) 'processId': processId,
      'icon': icon,
      'iconPath': iconPath,
      'supportsAuth': supportsAuth ||
          checkStatus != null ||
          signIn != null ||
          signOut != null,
    });
  }
}

class _RpcTests implements LumideTests {
  _RpcTests(this._session);

  final RpcSession _session;
  int _lastRunId = 0;

  @override
  Future<LumideTestRun> createRun({
    required String title,
    LumideOutputChannel? output,
    String? runCommand,
    String? debugCommand,
    String? stopCommand,
  }) async {
    final id = 'run-${++_lastRunId}';
    await _session.sendRequest(PluginMethods.testsCreateRun, {
      'id': id,
      'title': title,
      if (output != null) 'outputChannelId': output.id,
      if (runCommand != null) 'runCommand': runCommand,
      if (debugCommand != null) 'debugCommand': debugCommand,
      if (stopCommand != null) 'stopCommand': stopCommand,
    });
    return _RpcTestRun(id, _session);
  }
}

class _RpcTestRun implements LumideTestRun {
  _RpcTestRun(this.id, this._session);

  @override
  final String id;
  final RpcSession _session;
  bool _ended = false;

  @override
  Future<void> update(List<LumideTestResult> results) async {
    if (_ended || results.isEmpty) return;
    await _session.sendRequest(PluginMethods.testsUpdateRun, {
      'id': id,
      'results': [for (final result in results) result.toJson()],
    });
  }

  @override
  Future<void> setCoverage(List<LumideFileCoverage> files) async {
    await _session.sendRequest(PluginMethods.testsSetCoverage, {
      'id': id,
      'files': [for (final file in files) file.toJson()],
    });
  }

  @override
  Future<void> end({String? summary}) async {
    if (_ended) return;
    _ended = true;
    await _session.sendRequest(PluginMethods.testsEndRun, {
      'id': id,
      if (summary != null) 'summary': summary,
    });
  }
}
