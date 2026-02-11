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

  // UI Panels
  static const uiCreatePanel = 'ui/createPanel';
  static const uiUpdatePanel = 'ui/updatePanel';
  static const uiDisposePanel = 'ui/disposePanel';

  // Workspace / Configuration
  static const workspaceGetConfiguration = 'workspace/getConfiguration';
  static const workspaceOnDidChangeConfiguration =
      'workspace/onDidChangeConfiguration';

  // Commands (Plugin → IDE)
  static const commandsRegister = 'commands/register';
}
