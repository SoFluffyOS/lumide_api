import 'package:json_rpc_2/error_code.dart' as rpc_error_code;
import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;
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
        const LumideWorkspaceFolder(
          uri: 'file:///work/api',
          name: 'api',
          label: 'api (work)',
        ).toJson(),
      ],
    );

    final folders = await harness.context.workspace.getWorkspaceFolders();

    expect(folders.map((folder) => folder.name), ['app', 'api']);
    expect(folders.last.uri, 'file:///work/api');
    expect(folders.last.label, 'api (work)');
    expect(folders.first.label, isNull);
  });

  test('falls back to the root on a host without workspace folders', () async {
    final harness = RpcHarness.create();
    harness.host.registerMethod(
      PluginMethods.workspaceGetRootUri,
      (_) => 'file:///home/me/app',
    );
    harness.host.registerMethod(
      PluginMethods.workspaceGetWorkspaceFolders,
      (_) => throw RpcException(rpc_error_code.METHOD_NOT_FOUND, 'unknown'),
    );

    final folders = await harness.context.workspace.getWorkspaceFolders();

    expect(folders, [
      const LumideWorkspaceFolder(uri: 'file:///home/me/app', name: 'app'),
    ]);
  });

  test('reports folders added, removed and relabelled until disposed',
      () async {
    final harness = RpcHarness.create();
    final events = <LumideWorkspaceFoldersChangeEvent>[];
    final listener = harness.context.workspace.onDidChangeWorkspaceFolders(
      events.add,
    );

    harness.host.sendNotification(
      HostMethods.didChangeWorkspaceFolders,
      LumideWorkspaceFoldersChangeEvent(
        added: const [LumideWorkspaceFolder(uri: 'file:///web', name: 'web')],
        removed: const [
          LumideWorkspaceFolder(uri: 'file:///api', name: 'api'),
        ],
        changed: const [
          LumideWorkspaceFolder(
            uri: 'file:///a/app',
            name: 'app',
            label: 'app (a)',
          ),
        ],
      ).toJson(),
    );
    await pumpEventQueue();

    final event = events.single;
    expect(event.added.single.uri, 'file:///web');
    expect(event.removed.single.name, 'api');
    expect(event.changed.single.label, 'app (a)');
    expect(() => event.added.add(event.removed.single), throwsUnsupportedError);

    listener.dispose();
    harness.host.sendNotification(
      HostMethods.didChangeWorkspaceFolders,
      LumideWorkspaceFoldersChangeEvent().toJson(),
    );
    await pumpEventQueue();
    expect(events, hasLength(1));
  });

  test('custom workspaces get default folder implementations', () async {
    final workspace = _RootOnlyWorkspace();

    expect(await workspace.getWorkspaceFolders(), [
      const LumideWorkspaceFolder(uri: 'file:///src/lumide', name: 'lumide'),
    ]);
    workspace
        .onDidChangeWorkspaceFolders((_) => fail('never called'))
        .dispose();
  });

  test('folders compare by value', () {
    const folder = LumideWorkspaceFolder(uri: 'file:///a', name: 'a');
    expect(folder, const LumideWorkspaceFolder(uri: 'file:///a', name: 'a'));
    expect(
      folder,
      isNot(
          const LumideWorkspaceFolder(uri: 'file:///a', name: 'a', label: 'x')),
    );
    expect(
      folder.hashCode,
      const LumideWorkspaceFolder(uri: 'file:///a', name: 'a').hashCode,
    );
  });
}

class _RootOnlyWorkspace extends LumideWorkspace {
  @override
  Future<String?> getRootUri() async => 'file:///src/lumide';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
