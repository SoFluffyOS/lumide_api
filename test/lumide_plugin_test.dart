import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('graceful shutdown deactivates a plugin exactly once', () async {
    final process = await Process.start(
      Platform.resolvedExecutable,
      ['run', 'test/fixtures/deactivation_plugin.dart'],
    );
    addTearDown(() {
      process.kill();
    });

    final initializeResponse = Completer<void>();
    final shutdownResponse = Completer<void>();
    final stdoutSubscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      final response = jsonDecode(line) as Map<String, dynamic>;
      if (response['id'] == 1) initializeResponse.complete();
      if (response['id'] == 2) shutdownResponse.complete();
    });
    final stderrLines = <String>[];
    final stderrSubscription = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(stderrLines.add);

    process.stdin.writeln(
      jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'initialize'}),
    );
    await initializeResponse.future.timeout(const Duration(seconds: 5));

    process.stdin.writeln(
      jsonEncode({'jsonrpc': '2.0', 'id': 2, 'method': 'shutdown'}),
    );
    await shutdownResponse.future.timeout(const Duration(seconds: 5));
    await process.stdin.close();
    expect(
      await process.exitCode.timeout(const Duration(seconds: 5)),
      0,
    );
    await stdoutSubscription.cancel();
    await stderrSubscription.cancel();

    expect(stderrLines.where((line) => line == 'deactivation-called'),
        hasLength(1));
    expect(
      stderrLines.where((line) => line.contains('deactivation:')),
      isEmpty,
    );
  });
}
