/// SDK provider and toolchain models.
library;

/// An extensible SDK kind identifier.
final class LumideSdkKind {
  const LumideSdkKind(this.value);

  final String value;

  static const dart = LumideSdkKind('dart');
  static const flutter = LumideSdkKind('flutter');

  @override
  bool operator ==(Object other) =>
      other is LumideSdkKind && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Identifies an external toolchain manager without restricting plugins to a
/// host-defined list.
final class LumideSdkManagerId {
  const LumideSdkManagerId(this.value);

  final String value;

  static const fvm = LumideSdkManagerId('fvm');
  static const puro = LumideSdkManagerId('puro');

  @override
  bool operator ==(Object other) =>
      other is LumideSdkManagerId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Describes a persisted SDK selection change made by the host.
///
/// A null [workspacePath] means the user-level default changed and can affect
/// every workspace. A non-null path limits the change to that workspace.
final class LumideSdkSelectionChangeEvent {
  const LumideSdkSelectionChangeEvent({
    required this.kind,
    this.workspacePath,
  });

  factory LumideSdkSelectionChangeEvent.fromJson(Map<dynamic, dynamic> json) {
    return LumideSdkSelectionChangeEvent(
      kind: LumideSdkKind(json['kind']?.toString() ?? ''),
      workspacePath: json['workspacePath']?.toString(),
    );
  }

  final LumideSdkKind kind;
  final String? workspacePath;

  Map<String, Object?> toJson() => {
        'kind': kind.value,
        if (workspacePath != null) 'workspacePath': workspacePath,
      };
}

enum LumideSdkArchiveFormat {
  zip,
  tarGz,
  tarXz;

  static LumideSdkArchiveFormat fromName(String? name) {
    return switch (name) {
      'tarGz' => LumideSdkArchiveFormat.tarGz,
      'tarXz' => LumideSdkArchiveFormat.tarXz,
      _ => LumideSdkArchiveFormat.zip,
    };
  }
}

enum LumideSdkSource {
  lumideManaged,
  system,
  externalManager,
  externalCustom;

  static LumideSdkSource fromName(String? name) {
    return switch (name) {
      'lumideManaged' => LumideSdkSource.lumideManaged,
      'externalManager' => LumideSdkSource.externalManager,
      'externalCustom' => LumideSdkSource.externalCustom,
      _ => LumideSdkSource.system,
    };
  }
}

enum LumideSdkManagerScope {
  workspace,
  global;

  static LumideSdkManagerScope? fromName(String? name) {
    return switch (name) {
      'workspace' => LumideSdkManagerScope.workspace,
      'global' => LumideSdkManagerScope.global,
      _ => null,
    };
  }
}

enum LumideSdkPurpose {
  analyze,
  run,
  debug,
  build,
  terminal;

  static LumideSdkPurpose fromName(String? name) {
    return switch (name) {
      'analyze' => LumideSdkPurpose.analyze,
      'debug' => LumideSdkPurpose.debug,
      'build' => LumideSdkPurpose.build,
      'terminal' => LumideSdkPurpose.terminal,
      _ => LumideSdkPurpose.run,
    };
  }
}

enum LumideSdkValidationState {
  valid,
  warning,
  invalid,
  unavailable;

  static LumideSdkValidationState fromName(String? name) {
    return switch (name) {
      'valid' => LumideSdkValidationState.valid,
      'warning' => LumideSdkValidationState.warning,
      'unavailable' => LumideSdkValidationState.unavailable,
      _ => LumideSdkValidationState.invalid,
    };
  }
}

class LumideSdkProviderCapabilities {
  const LumideSdkProviderCapabilities({
    this.catalog = false,
    this.discovery = true,
    this.resolution = true,
    this.validation = true,
    this.install = false,
  });

  factory LumideSdkProviderCapabilities.fromJson(Map<dynamic, dynamic> json) {
    return LumideSdkProviderCapabilities(
      catalog: json['catalog'] == true,
      discovery: json['discovery'] != false,
      resolution: json['resolution'] != false,
      validation: json['validation'] != false,
      install: json['install'] == true,
    );
  }

  final bool catalog;
  final bool discovery;
  final bool resolution;
  final bool validation;
  final bool install;

  Map<String, Object?> toJson() => {
        'catalog': catalog,
        'discovery': discovery,
        'resolution': resolution,
        'validation': validation,
        'install': install,
      };
}

class LumideSdkProviderDescriptor {
  const LumideSdkProviderDescriptor({
    required this.id,
    required this.kind,
    required this.title,
    this.capabilities = const LumideSdkProviderCapabilities(),
    this.icon,
    this.iconPath,
  });

