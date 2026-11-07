/// Project templates a plugin offers in Lumide's New Project dialog.
library;

/// A kind of project a plugin can create, declared in `plugin.yaml` under
/// `contributes.projectTemplates`. Lumide lists it without starting the
/// plugin, draws its [fields], and starts the plugin with the
/// `onProjectTemplate:<id>` activation event when the user creates one.
class LumideProjectTemplate {
  const LumideProjectTemplate({
    required this.id,
    required this.name,
    this.description = '',
    this.group,
    this.nameHint,
    this.namePattern,
    this.nameRule,
    this.fields = const [],
  });

  /// Reads a template from its manifest entry; null without an `id` and a
  /// `name`.
  static LumideProjectTemplate? fromMap(Map<dynamic, dynamic> map) {
    final id = map['id']?.toString();
    final name = map['name']?.toString();
    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      return null;
    }

    return LumideProjectTemplate(
      id: id,
      name: name,
      description: map['description']?.toString() ?? '',
      group: map['group']?.toString(),
      nameHint: map['nameHint']?.toString(),
      namePattern: map['namePattern']?.toString(),
      nameRule: map['nameRule']?.toString(),
      fields: [
        if (map['fields'] case final List<dynamic> fields)
          for (final field in fields)
            if (field case final Map<dynamic, dynamic> fieldMap)
              if (LumideProjectTemplateField.fromMap(fieldMap)
                  case final parsed?)
                parsed,
      ],
    );
  }

  /// Unique across plugins, by convention prefixed like commands, such as
  /// `flutter.app`.
  final String id;

  /// Shown in the template list, such as `App`.
  final String name;

  /// One line under the name.
  final String description;

  /// The heading the template is listed under, such as `Flutter`; the
  /// plugin's name when null.
  final String? group;

  /// An example name, shown in the empty name field, such as `my_app`.
  final String? nameHint;

  /// A regular expression the whole project name must match, such as
  /// `^[a-z][a-z0-9_]*$` for a Dart package.
  final String? namePattern;

  /// What [namePattern] asks for, shown when the name doesn't match.
  final String? nameRule;

  /// What the user fills in besides the name and folder, which Lumide asks
  /// for itself.
  final List<LumideProjectTemplateField> fields;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description.isNotEmpty) 'description': description,
        if (group != null) 'group': group,
        if (nameHint != null) 'nameHint': nameHint,
        if (namePattern != null) 'namePattern': namePattern,
        if (nameRule != null) 'nameRule': nameRule,
        if (fields.isNotEmpty)
          'fields': [for (final field in fields) field.toJson()],
      };
}

/// How a [LumideProjectTemplateField] is drawn, and the value it gives.
enum LumideProjectFieldType {
  /// A text field; a `String`.
  text,

  /// One of the options, as a dropdown; the option's `String` value.
  select,

  /// Any of the options, as toggles; a `List<String>` of their values.
  multiSelect,

  /// A switch; a `bool`.
  boolean;

  static LumideProjectFieldType? tryParse(String? value) => switch (value) {
        'text' => text,
        'select' => select,
        'multiSelect' => multiSelect,
        'boolean' => boolean,
        _ => null,
      };
}

/// One choice of a [LumideProjectFieldType.select] or
/// [LumideProjectFieldType.multiSelect] field.
class LumideProjectFieldOption {
  const LumideProjectFieldOption({required this.value, required this.label});

  /// What the plugin receives.
  final String value;

  /// What the user sees.
  final String label;

  Map<String, dynamic> toJson() => {'value': value, 'label': label};
}

/// A value a template asks for, such as a Flutter app's platforms.
class LumideProjectTemplateField {
  const LumideProjectTemplateField({
    required this.id,
    required this.type,
    required this.label,
    this.description,
    this.options = const [],
    this.defaultValue,
    this.required = false,
    this.advanced = false,
    this.remember = false,
    this.pattern,
    this.note,
  });

  /// Reads a field from its manifest entry; null without an `id`, a known
  /// `type` and a `label`, or a choice field without options.
  static LumideProjectTemplateField? fromMap(Map<dynamic, dynamic> map) {
    final id = map['id']?.toString();
    final type = LumideProjectFieldType.tryParse(map['type']?.toString());
    final label = map['label']?.toString();
    if (id == null || id.isEmpty || type == null || label == null) {
      return null;
    }

    final options = _optionsOf(map['options']);
    final isChoice = switch (type) {
      LumideProjectFieldType.select ||
      LumideProjectFieldType.multiSelect =>
        true,
      LumideProjectFieldType.text || LumideProjectFieldType.boolean => false,
    };
    if (isChoice && options.isEmpty) {
      return null;
    }

    return LumideProjectTemplateField(
      id: id,
      type: type,
      label: label,
      description: map['description']?.toString(),
      options: options,
      defaultValue: _plain(map['default']),
      required: map['required'] == true,
      advanced: map['advanced'] == true,
      remember: map['remember'] == true,
      pattern: map['pattern']?.toString(),
      note: map['note']?.toString(),
    );
  }

