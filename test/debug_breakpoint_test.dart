import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

void main() {
  test('logMessage round trips and copyWith clears with empty strings', () {
    const breakpoint = LumideDebugBreakpoint(
      sourceUri: 'file:///lib/main.dart',
      line: 12,
      condition: 'count > 3',
      logMessage: 'count = {count}',
    );

    final decoded = LumideDebugBreakpoint.fromJson(breakpoint.toJson());
    expect(decoded.logMessage, 'count = {count}');

    final cleared = decoded.copyWith(condition: '', enabled: false);
    expect(cleared.condition, isNull);
    expect(cleared.logMessage, 'count = {count}');
    expect(cleared.enabled, isFalse);
    expect(cleared.line, 12);
  });
}
