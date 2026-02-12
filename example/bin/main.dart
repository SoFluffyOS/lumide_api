/// Comprehensive demo plugin for Lumide IDE.
///
/// Showcases ALL plugin API features:
/// - Lifecycle management (onActivate / onDeactivate)
/// - File System API (read, write, exists, list)
/// - Editor API (activeDocument, insertText, replaceText, selections)
/// - Window API (showMessage, showQuickPick, showInputBox)
/// - Shell API (run commands)
/// - HTTP API (GET / POST requests)
/// - Workspace API (getConfiguration, document events)
/// - Commands API (register commands for the Command Palette)
/// - Status Bar API (create, update, dispose status bar items)
/// - Logging via stderr (stdout is reserved for JSON-RPC)
library;

import 'dart:async';

import 'package:lumide_api/lumide_api.dart';

void main() => DemoPlugin().run();

class DemoPlugin extends LumidePlugin {
  Timer? _heartbeat;
  late LumideContext _context;
  late DateTime _activatedAt;

  String _greeting = 'Hello from Demo Plugin!';
  int _heartbeatInterval = 1;
  bool _logDocumentEvents = true;

  @override
  Future<void> onActivate(LumideContext context) async {
    _context = context;
    _activatedAt = DateTime.now();
    log('🔌 Demo Plugin activated!');

    // ── 1. Configuration API ───────────────────────────────────────
    await _loadConfiguration();

    // ── 2. Window API: show greeting from config ───────────────────
    await _context.window.showMessage(_greeting);

    // ── 3. Document Events (conditional on config) ─────────────────
    _registerDocumentEvents();

    // ── 4. Shell API: run a command on startup ─────────────────────
    await _demonstrateShell();

    // ── 5. File System API: list + read active file ────────────────
    await _demonstrateFileSystem();

    // ── 6. Commands API: register commands for the Command Palette ──
    await _registerCommands();

    // ── 7. Status Bar API: create status bar items ─────────────────
    await _createStatusBarItems();

    // ── 8. Toolbar API ──────────────────────────────────────────────
    await _demonstrateToolbar();

    // ── 9. Editor event listeners (event-driven, no polling) ────────
    _context.editor.onDidChangeSelections(_onSelectionsChanged);
    _context.editor.onDidChangeActiveDocument(_onActiveDocumentChanged);
    _context.workspace.onDidSaveTextDocument(_onDocumentSaved);
    _context.workspace.onDidChangeConfiguration(_onConfigChanged);

    // ── 9. Heartbeat (status bar uptime updater) ────────────────────
    _startHeartbeat();
  }

  @override
  Future<void> onDeactivate() async {
    _heartbeat?.cancel();
    log('👋 Demo Plugin deactivated');
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    log('❤️  Heartbeat: every ${_heartbeatInterval}s');
    _heartbeat = Timer.periodic(
      Duration(seconds: _heartbeatInterval),
      (_) {
        final uptime = DateTime.now().difference(_activatedAt);
        final minutes = uptime.inMinutes;
        final seconds = uptime.inSeconds % 60;
        _context.statusBar.updateItem(
          'greeting',
          text: '🦊 Demo ${minutes}m${seconds}s',
          tooltip: 'Demo Plugin uptime: ${minutes}m ${seconds}s',
        );
      },
    );
  }

