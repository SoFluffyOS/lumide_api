import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

import 'support/rpc_harness.dart';

void main() {
  test('disposing a listener stops its events', () async {
    final harness = RpcHarness.create();
    final saved = <String>[];
    final subscription =
        harness.context.workspace.onDidSaveTextDocument(saved.add);

    await harness.host.sendRequest(
      HostMethods.didSaveTextDocument,
      {'uri': 'file:///a.dart'},
    );
    subscription.dispose();
    subscription.dispose();
    await harness.host.sendRequest(
      HostMethods.didSaveTextDocument,
      {'uri': 'file:///b.dart'},
    );

    expect(saved, ['file:///a.dart']);
  });

  test('a listener can dispose itself while events are dispatched', () async {
    final harness = RpcHarness.create();
    final calls = <String>[];
    late final LumideDisposable first;
    first = harness.context.workspace.onDidSaveTextDocument((uri) {
      calls.add('first:$uri');
      first.dispose();
    });
    harness.context.workspace.onDidSaveTextDocument((uri) {
      calls.add('second:$uri');
    });

    await harness.host.sendRequest(
      HostMethods.didSaveTextDocument,
      {'uri': 'a'},
    );
    await harness.host.sendRequest(
      HostMethods.didSaveTextDocument,
      {'uri': 'b'},
    );

    expect(calls, ['first:a', 'second:a', 'second:b']);
  });
}
