/// One folder of the workspace. A workspace can hold several folders; the
/// first is the one Lumide was opened with.
class LumideWorkspaceFolder {
  const LumideWorkspaceFolder({
    required this.uri,
    required this.name,
    this.label,
  });

  factory LumideWorkspaceFolder.fromJson(Map<dynamic, dynamic> json) {
    final uri = json['uri'] as String;
    return LumideWorkspaceFolder(
      uri: uri,
      name: json['name'] as String? ?? _basename(uri),
      label: json['label'] as String?,
    );
  }

  /// A folder for [uri], named after its last path segment.
  factory LumideWorkspaceFolder.fromUri(String uri) =>
      LumideWorkspaceFolder(uri: uri, name: _basename(uri));

  /// The folder's `file:` URI.
  final String uri;

  /// The folder's name: the last segment of its path. Stable while the
  /// folder is open; two folders can share it.
  final String name;

  /// How Lumide shows the folder, such as `app (client)` when another
  /// folder is also named `app`. Can change when folders are added or
  /// removed. Null when the host does not send one.
  final String? label;

  Map<String, Object?> toJson() => {
        'uri': uri,
        'name': name,
        if (label != null) 'label': label,
      };

  @override
  bool operator ==(Object other) =>
      other is LumideWorkspaceFolder &&
      other.uri == uri &&
      other.name == name &&
      other.label == label;

  @override
  int get hashCode => Object.hash(uri, name, label);

  @override
  String toString() => 'LumideWorkspaceFolder($uri)';
}

String _basename(String uri) {
  final segments = Uri.parse(uri).pathSegments.where(
        (segment) => segment.isNotEmpty,
      );
  return segments.lastOrNull ?? uri;
}

/// Folders added to or removed from the workspace, or whose label changed.
class LumideWorkspaceFoldersChangeEvent {
  LumideWorkspaceFoldersChangeEvent({
    List<LumideWorkspaceFolder> added = const [],
    List<LumideWorkspaceFolder> removed = const [],
    List<LumideWorkspaceFolder> changed = const [],
  })  : added = List.unmodifiable(added),
        removed = List.unmodifiable(removed),
        changed = List.unmodifiable(changed);

  factory LumideWorkspaceFoldersChangeEvent.fromJson(
    Map<dynamic, dynamic> json,
  ) {
    List<LumideWorkspaceFolder> folders(Object? list) => [
          for (final folder in list as List? ?? const [])
            LumideWorkspaceFolder.fromJson(folder as Map),
        ];
    return LumideWorkspaceFoldersChangeEvent(
      added: folders(json['added']),
      removed: folders(json['removed']),
      changed: folders(json['changed']),
    );
  }

  final List<LumideWorkspaceFolder> added;
  final List<LumideWorkspaceFolder> removed;

  /// Folders still in the workspace whose [LumideWorkspaceFolder.label]
  /// changed, with their new label.
  final List<LumideWorkspaceFolder> changed;

  Map<String, Object?> toJson() => {
        'added': [for (final folder in added) folder.toJson()],
        'removed': [for (final folder in removed) folder.toJson()],
        if (changed.isNotEmpty)
          'changed': [for (final folder in changed) folder.toJson()],
      };
}
