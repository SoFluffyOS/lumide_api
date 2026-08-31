import 'dart:async';

import 'package:lumide_api/lumide_api.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

void main() {
  test('SDK bridge routes every host and provider RPC contract', () async {
    final channels = StreamChannelController<String>(sync: true);
    final pluginSession = RpcSession(channels.local);
    final hostSession = RpcSession(channels.foreign);
    final context = RpcLumideContext(pluginSession);
    final pluginListening = pluginSession.listen();
    final hostListening = hostSession.listen();
    addTearDown(() async {
      await Future.wait([pluginSession.close(), hostSession.close()]);
      await Future.wait([pluginListening, hostListening]);
    });

    Map<dynamic, dynamic>? registeredProvider;
    var providerRegistrations = 0;
    String? unregisteredProvider;
    String? changedProvider;
    hostSession.registerMethod(PluginMethods.sdkRegisterProvider, (params) {
      providerRegistrations++;
      registeredProvider = params.value as Map;
      return null;
    });
    hostSession.registerMethod(PluginMethods.sdkUnregisterProvider, (params) {
      unregisteredProvider = (params.value as Map)['id']?.toString();
      return null;
    });
    hostSession.registerMethod(PluginMethods.sdkDidChange, (params) {
      changedProvider = (params.value as Map)['providerId']?.toString();
      return null;
    });
    hostSession.registerMethod(PluginMethods.sdkResolve, (params) {
      final request = LumideSdkResolveRequest.fromJson(params.value as Map);
      expect(request.workspacePath, '/workspace');
      return _resolution.toJson();
    });
    hostSession.registerMethod(PluginMethods.sdkRun, (params) {
      final json = params.value as Map;
      final request = LumideSdkResolveRequest.fromJson(json['request'] as Map);
      expect(request.executable, 'flutter');
      expect(json['arguments'], ['doctor']);
      expect(json['workingDirectory'], '/workspace');
      return {'exitCode': 0, 'stdout': 'healthy', 'stderr': ''};
    });

    await context.sdks.registerProvider(_provider);
    expect(
      await hostSession.sendRequest(
        HostMethods.sdkActivateProvider,
        {'id': 'flutter'},
      ),
      isTrue,
    );
    await context.sdks.didChange('flutter');
    final resolution = await context.sdks.resolve(_resolveRequest);
    final result = await context.sdks.run(
      _resolveRequest,
      const ['doctor'],
      workingDirectory: '/workspace',
    );
    await context.sdks.unregisterProvider('flutter');

    expect(registeredProvider?['id'], 'flutter');
    expect(providerRegistrations, 2);
    expect(changedProvider, 'flutter');
    expect(unregisteredProvider, 'flutter');
    expect(resolution?.installation.version, '3.47.2');
    expect(result.stdout, 'healthy');

    LumideSdkSelectionChangeEvent? selectionChange;
    context.sdks.onDidChangeSelection((event) {
      selectionChange = event;
    });
    await hostSession.sendRequest(
      HostMethods.sdkDidChangeSelection,
      const LumideSdkSelectionChangeEvent(
        kind: LumideSdkKind.flutter,
        workspacePath: '/workspace',
      ).toJson(),
    );
    expect(selectionChange?.kind, LumideSdkKind.flutter);
    expect(selectionChange?.workspacePath, '/workspace');

    context.sdks.onListAvailable((request) async {
      expect(request.providerId, 'flutter');
      return const [_release];
    });
    context.sdks.onDiscover((request) async {
      expect(request.workspacePath, '/workspace');
      return const [_installation];
    });
    context.sdks.onResolve((request) async {
      expect(request.purpose, LumideSdkPurpose.run);
      return _resolution;
    });
    context.sdks.onGetInstallPlan((request) async {
      expect(request.release.id, _release.id);
      return _installPlan;
    });
    context.sdks.onValidate((request) async {
      expect(request.installation.id, _installation.id);
      return const LumideSdkValidation(
        state: LumideSdkValidationState.valid,
        message: 'Healthy',
      );
    });

    final releases = await hostSession.sendRequest(
      HostMethods.sdkListAvailable,
      const LumideSdkListRequest(providerId: 'flutter').toJson(),
    ) as List;
    final installations = await hostSession.sendRequest(
      HostMethods.sdkDiscover,
      const LumideSdkDiscoveryRequest(
        providerId: 'flutter',
        workspacePath: '/workspace',
      ).toJson(),
    ) as List;
    final providerResolution = await hostSession.sendRequest(
      HostMethods.sdkResolve,
      _resolveRequest.toJson(),
    ) as Map;
    final plan = await hostSession.sendRequest(
      HostMethods.sdkGetInstallPlan,
      const LumideSdkInstallPlanRequest(
        providerId: 'flutter',
        release: _release,
      ).toJson(),
    ) as Map;
    final validation = await hostSession.sendRequest(
      HostMethods.sdkValidate,
      const LumideSdkValidationRequest(
        providerId: 'flutter',
        installation: _installation,
      ).toJson(),
    ) as Map;

    expect(
      LumideSdkRelease.fromJson(releases.single as Map).toJson(),
      _release.toJson(),
    );
    expect(
      LumideSdkInstallation.fromJson(installations.single as Map).toJson(),
      _installation.toJson(),
    );
    expect(
      LumideSdkResolution.fromJson(providerResolution).executable,
      'bin/flutter',
    );
    expect(LumideSdkInstallPlan.fromJson(plan).sha256, 'a' * 64);
    expect(
      LumideSdkValidation.fromJson(validation).state,
      LumideSdkValidationState.valid,
    );
  });

  test('SDK bridge identifies hosts without SDK API support', () async {
    final channels = StreamChannelController<String>(sync: true);
    final pluginSession = RpcSession(channels.local);
    final hostSession = RpcSession(channels.foreign);
    final context = RpcLumideContext(pluginSession);
    final pluginListening = pluginSession.listen();
    final hostListening = hostSession.listen();
    addTearDown(() async {
      await Future.wait([pluginSession.close(), hostSession.close()]);
      await Future.wait([pluginListening, hostListening]);
    });

    await expectLater(
      context.sdks.resolve(_resolveRequest),
      throwsA(isA<UnsupportedError>()),
    );
  });
}

const _provider = LumideSdkProviderDescriptor(
  id: 'flutter',
  kind: LumideSdkKind.flutter,
  title: 'Flutter',
  capabilities: LumideSdkProviderCapabilities(
    catalog: true,
    install: true,
  ),
);

const _release = LumideSdkRelease(
  id: 'flutter-3.47.2',
  version: '3.47.2',
  channel: 'stable',
);

const _installation = LumideSdkInstallation(
  id: 'flutter-3.47.2',
  providerId: 'flutter',
  kind: LumideSdkKind.flutter,
  version: '3.47.2',
  rootPath: '/sdk/flutter',
  source: LumideSdkSource.lumideManaged,
  executables: {'flutter': 'bin/flutter'},
);

const _resolution = LumideSdkResolution(
  installation: _installation,
  executable: 'bin/flutter',
);

const _resolveRequest = LumideSdkResolveRequest(
  kind: LumideSdkKind.flutter,
  providerId: 'flutter',
  workspacePath: '/workspace',
  executable: 'flutter',
  purpose: LumideSdkPurpose.run,
);

final _installPlan = LumideSdkInstallPlan.archive(
  releaseId: _release.id,
  archiveUri: 'https://example.test/flutter.zip',
  sha256: 'a' * 64,
  format: LumideSdkArchiveFormat.zip,
  rootDirectory: 'flutter',
  executables: const {'flutter': 'bin/flutter'},
);