  factory LumideSdkProviderDescriptor.fromJson(Map<dynamic, dynamic> json) {
    final rawCapabilities = json['capabilities'];
    return LumideSdkProviderDescriptor(
      id: json['id']?.toString() ?? '',
      kind: LumideSdkKind(json['kind']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      capabilities: rawCapabilities is Map
          ? LumideSdkProviderCapabilities.fromJson(rawCapabilities)
          : const LumideSdkProviderCapabilities(),
      icon: json['icon']?.toString(),
      iconPath: json['iconPath']?.toString(),
    );
  }

  final String id;
  final LumideSdkKind kind;
  final String title;
  final LumideSdkProviderCapabilities capabilities;
  final String? icon;
  final String? iconPath;

  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind.value,
        'title': title,
        'capabilities': capabilities.toJson(),
        if (icon != null) 'icon': icon,
        if (iconPath != null) 'iconPath': iconPath,
      };
}

class LumideEmbeddedSdk {
  const LumideEmbeddedSdk({
    required this.kind,
    required this.version,
    this.rootPath,
    this.executables = const {},
  });

  factory LumideEmbeddedSdk.fromJson(Map<dynamic, dynamic> json) {
    return LumideEmbeddedSdk(
      kind: LumideSdkKind(json['kind']?.toString() ?? ''),
      version: json['version']?.toString() ?? '',
      rootPath: json['rootPath']?.toString(),
      executables: _stringMap(json['executables']),
    );
  }

  final LumideSdkKind kind;
  final String version;
  final String? rootPath;
  final Map<String, String> executables;

  Map<String, Object?> toJson() => {
        'kind': kind.value,
        'version': version,
        if (rootPath != null) 'rootPath': rootPath,
        if (executables.isNotEmpty) 'executables': executables,
      };
}

class LumideSdkRelease {
  const LumideSdkRelease({
    required this.id,
    required this.version,
    required this.channel,
    this.releaseDate,
    this.archiveUri,
    this.sha256,
    this.archiveFormat,
    this.archiveRootDirectory,
    this.platform,
    this.architecture,
    this.embeddedSdks = const [],
    this.stale = false,
  });

  factory LumideSdkRelease.fromJson(Map<dynamic, dynamic> json) {
    final archiveFormat = json['archiveFormat']?.toString();
    return LumideSdkRelease(
      id: json['id']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      channel: json['channel']?.toString() ?? '',
      releaseDate: json['releaseDate']?.toString(),
      archiveUri: json['archiveUri']?.toString(),
      sha256: json['sha256']?.toString(),
      archiveFormat: archiveFormat == null
          ? null
          : LumideSdkArchiveFormat.fromName(archiveFormat),
      archiveRootDirectory: json['archiveRootDirectory']?.toString(),
      platform: json['platform']?.toString(),
      architecture: json['architecture']?.toString(),
      stale: json['stale'] == true,
      embeddedSdks: _mapList(json['embeddedSdks'])
          .map(LumideEmbeddedSdk.fromJson)
          .toList(),
    );
  }

  final String id;
  final String version;
  final String channel;
  final String? releaseDate;
  final String? archiveUri;
  final String? sha256;
  final LumideSdkArchiveFormat? archiveFormat;
  final String? archiveRootDirectory;
  final String? platform;
  final String? architecture;
  final List<LumideEmbeddedSdk> embeddedSdks;
  final bool stale;

  LumideSdkRelease copyWith({bool? stale}) {
    return LumideSdkRelease(
      id: id,
      version: version,
      channel: channel,
      releaseDate: releaseDate,
      archiveUri: archiveUri,
      sha256: sha256,
      archiveFormat: archiveFormat,
      archiveRootDirectory: archiveRootDirectory,
      platform: platform,
      architecture: architecture,
      embeddedSdks: embeddedSdks,
      stale: stale ?? this.stale,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'version': version,
        'channel': channel,
        if (releaseDate != null) 'releaseDate': releaseDate,
        if (archiveUri != null) 'archiveUri': archiveUri,
        if (sha256 != null) 'sha256': sha256,
        if (archiveFormat != null) 'archiveFormat': archiveFormat?.name,
        if (archiveRootDirectory != null)
          'archiveRootDirectory': archiveRootDirectory,
        if (platform != null) 'platform': platform,
        if (architecture != null) 'architecture': architecture,
        if (stale) 'stale': stale,
        if (embeddedSdks.isNotEmpty)
          'embeddedSdks': embeddedSdks.map((sdk) => sdk.toJson()).toList(),
      };
}

class LumideSdkInstallation {
  const LumideSdkInstallation({
    required this.id,
    required this.providerId,
    required this.kind,
    required this.version,
    required this.rootPath,
    required this.source,
    this.channel,
    this.displayName,
    this.managerId,
    this.managerScope,
    this.executables = const {},
    this.embeddedSdks = const [],
    this.metadata = const {},
  });

