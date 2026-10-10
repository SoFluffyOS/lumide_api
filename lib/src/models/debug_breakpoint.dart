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
    this.logMessage,
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

  /// Optional expression; the backend only stops when it evaluates to true.
  final String? condition;

  /// Optional message logged instead of stopping (a logpoint). Expressions
  /// in `{braces}` are interpolated by the backend.
  final String? logMessage;

  /// Whether the breakpoint should be active.
  final bool enabled;

  /// Whether the backend successfully installed the breakpoint.
  final bool verified;

  /// Optional backend message describing the breakpoint state.
  final String? message;

  /// Copies this breakpoint. Pass an empty string to clear [condition] or
  /// [logMessage].
  LumideDebugBreakpoint copyWith({
    String? id,
    String? condition,
    String? logMessage,
    bool? enabled,
    bool? verified,
    String? message,
  }) {
    return LumideDebugBreakpoint(
      id: id ?? this.id,
      sourceUri: sourceUri,
      line: line,
      column: column,
      endLine: endLine,
      endColumn: endColumn,
      condition: _cleared(condition, this.condition),
      logMessage: _cleared(logMessage, this.logMessage),
      enabled: enabled ?? this.enabled,
      verified: verified ?? this.verified,
      message: message ?? this.message,
    );
  }

  static String? _cleared(String? next, String? current) {
    if (next == null) return current;
    if (next.trim().isEmpty) return null;
    return next;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'sourceUri': sourceUri,
      'line': line,
      if (column != null) 'column': column,
      if (endLine != null) 'endLine': endLine,
      if (endColumn != null) 'endColumn': endColumn,
      if (condition != null) 'condition': condition,
      if (logMessage != null) 'logMessage': logMessage,
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
      logMessage: json['logMessage'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      verified: json['verified'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}