  /// The key of the value in [LumideProjectCreateRequest.values].
  final String id;

  final LumideProjectFieldType type;

  /// Shown beside the control.
  final String label;

  /// One line under the label.
  final String? description;

  /// The choices of a select or multi-select field.
  final List<LumideProjectFieldOption> options;

  /// The value before the user changes it: a `String`, a `List<String>`
  /// or a `bool`, by [type].
  final Object? defaultValue;

  /// Whether creating needs a value: text that isn't empty, or at least one
  /// choice.
  final bool required;

  /// Whether the field is folded under More, for values most people keep.
  final bool advanced;

  /// Whether the user's last value becomes the default next time, such as
  /// an organization.
  final bool remember;

  /// A regular expression a text value must match, when it isn't empty.
  final String? pattern;

  /// A caution shown under the field, such as that a value can't change
  /// after release.
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'label': label,
        if (description != null) 'description': description,
        if (options.isNotEmpty)
          'options': [for (final option in options) option.toJson()],
        if (defaultValue != null) 'default': defaultValue,
        if (required) 'required': true,
        if (advanced) 'advanced': true,
        if (remember) 'remember': true,
        if (pattern != null) 'pattern': pattern,
        if (note != null) 'note': note,
      };

  /// Options as `{value, label}` maps, or as bare values labeled by
  /// themselves.
  static List<LumideProjectFieldOption> _optionsOf(Object? options) => [
        if (options case final List<dynamic> list)
          for (final option in list)
            if (_optionOf(option) case final parsed?) parsed,
      ];

  static LumideProjectFieldOption? _optionOf(Object? option) {
    if (option case final Map<dynamic, dynamic> map) {
      final value = map['value']?.toString();
      if (value == null) {
        return null;
      }

      return LumideProjectFieldOption(
        value: value,
        label: map['label']?.toString() ?? value,
      );
    }

    if (option == null) {
      return null;
    }

    return LumideProjectFieldOption(
      value: option.toString(),
      label: option.toString(),
    );
  }

  /// [value] as plain Dart values, not YAML nodes.
  static Object? _plain(Object? value) => switch (value) {
        final List<dynamic> list => [for (final item in list) item.toString()],
        final bool flag => flag,
        null => null,
        _ => value.toString(),
      };
}

/// What Lumide asks a plugin to create, once the user presses Create.
class LumideProjectCreateRequest {
  const LumideProjectCreateRequest({
    required this.templateId,
    required this.name,
    required this.parent,
    required this.path,
    this.values = const {},
  });

  factory LumideProjectCreateRequest.fromJson(Map<dynamic, dynamic> json) =>
      LumideProjectCreateRequest(
        templateId: json['templateId'].toString(),
        name: json['name'].toString(),
        parent: json['parent'].toString(),
        path: json['path'].toString(),
        values: switch (json['values']) {
          final Map<dynamic, dynamic> values => {
              for (final MapEntry(:key, :value) in values.entries)
                key.toString(): value,
            },
          _ => const {},
        },
      );

  /// The template's id.
  final String templateId;

  /// The project's name, as the user typed it and the template's
  /// `namePattern` allows.
  final String name;

  /// The folder the project goes in. The plugin may write here, and in
  /// [path], while it creates the project, without a file system
  /// permission for it.
  final String parent;

  /// The project's own folder: [name] in [parent]. It doesn't exist yet.
  final String path;

  /// Each field's value by its id: a `String`, a `List<String>` or a
  /// `bool`.
  final Map<String, Object?> values;

  /// The text value of field [id]; empty when unset.
  String text(String id) => values[id]?.toString() ?? '';

  /// The values chosen in multi-select field [id].
  List<String> choices(String id) => switch (values[id]) {
        final List<dynamic> list => [for (final item in list) item.toString()],
        _ => const [],
      };

  /// Whether boolean field [id] is on.
  bool flag(String id) => values[id] == true;

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'name': name,
        'parent': parent,
        'path': path,
        'values': values,
      };
}

/// What a plugin created.
class LumideProjectCreation {
  const LumideProjectCreation({this.path, this.openFiles = const []});

  factory LumideProjectCreation.fromJson(Map<dynamic, dynamic> json) =>
      LumideProjectCreation(
        path: json['path']?.toString(),
        openFiles: [
          if (json['openFiles'] case final List<dynamic> files)
            for (final file in files) file.toString(),
        ],
      );

  /// The folder to open; the request's `path` when null.
  final String? path;

  /// Files to open once the folder is, relative to it, such as
  /// `lib/main.dart`.
  final List<String> openFiles;

  Map<String, dynamic> toJson() => {
        if (path != null) 'path': path,
        if (openFiles.isNotEmpty) 'openFiles': openFiles,
      };
}
