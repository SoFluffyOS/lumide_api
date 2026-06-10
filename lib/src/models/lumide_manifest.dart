/// Plugin manifest model parsed from plugin.yaml.
library;

import 'package:lumide_api/src/models/configuration_property.dart';
import 'package:lumide_api/src/models/launch.dart';
import 'package:lumide_api/src/models/permission.dart';
import 'package:yaml/yaml.dart';

/// Parsed plugin manifest from plugin.yaml.
class LumideManifest {
  const LumideManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.entryPoint,
    this.permissions = const [],
    this.uiCapabilities = const [],
    this.configuration = const [],
    this.commands = const [],
    this.keybindings = const [],
    this.launchProviders = const [],
    this.activationEvents = const [],
    this.themes = const [],
    this.iconThemes = const [],
  });

  /// Parses a manifest from YAML content.
  factory LumideManifest.fromYaml(String yamlContent) {
    final doc = loadYaml(yamlContent) as YamlMap;

    final permissions = <Permission>[];
    // Handle permissions as either YamlMap or YamlList
    if (doc['permissions'] case final YamlMap perms) {
      if (perms['network'] case final YamlList domains) {
        for (final domain in domains) {
          permissions.add(Permission.network(domain.toString()));
        }
      }
      if (perms['files'] case final YamlList paths) {
        for (final path in paths) {
          permissions.add(Permission.fileSystem(path.toString()));
        }
      }
      if (perms['shell'] case final YamlList commands) {
        for (final cmd in commands) {
          permissions.add(Permission.shell(cmd.toString()));
        }
      }
    } else if (doc['permissions'] case final YamlList permList) {
      // Handle list format: - fileSystem: [...]
      for (final item in permList) {
        if (item case final YamlMap perm) {
          if (perm['fileSystem'] case final YamlList paths) {
            for (final path in paths) {
              permissions.add(Permission.fileSystem(path.toString()));
            }
          }
          if (perm['network'] case final YamlList domains) {
            for (final domain in domains) {
              permissions.add(Permission.network(domain.toString()));
            }
          }
          if (perm['shell'] case final YamlList cmds) {
            for (final cmd in cmds) {
              permissions.add(Permission.shell(cmd.toString()));
            }
          }
        }
      }
    }

    final uiCapabilities = <String>[];
    if (doc['ui_capabilities'] case final YamlList caps) {
      for (final cap in caps) {
        uiCapabilities.add(cap.toString());
      }
    }

    // Extract name with fallbacks
    final name = doc['name']?.toString() ??
        doc['displayName']?.toString() ??
        'Unknown Plugin';

    // Extract id with fallback to name
    final id = doc['id']?.toString() ?? name;

    // Extract version (optional, can be overridden by loaders)
    final version = doc['version']?.toString() ?? '0.0.0';

    // Extract entry point with fallback
    final entryPoint = doc['entry_point']?.toString() ??
        doc['entryPoint']?.toString() ??
        'bin/main.dart';

    final configuration = <ConfigurationProperty>[];
    if (doc['configuration'] case final YamlList configList) {
      for (final item in configList) {
        if (item case final YamlMap configMap) {
          configuration.add(
            ConfigurationProperty.fromMap(
              Map<String, dynamic>.from(configMap),
            ),
          );
        }
      }
    }

    // Parse contributes.commands
    final commands = <ManifestCommand>[];
    final contributes = doc['contributes'];
    if (contributes case final YamlMap contributesMap) {
      if (contributesMap['commands'] case final YamlList commandList) {
        for (final item in commandList) {
          if (item case final YamlMap commandMap) {
            final commandId = commandMap['id']?.toString();
            final title = commandMap['title']?.toString();
            if (commandId != null && title != null) {
              commands.add(ManifestCommand(
                id: commandId,
                title: title,
                category: commandMap['category']?.toString(),
              ));
            }
          }
        }
      }
    }

    // Parse contributes.keybindings
    final keybindings = <ManifestKeybinding>[];
    if (contributes case final YamlMap contributesMap) {
      if (contributesMap['keybindings'] case final YamlList keybindingList) {
        for (final item in keybindingList) {
          if (item case final YamlMap keybindingMap) {
            final commandId = keybindingMap['command']?.toString();
            final key = keybindingMap['key']?.toString();
            if (commandId != null && key != null) {
              keybindings.add(ManifestKeybinding(
                command: commandId,
                key: key,
                when: keybindingMap['when']?.toString(),
              ));
            }
          }
        }
      }
    }

    // Parse contributes.launchProviders
    final launchProviders = <LumideLaunchProvider>[];
    if (contributes case final YamlMap contributesMap) {
      if (contributesMap['launchProviders']
          case final YamlList launchProviderList) {
        for (final item in launchProviderList) {
          if (item case final YamlMap launchProviderMap) {
            final provider = LumideLaunchProvider.fromJson(launchProviderMap);
            if (provider.id.isNotEmpty && provider.title.isNotEmpty) {
              launchProviders.add(provider);
            }
          }
        }
      }
    }

    // Parse contributes.themes
    final themes = <ManifestTheme>[];
    if (contributes case final YamlMap contributesMap) {
      if (contributesMap['themes'] case final YamlList themeList) {
        for (final item in themeList) {
          if (item case final YamlMap themeMap) {
            final themeId = themeMap['id']?.toString();
            final label = themeMap['label']?.toString();
            final uiTheme = themeMap['uiTheme']?.toString();
            final path = themeMap['path']?.toString();
            if (themeId != null &&
                label != null &&
                uiTheme != null &&
                path != null) {
              themes.add(ManifestTheme(
                id: themeId,
                label: label,
                uiTheme: uiTheme,
                path: path,
              ));
            }
          }
        }
      }
    }

    // Backward compat: convert legacy top-level color_theme to single-item list
    if (themes.isEmpty) {
      if (doc['color_theme']?.toString() case final String legacyPath) {
        themes.add(ManifestTheme(
          id: '$id.color-theme',
          label: name,
          uiTheme: 'dark',
          path: legacyPath,
        ));
      }
    }

    // Parse contributes.iconThemes
    final iconThemes = <ManifestIconTheme>[];
    if (contributes case final YamlMap contributesMap) {
      if (contributesMap['iconThemes'] case final YamlList iconThemeList) {
        for (final item in iconThemeList) {
          if (item case final YamlMap iconThemeMap) {
            final themeId = iconThemeMap['id']?.toString();
            final label = iconThemeMap['label']?.toString();
            final path = iconThemeMap['path']?.toString();
            if (themeId != null && label != null && path != null) {
              iconThemes.add(ManifestIconTheme(
                id: themeId,
                label: label,
                path: path,
              ));
            }
          }
        }
      }
    }

    // Backward compat: convert legacy top-level icon_theme to single-item list
    if (iconThemes.isEmpty) {
      if (doc['icon_theme']?.toString() case final String legacyPath) {
        iconThemes.add(ManifestIconTheme(
          id: '$id.icon-theme',
          label: name,
          path: legacyPath,
        ));
      }
    }

    final activationEvents = <String>[];
    if (doc['activation_events'] case final YamlList events) {
      for (final event in events) {
        activationEvents.add(event.toString());
      }
    }

    return LumideManifest(
      id: id,
      name: name,
      version: version,
      description: doc['description']?.toString() ?? '',
      entryPoint: entryPoint,
      permissions: permissions,
      uiCapabilities: uiCapabilities,
      configuration: configuration,
      commands: commands,
      keybindings: keybindings,
      launchProviders: launchProviders,
      themes: themes,
      iconThemes: iconThemes,
      activationEvents: activationEvents,
    );
  }

  /// Unique plugin identifier (e.g., 'com.example.my-plugin').
  final String id;

  /// Human-readable name.
  final String name;

  /// Semantic version.
  final String version;

  /// Plugin description.
  final String description;

  /// Entry point executable or script.
  final String entryPoint;

  /// Requested permissions.
  final List<Permission> permissions;

  /// Requested UI capabilities (e.g., 'webview', 'treeview').
  final List<String> uiCapabilities;

  /// Events that trigger plugin activation (e.g., 'workspaceContains:pubspec.yaml').
  final List<String> activationEvents;

  /// Configuration properties exposed by this plugin.
  final List<ConfigurationProperty> configuration;

  /// Color themes contributed by this plugin.
  final List<ManifestTheme> themes;

  /// Icon themes contributed by this plugin.
  final List<ManifestIconTheme> iconThemes;

  /// Commands contributed by this plugin.
  final List<ManifestCommand> commands;

  /// Keybindings contributed by this plugin.
  final List<ManifestKeybinding> keybindings;

  /// Launch providers contributed by this plugin.
  final List<LumideLaunchProvider> launchProviders;

  /// Creates a copy of this manifest with some fields replaced.
  LumideManifest copyWith({
    String? id,
    String? name,
    String? version,
    String? description,
    String? entryPoint,
    List<Permission>? permissions,
    List<String>? uiCapabilities,
    List<String>? activationEvents,
    List<ConfigurationProperty>? configuration,
    List<ManifestTheme>? themes,
    List<ManifestIconTheme>? iconThemes,
    List<ManifestCommand>? commands,
    List<ManifestKeybinding>? keybindings,
    List<LumideLaunchProvider>? launchProviders,
  }) {
    return LumideManifest(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      description: description ?? this.description,
      entryPoint: entryPoint ?? this.entryPoint,
      permissions: permissions ?? this.permissions,
      uiCapabilities: uiCapabilities ?? this.uiCapabilities,
      activationEvents: activationEvents ?? this.activationEvents,
      configuration: configuration ?? this.configuration,
      themes: themes ?? this.themes,
      iconThemes: iconThemes ?? this.iconThemes,
      commands: commands ?? this.commands,
      keybindings: keybindings ?? this.keybindings,
      launchProviders: launchProviders ?? this.launchProviders,
    );
  }
}

