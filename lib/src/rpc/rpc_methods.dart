/// Standard RPC method names.
library;

/// Method names for IDE-to-Plugin communication.
class HostMethods {
  HostMethods._();

  /// Initialize the plugin.
  static const initialize = 'initialize';

  /// Shutdown the plugin.
  static const shutdown = 'shutdown';

  /// Plugin is ready.
  static const ready = 'ready';

  /// Get process information (memory, etc).
  static const getProcessInfo = 'getProcessInfo';

  // Document Events (IDE → Plugin notifications)
  static const didOpenTextDocument = 'workspace/didOpenTextDocument';
  static const didCloseTextDocument = 'workspace/didCloseTextDocument';
  static const didChangeTextDocument = 'workspace/didChangeTextDocument';

  // Commands (IDE → Plugin)
  static const commandsExecute = 'commands/execute';

  // Configuration (IDE → Plugin)
  static const didChangeConfiguration = 'workspace/onDidChangeConfiguration';

  // Editor Events (IDE → Plugin)
  static const didChangeSelections = 'editor/didChangeSelections';
  static const didChangeActiveDocument = 'editor/didChangeActiveDocument';
  static const didSaveTextDocument = 'workspace/didSaveTextDocument';

  // Shell Events (IDE → Plugin)
  static const shellOnStdout = 'shell/onStdout';
  static const shellOnStderr = 'shell/onStderr';
  static const shellOnExit = 'shell/onExit';

  // Inline Completion back-channel (IDE → Plugin)
  static const inlineCompletionRequest = 'languages/inlineCompletionRequest';
  static const aiCheckStatus = 'languages/aiCheckStatus';
  static const aiSignIn = 'languages/aiSignIn';
  static const aiSignOut = 'languages/aiSignOut';

  // Debug (IDE → Plugin)
  static const launchResolveConfigurations = 'launch/resolveConfigurations';
  static const launchResolveConfiguration = 'launch/resolveConfiguration';
  static const launchImportConfiguration = 'launch/importConfiguration';
  static const launchConfigure = 'launch/configure';
  static const launchStart = 'launch/start';
  static const launchDidStart = 'launch/onDidStart';
  static const launchDidEnd = 'launch/onDidEnd';

  // Debug (IDE → Plugin)
  static const debugLaunch = 'debug/launch';
  static const debugContinue = 'debug/continue';
  static const debugPause = 'debug/pause';
  static const debugStepOver = 'debug/stepOver';
  static const debugStepInto = 'debug/stepInto';
  static const debugStepOut = 'debug/stepOut';
  static const debugStop = 'debug/stop';
  static const debugSetBreakpoints = 'debug/setBreakpoints';
  static const debugSetExceptionPauseMode = 'debug/setExceptionPauseMode';
  static const debugGetStackFrames = 'debug/getStackFrames';
  static const debugGetScopes = 'debug/getScopes';
  static const debugGetVariables = 'debug/getVariables';
  static const debugEvaluate = 'debug/evaluate';
}

/// Method names for Plugin-to-IDE communication.
class PluginMethods {
  PluginMethods._();

  // File System
  static const fsReadString = 'fs/readString';
  static const fsWriteString = 'fs/writeString';
  static const fsCreateDirectory = 'fs/createDirectory';
  static const fsExists = 'fs/exists';
  static const fsIsDirectory = 'fs/isDirectory';
  static const fsList = 'fs/list';
  static const fsDownloadFile = 'fs/downloadFile';

  // HTTP
  static const httpGet = 'http/get';
  static const httpPost = 'http/post';

  // Shell
  static const shellRun = 'shell/run';
  static const shellSpawn = 'shell/spawn';
  static const shellWriteStdin = 'shell/writeStdin';
  static const shellKill = 'shell/kill';

  // Terminal
  static const terminalCreate = 'terminal/create';
  static const terminalSendText = 'terminal/sendText';
  static const terminalShow = 'terminal/show';
  static const terminalDispose = 'terminal/dispose';
  static const terminalOnData = 'terminal/onData';
  static const terminalOnDidDispose = 'terminal/onDidDispose';

