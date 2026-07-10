/// Launch provider models.
library;

import 'package:lumide_api/src/models/configuration_property.dart';

/// Supported launch action types.
enum LumideLaunchKind {
  run,
  debug,
  attach,
  test;

  static LumideLaunchKind fromName(String? name) {
    return switch (name) {
      'debug' => LumideLaunchKind.debug,
      'attach' => LumideLaunchKind.attach,
      'test' => LumideLaunchKind.test,
      _ => LumideLaunchKind.run,
    };
  }
}

/// Static or runtime launch provider contribution.
class LumideLaunchImportDescriptor {
  const LumideLaunchImportDescriptor({
    required this.format,
    this.selectors = const {},
  });

  factory LumideLaunchImportDescriptor.fromJson(Map<dynamic, dynamic> json) {
    final rawSelectors = json['selectors'];
    return LumideLaunchImportDescriptor(
      format: json['format']?.toString() ?? '',
      selectors: rawSelectors is Map
          ? rawSelectors.map(
              (key, value) => MapEntry(key.toString(), _stringList(value)),
            )
          : const {},
    );
  }

  final String format;
  final Map<String, List<String>> selectors;

  bool matches(String sourceFormat, Map<String, Object?> raw) {
    if (format != sourceFormat) return false;
    return selectors.entries.every((entry) {
      final value = raw[entry.key]?.toString();
      return value != null && entry.value.contains(value);
    });
  }

  Map<String, Object?> toJson() {
    return {
      'format': format,
      if (selectors.isNotEmpty) 'selectors': selectors,
    };
  }
}

class LumideLaunchProvider {
  const LumideLaunchProvider({
    required this.id,
    required this.title,
    this.workspacePatterns = const [],
    this.kinds = const [LumideLaunchKind.run],
    this.defaultKinds = const [LumideLaunchKind.run],
    this.icon,
    this.iconPath,
    this.configurationSchema,
    this.configurationSnippets = const [],
    this.configurationImports = const [],
    this.priority = 0,
  });

  factory LumideLaunchProvider.fromJson(Map<dynamic, dynamic> json) {
    return LumideLaunchProvider(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      workspacePatterns:
          _stringList(json['workspacePatterns'] ?? json['workspaceContains']),
      kinds: _kindList(json['kinds']),
      defaultKinds: json.containsKey('defaultKinds')
          ? _kindList(json['defaultKinds'])
          : const [LumideLaunchKind.run],
      icon: json['icon']?.toString(),
      iconPath: json['iconPath']?.toString(),
      configurationSchema: json['configurationSchema']?.toString(),
      configurationSnippets: _objectMapList(json['configurationSnippets']),
      configurationImports: _launchImportDescriptors(
        json['configurationImports'],
      ),
      priority: _intValue(json['priority']),
    );
  }

  final String id;
  final String title;
  final List<String> workspacePatterns;
  final List<LumideLaunchKind> kinds;
  final List<LumideLaunchKind> defaultKinds;
  final String? icon;
  final String? iconPath;
  final String? configurationSchema;
  final List<Map<String, Object?>> configurationSnippets;
  final List<LumideLaunchImportDescriptor> configurationImports;
  final int priority;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      if (workspacePatterns.isNotEmpty) 'workspacePatterns': workspacePatterns,
      'kinds': kinds.map((kind) => kind.name).toList(),
      'defaultKinds': defaultKinds.map((kind) => kind.name).toList(),
      if (icon != null) 'icon': icon,
      if (iconPath != null) 'iconPath': iconPath,
      if (configurationSchema != null)
        'configurationSchema': configurationSchema,
      if (configurationSnippets.isNotEmpty)
        'configurationSnippets': configurationSnippets,
      if (configurationImports.isNotEmpty)
        'configurationImports': configurationImports
            .map((descriptor) => descriptor.toJson())
            .toList(),
      'priority': priority,
    };
  }
}

