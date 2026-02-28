/// Comprehensive "Text Tools & Demo" plugin for Lumide IDE.
///
/// Showcases ALL plugin API features in a practical context:
/// - **Toolbar**: Central "Tools" menu for quick access to actions.
/// - **Editor API**: Text manipulation, document reading, navigation.
/// - **Window API**: QuickPick menus, messages with titles, confirm dialogs.
/// - **Workspace API**: Root URI, file search, configuration, events.
/// - **Status Bar API**: Real-time cursor position and selection statistics.
/// - **HTTP API**: Fetching external data (Lorem Ipsum).
/// - **Shell & FS API**: System operations with working directory, directory checks.
/// - **Lifecycle & Config**: Management of plugin state and settings.
library;

import 'dart:async';
import 'dart:convert';

import 'package:lumide_api/lumide_api.dart';

void main() => TextToolsPlugin().run();

class TextToolsPlugin extends LumidePlugin {
  late LumideContext _context;
  Timer? _heartbeat;
  bool _logEvents = true;

  @override
  Future<void> onActivate(LumideContext context) async {
    _context = context;
    log('🔌 Text Tools Plugin activated!');

    await _loadConfiguration();
    await _registerCommands();
    await _setupStatusBar();
    await _setupToolbar();
    _registerEventListeners();
    _startHeartbeat();

    // Demonstrate workspace root API
    final root = await context.workspace.getRootUri();
    log('📁 Workspace root: $root');
  }

  @override
  Future<void> onDeactivate() async {
    _heartbeat?.cancel();
    log('👋 Text Tools Plugin deactivated');
  }

  Future<void> _loadConfiguration() async {
    if (await _context.workspace.getConfiguration('text_tools.logEvents')
        case final bool val) {
      _logEvents = val;
    }
  }

  void _registerEventListeners() {
    _context.workspace.onDidChangeConfiguration((settings) {
      if (settings['text_tools.logEvents'] case final bool val) {
        _logEvents = val;
        log('⚙️ Config updated: logEvents = $val');
      }
    });

    _context.editor.onDidChangeSelections(_updateStatusBar);

    if (_logEvents) {
      _context.workspace.onDidSaveTextDocument((uri) {
        log('💾 Saved: ${Uri.parse(uri).pathSegments.last}');
      });
    }
  }

  void _startHeartbeat() {
    _heartbeat = Timer.periodic(const Duration(minutes: 5), (_) {
      log('❤️ Plugin still running...');
    });
  }

  Future<void> _setupToolbar() async {
    await _context.toolbar.registerItem(
      id: 'text_tools_menu',
      icon: 'list',
      tooltip: 'Text Tools',
      alignment: ToolbarItemAlignment.left,
      priority: 100,
    );

    _context.toolbar.onTap((id, position) {
      if (id == 'text_tools_menu') {
        _showToolsMenu(position);
      }
    });
  }

  Future<void> _showToolsMenu(Map<String, int> position) async {
    final choice = await _context.window.showQuickPick(
      [
        const QuickPickItem(
          label: 'Upper Case',
          description: 'Convert selection to upper case',
          payload: 'upper',
        ),
        const QuickPickItem(
          label: 'Lower Case',
          description: 'Convert selection to lower case',
          payload: 'lower',
        ),
        const QuickPickItem(
          label: 'Insert Lorem Ipsum',
          description: 'Insert placeholder text (HTTP API)',
          payload: 'lorem',
        ),
        const QuickPickItem(label: '', isSeparator: true),
        const QuickPickItem(
          label: 'Document Stats',
          description: 'Word count via getDocumentText()',
          payload: 'stats',
        ),
        const QuickPickItem(
          label: 'Go to Line',
          description: 'Navigate to a line (revealRange)',
          payload: 'goto',
        ),
        const QuickPickItem(
          label: 'Find Dart Files',
          description: 'Search workspace with findFiles()',
          payload: 'find',
        ),
        const QuickPickItem(label: '', isSeparator: true),
        const QuickPickItem(
          label: 'List Files',
          description: 'List directory contents (FS + isDirectory)',
          payload: 'ls',
        ),
        const QuickPickItem(
          label: 'Run Git Status',
          description: 'Shell with workingDirectory',
          payload: 'git',
        ),
        const QuickPickItem(
          label: 'Open Terminal',
          description: 'Create and show a new terminal',
          payload: 'term',
        ),
        const QuickPickItem(
          label: 'Log to Output',
          description: 'Write to an output channel',
          payload: 'log',
        ),
        const QuickPickItem(label: '', isSeparator: true),
        const QuickPickItem(
          label: 'Confirm Dialog',
          description: 'Show a confirmation dialog',
          payload: 'confirm',
        ),
      ],
      placeholder: 'Select a tool...',
      position: position,
    );

    if (choice == null) return;

    switch (choice.payload) {
      case 'upper':
        await _transformText((s) => s.toUpperCase());
      case 'lower':
        await _transformText((s) => s.toLowerCase());
      case 'lorem':
        await _insertLoremIpsum();
      case 'stats':
        await _showDocumentStats();
      case 'goto':
        await _goToLine();
      case 'find':
        await _findDartFiles();
      case 'ls':
        await _listFiles();
      case 'git':
        await _runGitStatus();
      case 'term':
        await _demonstrateTerminal();
      case 'log':
        await _demonstrateOutput();
      case 'confirm':
        await _demonstrateConfirm();
    }
  }

