/// Kind of a [LumideFileChange].
enum LumideFileChangeType { created, changed, deleted, renamed }

/// One file or folder change in the workspace.
class LumideFileChange {
  const LumideFileChange({
    required this.uri,
    required this.type,
    this.oldUri,
  });

  factory LumideFileChange.fromJson(Map<dynamic, dynamic> json) {
    final typeName = json['type'] as String?;
    return LumideFileChange(
      uri: json['uri'] as String,
      type: LumideFileChangeType.values.firstWhere(
        (type) => type.name == typeName,
        orElse: () => LumideFileChangeType.changed,
      ),
      oldUri: json['oldUri'] as String?,
    );
  }

  /// The `file:` URI of the file or folder (the new location for renames).
  final String uri;
  final LumideFileChangeType type;

  /// The previous location, for [LumideFileChangeType.renamed].
  final String? oldUri;

  Map<String, Object?> toJson() => {
        'uri': uri,
        'type': type.name,
        if (oldUri != null) 'oldUri': oldUri,
      };
}

/// A batch of workspace file changes.
class LumideFileChangeEvent {
  const LumideFileChangeEvent({
    required this.changes,
    this.isOverflow = false,
  });

  factory LumideFileChangeEvent.fromJson(Map<dynamic, dynamic> json) {
    return LumideFileChangeEvent(
      changes: [
        for (final change in json['changes'] as List? ?? const [])
          LumideFileChange.fromJson(change as Map),
      ],
      isOverflow: json['isOverflow'] as bool? ?? false,
    );
  }

  final List<LumideFileChange> changes;

  /// True when too many files changed to list; rescan what you depend on.
  final bool isOverflow;

  Map<String, Object?> toJson() => {
        'changes': [for (final change in changes) change.toJson()],
        if (isOverflow) 'isOverflow': true,
      };
}
