import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

void main() {
  test('provider descriptor round trips extensible kinds and capabilities', () {
    const provider = LumideSdkProviderDescriptor(
      id: 'flutter',
      kind: LumideSdkKind.flutter,
      title: 'Flutter',
      capabilities: LumideSdkProviderCapabilities(
        catalog: true,
        install: true,
      ),
      iconPath: 'assets/flutter.svg',
    );

    final decoded = LumideSdkProviderDescriptor.fromJson(provider.toJson());

    expect(decoded.id, 'flutter');
    expect(decoded.kind, LumideSdkKind.flutter);
    expect(decoded.capabilities.catalog, isTrue);
    expect(decoded.capabilities.install, isTrue);
    expect(decoded.iconPath, 'assets/flutter.svg');
  });

  test('release preserves archive integrity and embedded SDK metadata', () {
    const release = LumideSdkRelease(
      id: 'flutter-3.47.2-stable-macos-arm64',
      version: '3.47.2',
      channel: 'stable',
      archiveUri: 'https://example.invalid/flutter.tar.xz',
      sha256: 'abc123',
      archiveFormat: LumideSdkArchiveFormat.tarXz,
      archiveRootDirectory: 'flutter',
      platform: 'macos',
      architecture: 'arm64',
      embeddedSdks: [
        LumideEmbeddedSdk(
          kind: LumideSdkKind.dart,
          version: '3.13.2',
          rootPath: 'bin/cache/dart-sdk',
          executables: {'dart': 'bin/dart'},
        ),
      ],
    );

    final decoded = LumideSdkRelease.fromJson(release.toJson());

    expect(decoded.archiveFormat, LumideSdkArchiveFormat.tarXz);
    expect(decoded.embeddedSdks.single.kind, LumideSdkKind.dart);
    expect(decoded.embeddedSdks.single.version, '3.13.2');
  });

  test('installation, resolution, and validation round trip', () {
    const installation = LumideSdkInstallation(
      id: 'flutter-system',
      providerId: 'lumide_flutter.flutter',
      kind: LumideSdkKind.flutter,
      version: '3.47.2',
      rootPath: '/opt/flutter',
      source: LumideSdkSource.system,
      executables: {'flutter': 'bin/flutter', 'dart': 'bin/dart'},
    );
    const resolution = LumideSdkResolution(
      installation: installation,
      executable: '/opt/flutter/bin/flutter',
      arguments: ['--suppress-analytics'],
      environment: {'FLUTTER_ROOT': '/opt/flutter'},
    );
    const validation = LumideSdkValidation(
      state: LumideSdkValidationState.valid,
      message: 'Flutter 3.47.2',
    );

    final decodedResolution = LumideSdkResolution.fromJson(
      resolution.toJson(),
    );
    final decodedValidation = LumideSdkValidation.fromJson(
      validation.toJson(),
    );

    expect(decodedResolution.installation.source, LumideSdkSource.system);
    expect(decodedResolution.executable, '/opt/flutter/bin/flutter');
    expect(decodedResolution.environment['FLUTTER_ROOT'], '/opt/flutter');
    expect(decodedValidation.isValid, isTrue);
  });

  test('external manager provenance round trips', () {
    const installation = LumideSdkInstallation(
      id: 'fvm-stable',
      providerId: 'flutter',
      kind: LumideSdkKind.flutter,
      version: '3.35.0',
      rootPath: '/sdks/flutter',
      source: LumideSdkSource.externalManager,
      managerId: LumideSdkManagerId.fvm,
      managerScope: LumideSdkManagerScope.workspace,
    );

    final decoded = LumideSdkInstallation.fromJson(installation.toJson());

    expect(decoded.source, LumideSdkSource.externalManager);
    expect(decoded.managerId, LumideSdkManagerId.fvm);
    expect(decoded.managerScope, LumideSdkManagerScope.workspace);
  });

  test('warning validation remains usable while invalid does not', () {
    const warning = LumideSdkValidation(
      state: LumideSdkValidationState.warning,
    );
    const invalid = LumideSdkValidation(
      state: LumideSdkValidationState.invalid,
    );

    expect(warning.isValid, isTrue);
    expect(invalid.isValid, isFalse);
  });

  test('archive install plan round trips required security fields', () {
    const plan = LumideSdkInstallPlan.archive(
      releaseId: 'flutter-3.47.2',
      archiveUri: 'https://example.invalid/flutter.zip',
      sha256: 'deadbeef',
      format: LumideSdkArchiveFormat.zip,
      rootDirectory: 'flutter',
      executables: {'flutter': 'bin/flutter'},
    );

    final decoded = LumideSdkInstallPlan.fromJson(plan.toJson());

    expect(decoded.releaseId, plan.releaseId);
    expect(decoded.sha256, plan.sha256);
    expect(decoded.rootDirectory, 'flutter');
  });
}
