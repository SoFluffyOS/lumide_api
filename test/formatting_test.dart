import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

import 'support/rpc_harness.dart';

void main() {
  test('registers a formatter and answers host requests', () async {
    final harness = RpcHarness.create();
    Map<dynamic, dynamic>? registration;
    harness.host.registerMethod(
      PluginMethods.languagesRegisterFormattingProvider,
      (params) {
        registration = params.value as Map;
        return null;
      },
    );

    await harness.context.languages.registerFormattingProvider(
      id: 'pint',
      fileExtensions: const ['.php'],
      provideFormatting: (request) async =>
          '${request.text.trim()}\n// tab ${request.tabSize}',
    );

    expect(registration, {
      'id': 'pint',
      'fileExtensions': ['.php'],
      'languageIds': <String>[],
    });

    final response = await harness.host.sendRequest(
      HostMethods.languagesProvideFormatting,
      const LumideFormattingRequest(
        uri: 'file:///a.php',
        text: '<?php  ',
        tabSize: 4,
        insertSpaces: true,
      ).toJson()
        ..['id'] = 'pint',
    );

    expect(response, {'text': '<?php\n// tab 4'});
  });

  test('returns null for unknown or unregistered formatters', () async {
    final harness = RpcHarness.create();
    harness.host
      ..registerMethod(
        PluginMethods.languagesRegisterFormattingProvider,
        (_) => null,
      )
      ..registerMethod(
        PluginMethods.languagesUnregisterFormattingProvider,
        (_) => null,
      );
    await harness.context.languages.registerFormattingProvider(
      id: 'nixfmt',
      languageIds: const ['nix'],
      provideFormatting: (request) async => 'formatted',
    );
    await harness.context.languages.unregisterFormattingProvider('nixfmt');

    final response = await harness.host.sendRequest(
      HostMethods.languagesProvideFormatting,
      {'id': 'nixfmt', 'uri': 'file:///a.nix', 'text': 'x'},
    );

    expect(response, isNull);
  });
}
