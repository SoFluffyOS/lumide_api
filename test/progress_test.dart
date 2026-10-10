import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

import 'support/rpc_harness.dart';

void main() {
  late RpcHarness harness;
  late List<(String, Map<dynamic, dynamic>)> calls;

  setUp(() {
    harness = RpcHarness.create();
    calls = [];
    for (final method in [
      PluginMethods.windowCreateProgress,
      PluginMethods.windowReportProgress,
      PluginMethods.windowEndProgress,
    ]) {
      harness.host.registerMethod(method, (params) {
        calls.add((method, params.value as Map));
        return null;
      });
    }
  });

  test('withProgress reports and ends even when the task throws', () async {
    await expectLater(
      harness.context.window.withProgress<void>(
        title: 'Indexing',
        task: (progress) async {
          await progress.report(message: 'lib/', percentage: 40);
          throw StateError('failed');
        },
      ),
      throwsStateError,
    );

    expect(calls.map((call) => call.$1), [
      PluginMethods.windowCreateProgress,
      PluginMethods.windowReportProgress,
      PluginMethods.windowEndProgress,
    ]);
    expect(calls[1].$2['percentage'], 40);
    expect(calls.first.$2['cancellable'], false);
  });

  test('cancellation reaches listeners once and done is idempotent', () async {
    final progress = await harness.context.window.createProgress(
      title: 'Build',
      cancellable: true,
    );
    var cancellations = 0;
    progress.onCancel(() => cancellations++);

    harness.host
      ..sendNotification(HostMethods.windowCancelProgress, {'id': progress.id})
      ..sendNotification(HostMethods.windowCancelProgress, {'id': progress.id});
    await pumpEventQueue();

    expect(progress.isCancelled, isTrue);
    expect(cancellations, 1);

    await progress.done();
    await progress.done();
    await progress.report(message: 'ignored');
    expect(
      calls.where((call) => call.$1 == PluginMethods.windowEndProgress),
      hasLength(1),
    );
    expect(
      calls.where((call) => call.$1 == PluginMethods.windowReportProgress),
      isEmpty,
    );
  });
}