  void _onConfigChanged(Map<String, Object?> settings) {
    log('⚙️  Configuration changed: $settings');

    if (settings['lumide_demo_plugin.greeting'] case final String val) {
      _greeting = val;
    }
    if (settings['lumide_demo_plugin.logDocumentEvents'] case final bool val) {
      _logDocumentEvents = val;
    }
    if (settings['lumide_demo_plugin.heartbeatInterval'] case final int val
        when val != _heartbeatInterval) {
      _heartbeatInterval = val;
      _startHeartbeat();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 1. Configuration API — values drive plugin behavior
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _loadConfiguration() async {
    try {
      // greeting → used by window.showMessage on activation
      if (await _context.workspace.getConfiguration(
        'lumide_demo_plugin.greeting',
      )
          case final String val) {
        _greeting = val;
      }
      log('⚙️  greeting: $_greeting');

      // heartbeatInterval → controls Timer.periodic duration
      if (await _context.workspace.getConfiguration(
        'lumide_demo_plugin.heartbeatInterval',
      )
          case final int val) {
        _heartbeatInterval = val;
      }
      log('⚙️  heartbeatInterval: ${_heartbeatInterval}s');

      // logDocumentEvents → gates document event logging
      if (await _context.workspace.getConfiguration(
        'lumide_demo_plugin.logDocumentEvents',
      )
          case final bool val) {
        _logDocumentEvents = val;
      }
      log('⚙️  logDocumentEvents: $_logDocumentEvents');
    } catch (error) {
      log('⚠ Error loading config: $error');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 2. Document Events — conditional on logDocumentEvents config
  // ═══════════════════════════════════════════════════════════════════

  void _registerDocumentEvents() {
    _context.workspace.onDidOpenTextDocument((uri) {
      if (_logDocumentEvents) log('📂 Document opened: $uri');
    });

    _context.workspace.onDidCloseTextDocument((uri) {
      if (_logDocumentEvents) log('📕 Document closed: $uri');
    });

    _context.workspace.onDidChangeTextDocument((event) {
      if (_logDocumentEvents) {
        log('✏️  Document changed: ${event.uri} '
            '(${event.changes.length} change(s))');
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // 3. Shell API
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _demonstrateShell() async {
    try {
      final result = await _context.shell.run('date', []);
      log('🐚 System date: ${result.stdout.trim()}');
    } catch (error) {
      log('⚠ Shell demo: $error');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 4. File System API (readString, exists, list)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _demonstrateFileSystem() async {
    try {
      final uri = await _context.editor.getActiveDocumentUri();
      if (uri == null) return;

      final filePath = Uri.parse(uri).toFilePath();
      final dir = filePath.substring(0, filePath.lastIndexOf('/'));

      // fs.list
      final entries = await _context.fs.list(dir);
      log('📁 $dir — ${entries.length} entries');
      for (final entry in entries.take(5)) {
        log('   $entry');
      }
      if (entries.length > 5) log('   ... +${entries.length - 5} more');

      // fs.readString (preview)
      final content = await _context.fs.readString(filePath);
      final preview =
          content.length > 80 ? '${content.substring(0, 80)}...' : content;
      log('📖 Preview: $preview');
    } catch (error) {
      log('⚠ FileSystem demo: $error');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 5. Editor Event Callbacks
  // ═══════════════════════════════════════════════════════════════════

  void _onActiveDocumentChanged(String? uri) {
    if (uri == null) {
      log('📄 Active document: none');
      return;
    }
    final filename = Uri.parse(uri).pathSegments.last;
    log('📄 Active document changed: $filename');
  }

  void _onDocumentSaved(String uri) {
    final filename = Uri.parse(uri).pathSegments.last;
    log('💾 Document saved: $filename');
  }

  // ═══════════════════════════════════════════════════════════════════
  // 6. HTTP API (GET / POST) — called on demand, not on activation
  // ═══════════════════════════════════════════════════════════════════

  Future<void> demonstrateHttp([Map<String, dynamic>? args]) async {
    try {
      final getResp = await _context.http.get('https://httpbin.org/get');
      log('🌐 GET status: ${getResp.statusCode}');

      final postResp = await _context.http.post(
        'https://httpbin.org/post',
        body: '{"demo": true}',
      );
      log('🌐 POST status: ${postResp.statusCode}');
    } catch (error) {
      log('⚠ HTTP demo: $error');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 7. Window API (showMessage, quickPick, inputBox)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> demonstrateWindowDialogs([Map<String, dynamic>? args]) async {
    if (args != null) {
      log('🖱️ Command executed with args: $args');
    }
    try {
      final choice = await _context.window.showQuickPick(
        [
          const QuickPickItem(label: 'Option A', description: 'Description A'),
          const QuickPickItem(label: 'Option B', detail: 'Detail B'),
          const QuickPickItem(label: 'Option C', picked: true),
        ],
        placeholder: 'Pick something...',
      );
      log('🪟 Quick pick: ${choice?.label}');

      final input = await _context.window.showInputBox(
        prompt: 'Enter something:',
        value: 'default',
        placeHolder: 'Type here...',
        title: 'Input Demo',
      );
      log('🪟 Input box: $input');
    } catch (error) {
      log('⚠ Window demo: $error');
    }
  }

  // ... (existing code) ...

  // ═══════════════════════════════════════════════════════════════════
  // 11. Toolbar API (registerItem, unregisterItem, onTap)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _demonstrateToolbar() async {
    try {
      await _context.toolbar.registerItem(
        id: 'demo_action',
        icon: 'play',
        tooltip: 'Run Demo Action',
      );

      _context.toolbar.onTap((id) {
        if (id == 'demo_action') {
          demonstrateWindowDialogs();
        }
      });
      
      log('🛠️ Registered toolbar item');
    } catch (error) {
     log('⚠ Toolbar demo: $error');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 8. Editor Manipulation (insertText, replaceText, setSelections)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> demonstrateEditorManipulation([Map<String, dynamic>? args]) async {
    try {
      // insertText
      await _context.editor.insertText('// Inserted by Demo Plugin\n');
      log('✍️  Inserted comment at cursor');

      // setSelections — move cursor to line 0, column 0
      await _context.editor.setSelections([
        {
          'anchor': {'line': 0, 'column': 0},
          'focus': {'line': 0, 'column': 0},
        },
      ]);
      log('✍️  Moved cursor to start of file');
    } catch (error) {
      log('⚠ Editor manipulation: $error');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 9. Commands API (register commands for the Command Palette)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _registerCommands() async {
    try {
      await _context.commands.registerCommand(
        id: 'lumide_demo_plugin.sayHello',
        title: 'Demo: Say Hello',
        category: 'Demo Plugin',
        callback: () async {
          await _context.window.showMessage(_greeting);
        },
      );

      await _context.commands.registerCommand(
        id: 'lumide_demo_plugin.showActiveFile',
        title: 'Demo: Show Active File',
        category: 'Demo Plugin',
        callback: () async {
          final uri = await _context.editor.getActiveDocumentUri();
          await _context.window.showMessage(
            uri != null ? 'Active: $uri' : 'No active file',
          );
        },
      );

      await _context.commands.registerCommand(
        id: 'lumide_demo_plugin.insertTimestamp',
        title: 'Demo: Insert Timestamp',
        category: 'Demo Plugin',
        callback: () async {
          final now = DateTime.now().toIso8601String();
          await _context.editor.insertText('// $now\n');
          log('⏱️  Inserted timestamp');
        },
      );

      await _context.commands.registerCommand(
        id: 'lumide_demo_plugin.toggleStatusBar',
        title: 'Demo: Toggle Status Bar Items',
        category: 'Demo Plugin',
        callback: () async {
          _statusBarVisible = !_statusBarVisible;
          if (_statusBarVisible) {
            await _context.statusBar.show('greeting');
            await _context.statusBar.show('cursor');
          } else {
            await _context.statusBar.hide('greeting');
            await _context.statusBar.hide('cursor');
          }
          log('📊 Status bar items ${_statusBarVisible ? 'shown' : 'hidden'}');
        },
      );

      await _context.commands.registerCommand(
        id: 'lumide_demo_plugin.showWindowDemo',
        title: 'Demo: Window Dialogs (Quick Pick, Input)',
        category: 'Demo Plugin',
        callback: demonstrateWindowDialogs,
      );

      await _context.commands.registerCommand(
        id: 'lumide_demo_plugin.showHttpDemo',
        title: 'Demo: HTTP Requests',
        category: 'Demo Plugin',
        callback: demonstrateHttp,
      );

      await _context.commands.registerCommand(
        id: 'lumide_demo_plugin.editorManipulation',
        title: 'Demo: Editor Manipulation',
        category: 'Demo Plugin',
        callback: demonstrateEditorManipulation,
      );

      log('🎯 Registered demo commands');
    } catch (error) {
      log('⚠ Commands demo: $error');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 10. Status Bar API (create, update, show/hide, dispose)
  // ═══════════════════════════════════════════════════════════════════

  bool _statusBarVisible = true;

  Future<void> _createStatusBarItems() async {
    try {
      // Left-aligned item showing plugin status
      await _context.statusBar.createItem(
        id: 'greeting',
        text: '🦊 Demo Plugin',
        tooltip: 'Demo Plugin is running',
        command: 'lumide_demo_plugin.sayHello',
        alignment: 'left',
        priority: 10,
      );

      // Right-aligned item showing cursor info (updated via selection events)
      await _context.statusBar.createItem(
        id: 'cursor',
        text: 'L-:-',
        tooltip: 'Cursor position (via Demo Plugin)',
        alignment: 'right',
        priority: 5,
      );

      log('📊 Created 2 status bar items');
    } catch (error) {
      log('⚠ StatusBar demo: $error');
    }
  }

  void _onSelectionsChanged(List<Map<String, dynamic>> selections) {
    if (selections.isEmpty) return;
    try {
      final focus = selections.first['focus'] as Map<String, dynamic>;
      final line = focus['line'] as int;
      final column = focus['column'] as int;
      _context.statusBar.updateItem(
        'cursor',
        text: 'L${line + 1}:${column + 1}',
      );
    } catch (error) {
      log('⚠ Cursor status bar update: $error');
    }
  }
}
