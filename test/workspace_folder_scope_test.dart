import 'package:json_rpc_2/error_code.dart' as rpc_error_code;
import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;
import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

import 'support/rpc_harness.dart';

const _app = LumideWorkspaceFolder(uri: 'file:///work/app', name: 'app');
const _package = LumideWorkspaceFolder(
  uri: 'file:///work/app/packages/ui',
  name: 'ui',
);

void main() {
  group('LumideWorkspaceFolder.containing', () {
    test('picks the deepest folder holding a URI or path', () {
      final folders = [_app, _package];

      expect(
        LumideWorkspaceFolder.containing(
          folders,
          'file:///work/app/lib/a.dart',
        ),
        _app,
      );
      expect(
        LumideWorkspaceFolder.containing(
          folders,
          '/work/app/packages/ui/lib/b.dart',
        ),
        _package,
      );
      expect(LumideWorkspaceFolder.containing(folders, '/work/app'), _app);
    });

    test('does not match a sibling that shares a prefix', () {
      expect(
        LumideWorkspaceFolder.containing([_app], 'file:///work/application/x'),
        isNull,
      );
    });
  });

  test('asks the host for the folder of a URI', () async {
    final harness = RpcHarness.create();
    String? asked;
    harness.host.registerMethod(PluginMethods.workspaceGetWorkspaceFolder, (
      params,
    ) {
      asked = (params.value as Map)['uri'] as String;
      return _package.toJson();
    });

    final folder = await harness.context.workspace.getWorkspaceFolder(
      'file:///work/app/packages/ui/lib/b.dart',
    );

    expect(asked, 'file:///work/app/packages/ui/lib/b.dart');
    expect(folder, _package);
  });

  test('finds the folder from the folder list on older hosts', () async {
    final harness = RpcHarness.create();
    harness.host.registerMethod(
      PluginMethods.workspaceGetWorkspaceFolder,
      (_) => throw RpcException(rpc_error_code.METHOD_NOT_FOUND, 'unknown'),
    );
    harness.host.registerMethod(
      PluginMethods.workspaceGetWorkspaceFolders,
      (_) => [_app.toJson(), _package.toJson()],
    );

    expect(
      await harness.context.workspace.getWorkspaceFolder(
        'file:///work/app/packages/ui/pubspec.yaml',
      ),
      _package,
    );
    expect(
      await harness.context.workspace.getWorkspaceFolder('file:///tmp/x'),
      isNull,
    );
  });

  test('searches one folder, even on hosts that search them all', () async {
    final harness = RpcHarness.create();
    Map<dynamic, dynamic>? request;
    harness.host.registerMethod(PluginMethods.workspaceFindFiles, (params) {
      request = params.value as Map;
      return [
        'file:///work/app/pubspec.yaml',
        'file:///work/app/packages/ui/pubspec.yaml',
      ];
    });

    final files = await harness.context.workspace.findFiles(
      '**/pubspec.yaml',
      folder: _package.uri,
    );

    expect(request?['folder'], _package.uri);
    expect(files, ['file:///work/app/packages/ui/pubspec.yaml']);
  });

  test('sends the scope of a configuration read', () async {
    final harness = RpcHarness.create();
    final requests = <Map<dynamic, dynamic>>[];
    harness.host.registerMethod(PluginMethods.workspaceGetConfiguration, (
      params,
    ) {
      requests.add(params.value as Map);
      return 80;
    });

    await harness.context.workspace.getConfiguration('printWidth');
    await harness.context.workspace.getConfiguration(
      'printWidth',
      scope: _package.uri,
    );

    expect(requests.first.containsKey('scope'), isFalse);
    expect(requests.last['scope'], _package.uri);
  });

  test('custom workspaces find the folder of a URI by default', () async {
    final workspace = _FoldersWorkspace();

    expect(
      await workspace.getWorkspaceFolder('file:///work/app/lib/main.dart'),
      _app,
    );
  });

  test('tells the host which folder an SDK changed in', () async {
    final harness = RpcHarness.create();
    final changes = <Map<dynamic, dynamic>>[];
    harness.host.registerMethod(PluginMethods.sdkDidChange, (params) {
      changes.add(params.value as Map);
      return null;
    });

    await harness.context.sdks.didChange('flutter');
    await harness.context.sdks.didChange(
      'flutter',
      workspaceFolder: '/work/app/packages/ui',
    );

    expect(changes.first.containsKey('workspaceFolder'), isFalse);
    expect(changes.last['workspaceFolder'], '/work/app/packages/ui');
  });
}

class _FoldersWorkspace extends LumideWorkspace {
  @override
  Future<List<LumideWorkspaceFolder>> getWorkspaceFolders() async => [
        _app,
        _package,
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
