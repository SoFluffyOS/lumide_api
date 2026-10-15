import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

import 'support/rpc_harness.dart';

void main() {
  test('lists the workspace folders in order', () async {
    final harness = RpcHarness.create();
    harness.host.registerMethod(
      PluginMethods.workspaceGetWorkspaceFolders,
      (_) => [
        const LumideWorkspaceFolder(uri: 'file:///app', name: 'app').toJson(),
        const LumideWorkspaceFolder(uri: 'file:///api', name: 'api').toJson(),
      ],
    );

    final folders = await harness.context.workspace.getWorkspaceFolders();

    expect(folders.map((folder) => folder.name), ['app', 'api']);
    expect(folders.last.uri, 'file:///api');
  });

  test('reports folders added and removed until disposed', () async {
    final harness = RpcHarness.create();
    final events = <LumideWorkspaceFoldersChangeEvent>[];
    final listener = harness.context.workspace.onDidChangeWorkspaceFolders(
      events.add,
    );

    harness.host.sendNotification(
      HostMethods.didChangeWorkspaceFolders,
      const LumideWorkspaceFoldersChangeEvent(
        added: [LumideWorkspaceFolder(uri: 'file:///web', name: 'web')],
        removed: [LumideWorkspaceFolder(uri: 'file:///api', name: 'api')],
      ).toJson(),
    );
    await pumpEventQueue();

    expect(events.single.added.single.uri, 'file:///web');
    expect(events.single.removed.single.name, 'api');

    listener.dispose();
    harness.host.sendNotification(
      HostMethods.didChangeWorkspaceFolders,
      const LumideWorkspaceFoldersChangeEvent().toJson(),
    );
    await pumpEventQueue();
    expect(events, hasLength(1));
  });
}
