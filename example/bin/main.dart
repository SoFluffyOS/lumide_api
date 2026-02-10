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
/// - Logging via stderr (stdout is reserved for JSON-RPC)
library;

import 'dart:async';

import 'package:lumide_api/lumide_api.dart';

void main() => DemoPlugin().run();

class DemoPlugin extends LumidePlugin {
  Timer? _heartbeat;
  late LumideContext _context;

  // ── Configuration values (loaded from settings) ──────────────────
  String _greeting = 'Hello from Demo Plugin!';
  int _heartbeatInterval = 30;
  bool _logDocumentEvents = true;

  @override
  Future<void> onActivate(LumideContext context) async {
    _context = context;
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

    // ── 6. Editor API: report active document + selections ─────────
    await _reportActiveDocument();

    // ── 7. Heartbeat (interval from config) ────────────────────────
    _heartbeat = Timer.periodic(
      Duration(seconds: _heartbeatInterval),
      (_) async => _reportActiveDocument(),
    );
  }

  @override
  Future<void> onDeactivate() async {
    _heartbeat?.cancel();
    log('👋 Demo Plugin deactivated');
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
  // 5. Editor API (activeDocument, selections, insertText, replaceText)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _reportActiveDocument() async {
    try {
      final uri = await _context.editor.getActiveDocumentUri();
      if (uri == null) {
        log('📄 No active document');
        return;
      }

      final path = Uri.parse(uri).toFilePath();
      log('� Active: ${path.split('/').last}');

      // fs.exists
      final exists = await _context.fs.exists(path);
      log('   Exists: $exists');

      // editor.getSelections
      final selections = await _context.editor.getSelections();
      for (final sel in selections) {
        final anchor = sel['anchor'] as Map<String, dynamic>;
        final focus = sel['focus'] as Map<String, dynamic>;
        final isCollapsed = anchor['line'] == focus['line'] &&
            anchor['column'] == focus['column'];
        if (isCollapsed) {
          log('   Cursor: L${focus['line']}:${focus['column']}');
        } else {
          log('   Selection: L${anchor['line']}:${anchor['column']} → '
              'L${focus['line']}:${focus['column']}');
        }
      }
    } catch (error) {
      log('⚠ Error: $error');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 6. HTTP API (GET / POST) — called on demand, not on activation
  // ═══════════════════════════════════════════════════════════════════

  Future<void> demonstrateHttp() async {
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

  Future<void> demonstrateWindowDialogs() async {
    try {
      final choice = await _context.window.showQuickPick(
        ['Option A', 'Option B', 'Option C'],
        placeholder: 'Pick something...',
      );
      log('🪟 Quick pick: $choice');

      final input = await _context.window.showInputBox(
        prompt: 'Enter something:',
        value: 'default',
      );
      log('🪟 Input box: $input');
    } catch (error) {
      log('⚠ Window demo: $error');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 8. Editor Manipulation (insertText, replaceText, setSelections)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> demonstrateEditorManipulation() async {
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
}
