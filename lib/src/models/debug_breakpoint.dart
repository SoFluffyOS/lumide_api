/// A breakpoint tracked by the debug backend.
class LumideDebugBreakpoint {
  const LumideDebugBreakpoint({
    required this.sourceUri,
    required this.line,
    this.id,
    this.column,
    this.endLine,
    this.endColumn,
    this.condition,
    this.enabled = true,
    this.verified = false,
    this.message,
  });

  /// Optional backend-specific identifier.
  final String? id;

  /// File URI for the breakpoint source.
  final String sourceUri;

  /// 1-based line number.
  final int line;

  /// 1-based column number.
  final int? column;

  /// Optional 1-based end line number.
  final int? endLine;

  /// Optional 1-based end column number.
  final int? endColumn;

  /// Optional conditional expression.
  final String? condition;

  /// Whether the breakpoint should be active.
  final bool enabled;

  /// Whether the backend successfully installed the breakpoint.
  final bool verified;

  /// Optional backend message describing the breakpoint state.
  final String? message;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'sourceUri': sourceUri,
      'line': line,
      if (column != null) 'column': column,
      if (endLine != null) 'endLine': endLine,
      if (endColumn != null) 'endColumn': endColumn,
      if (condition != null) 'condition': condition,
      'enabled': enabled,
      'verified': verified,
      if (message != null) 'message': message,
    };
  }

  factory LumideDebugBreakpoint.fromJson(Map json) {
    return LumideDebugBreakpoint(
      id: json['id'] as String?,
      sourceUri: json['sourceUri'] as String,
      line: json['line'] as int,
      column: json['column'] as int?,
      endLine: json['endLine'] as int?,
      endColumn: json['endColumn'] as int?,
      condition: json['condition'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      verified: json['verified'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}