/// A command declared in a plugin manifest.
class ManifestCommand {
  const ManifestCommand({
    required this.id,
    required this.title,
    this.category,
  });

  final String id;
  final String title;
  final String? category;
}

/// A keybinding declared in a plugin manifest.
class ManifestKeybinding {
  const ManifestKeybinding({
    required this.command,
    required this.key,
    this.when,
  });

  final String command;
  final String key;
  final String? when;
}

/// A color theme declared in a plugin manifest under `contributes.themes`.
class ManifestTheme {
  const ManifestTheme({
    required this.id,
    required this.label,
    required this.uiTheme,
    required this.path,
  });

  /// Unique theme identifier (e.g., 'dracula').
  final String id;

  /// Human-readable theme name.
  final String label;

  /// Base UI theme type: 'light', 'dark', 'high-contrast'.
  final String uiTheme;

  /// Relative path to the theme JSON file.
  final String path;
}

/// An icon theme declared in a plugin manifest under `contributes.iconThemes`.
class ManifestIconTheme {
  const ManifestIconTheme({
    required this.id,
    required this.label,
    required this.path,
  });

  /// Unique icon theme identifier.
  final String id;

  /// Human-readable icon theme name.
  final String label;

  /// Relative path to the icon theme JSON file.
  final String path;
}