  Future<void> _transformText(String Function(String) transformer) async {
    final text = await _context.editor.getSelectedText();
    if (text == null || text.isEmpty) {
      await _context.window.showMessage(
        'Select some text first',
        title: 'Text Tools',
        type: MessageType.warning,
      );
      return;
    }

    final newText = transformer(text);
    await _context.editor.replaceSelection(newText);
    log('✨ Transformed text');
  }

  Future<void> _insertLoremIpsum() async {
    try {
      log('🌐 Fetching Lorem Ipsum...');
      final response = await _context.http.get(
        'https://baconipsum.com/api/?type=meat-and-filler&sentences=1&start-with-lorem=1',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final text = data.first as String;
          await _context.editor.insertText(text);
          log('✍️ Inserted Lorem Ipsum');
        }
      } else {
        await _context.window.showMessage(
          'Failed to fetch text: ${response.statusCode}',
          title: 'Text Tools',
          type: MessageType.error,
        );
      }
    } catch (e) {
      log('⚠ HTTP Error: $e');
      await _context.window.showMessage(
        'Error fetching text: $e',
        title: 'Text Tools',
        type: MessageType.error,
      );
    }
  }

  /// Uses getDocumentText() to read the full document content.
  Future<void> _showDocumentStats() async {
    final uri = await _context.editor.getActiveDocumentUri();
    if (uri == null) {
      await _context.window.showMessage(
        'No active document',
        title: 'Text Tools',
        type: MessageType.warning,
      );
      return;
    }

    final content = await _context.editor.getDocumentText(uri);
    if (content == null) {
      await _context.window.showMessage(
        'Could not read document',
        title: 'Text Tools',
        type: MessageType.warning,
      );
      return;
    }

    final lines = content.split('\n').length;
    final chars = content.length;
    final words =
        content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    await _context.window.showMessage(
      'Lines: $lines\nWords: $words\nCharacters: $chars',
      title: 'Document Statistics',
    );
  }

  /// Uses revealRange() to navigate to a specific line.
  Future<void> _goToLine() async {
    final uri = await _context.editor.getActiveDocumentUri();
    if (uri == null) return;

    final input = await _context.window.showInputBox(
      prompt: 'Enter line number',
      title: 'Go to Line',
    );
    if (input == null) return;

    final line = int.tryParse(input);
    if (line == null || line < 1) {
      await _context.window.showMessage(
        'Invalid line number',
        title: 'Text Tools',
        type: MessageType.warning,
      );
      return;
    }

    await _context.editor.revealRange(uri: uri, line: line - 1);
  }

  /// Uses findFiles() to search the workspace by glob pattern.
  Future<void> _findDartFiles() async {
    final files = await _context.workspace.findFiles(
      '**/*.dart',
      maxResults: 20,
    );

    if (files.isEmpty) {
      await _context.window.showMessage(
        'No Dart files found',
        title: 'Text Tools',
      );
      return;
    }

    final items = files.map((f) {
      final name = Uri.parse(f).pathSegments.last;
      return QuickPickItem(label: name, description: f, payload: f);
    }).toList();

    final selected = await _context.window.showQuickPick(
      items,
      placeholder: 'Found ${files.length} Dart files — select to open',
    );

    // Uses openDocument() to open the selected file
    if (selected?.payload case final String uri) {
      await _context.editor.openDocument(uri);
    }
  }

  /// Uses isDirectory() and list() to browse the file system.
  Future<void> _listFiles() async {
    final uri = await _context.editor.getActiveDocumentUri();
    if (uri == null) return;
    final path = Uri.parse(uri).toFilePath();
    final dir = path.substring(0, path.lastIndexOf('/'));

    final entries = await _context.fs.list(dir);
    final items = <QuickPickItem>[];

    for (final entry in entries) {
      final name = Uri.parse(entry).pathSegments.last;
      final isDir = await _context.fs.isDirectory(entry);
      items.add(QuickPickItem(
        label: isDir ? '📁 $name' : '📄 $name',
        description: entry,
        payload: entry,
        icon: isDir ? 'folder' : 'file',
      ));
    }

    await _context.window.showQuickPick(
      items,
      placeholder: 'Files in $dir',
    );
  }

  /// Uses shell.run() with workingDirectory parameter.
  Future<void> _runGitStatus() async {
    final root = await _context.workspace.getRootUri();
    if (root == null) {
      await _context.window.showMessage(
        'No workspace open',
        title: 'Text Tools',
        type: MessageType.warning,
      );
      return;
    }

    final result = await _context.shell.run(
      'git',
      ['status', '--short'],
      workingDirectory: root,
    );

    final output = result.stdout.toString().trim();
    await _context.window.showMessage(
      output.isEmpty ? 'Working tree clean' : output,
      title: 'Git Status',
    );
  }

  Future<void> _demonstrateTerminal() async {
    final terminal = await _context.window.createTerminal(
      name: 'Demo Terminal',
    );
    await terminal.show();
    await terminal.sendText('echo "Hello from Text Tools Plugin!"');
  }

  Future<void> _demonstrateOutput() async {
    final channel = await _context.window.createOutputChannel('Text Tools Log');
    await channel.show();
    await channel.appendLine('Text Tools Plugin Log initialized.');
    await channel.appendLine('Timestamp: ${DateTime.now()}');
    await channel.appendLog(LumideLogRecord(
      level: 'INFO',
      message: 'Structured log entry',
      name: 'TextTools',
      time: DateTime.now(),
    ));
  }

  /// Uses showConfirmDialog() for user confirmation.
  Future<void> _demonstrateConfirm() async {
    final confirmed = await _context.window.showConfirmDialog(
      'This will insert text at the cursor. Continue?',
      title: 'Confirm Action',
    );

    if (confirmed) {
      await _context.editor.insertText('✅ Confirmed!');
      await _context.window.showMessage(
        'Text inserted',
        title: 'Text Tools',
      );
    } else {
      await _context.window.showMessage(
        'Action cancelled',
        title: 'Text Tools',
      );
    }
  }

  Future<void> _setupStatusBar() async {
    await _context.statusBar.createItem(
      id: 'cursor_pos',
      text: 'Ln 1, Col 1',
      alignment: 'right',
      priority: 100,
      tooltip: 'Current Cursor Position',
    );

    await _context.statusBar.createItem(
      id: 'selection_count',
      text: '',
      alignment: 'right',
      priority: 90,
      tooltip: 'Characters selected',
    );
    await _context.statusBar.hide('selection_count');
  }

  void _updateStatusBar(List<Map<String, dynamic>> selections) {
    if (selections.isEmpty) return;

    final focus = selections.first['focus'] as Map;
    final line = (focus['line'] as int) + 1;
    final col = (focus['column'] as int) + 1;
    _context.statusBar.updateItem('cursor_pos', text: 'Ln $line, Col $col');

    final anchor = selections.first['anchor'] as Map;
    final aLine = (anchor['line'] as int) + 1;
    final aCol = (anchor['column'] as int) + 1;

    if (aLine != line || aCol != col) {
      _context.statusBar.updateItem('selection_count', text: '(Selecting)');
      _context.statusBar.show('selection_count');
    } else {
      _context.statusBar.hide('selection_count');
    }
  }

  Future<void> _registerCommands() async {
    await _context.commands.registerCommand(
      id: 'text_tools.showMenu',
      title: 'Text Tools: Show Menu',
      callback: ([args]) => _showToolsMenu({}),
    );

    await _context.commands.registerCommand(
      id: 'text_tools.lorem',
      title: 'Text Tools: Insert Lorem Ipsum',
      callback: ([args]) => _insertLoremIpsum(),
    );
  }
}