/// A concrete launch target exposed by a provider.
class LumideLaunchConfiguration {
  const LumideLaunchConfiguration({
    required this.id,
    required this.label,
    this.kind = LumideLaunchKind.run,
    this.kinds = const [],
    this.description,
    this.detail,
    this.deduplicationKey,
    this.icon,
    this.iconPath,
    this.noTint = false,
    this.isAction = false,
    this.options = const [],
    this.arguments = const {},
    this.isDefault = false,
  });

  factory LumideLaunchConfiguration.fromJson(Map<dynamic, dynamic> json) {
    return LumideLaunchConfiguration(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      kind: LumideLaunchKind.fromName(json['kind']?.toString()),
      kinds: json.containsKey('kinds') ? _kindList(json['kinds']) : const [],
      description: json['description']?.toString(),
      detail: json['detail']?.toString(),
      deduplicationKey: json['deduplicationKey']?.toString(),
      icon: json['icon']?.toString(),
      iconPath: json['iconPath']?.toString(),
      noTint: json['noTint'] == true,
      isAction: json['isAction'] == true,
      options: _optionList(json['options'] ?? json['actions']),
      arguments: _objectMap(json['arguments']),
      isDefault: json['isDefault'] == true,
    );
  }

  final String id;
  final String label;
  final LumideLaunchKind kind;
  final List<LumideLaunchKind> kinds;
  List<LumideLaunchKind> get supportedKinds => switch (kinds.isEmpty) {
        true => [kind],
        false => kinds,
      };
  final String? description;
  final String? detail;
  final String? deduplicationKey;
  final String? icon;
  final String? iconPath;

  /// When true, the icon is rendered without any theme color tint.
  final bool noTint;

  /// When true, this represents a utility command rather than an executable target.
  final bool isAction;
  final List<LumideLaunchOption> options;
  final Map<String, Object?> arguments;
  final bool isDefault;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'label': label,
      'kind': kind.name,
      if (kinds.isNotEmpty) 'kinds': kinds.map((kind) => kind.name).toList(),
      if (description != null) 'description': description,
      if (detail != null) 'detail': detail,
      if (deduplicationKey != null) 'deduplicationKey': deduplicationKey,
      if (icon != null) 'icon': icon,
      if (iconPath != null) 'iconPath': iconPath,
      if (noTint) 'noTint': noTint,
      if (isAction) 'isAction': isAction,
      if (options.isNotEmpty)
        'options': options.map((option) => option.toJson()).toList(),
      'arguments': arguments,
      if (isDefault) 'isDefault': isDefault,
    };
  }
}

/// Persisted, provider-owned launch configuration supplied by the host.
class LumideLaunchSourceConfiguration {
  const LumideLaunchSourceConfiguration({
    required this.id,
    required this.name,
    required this.providerId,
    this.kinds = const [],
    this.config = const {},
  });

  factory LumideLaunchSourceConfiguration.fromJson(Map<dynamic, dynamic> json) {
    return LumideLaunchSourceConfiguration(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      kinds: _kindList(json['kinds']),
      config: _objectMap(json['config']),
    );
  }

  final String id;
  final String name;
  final String providerId;
  final List<LumideLaunchKind> kinds;
  final Map<String, Object?> config;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'providerId': providerId,
      'kinds': kinds.map((kind) => kind.name).toList(),
      'config': config,
    };
  }
}

enum LumideLaunchDiagnosticSeverity { warning, error }

class LumideLaunchConfigurationDiagnostic {
  const LumideLaunchConfigurationDiagnostic({
    required this.severity,
    required this.message,
    this.path,
  });

  factory LumideLaunchConfigurationDiagnostic.fromJson(
    Map<dynamic, dynamic> json,
  ) {
    return LumideLaunchConfigurationDiagnostic(
      severity: switch (json['severity']?.toString()) {
        'warning' => LumideLaunchDiagnosticSeverity.warning,
        _ => LumideLaunchDiagnosticSeverity.error,
      },
      message: json['message']?.toString() ?? '',
      path: json['path']?.toString(),
    );
  }

