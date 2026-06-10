/// Configuration property model for plugin settings.
library;

/// The type of a configuration property.
enum ConfigPropertyType {
  /// A string value.
  string,

  /// A boolean value.
  boolean,

  /// An integer value.
  integer,

  /// A double/number value.
  number,

  /// A file path value (triggers file picker in UI).
  filePath,

  /// A folder path value (triggers folder picker in UI).
  folderPath,
}

/// Describes a single configurable setting exposed by a plugin.
///
/// Used by both built-in and external plugins to declare their
/// configuration schema. The IDE auto-generates settings UI from these.
///
/// Example in `plugin.yaml`:
/// ```yaml
/// configuration:
///   - key: printWidth
///     type: integer
///     default: 80
///     description: Maximum line width before wrapping.
///   - key: useTabs
///     type: boolean
///     default: false
///     description: Use tabs instead of spaces.
/// ```
class ConfigurationProperty {
  const ConfigurationProperty({
    required this.key,
    required this.type,
    this.title,
    required this.description,
    this.defaultValue,
    this.enumValues,
  });

  factory ConfigurationProperty.fromMap(Map<String, dynamic> map) {
    return ConfigurationProperty(
      key: map['key'] as String,
      type: _parseType(map['type'] as String?),
      title: map['title'] as String?,
      description: map['description'] as String? ?? '',
      defaultValue: map['default'],
      enumValues: switch (map['enum']) {
        final List list => list.map((e) => e.toString()).toList(),
        _ => null,
      },
    );
  }

  /// Unique key for this setting (e.g., 'printWidth').
  final String key;

  /// The data type of this setting.
  final ConfigPropertyType type;

  /// Optional human-readable title. If null, UI may use [key].
  final String? title;

  /// Human-readable description shown in the settings UI.
  final String description;

  /// Default value when no user override exists.
  final Object? defaultValue;

  /// If non-null, restricts the value to one of these options.
  ///
  /// Rendered as a dropdown in the settings UI.
  final List<String>? enumValues;

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'key': key,
        'type': type.name,
        if (title != null) 'title': title,
        'description': description,
        if (defaultValue != null) 'default': defaultValue,
        if (enumValues != null) 'enum': enumValues,
      };

  static ConfigPropertyType _parseType(String? type) => switch (type) {
        'string' => ConfigPropertyType.string,
        'bool' || 'boolean' => ConfigPropertyType.boolean,
        'int' || 'integer' => ConfigPropertyType.integer,
        'number' || 'double' => ConfigPropertyType.number,
        'filePath' || 'file_path' => ConfigPropertyType.filePath,
        'folderPath' ||
        'folder_path' ||
        'directory' =>
          ConfigPropertyType.folderPath,
        _ => ConfigPropertyType.string,
      };
}
