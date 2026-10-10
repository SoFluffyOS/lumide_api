/// State of a test in a [LumideTestResult].
enum LumideTestState { queued, running, passed, failed, skipped, errored }

/// One test or group in a test run. Groups are results that other results
/// point to with [parentId].
class LumideTestResult {
  const LumideTestResult({
    required this.id,
    required this.label,
    required this.state,
    this.parentId,
    this.uri,
    this.line,
    this.message,
    this.durationMs,
  });

  factory LumideTestResult.fromJson(Map<dynamic, dynamic> json) {
    final stateName = json['state'] as String?;
    return LumideTestResult(
      id: json['id'] as String,
      label: json['label'] as String,
      state: LumideTestState.values.firstWhere(
        (state) => state.name == stateName,
        orElse: () => LumideTestState.queued,
      ),
      parentId: json['parentId'] as String?,
      uri: json['uri'] as String?,
      line: json['line'] as int?,
      message: json['message'] as String?,
      durationMs: json['durationMs'] as int?,
    );
  }

  /// Stable within a run; sending the same id again updates the result.
  final String id;
  final String label;
  final LumideTestState state;

  /// The group this result belongs to.
  final String? parentId;

  /// `file:` URI of the test source, for navigation.
  final String? uri;

  /// 1-based line of the test in [uri].
  final int? line;

  /// Failure or error details.
  final String? message;
  final int? durationMs;

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'state': state.name,
        if (parentId != null) 'parentId': parentId,
        if (uri != null) 'uri': uri,
        if (line != null) 'line': line,
        if (message != null) 'message': message,
        if (durationMs != null) 'durationMs': durationMs,
      };
}