  // Window/UI
  static const windowShowMessage = 'window/showMessage';
  static const windowShowQuickPick = 'window/showQuickPick';
  static const windowShowInputBox = 'window/showInputBox';
  static const windowOpenUrl = 'window/openUrl';
  static const windowCreateWebviewPanel = 'window/createWebviewPanel';
  static const windowShowConfirmDialog = 'window/showConfirmDialog';
  static const windowShowDeviceAuthDialog = 'window/showDeviceAuthDialog';
  static const windowShowOpenDialog = 'window/showOpenDialog';
  static const windowShowOpenFolderDialog = 'window/showOpenFolderDialog';

  // Webview API
  static const webviewPostMessage = 'webview/postMessage';
  static const webviewOnDidReceiveMessage = 'webview/onDidReceiveMessage';
  static const webviewOnDidDispose = 'webview/onDidDispose';
  static const webviewDispose = 'webview/dispose';

  // Editor
  static const editorGetActiveDocument = 'editor/getActiveDocument';
  static const editorInsertText = 'editor/insertText';
  static const editorReplaceText = 'editor/replaceText';
  static const editorGetSelections = 'editor/getSelections';
  static const editorSetSelections = 'editor/setSelections';
  static const editorGetSelectedText = 'editor/getSelectedText';
  static const editorReplaceSelection = 'editor/replaceSelection';
  static const editorGetDocumentText = 'editor/getDocumentText';
  static const editorOpenDocument = 'editor/openDocument';
  static const editorRevealRange = 'editor/revealRange';

  // Output Channels
  static const windowCreateOutputChannel = 'window/createOutputChannel';
  static const windowAppendOutput = 'window/appendOutput';
  static const windowAppendLog = 'window/appendLog';
  static const windowClearOutput = 'window/clearOutput';
  static const windowShowOutput = 'window/showOutput';
  static const windowDisposeOutputChannel = 'window/disposeOutputChannel';

  // UI Panels
  static const uiCreatePanel = 'ui/createPanel';
  static const uiUpdatePanel = 'ui/updatePanel';
  static const uiDisposePanel = 'ui/disposePanel';

  // Workspace / Configuration
  static const workspaceGetConfiguration = 'workspace/getConfiguration';
  static const workspaceUpdateConfiguration = 'workspace/updateConfiguration';
  static const workspaceGetRootUri = 'workspace/getRootUri';
  static const workspaceFindFiles = 'workspace/findFiles';

  // Commands (Plugin → IDE)
  static const commandsRegister = 'commands/register';

  // Menu actions (Plugin → IDE)
  static const menusRegisterAction = 'menus/registerAction';
  static const menusUnregisterAction = 'menus/unregisterAction';

  // Status Bar (Plugin → IDE)
  static const statusBarCreate = 'statusBar/create';
  static const statusBarUpdate = 'statusBar/update';
  static const statusBarDispose = 'statusBar/dispose';

  // Toolbar (Plugin → IDE)
  static const toolbarRegisterItem = 'toolbar/registerItem';
  static const toolbarUnregisterItem = 'toolbar/unregisterItem';
  static const toolbarOnTap = 'toolbar/onTap';

  // Launch (Plugin → IDE)
  static const launchRegisterProvider = 'launch/registerProvider';
  static const launchUpdateConfigurations = 'launch/updateConfigurations';
  static const launchUnregisterProvider = 'launch/unregisterProvider';
  static const launchDidStart = 'launch/onDidStart';
  static const launchDidEnd = 'launch/onDidEnd';

  // Languages (Plugin → IDE)
  static const languagesRegisterServer = 'languages/registerServer';
  static const languagesRegisterInlineProvider =
      'languages/registerInlineProvider';
  static const languagesSendLspRequest = 'languages/sendLspRequest';

  // Debug (Plugin → IDE)
  static const debugStartSession = 'debug/startSession';
  static const debugUpdateSession = 'debug/updateSession';
  static const debugEndSession = 'debug/endSession';
  static const debugUpdateBreakpoints = 'debug/updateBreakpoints';
}