  final LumideLaunchDiagnosticSeverity severity;
  final String message;
  final String? path;

  Map<String, Object?> toJson() {
    return {
      'severity': severity.name,
      'message': message,
      if (path != null) 'path': path,
    };
  }
}

class LumideLaunchResolution {
  const LumideLaunchResolution({
    this.configuration,
    this.diagnostics = const [],
  });

  factory LumideLaunchResolution.fromJson(Map<dynamic, dynamic> json) {
    final rawConfiguration = json['configuration'];
    final rawDiagnostics = json['diagnostics'];
    return LumideLaunchResolution(
      configuration: rawConfiguration is Map
          ? LumideLaunchConfiguration.fromJson(rawConfiguration)
          : null,
      diagnostics: rawDiagnostics is List
          ? rawDiagnostics
              .whereType<Map>()
              .map(LumideLaunchConfigurationDiagnostic.fromJson)
              .toList()
          : const [],
    );
  }

  final LumideLaunchConfiguration? configuration;
  final List<LumideLaunchConfigurationDiagnostic> diagnostics;

  Map<String, Object?> toJson() {
    return {
      if (configuration case final configuration?)
        'configuration': configuration.toJson(),
      'diagnostics': diagnostics.map((item) => item.toJson()).toList(),
    };
  }
}

enum LumideLaunchImportFidelity { exact, partial, unsupported }

class LumideForeignLaunchConfiguration {
  const LumideForeignLaunchConfiguration({
    required this.format,
    required this.name,
    required this.raw,
  });

  factory LumideForeignLaunchConfiguration.fromJson(
    Map<dynamic, dynamic> json,
  ) {
    return LumideForeignLaunchConfiguration(
      format: json['format']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      raw: _objectMap(json['raw']),
    );
  }

  final String format;
  final String name;
  final Map<String, Object?> raw;

  Map<String, Object?> toJson() {
    return {
      'format': format,
      'name': name,
      'raw': raw,
    };
  }
}

class LumideLaunchImportResult {
  const LumideLaunchImportResult({
    required this.fidelity,
    this.configuration,
    this.diagnostics = const [],
  });

  factory LumideLaunchImportResult.fromJson(Map<dynamic, dynamic> json) {
    final rawConfiguration = json['configuration'];
    final rawDiagnostics = json['diagnostics'];
    return LumideLaunchImportResult(
      fidelity: switch (json['fidelity']?.toString()) {
        'exact' => LumideLaunchImportFidelity.exact,
        'partial' => LumideLaunchImportFidelity.partial,
        _ => LumideLaunchImportFidelity.unsupported,
      },
      configuration: rawConfiguration is Map
          ? LumideLaunchSourceConfiguration.fromJson(rawConfiguration)
          : null,
      diagnostics: rawDiagnostics is List
          ? rawDiagnostics
              .whereType<Map>()
              .map(LumideLaunchConfigurationDiagnostic.fromJson)
              .toList()
          : const [],
    );
  }

  final LumideLaunchImportFidelity fidelity;
  final LumideLaunchSourceConfiguration? configuration;
  final List<LumideLaunchConfigurationDiagnostic> diagnostics;

  Map<String, Object?> toJson() {
    return {
      'fidelity': fidelity.name,
      if (configuration case final configuration?)
        'configuration': configuration.toJson(),
      'diagnostics': diagnostics.map((item) => item.toJson()).toList(),
    };
  }
}

/// A selectable value for a launch option.
class LumideLaunchOptionChoice {
  const LumideLaunchOptionChoice({
    required this.value,
    required this.label,
    this.description,
    this.detail,
    this.icon,
    this.iconPath,
    this.enabled = true,
  });

