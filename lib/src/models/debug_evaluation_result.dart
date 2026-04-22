/// Result of evaluating an expression in the current debug context.
class LumideDebugEvaluationResult {
  const LumideDebugEvaluationResult({
    required this.result,
    this.type,
    this.variablesReference,
  });

  final String result;
  final String? type;
  final int? variablesReference;

  Map<String, dynamic> toJson() {
    return {
      'result': result,
      if (type != null) 'type': type,
      if (variablesReference != null) 'variablesReference': variablesReference,
    };
  }

  factory LumideDebugEvaluationResult.fromJson(Map json) {
    return LumideDebugEvaluationResult(
      result: json['result'] as String,
      type: json['type'] as String?,
      variablesReference: json['variablesReference'] as int?,
    );
  }
}
