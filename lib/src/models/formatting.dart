/// A whole-document formatting request sent to a plugin formatter.
class LumideFormattingRequest {
  const LumideFormattingRequest({
    required this.uri,
    required this.text,
    required this.tabSize,
    required this.insertSpaces,
    this.languageId,
  });

  factory LumideFormattingRequest.fromJson(Map<dynamic, dynamic> json) {
    return LumideFormattingRequest(
      uri: json['uri'] as String,
      text: json['text'] as String,
      tabSize: json['tabSize'] as int? ?? 2,
      insertSpaces: json['insertSpaces'] as bool? ?? true,
      languageId: json['languageId'] as String?,
    );
  }

  /// The document URI (`file:///...`).
  final String uri;

  /// The current editor text, including unsaved changes.
  final String text;

  final int tabSize;
  final bool insertSpaces;

  /// The editor's language ID, when known.
  final String? languageId;

  Map<String, Object?> toJson() => {
        'uri': uri,
        'text': text,
        'tabSize': tabSize,
        'insertSpaces': insertSpaces,
        if (languageId != null) 'languageId': languageId,
      };
}