  factory LumideLaunchOptionChoice.fromJson(Map<dynamic, dynamic> json) {
    final rawValue = json['value'];
    final label = json['label']?.toString() ?? rawValue?.toString() ?? '';
    return LumideLaunchOptionChoice(
      value: rawValue ?? label,
      label: label,
      description: json['description']?.toString(),
      detail: json['detail']?.toString(),
      icon: json['icon']?.toString(),
      iconPath: json['iconPath']?.toString(),
      enabled: json['enabled'] != false,
    );
  }

  final Object? value;
  final String label;
  final String? description;
  final String? detail;
  final String? icon;
  final String? iconPath;
  final bool enabled;

  Map<String, Object?> toJson() {
    return {
      'value': value,
      'label': label,
      if (description != null) 'description': description,
      if (detail != null) 'detail': detail,
      if (icon != null) 'icon': icon,
      if (iconPath != null) 'iconPath': iconPath,
      if (!enabled) 'enabled': enabled,
    };
  }
}

/// A type-safe value for a launch option, containing its concrete type representation.
sealed class LumideLaunchValue<T> {
  const LumideLaunchValue(this.value);

  /// The concrete type-safe value.
  final T? value;

  /// The category type for the IDE UI rendering.
  ConfigPropertyType get type;

  /// The untyped value for serialization.
  Object? get raw => value;
}

/// A string-typed launch value.
class StringLaunchValue extends LumideLaunchValue<String> {
  const StringLaunchValue(super.value);

  @override
  ConfigPropertyType get type => ConfigPropertyType.string;
}

/// A string-typed launch value representing a file path.
class FilePathLaunchValue extends LumideLaunchValue<String> {
  const FilePathLaunchValue(super.value);

  @override
  ConfigPropertyType get type => ConfigPropertyType.filePath;
}

/// A string-typed launch value representing a folder path.
class FolderPathLaunchValue extends LumideLaunchValue<String> {
  const FolderPathLaunchValue(super.value);

  @override
  ConfigPropertyType get type => ConfigPropertyType.folderPath;
}

/// A boolean-typed launch value.
class BoolLaunchValue extends LumideLaunchValue<bool> {
  const BoolLaunchValue(super.value);

  @override
  ConfigPropertyType get type => ConfigPropertyType.boolean;
}

/// An integer-typed launch value.
class IntLaunchValue extends LumideLaunchValue<int> {
  const IntLaunchValue(super.value);

  @override
  ConfigPropertyType get type => ConfigPropertyType.integer;
}

/// A double-typed launch value.
class DoubleLaunchValue extends LumideLaunchValue<double> {
  const DoubleLaunchValue(super.value);

  @override
  ConfigPropertyType get type => ConfigPropertyType.number;
}

/// A schema-driven launch option associated with a launch configuration.
class LumideLaunchOption {
  const LumideLaunchOption({
    required this.id,
    required this.label,
    required this.value,
    this.description,
    this.detail,
    this.placeholder,
    this.icon,
    this.iconPath,
    this.enabled = true,
    this.choices,
  });

  factory LumideLaunchOption.fromJson(Map<dynamic, dynamic> json) {
    final type = _configurationType(json['type']);
    final rawValue = json['value'];
    final LumideLaunchValue launchValue = (switch (type) {
      ConfigPropertyType.string => StringLaunchValue(rawValue?.toString()),
      ConfigPropertyType.filePath => FilePathLaunchValue(rawValue?.toString()),
      ConfigPropertyType.folderPath =>
        FolderPathLaunchValue(rawValue?.toString()),
      ConfigPropertyType.boolean => BoolLaunchValue(
          rawValue is bool
              ? rawValue
              : (rawValue == null
                  ? null
                  : rawValue.toString().toLowerCase() == 'true'),
        ),
      ConfigPropertyType.integer => IntLaunchValue(_nullableIntValue(rawValue)),
      ConfigPropertyType.number => DoubleLaunchValue(
          rawValue is num
              ? rawValue.toDouble()
              : (rawValue == null
                  ? null
                  : double.tryParse(rawValue.toString())),
        ),
    }) as LumideLaunchValue;

    return LumideLaunchOption(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      value: launchValue,
      description: json['description']?.toString(),
      detail: json['detail']?.toString(),
      placeholder: json['placeholder']?.toString(),
      icon: json['icon']?.toString(),
      iconPath: json['iconPath']?.toString(),
      enabled: json['enabled'] != false,
      choices: _choiceList(json['choices']),
    );
  }

