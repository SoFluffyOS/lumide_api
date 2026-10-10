import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

import 'support/rpc_harness.dart';

void main() {
  test('executeCommand forwards the id and args', () async {
    final harness = RpcHarness.create();
    Map<dynamic, dynamic>? request;
    harness.host.registerMethod(PluginMethods.commandsExecuteCommand, (params) {
      request = params.value as Map;
      return request?['id'] == 'flutter.hotReload';
    });

    expect(
      await harness.context.commands.executeCommand('flutter.hotReload', {
        'reason': 'save',
      }),
      isTrue,
    );
    expect(request?['args'], {'reason': 'save'});
    expect(await harness.context.commands.executeCommand('missing'), isFalse);
  });
}