  factory LumideSdkInstallation.fromJson(Map<dynamic, dynamic> json) {
    return LumideSdkInstallation(
      id: json['id']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      kind: LumideSdkKind(json['kind']?.toString() ?? ''),
      version: json['version']?.toString() ?? '',
      rootPath: json['rootPath']?.toString() ?? '',
      source: LumideSdkSource.fromName(json['source']?.toString()),
      channel: json['channel']?.toString(),
      displayName: json['displayName']?.toString(),
      managerId: switch (json['managerId']?.toString()) {
        final value? when value.isNotEmpty => LumideSdkManagerId(value),
        _ => null,
      },
      managerScope: LumideSdkManagerScope.fromName(
        json['managerScope']?.toString(),
      ),
      executables: _stringMap(json['executables']),
      embeddedSdks: _mapList(json['embeddedSdks'])
          .map(LumideEmbeddedSdk.fromJson)
          .toList(),
      metadata: _objectMap(json['metadata']),
    );
  }

  final String id;
  final String providerId;
  final LumideSdkKind kind;
  final String version;
  final String rootPath;
  final LumideSdkSource source;
  final String? channel;
  final String? displayName;
  final LumideSdkManagerId? managerId;
  final LumideSdkManagerScope? managerScope;
  final Map<String, String> executables;
  final List<LumideEmbeddedSdk> embeddedSdks;
  final Map<String, Object?> metadata;

