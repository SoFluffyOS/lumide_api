/// Comprehensive "Text Tools & Demo" plugin for Lumide IDE.
///
/// Showcases ALL plugin API features in a practical context:
/// - **Toolbar**: Central "Tools" menu for quick access to actions.
/// - **Editor API**: Text manipulation (Upper/Lower case), insertion (Lorem Ipsum).
/// - **Window API**: QuickPick menus, Information messages, Input boxes.
/// - **Status Bar API**: Real-time cursor position and selection statistics.
/// - **HTTP API**: Fetching external data (Lorem Ipsum).
/// - **Shell & FS API**: System operations (ls, file listing).
/// - **Lifecycle & Config**: Management of plugin state and settings.
library;

import 'dart:async';
import 'dart:convert'; // For Lorem Ipsum decoding if needed

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

    // 1. Load Configuration
    await _loadConfiguration();

    // 2. Register Commands
    await _registerCommands();

    // 3. Setup Status Bar
    await _setupStatusBar();

    // 4. Setup Toolbar
    await _setupToolbar();

    // 5. Register Event Listeners
    _registerEventListeners();

    // 6. Start Heartbeat (demonstrates long-running task)
    _startHeartbeat();
  }

  @override
  Future<void> onDeactivate() async {
    _heartbeat?.cancel();
    log('👋 Text Tools Plugin deactivated');
  }

  // ═══════════════════════════════════════════════════════════════════
  // 1. Configuration & Lifecycle
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _loadConfiguration() async {
    // Example: Check if event logging is enabled
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

  // ═══════════════════════════════════════════════════════════════════
  // 2. Toolbar & Menu System
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _setupToolbar() async {
    await _context.toolbar.registerItem(
      id: 'text_tools_menu',
      icon: 'list', // Generic list/menu icon
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
          description: 'Insert placeholder text',
          payload: 'lorem',
        ),
        const QuickPickItem(
          label: 'Document Stats',
          description: 'Show lines and characters count',
          payload: 'stats',
        ),
        const QuickPickItem(
          label: 'List Files',
          description: 'List files in current directory (FS API)',
          payload: 'ls',
        ),
        const QuickPickItem(
            label: 'Run System Command',
            description: 'Run "date" (Shell API)',
            payload: 'date'),
      ],
      placeholder: 'Select a tool...',
      position: position, // Show menu at the toolbar button
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
      case 'ls':
        await _listFiles();
      case 'date':
        await _runDateCommand();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 3. Text Operations (Editor API + HTTP API)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _transformText(String Function(String) transformer) async {
    await _context.editor.insertText(transformer('Hello Lumide'));
    log('✍️ Inserted transformed text');
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
        await _context.window.showMessage('Failed to fetch text', type: MessageType.error);
      }
    } catch (e) {
      log('⚠ HTTP Error: $e');
      await _context.window.showMessage('Error fetching text: $e', type: MessageType.error);
    }
  }

  Future<void> _showDocumentStats() async {
    final uri = await _context.editor.getActiveDocumentUri();
    if (uri == null) {
      await _context.window.showMessage('No active document', type: MessageType.warning);
      return;
    }

    // FS API usage
    final path = Uri.parse(uri).toFilePath();
    final content = await _context.fs.readString(path);
    final lines = content.split('\n').length;
    final chars = content.length;

    await _context.window.showMessage(
      'Document Statistics:\nLines: $lines\nCharacters: $chars',
      type: MessageType.info,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 4. System Operations (Shell & FS)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _listFiles() async {
    final uri = await _context.editor.getActiveDocumentUri();
    if (uri == null) return;
    final path = Uri.parse(uri).toFilePath();
    final dir = path.substring(0, path.lastIndexOf('/'));

    final files = await _context.fs.list(dir);
    
    // Show in a QuickPick
    await _context.window.showQuickPick(
      files.map((f) => QuickPickItem(label: f)).toList(),
      placeholder: 'Files in $dir',
    );
  }

  Future<void> _runDateCommand() async {
    final result = await _context.shell.run('date', []);
    await _context.window.showMessage('System Date: ${result.stdout.trim()}');
  }

  // ═══════════════════════════════════════════════════════════════════
  // 5. Status Bar & Commands
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _setupStatusBar() async {
    // Cursor Position
    await _context.statusBar.createItem(
      id: 'cursor_pos',
      text: 'Ln 1, Col 1',
      alignment: 'right',
      priority: 100,
      tooltip: 'Current Cursor Position',
    );

    // Selection Count (Hidden by default)
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

    // Update Cursor
    final focus = selections.first['focus'] as Map;
    final line = (focus['line'] as int) + 1;
    final col = (focus['column'] as int) + 1;
    _context.statusBar.updateItem('cursor_pos', text: 'Ln $line, Col $col');

    // Update Selection Count (Simplified logic for primary selection)
    // Calculating actual selection length requires document text which is expensive to fetch on every move.
    // So we'll just show if multiple lines are selected or if it's a range.
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
    // Command Palette wrappers for features
    await _context.commands.registerCommand(
      id: 'text_tools.showMenu',
      title: 'Text Tools: Show Menu',
      callback: ([args]) {
        // If triggered from command palette, we don't have a toolbar position.
        // Pass null or a default behavior.
        return _showToolsMenu({}); 
      },
    );
    
    await _context.commands.registerCommand(
      id: 'text_tools.lorem',
      title: 'Text Tools: Insert Lorem Ipsum',
      callback: ([args]) => _insertLoremIpsum(),
    );
  }
}
