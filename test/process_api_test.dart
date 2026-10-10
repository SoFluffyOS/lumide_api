import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

import 'support/rpc_harness.dart';

void main() {
  test('shell.run forwards environment and stdin', () async {
    final harness = RpcHarness.create();
    Map<dynamic, dynamic>? request;
    harness.host.registerMethod(PluginMethods.shellRun, (params) {
      request = params.value as Map;
      return {'exitCode': 0, 'stdout': 'formatted', 'stderr': ''};
    });

    final result = await harness.context.shell.run(
      'pint',
      const ['--stdin'],
      environment: const {'XDEBUG_MODE': 'off'},
      stdin: '<?php echo 1;',
    );

    expect(result.stdout, 'formatted');
    expect(request?['environment'], {'XDEBUG_MODE': 'off'});
    expect(request?['stdin'], '<?php echo 1;');
  });

  test('shell.run omits optional fields when unset', () async {
    final harness = RpcHarness.create();
    Map<dynamic, dynamic>? request;
    harness.host.registerMethod(PluginMethods.shellRun, (params) {
      request = params.value as Map;
      return {'exitCode': 0, 'stdout': '', 'stderr': ''};
    });

    await harness.context.shell.run('git', const ['status']);

    expect(request?.containsKey('environment'), isFalse);
    expect(request?.containsKey('stdin'), isFalse);
  });

  test('shell.kill sends the signal name', () async {
    final harness = RpcHarness.create();
    final signals = <Object?>[];
    harness.host.registerMethod(PluginMethods.shellKill, (params) {
      signals.add((params.value as Map)['signal']);
      return true;
    });

    await harness.context.shell.kill(42, signal: LumideProcessSignal.interrupt);
    await harness.context.shell.kill(42);

    expect(signals, ['SIGINT', null]);
  });

  test('sdks.spawn returns the pid from the host', () async {
    final harness = RpcHarness.create();
    Map<dynamic, dynamic>? request;
    harness.host.registerMethod(PluginMethods.sdkSpawn, (params) {
      request = params.value as Map;
      return 1234;
    });

    final pid = await harness.context.sdks.spawn(
      const LumideSdkResolveRequest(
        kind: LumideSdkKind('flutter'),
        executable: 'flutter',
      ),
      const ['run', '--machine'],
      workingDirectory: '/app',
      environment: const {'FLAVOR': 'dev'},
    );

    expect(pid, 1234);
    expect(request?['arguments'], ['run', '--machine']);
    expect(request?['environment'], {'FLAVOR': 'dev'});
    expect((request?['request'] as Map)['executable'], 'flutter');
  });

  test('signal wire names round trip', () {
    for (final signal in LumideProcessSignal.values) {
      expect(LumideProcessSignal.fromWireName(signal.wireName), signal);
    }
    expect(LumideProcessSignal.fromWireName('SIGUSR1'), isNull);
  });
}
