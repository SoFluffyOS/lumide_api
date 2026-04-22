/// A stack frame provided by the active debug session.
class LumideDebugStackFrame {
  const LumideDebugStackFrame({
    required this.id,
    required this.name,
    required this.sourceUri,
    required this.line,
    required this.column,
    this.sourceName,
    this.endLine,
    this.endColumn,
  });

  final int id;
  final String name;
  final String sourceUri;
  final String? sourceName;
  final int line;
  final int column;
  final int? endLine;
  final int? endColumn;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sourceUri': sourceUri,
      if (sourceName != null) 'sourceName': sourceName,
      'line': line,
      'column': column,
      if (endLine != null) 'endLine': endLine,
      if (endColumn != null) 'endColumn': endColumn,
    };
  }

  factory LumideDebugStackFrame.fromJson(Map json) {
    return LumideDebugStackFrame(
      id: json['id'] as int,
      name: json['name'] as String,
      sourceUri: json['sourceUri'] as String,
      sourceName: json['sourceName'] as String?,
      line: json['line'] as int,
      column: json['column'] as int? ?? 1,
      endLine: json['endLine'] as int?,
      endColumn: json['endColumn'] as int?,
    );
  }
}
