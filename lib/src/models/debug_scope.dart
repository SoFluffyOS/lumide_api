/// A variable scope for a stack frame.
class LumideDebugScope {
  const LumideDebugScope({
    required this.id,
    required this.name,
    this.presentationHint,
    this.namedVariables,
    this.indexedVariables,
  });

  final int id;
  final String name;
  final String? presentationHint;
  final int? namedVariables;
  final int? indexedVariables;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (presentationHint != null) 'presentationHint': presentationHint,
      if (namedVariables != null) 'namedVariables': namedVariables,
      if (indexedVariables != null) 'indexedVariables': indexedVariables,
    };
  }

  factory LumideDebugScope.fromJson(Map json) {
    return LumideDebugScope(
      id: json['id'] as int,
      name: json['name'] as String,
      presentationHint: json['presentationHint'] as String?,
      namedVariables: json['namedVariables'] as int?,
      indexedVariables: json['indexedVariables'] as int?,
    );
  }
}
