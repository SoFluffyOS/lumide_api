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
