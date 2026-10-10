import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

import 'support/rpc_harness.dart';

void main() {
  late RpcHarness harness;

  setUp(() {
    harness = RpcHarness.create();
    harness.host
      ..registerMethod(PluginMethods.languagesRegisterServer, (_) => null)
      ..registerMethod(
        PluginMethods.languagesRegisterInlineProvider,
        (_) => null,
      );
  });

  Future<void> registerServer(String id, String status) =>
      harness.context.languages.registerLanguageServer(
        id: id,
        languageId: 'dart',
        fileExtensions: const ['.dart'],
        command: 'server',
        checkStatus: () async => status,
      );

  Future<void> registerInline(String id, String completion) =>
      harness.context.languages.registerInlineCompletionProvider(
        id: id,
        displayName: id,
        onProvideCompletions: (_) async => [InlineCompletion(text: completion)],
        checkStatus: () async => '$id ready',
      );

  test('several providers answer status checks for their own id', () async {
    await registerServer('server-a', 'a ready');
    await registerInline('copilot', 'x');

    expect(
      await harness.host.sendRequest(HostMethods.aiCheckStatus, {
        'id': 'server-a',
      }),
      'a ready',
    );
    expect(
      await harness.host.sendRequest(HostMethods.aiCheckStatus, {
        'id': 'copilot',
      }),
      'copilot ready',
    );
    expect(
      await harness.host.sendRequest(HostMethods.aiCheckStatus, {
        'id': 'missing',
      }),
      isNull,
    );
  });

  test('registering a provider again replaces its handlers', () async {
    await registerServer('server-a', 'old');
    await registerServer('server-a', 'new');
    await registerInline('copilot', 'first');
    await registerInline('copilot', 'second');

    expect(
      await harness.host.sendRequest(HostMethods.aiCheckStatus, {
        'id': 'server-a',
      }),
      'new',
    );
    expect(
      await harness.host.sendRequest(HostMethods.inlineCompletionRequest, {
        'id': 'copilot',
        'uri': 'file:///a.dart',
        'line': 0,
        'column': 0,
        'documentText': '',
      }),
      [
        {'text': 'second'},
      ],
    );
  });

  test('re-registering without a handler removes it', () async {
    await registerServer('server-a', 'ready');
    await harness.context.languages.registerLanguageServer(
      id: 'server-a',
      languageId: 'dart',
      fileExtensions: const ['.dart'],
      command: 'server',
    );

    expect(
      await harness.host.sendRequest(HostMethods.aiCheckStatus, {
        'id': 'server-a',
      }),
      isNull,
    );
  });
}
