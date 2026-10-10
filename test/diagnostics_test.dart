import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

import 'support/rpc_harness.dart';

void main() {
  test('diagnostic JSON round trips with defaults', () {
    const diagnostic = LumideDiagnostic(
      message: 'Unused variable',
      startLine: 3,
      startColumn: 4,
      severity: LumideDiagnosticSeverity.warning,
      source: 'phpstan',
    );

    final decoded = LumideDiagnostic.fromJson(diagnostic.toJson());

    expect(decoded.endLine, 3);
    expect(decoded.endColumn, 4);
    expect(decoded.severity, LumideDiagnosticSeverity.warning);
    expect(decoded.source, 'phpstan');
    expect(
      LumideDiagnostic.fromJson({'message': 'x', 'startLine': 0}).severity,
      LumideDiagnosticSeverity.error,
    );
  });

  test('set and clear forward to the host', () async {
    final harness = RpcHarness.create();
    final calls = <(String, Map<dynamic, dynamic>)>[];
    for (final method in [
      PluginMethods.languagesSetDiagnostics,
      PluginMethods.languagesClearDiagnostics,
    ]) {
      harness.host.registerMethod(method, (params) {
        calls.add((method, params.value as Map));
        return null;
      });
    }

    await harness.context.languages.setDiagnostics('lint', 'file:///a.php', [
      const LumideDiagnostic(message: 'Bad', startLine: 1),
    ]);
    await harness.context.languages.clearDiagnostics('lint');

    expect(calls.first.$2['collection'], 'lint');
    expect((calls.first.$2['diagnostics'] as List).single['message'], 'Bad');
    expect(calls.last.$1, PluginMethods.languagesClearDiagnostics);
    expect(calls.last.$2.containsKey('uri'), isFalse);
  });
}
