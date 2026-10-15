/// One folder of the workspace. A workspace can hold several folders; the
/// first is the one Lumide was opened with.
class LumideWorkspaceFolder {
  const LumideWorkspaceFolder({required this.uri, required this.name});

  factory LumideWorkspaceFolder.fromJson(Map<dynamic, dynamic> json) {
    return LumideWorkspaceFolder(
      uri: json['uri'] as String,
      name: json['name'] as String? ?? '',
    );
  }

  /// The folder's `file:` URI.
  final String uri;

  /// The folder's name as Lumide shows it, told apart from folders of the
  /// same name.
  final String name;

  Map<String, Object?> toJson() => {'uri': uri, 'name': name};
}

/// Folders added to or removed from the workspace.
class LumideWorkspaceFoldersChangeEvent {
  const LumideWorkspaceFoldersChangeEvent({
    this.added = const [],
    this.removed = const [],
  });

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
    );
  }

  final List<LumideWorkspaceFolder> added;
  final List<LumideWorkspaceFolder> removed;

  Map<String, Object?> toJson() => {
        'added': [for (final folder in added) folder.toJson()],
        'removed': [for (final folder in removed) folder.toJson()],
      };
}
