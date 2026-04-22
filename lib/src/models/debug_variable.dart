/// A variable value exposed by a debug scope.
class LumideDebugVariable {
  const LumideDebugVariable({
    required this.name,
    required this.value,
    this.type,
    this.evaluateName,
    this.variablesReference,
    this.presentationHint,
  });

  final String name;
  final String value;
  final String? type;
  final String? evaluateName;

  /// Non-zero when the variable has child variables that can be requested.
  final int? variablesReference;

  final String? presentationHint;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      if (type != null) 'type': type,
      if (evaluateName != null) 'evaluateName': evaluateName,
      if (variablesReference != null) 'variablesReference': variablesReference,
      if (presentationHint != null) 'presentationHint': presentationHint,
    };
  }

  factory LumideDebugVariable.fromJson(Map json) {
    return LumideDebugVariable(
      name: json['name'] as String,
      value: json['value'] as String,
      type: json['type'] as String?,
      evaluateName: json['evaluateName'] as String?,
      variablesReference: json['variablesReference'] as int?,
      presentationHint: json['presentationHint'] as String?,
    );
  }
}