  Map<String, Object?> toJson() => {
        'id': id,
        'providerId': providerId,
        'kind': kind.value,
        'version': version,
        'rootPath': rootPath,
        'source': source.name,
        if (channel != null) 'channel': channel,
        if (displayName != null) 'displayName': displayName,
        if (managerId != null) 'managerId': managerId?.value,
        if (managerScope != null) 'managerScope': managerScope?.name,
        if (executables.isNotEmpty) 'executables': executables,
        if (embeddedSdks.isNotEmpty)
          'embeddedSdks': embeddedSdks.map((sdk) => sdk.toJson()).toList(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

class LumideSdkInstallPlan {
  const LumideSdkInstallPlan.archive({
    required this.releaseId,
    required this.archiveUri,
    required this.sha256,
    required this.format,
    required this.rootDirectory,
    required this.executables,
  });

  factory LumideSdkInstallPlan.fromJson(Map<dynamic, dynamic> json) {
    return LumideSdkInstallPlan.archive(
      releaseId: json['releaseId']?.toString() ?? '',
      archiveUri: json['archiveUri']?.toString() ?? '',
      sha256: json['sha256']?.toString() ?? '',
      format: LumideSdkArchiveFormat.fromName(json['format']?.toString()),
      rootDirectory: json['rootDirectory']?.toString() ?? '',
      executables: _stringMap(json['executables']),
    );
  }

  final String releaseId;
  final String archiveUri;
  final String sha256;
  final LumideSdkArchiveFormat format;
  final String rootDirectory;
  final Map<String, String> executables;

  Map<String, Object?> toJson() => {
        'type': 'archive',
        'releaseId': releaseId,
        'archiveUri': archiveUri,
        'sha256': sha256,
        'format': format.name,
        'rootDirectory': rootDirectory,
        'executables': executables,
      };
}

class LumideSdkResolveRequest {
  const LumideSdkResolveRequest({
    required this.kind,
    this.providerId,
    this.workspacePath,
    this.executable,
    this.purpose = LumideSdkPurpose.run,
  });

  factory LumideSdkResolveRequest.fromJson(Map<dynamic, dynamic> json) {
    return LumideSdkResolveRequest(
      kind: LumideSdkKind(json['kind']?.toString() ?? ''),
      providerId: json['providerId']?.toString(),
      workspacePath: json['workspacePath']?.toString(),
      executable: json['executable']?.toString(),
      purpose: LumideSdkPurpose.fromName(json['purpose']?.toString()),
    );
  }

  final LumideSdkKind kind;
  final String? providerId;
  final String? workspacePath;
  final String? executable;
  final LumideSdkPurpose purpose;

  Map<String, Object?> toJson() => {
        'kind': kind.value,
        if (providerId != null) 'providerId': providerId,
        if (workspacePath != null) 'workspacePath': workspacePath,
        if (executable != null) 'executable': executable,
        'purpose': purpose.name,
      };
}

class LumideSdkResolution {
  const LumideSdkResolution({
    required this.installation,
    required this.executable,
    this.arguments = const [],
    this.environment = const {},
    this.conflictMessage,
  });

  factory LumideSdkResolution.fromJson(Map<dynamic, dynamic> json) {
    final rawInstallation = json['installation'];
    return LumideSdkResolution(
      installation: LumideSdkInstallation.fromJson(
        rawInstallation is Map ? rawInstallation : const {},
      ),
      executable: json['executable']?.toString() ?? '',
      arguments: _stringList(json['arguments']),
      environment: _stringMap(json['environment']),
      conflictMessage: json['conflictMessage']?.toString(),
    );
  }

  final LumideSdkInstallation installation;
  final String executable;
  final List<String> arguments;
  final Map<String, String> environment;
  final String? conflictMessage;

  Map<String, Object?> toJson() => {
        'installation': installation.toJson(),
        'executable': executable,
        if (arguments.isNotEmpty) 'arguments': arguments,
        if (environment.isNotEmpty) 'environment': environment,
        if (conflictMessage != null) 'conflictMessage': conflictMessage,
      };
}

class LumideSdkValidation {
  const LumideSdkValidation({
    required this.state,
    this.message,
    this.details = const [],
  });

  factory LumideSdkValidation.fromJson(Map<dynamic, dynamic> json) {
    return LumideSdkValidation(
      state: LumideSdkValidationState.fromName(json['state']?.toString()),
      message: json['message']?.toString(),
      details: _stringList(json['details']),
    );
  }

  final LumideSdkValidationState state;
  final String? message;
  final List<String> details;

  bool get isValid =>
      state == LumideSdkValidationState.valid ||
      state == LumideSdkValidationState.warning;

  Map<String, Object?> toJson() => {
        'state': state.name,
        if (message != null) 'message': message,
        if (details.isNotEmpty) 'details': details,
      };
}

class LumideSdkListRequest {
  const LumideSdkListRequest({
    required this.providerId,
    this.channel,
    this.includePrereleases = false,
  });

  factory LumideSdkListRequest.fromJson(Map<dynamic, dynamic> json) {
    return LumideSdkListRequest(
      providerId: json['providerId']?.toString() ?? '',
      channel: json['channel']?.toString(),
      includePrereleases: json['includePrereleases'] == true,
    );
  }

  final String providerId;
  final String? channel;
  final bool includePrereleases;

  Map<String, Object?> toJson() => {
        'providerId': providerId,
        if (channel != null) 'channel': channel,
        'includePrereleases': includePrereleases,
      };
}

class LumideSdkDiscoveryRequest {
  const LumideSdkDiscoveryRequest({
    required this.providerId,
    this.workspacePath,
  });

  factory LumideSdkDiscoveryRequest.fromJson(Map<dynamic, dynamic> json) {
    return LumideSdkDiscoveryRequest(
      providerId: json['providerId']?.toString() ?? '',
      workspacePath: json['workspacePath']?.toString(),
    );
  }

  final String providerId;
  final String? workspacePath;

  Map<String, Object?> toJson() => {
        'providerId': providerId,
        if (workspacePath != null) 'workspacePath': workspacePath,
      };
}

class LumideSdkInstallPlanRequest {
  const LumideSdkInstallPlanRequest({
    required this.providerId,
    required this.release,
  });

  factory LumideSdkInstallPlanRequest.fromJson(Map<dynamic, dynamic> json) {
    final rawRelease = json['release'];
    return LumideSdkInstallPlanRequest(
      providerId: json['providerId']?.toString() ?? '',
      release: LumideSdkRelease.fromJson(
        rawRelease is Map ? rawRelease : const {},
      ),
    );
  }

  final String providerId;
  final LumideSdkRelease release;

  Map<String, Object?> toJson() => {
        'providerId': providerId,
        'release': release.toJson(),
      };
}

class LumideSdkValidationRequest {
  const LumideSdkValidationRequest({
    required this.providerId,
    required this.installation,
  });

  factory LumideSdkValidationRequest.fromJson(Map<dynamic, dynamic> json) {
    final rawInstallation = json['installation'];
    return LumideSdkValidationRequest(
      providerId: json['providerId']?.toString() ?? '',
      installation: LumideSdkInstallation.fromJson(
        rawInstallation is Map ? rawInstallation : const {},
      ),
    );
  }

  final String providerId;
  final LumideSdkInstallation installation;

  Map<String, Object?> toJson() => {
        'providerId': providerId,
        'installation': installation.toJson(),
      };
}

List<Map<dynamic, dynamic>> _mapList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map) item
  ];
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return [for (final item in value) item.toString()];
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return const {};
  return value.map(
    (key, mapValue) => MapEntry(key.toString(), mapValue.toString()),
  );
}

Map<String, Object?> _objectMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
}
