import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

import 'support/rpc_harness.dart';

void main() {
  test('the host reloads a launch through the provider', () async {
    final harness = RpcHarness.create();
    LumideLaunchReloadRequest? received;
    harness.context.launch.onReload((request) async {
      received = request;
      return const LumideLaunchReloadResult(
        ok: false,
        message: 'Reload rejected',
        errors: ["lib/main.dart:4:3: Error: Expected ';' after this."],
      );
    });

    final response = await harness.host.sendRequest(
      HostMethods.launchReload,
      const LumideLaunchReloadRequest(
        providerId: 'flutter',
        kind: LumideLaunchKind.debug,
        configurationId: 'main',
        workspaceFolder: '/work/app',
        fullRestart: true,
      ).toJson(),
    );
    final result = LumideLaunchReloadResult.fromJson(response as Map);

    expect(received?.providerId, 'flutter');
    expect(received?.kind, LumideLaunchKind.debug);
    expect(received?.configurationId, 'main');
    expect(received?.workspaceFolder, '/work/app');
    expect(received?.fullRestart, isTrue);
    expect(result.ok, isFalse);
    expect(result.message, 'Reload rejected');
    expect(result.errors, [
      "lib/main.dart:4:3: Error: Expected ';' after this.",
    ]);
  });

  test('a provider without a reload handler is not asked', () async {
    final harness = RpcHarness.create();

    final response = harness.host.sendRequest(
      HostMethods.launchReload,
      const LumideLaunchReloadRequest(
        providerId: 'flutter',
        kind: LumideLaunchKind.run,
        configurationId: 'main',
      ).toJson(),
    );

    await expectLater(response, throwsA(isA<json_rpc.RpcException>()));
  });

  test('reload requests and results read what older peers leave out', () {
    final request = LumideLaunchReloadRequest.fromJson(const {
      'providerId': 'flutter',
      'configurationId': 'main',
    });
    final result = LumideLaunchReloadResult.fromJson(const {'ok': true});

    expect(request.kind, LumideLaunchKind.run);
    expect(request.workspaceFolder, isNull);
    expect(request.fullRestart, isFalse);
    expect(request.toJson().containsKey('workspaceFolder'), isFalse);
    expect(result.ok, isTrue);
    expect(result.message, isEmpty);
    expect(result.errors, isEmpty);
    expect(result.toJson(), {'ok': true});
  });
}
