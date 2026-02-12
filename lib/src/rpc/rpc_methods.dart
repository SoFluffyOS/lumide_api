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
}

/// Method names for Plugin-to-IDE communication.
class PluginMethods {
  PluginMethods._();

  // File System
  static const fsReadString = 'fs/readString';
  static const fsWriteString = 'fs/writeString';
  static const fsExists = 'fs/exists';
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

  // Window/UI
  static const windowShowMessage = 'window/showMessage';
  static const windowShowQuickPick = 'window/showQuickPick';
  static const windowShowInputBox = 'window/showInputBox';

  // Editor
  static const editorGetActiveDocument = 'editor/getActiveDocument';
  static const editorInsertText = 'editor/insertText';
  static const editorReplaceText = 'editor/replaceText';
  static const editorGetSelections = 'editor/getSelections';
  static const editorSetSelections = 'editor/setSelections';
  static const editorGetSelectedText = 'editor/getSelectedText';
  static const editorReplaceSelection = 'editor/replaceSelection';

  // Output Channels
  static const windowCreateOutputChannel = 'window/createOutputChannel';
  static const windowAppendOutput = 'window/appendOutput';
  static const windowShowOutput = 'window/showOutput';
  static const windowDisposeOutputChannel = 'window/disposeOutputChannel';

  // UI Panels
  static const uiCreatePanel = 'ui/createPanel';
  static const uiUpdatePanel = 'ui/updatePanel';
  static const uiDisposePanel = 'ui/disposePanel';

  // Workspace / Configuration
  static const workspaceGetConfiguration = 'workspace/getConfiguration';

  // Commands (Plugin → IDE)
  static const commandsRegister = 'commands/register';

  // Status Bar (Plugin → IDE)
  static const statusBarCreate = 'statusBar/create';
  static const statusBarUpdate = 'statusBar/update';
  static const statusBarDispose = 'statusBar/dispose';

  // Toolbar (Plugin → IDE)
  static const toolbarRegisterItem = 'toolbar/registerItem';
  static const toolbarUnregisterItem = 'toolbar/unregisterItem';
  static const toolbarOnTap = 'toolbar/onTap';
}