  final String id;
  final String label;
  final LumideLaunchValue value;
  final String? description;
  final String? detail;
  final String? placeholder;
  final String? icon;
  final String? iconPath;
  final bool enabled;
  final List<LumideLaunchOptionChoice>? choices;

  ConfigPropertyType get type => value.type;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      if (value.raw != null) 'value': value.raw,
      if (description != null) 'description': description,
      if (detail != null) 'detail': detail,
      if (placeholder != null) 'placeholder': placeholder,
      if (icon != null) 'icon': icon,
      if (iconPath != null) 'iconPath': iconPath,
      if (!enabled) 'enabled': enabled,
      if (choices case final choices?)
        'choices': choices.map((choice) => choice.toJson()).toList(),
    };
  }
}

/// Request sent when the host asks a provider to refresh configurations.
class LumideLaunchResolveRequest {
  const LumideLaunchResolveRequest({
    required this.providerId,
    this.kind,
    this.workspacePath,
  });

  factory LumideLaunchResolveRequest.fromJson(Map<dynamic, dynamic> json) {
    return LumideLaunchResolveRequest(
      providerId: json['providerId']?.toString() ?? '',
      kind: json['kind'] == null
          ? null
          : LumideLaunchKind.fromName(json['kind']?.toString()),
      workspacePath:
          (json['workspacePath'] ?? json['workspaceUri'])?.toString(),
    );
  }

  final String providerId;
  final LumideLaunchKind? kind;

  /// Canonical native filesystem path of the current workspace.
  final String? workspacePath;

  @Deprecated('Use workspacePath instead')
  String? get workspaceUri => workspacePath;
}

/// Request sent when the host asks a provider to create or edit a config.
class LumideLaunchConfigureRequest {
  const LumideLaunchConfigureRequest({
    required this.providerId,
    this.actionId,
    this.value,
    this.kind,
    this.configuration,
    this.workspacePath,
    this.position,
  });

  factory LumideLaunchConfigureRequest.fromJson(Map<dynamic, dynamic> json) {
    final rawConfiguration = json['configuration'];
    return LumideLaunchConfigureRequest(
      providerId: json['providerId']?.toString() ?? '',
      actionId: json['actionId']?.toString(),
      value: json['value'],
      kind: json['kind'] == null
          ? null
          : LumideLaunchKind.fromName(json['kind']?.toString()),
      configuration: rawConfiguration is Map
          ? LumideLaunchConfiguration.fromJson(rawConfiguration)
          : null,
      workspacePath:
          (json['workspacePath'] ?? json['workspaceUri'])?.toString(),
      position: _intMap(json['position']),
    );
  }

  final String providerId;
  final String? actionId;
  final Object? value;
  final LumideLaunchKind? kind;
  final LumideLaunchConfiguration? configuration;

  /// Canonical native filesystem path of the current workspace.
  final String? workspacePath;
  final Map<String, int>? position;

  @Deprecated('Use workspacePath instead')
  String? get workspaceUri => workspacePath;
}

/// Request sent when the host starts a launch action.
class LumideLaunchRequest {
  const LumideLaunchRequest({
    required this.providerId,
    required this.kind,
    required this.configuration,
    this.revealOutput = true,
  });

