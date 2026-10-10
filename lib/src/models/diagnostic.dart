/// Severity of a [LumideDiagnostic].
enum LumideDiagnosticSeverity { error, warning, information, hint }

/// A problem reported by a plugin, shown in the editor and Problems panel.
///
/// Lines and columns are zero-based; the end is exclusive.
class LumideDiagnostic {
  const LumideDiagnostic({
    required this.message,
    required this.startLine,
    this.startColumn = 0,
    int? endLine,
    int? endColumn,
    this.severity = LumideDiagnosticSeverity.error,
    this.source,
    this.code,
  })  : endLine = endLine ?? startLine,
        endColumn = endColumn ?? startColumn;

  factory LumideDiagnostic.fromJson(Map<dynamic, dynamic> json) {
    final severityName = json['severity'] as String?;
    return LumideDiagnostic(
      message: json['message'] as String,
      startLine: json['startLine'] as int,
      startColumn: json['startColumn'] as int? ?? 0,
      endLine: json['endLine'] as int?,
      endColumn: json['endColumn'] as int?,
      severity: LumideDiagnosticSeverity.values.firstWhere(
        (severity) => severity.name == severityName,
        orElse: () => LumideDiagnosticSeverity.error,
      ),
      source: json['source'] as String?,
      code: json['code'] as String?,
    );
  }

  final String message;
  final int startLine;
  final int startColumn;
  final int endLine;
  final int endColumn;
  final LumideDiagnosticSeverity severity;

  /// The tool that produced it, e.g. `phpstan`.
  final String? source;

  /// A rule or error code, e.g. `unused-variable`.
  final String? code;

  Map<String, Object?> toJson() => {
        'message': message,
        'startLine': startLine,
        'startColumn': startColumn,
        'endLine': endLine,
        'endColumn': endColumn,
        'severity': severity.name,
        if (source != null) 'source': source,
        if (code != null) 'code': code,
      };
}
