/// Launch provider models.
library;

/// Supported launch action types.
enum LumideLaunchKind {
  run,
  debug,
  test;

  static LumideLaunchKind fromName(String? name) {
    return switch (name) {
      'debug' => LumideLaunchKind.debug,
      'test' => LumideLaunchKind.test,
      _ => LumideLaunchKind.run,
    };
  }
}

/// Static or runtime launch provider contribution.
class LumideLaunchProvider {
  const LumideLaunchProvider({
    required this.id,
    required this.title,
    this.workspacePatterns = const [],
    this.kinds = const [LumideLaunchKind.run],
    this.icon,
    this.iconPath,
    this.priority = 0,
  });

  factory LumideLaunchProvider.fromJson(Map<dynamic, dynamic> json) {
    return LumideLaunchProvider(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      workspacePatterns:
          _stringList(json['workspacePatterns'] ?? json['workspaceContains']),
      kinds: _kindList(json['kinds']),
      icon: json['icon']?.toString(),
      iconPath: json['iconPath']?.toString(),
      priority: _intValue(json['priority']),
    );
  }

  final String id;
  final String title;
  final List<String> workspacePatterns;
  final List<LumideLaunchKind> kinds;
  final String? icon;
  final String? iconPath;
  final int priority;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      if (workspacePatterns.isNotEmpty) 'workspacePatterns': workspacePatterns,
      'kinds': kinds.map((kind) => kind.name).toList(),
      if (icon != null) 'icon': icon,
      if (iconPath != null) 'iconPath': iconPath,
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
    this.description,
    this.detail,
    this.icon,
    this.iconPath,
    this.arguments = const {},
    this.isDefault = false,
  });

  factory LumideLaunchConfiguration.fromJson(Map<dynamic, dynamic> json) {
    return LumideLaunchConfiguration(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      kind: LumideLaunchKind.fromName(json['kind']?.toString()),
      description: json['description']?.toString(),
      detail: json['detail']?.toString(),
      icon: json['icon']?.toString(),
      iconPath: json['iconPath']?.toString(),
      arguments: _objectMap(json['arguments']),
      isDefault: json['isDefault'] == true,
    );
  }

  final String id;
  final String label;
  final LumideLaunchKind kind;
  final String? description;
  final String? detail;
  final String? icon;
  final String? iconPath;
  final Map<String, Object?> arguments;
  final bool isDefault;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'label': label,
      'kind': kind.name,
      if (description != null) 'description': description,
      if (detail != null) 'detail': detail,
      if (icon != null) 'icon': icon,
      if (iconPath != null) 'iconPath': iconPath,
      'arguments': arguments,
      if (isDefault) 'isDefault': isDefault,
    };
  }
}

/// Request sent when the host asks a provider to refresh configurations.
class LumideLaunchResolveRequest {
  const LumideLaunchResolveRequest({
    required this.providerId,
    this.kind,
    this.workspaceUri,
  });

  factory LumideLaunchResolveRequest.fromJson(Map<dynamic, dynamic> json) {
    return LumideLaunchResolveRequest(
      providerId: json['providerId']?.toString() ?? '',
      kind: json['kind'] == null
          ? null
          : LumideLaunchKind.fromName(json['kind']?.toString()),
      workspaceUri: json['workspaceUri']?.toString(),
    );
  }

  final String providerId;
  final LumideLaunchKind? kind;
  final String? workspaceUri;
}

/// Request sent when the host asks a provider to create or edit a config.
class LumideLaunchConfigureRequest {
  const LumideLaunchConfigureRequest({
    required this.providerId,
    this.actionId,
    this.kind,
    this.configuration,
    this.workspaceUri,
    this.position,
  });

  factory LumideLaunchConfigureRequest.fromJson(Map<dynamic, dynamic> json) {
    final rawConfiguration = json['configuration'];
    return LumideLaunchConfigureRequest(
      providerId: json['providerId']?.toString() ?? '',
      actionId: json['actionId']?.toString(),
      kind: json['kind'] == null
          ? null
          : LumideLaunchKind.fromName(json['kind']?.toString()),
      configuration: rawConfiguration is Map
          ? LumideLaunchConfiguration.fromJson(rawConfiguration)
          : null,
      workspaceUri: json['workspaceUri']?.toString(),
      position: _intMap(json['position']),
    );
  }

  final String providerId;
  final String? actionId;
  final LumideLaunchKind? kind;
  final LumideLaunchConfiguration? configuration;
  final String? workspaceUri;
  final Map<String, int>? position;
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
