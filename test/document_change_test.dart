import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

import 'support/rpc_harness.dart';

void main() {
  test('change listeners toggle the host subscription', () async {
    final harness = RpcHarness.create();
    final subscriptions = <bool>[];
    harness.host.registerMethod(
      PluginMethods.workspaceSetTextDocumentChangeSubscription,
      (params) {
        subscriptions.add((params.value as Map)['enabled'] as bool);
        return null;
      },
    );

    final first = harness.context.workspace.onDidChangeTextDocument((_) {});
    final second = harness.context.workspace.onDidChangeTextDocument((_) {});
    await pumpEventQueue();
    expect(subscriptions, [true]);

    first.dispose();
    await pumpEventQueue();
    expect(subscriptions, [true]);

    second.dispose();
    await pumpEventQueue();
    expect(subscriptions, [true, false]);
  });

  test('ignores hosts without subscription support', () async {
    final harness = RpcHarness.create();
    harness.context.workspace.onDidChangeTextDocument((_) {});
    await pumpEventQueue();
  });

  test('decodes ranged and full changes with the version', () async {
    final harness = RpcHarness.create();
    harness.host.registerMethod(
      PluginMethods.workspaceSetTextDocumentChangeSubscription,
      (_) => null,
    );
    final events = <DocumentChangeEvent>[];
    harness.context.workspace.onDidChangeTextDocument(events.add);

    await harness.host.sendRequest(HostMethods.didChangeTextDocument, {
      'uri': 'file:///a.dart',
      'version': 3,
      'changes': [
        {
          'text': 'x',
          'startLine': 1,
          'startColumn': 2,
          'endLine': 1,
          'endColumn': 4,
        },
        {'text': 'full'},
      ],
    });

    final event = events.single;
    expect(event.version, 3);
    expect(event.changes.first.startLine, 1);
    expect(event.changes.first.endColumn, 4);
    expect(event.changes.last.startLine, isNull);
    expect(event.changes.last.text, 'full');
  });
}
