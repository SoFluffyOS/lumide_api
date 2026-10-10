import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

import 'support/rpc_harness.dart';

void main() {
  test('file change listeners subscribe and decode batches', () async {
    final harness = RpcHarness.create();
    final subscriptions = <bool>[];
    harness.host.registerMethod(
      PluginMethods.workspaceSetFileChangeSubscription,
      (params) {
        subscriptions.add((params.value as Map)['enabled'] as bool);
        return null;
      },
    );
    final events = <LumideFileChangeEvent>[];
    final listener = harness.context.workspace.onDidChangeFiles(events.add);
    await pumpEventQueue();

    harness.host.sendNotification(
      HostMethods.didChangeFiles,
      const LumideFileChangeEvent(
        changes: [
          LumideFileChange(
            uri: 'file:///app/pubspec.yaml',
            type: LumideFileChangeType.changed,
          ),
          LumideFileChange(
            uri: 'file:///app/lib/b.dart',
            type: LumideFileChangeType.renamed,
            oldUri: 'file:///app/lib/a.dart',
          ),
        ],
      ).toJson(),
    );
    await pumpEventQueue();

    final event = events.single;
    expect(event.isOverflow, isFalse);
    expect(event.changes.last.type, LumideFileChangeType.renamed);
    expect(event.changes.last.oldUri, 'file:///app/lib/a.dart');

    listener.dispose();
    await pumpEventQueue();
    expect(subscriptions, [true, false]);
  });
}