  factory LumideLaunchRequest.fromJson(Map<dynamic, dynamic> json) {
    final rawConfiguration = json['configuration'];
    return LumideLaunchRequest(
      providerId: json['providerId']?.toString() ?? '',
      kind: LumideLaunchKind.fromName(json['kind']?.toString()),
      configuration: rawConfiguration is Map
          ? LumideLaunchConfiguration.fromJson(rawConfiguration)
          : const LumideLaunchConfiguration(id: '', label: ''),
      revealOutput: json['revealOutput'] != false,
    );
  }

  final String providerId;
  final LumideLaunchKind kind;
  final LumideLaunchConfiguration configuration;
  final bool revealOutput;

  Map<String, Object?> toJson() {
    return {
      'providerId': providerId,
      'kind': kind.name,
      'configuration': configuration.toJson(),
      'revealOutput': revealOutput,
    };
  }
}

/// Runtime launch lifecycle event.
class LumideLaunchEvent {
  const LumideLaunchEvent({
    required this.providerId,
    required this.kind,
    required this.configurationId,
    this.exitCode,
    this.message,
  });

  factory LumideLaunchEvent.fromJson(Map<dynamic, dynamic> json) {
    return LumideLaunchEvent(
      providerId: json['providerId']?.toString() ?? '',
      kind: LumideLaunchKind.fromName(json['kind']?.toString()),
      configurationId: json['configurationId']?.toString() ?? '',
      exitCode: _nullableIntValue(json['exitCode']),
      message: json['message']?.toString(),
    );
  }

  final String providerId;
  final LumideLaunchKind kind;
  final String configurationId;
  final int? exitCode;
  final String? message;

  Map<String, Object?> toJson() {
    return {
      'providerId': providerId,
      'kind': kind.name,
      'configurationId': configurationId,
      if (exitCode != null) 'exitCode': exitCode,
      if (message != null) 'message': message,
    };
  }
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

List<LumideLaunchKind> _kindList(Object? value) {
  if (value is List) {
    final kinds = value
        .map((item) => LumideLaunchKind.fromName(item.toString()))
        .toList();
    return kinds.isEmpty ? const [LumideLaunchKind.run] : kinds;
  }
  return const [LumideLaunchKind.run];
}

List<LumideLaunchOption> _optionList(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map(LumideLaunchOption.fromJson)
        .where((option) => option.id.isNotEmpty && option.label.isNotEmpty)
        .toList();
  }
  return const [];
}

List<LumideLaunchOptionChoice>? _choiceList(Object? value) {
  if (value is! List) return null;

  return value.map((item) {
    if (item is Map) {
      return LumideLaunchOptionChoice.fromJson(item);
    }
    return LumideLaunchOptionChoice(
      value: item,
      label: item.toString(),
    );
  }).toList();
}

ConfigPropertyType _configurationType(Object? value) {
  return switch (value?.toString()) {
    'boolean' || 'bool' => ConfigPropertyType.boolean,
    'integer' || 'int' => ConfigPropertyType.integer,
    'number' => ConfigPropertyType.number,
    'filePath' || 'file_path' => ConfigPropertyType.filePath,
    'folderPath' ||
    'folder_path' ||
    'directory' =>
      ConfigPropertyType.folderPath,
    _ => ConfigPropertyType.string,
  };
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableIntValue(Object? value) {
  if (value == null) return null;
  return _intValue(value);
}

Map<String, Object?> _objectMap(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Map<String, Object?>> _objectMapList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(_objectMap).toList();
}

List<LumideLaunchImportDescriptor> _launchImportDescriptors(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(LumideLaunchImportDescriptor.fromJson)
      .where((descriptor) => descriptor.format.isNotEmpty)
      .toList();
}

Map<String, int>? _intMap(Object? value) {
  if (value is! Map) return null;

  final result = <String, int>{};
  for (final entry in value.entries) {
    final intValue = _nullableIntValue(entry.value);
    if (intValue != null) {
      result[entry.key.toString()] = intValue;
    }
  }
  return result.isEmpty ? null : result;
}
