import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

void main() {
  test('configuration kinds are additive and backward compatible', () {
    final legacy = LumideLaunchConfiguration.fromJson(const {
      'id': 'legacy',
      'label': 'Legacy',
      'kind': 'debug',
    });
    final modern = LumideLaunchConfiguration.fromJson(const {
      'id': 'modern',
      'label': 'Modern',
      'kind': 'run',
      'kinds': ['run', 'debug'],
    });

    expect(legacy.supportedKinds, [LumideLaunchKind.debug]);
    expect(modern.supportedKinds, [
      LumideLaunchKind.run,
      LumideLaunchKind.debug,
    ]);
    expect(modern.toJson()['kinds'], ['run', 'debug']);
  });

  test('source configuration and resolution round trip', () {
    const source = LumideLaunchSourceConfiguration(
      id: 'main',
      name: 'Main',
      providerId: 'flutter',
      kinds: [LumideLaunchKind.run, LumideLaunchKind.debug],
      config: {'target': 'lib/main.dart'},
    );
    const resolution = LumideLaunchResolution(
      configuration: LumideLaunchConfiguration(
        id: 'main',
        label: 'Main',
        kinds: [LumideLaunchKind.run, LumideLaunchKind.debug],
      ),
      diagnostics: [
        LumideLaunchConfigurationDiagnostic(
          severity: LumideLaunchDiagnosticSeverity.warning,
          message: 'Device is unavailable',
          path: r'$.config.deviceId',
        ),
      ],
    );

    final decodedSource = LumideLaunchSourceConfiguration.fromJson(
      source.toJson(),
    );
    final decodedResolution = LumideLaunchResolution.fromJson(
      resolution.toJson(),
    );

    expect(decodedSource.config['target'], 'lib/main.dart');
    expect(decodedSource.kinds, source.kinds);
    expect(decodedResolution.configuration?.supportedKinds, source.kinds);
    expect(decodedResolution.diagnostics.single.path, r'$.config.deviceId');
  });

  test('launch events carry the device and VM service they attached to', () {
    const event = LumideLaunchEvent(
      providerId: 'flutter',
      kind: LumideLaunchKind.run,
      configurationId: 'main',
      deviceId: 'raccoon',
      vmServiceUri: 'http://127.0.0.1:4000/abc=/',
    );

    final decoded = LumideLaunchEvent.fromJson(event.toJson());

    expect(decoded.deviceId, 'raccoon');
    expect(decoded.vmServiceUri, 'http://127.0.0.1:4000/abc=/');
    expect(
      LumideLaunchEvent.fromJson(const {
        'providerId': 'flutter',
        'kind': 'run',
        'configurationId': 'main',
      }).vmServiceUri,
      isNull,
      reason: 'older plugins send neither field',
    );
  });

  test('launch models carry their workspace folder', () {
    const configuration = LumideLaunchConfiguration(
      id: 'main',
      label: 'Main',
      workspaceFolder: '/work/api',
    );
    const source = LumideLaunchSourceConfiguration(
      id: 'main',
      name: 'Main',
      providerId: 'flutter',
      workspaceFolder: '/work/api',
    );
    const event = LumideLaunchEvent(
      providerId: 'flutter',
      kind: LumideLaunchKind.run,
      configurationId: 'main',
      workspaceFolder: '/work/api',
    );

    expect(
      LumideLaunchConfiguration.fromJson(configuration.toJson())
          .workspaceFolder,
      '/work/api',
    );
    expect(
      LumideLaunchSourceConfiguration.fromJson(source.toJson()).workspaceFolder,
      '/work/api',
    );
    expect(
      LumideLaunchEvent.fromJson(event.toJson()).workspaceFolder,
      '/work/api',
    );
    expect(
      configuration.withWorkspaceFolder('/work/web').workspaceFolder,
      '/work/web',
    );
    expect(
      const LumideLaunchConfiguration(id: 'a', label: 'A').toJson(),
      isNot(contains('workspaceFolder')),
    );
  });

  test('resolve requests name their folder, falling back to the workspace', () {
    final modern = LumideLaunchResolveRequest.fromJson(const {
      'providerId': 'flutter',
      'workspacePath': '/work/api',
      'workspaceFolder': '/work/api',
    });
    final legacy = LumideLaunchResolveRequest.fromJson(const {
      'providerId': 'flutter',
      'workspacePath': '/work/app',
    });

    expect(modern.workspaceFolder, '/work/api');
    expect(legacy.workspaceFolder, '/work/app');
  });

  test('foreign import result round trips fidelity and diagnostics', () {
    const foreign = LumideForeignLaunchConfiguration(
      format: 'vscode',
      name: 'Flutter',
      raw: {
        'type': 'dart',
        'request': 'launch',
        'program': 'lib/main.dart',
      },
    );
    const result = LumideLaunchImportResult(
      fidelity: LumideLaunchImportFidelity.partial,
      diagnostics: [
        LumideLaunchConfigurationDiagnostic(
          severity: LumideLaunchDiagnosticSeverity.warning,
          message: 'preLaunchTask is not supported',
        ),
      ],
    );

    expect(
      LumideForeignLaunchConfiguration.fromJson(foreign.toJson()).raw,
      foreign.raw,
    );
    final decoded = LumideLaunchImportResult.fromJson(result.toJson());
    expect(decoded.fidelity, LumideLaunchImportFidelity.partial);
    expect(decoded.diagnostics.single.message, contains('preLaunchTask'));
  });

  test('launch import descriptors match generic raw selectors', () {
    const descriptor = LumideLaunchImportDescriptor(
      format: 'vscode',
      selectors: {
        'type': ['dart'],
        'request': ['launch'],
      },
    );

    expect(
      descriptor.matches('vscode', const {
        'type': 'dart',
        'request': 'launch',
      }),
      isTrue,
    );
    expect(
      descriptor.matches('vscode', const {
        'type': 'node',
        'request': 'launch',
      }),
      isFalse,
    );
    expect(
      LumideLaunchImportDescriptor.fromJson(descriptor.toJson()).selectors,
      descriptor.selectors,
    );
  });
}
