import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

import 'support/rpc_harness.dart';

void main() {
  test('test runs create, stream results, and end once', () async {
    final harness = RpcHarness.create();
    final calls = <(String, Map<dynamic, dynamic>)>[];
    for (final method in [
      PluginMethods.testsCreateRun,
      PluginMethods.testsUpdateRun,
      PluginMethods.testsEndRun,
    ]) {
      harness.host.registerMethod(method, (params) {
        calls.add((method, params.value as Map));
        return null;
      });
    }

    final run = await harness.context.tests.createRun(title: 'widget_test');
    await run.update(const [
      LumideTestResult(
        id: 'group',
        label: 'Counter',
        state: LumideTestState.running,
      ),
      LumideTestResult(
        id: 'test-1',
        label: 'increments',
        parentId: 'group',
        state: LumideTestState.failed,
        uri: 'file:///app/test/widget_test.dart',
        line: 12,
        message: 'Expected: 1\\n  Actual: 0',
        durationMs: 40,
      ),
    ]);
    await run.end(summary: '1 failed');
    await run.end();
    await run.update(const [
      LumideTestResult(
          id: 'late', label: 'late', state: LumideTestState.passed),
    ]);

    expect(calls.map((call) => call.$1), [
      PluginMethods.testsCreateRun,
      PluginMethods.testsUpdateRun,
      PluginMethods.testsEndRun,
    ]);
    expect(calls.first.$2, {'id': run.id, 'title': 'widget_test'});
    final failed = LumideTestResult.fromJson(
      (calls[1].$2['results'] as List).last as Map,
    );
    expect(failed.state, LumideTestState.failed);
    expect(failed.parentId, 'group');
    expect(failed.line, 12);
    expect(calls.last.$2['summary'], '1 failed');
  });

  test('createRun sends output channel and run commands', () async {
    final harness = RpcHarness.create();
    final created = <Map<dynamic, dynamic>>[];
    harness.host
      ..registerMethod(PluginMethods.windowCreateOutputChannel, (_) => 'ch-1')
      ..registerMethod(PluginMethods.testsCreateRun, (params) {
        created.add(params.value as Map);
        return null;
      });

    final output = await harness.context.window.createOutputChannel('Tests');
    final run = await harness.context.tests.createRun(
      title: 'all tests',
      output: output,
      runCommand: 'demo.runTests',
      debugCommand: 'demo.debugTests',
      stopCommand: 'demo.stopTests',
    );

    expect(created.single, {
      'id': run.id,
      'title': 'all tests',
      'outputChannelId': 'ch-1',
      'runCommand': 'demo.runTests',
      'debugCommand': 'demo.debugTests',
      'stopCommand': 'demo.stopTests',
    });
  });
}
