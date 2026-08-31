import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

void main() {
  group('LumideManifest.fromYaml', () {
    test('parses static SDK provider contributions', () {
      final manifest = LumideManifest.fromYaml('''
id: lumide_flutter
name: Flutter
version: 2.0.0
contributes:
  sdkProviders:
    - id: flutter
      kind: flutter
      title: Flutter
      iconPath: assets/flutter.svg
      capabilities:
        catalog: true
        install: true
activation_events:
  - onSdkProvider:flutter
''');

      expect(manifest.sdkProviders, hasLength(1));
      expect(manifest.sdkProviders.single.kind, LumideSdkKind.flutter);
      expect(manifest.sdkProviders.single.capabilities.install, isTrue);
      expect(manifest.activationEvents, contains('onSdkProvider:flutter'));
    });

    test('parses contributes.themes list', () {
      const yaml = '''
id: test-plugin
name: Test Plugin
version: 1.0.0
description: A test plugin
entry_point: bin/main.dart
contributes:
  themes:
    - id: dracula
      label: Dracula
      uiTheme: dark
      path: ./themes/dracula.json
    - id: monokai
      label: Monokai
      uiTheme: dark
      path: ./themes/monokai.json
''';

      final manifest = LumideManifest.fromYaml(yaml);

      expect(manifest.themes, hasLength(2));
      expect(manifest.themes[0].id, 'dracula');
      expect(manifest.themes[0].label, 'Dracula');
      expect(manifest.themes[0].uiTheme, 'dark');
      expect(manifest.themes[0].path, './themes/dracula.json');
      expect(manifest.themes[1].id, 'monokai');
    });

    test('parses contributes.iconThemes list', () {
      const yaml = '''
id: icon-plugin
name: Icon Plugin
version: 1.0.0
description: An icon theme plugin
entry_point: bin/main.dart
contributes:
  iconThemes:
    - id: material-icons
      label: Material Icons
      path: ./icons/material.json
''';

      final manifest = LumideManifest.fromYaml(yaml);

      expect(manifest.iconThemes, hasLength(1));
      expect(manifest.iconThemes[0].id, 'material-icons');
      expect(manifest.iconThemes[0].label, 'Material Icons');
      expect(manifest.iconThemes[0].path, './icons/material.json');
    });

    test('backward compat: converts legacy color_theme to themes list', () {
      const yaml = '''
id: legacy-plugin
name: Legacy Plugin
version: 1.0.0
description: A legacy plugin
entry_point: bin/main.dart
color_theme: themes/old-theme.json
''';

      final manifest = LumideManifest.fromYaml(yaml);

      expect(manifest.themes, hasLength(1));
      expect(manifest.themes[0].id, 'legacy-plugin.color-theme');
      expect(manifest.themes[0].label, 'Legacy Plugin');
      expect(manifest.themes[0].uiTheme, 'dark');
      expect(manifest.themes[0].path, 'themes/old-theme.json');
    });

    test('backward compat: converts legacy icon_theme to iconThemes list', () {
      const yaml = '''
id: legacy-plugin
name: Legacy Plugin
version: 1.0.0
description: A legacy plugin
entry_point: bin/main.dart
icon_theme: icons/old-icons.json
''';

      final manifest = LumideManifest.fromYaml(yaml);

      expect(manifest.iconThemes, hasLength(1));
      expect(manifest.iconThemes[0].id, 'legacy-plugin.icon-theme');
      expect(manifest.iconThemes[0].label, 'Legacy Plugin');
      expect(manifest.iconThemes[0].path, 'icons/old-icons.json');
    });

    test('contributes.themes takes precedence over legacy color_theme', () {
      const yaml = '''
id: mixed-plugin
name: Mixed Plugin
version: 1.0.0
description: Plugin with both
entry_point: bin/main.dart
color_theme: themes/legacy.json
contributes:
  themes:
    - id: new-theme
      label: New Theme
      uiTheme: light
      path: ./themes/new.json
''';

      final manifest = LumideManifest.fromYaml(yaml);

      expect(manifest.themes, hasLength(1));
      expect(manifest.themes[0].id, 'new-theme');
    });

    test('skips themes with missing required fields', () {
      const yaml = '''
id: test-plugin
name: Test Plugin
version: 1.0.0
description: A test plugin
entry_point: bin/main.dart
contributes:
  themes:
    - id: valid-theme
      label: Valid
      uiTheme: dark
      path: ./themes/valid.json
    - id: missing-path
      label: Missing Path
      uiTheme: dark
    - label: Missing ID
      uiTheme: light
      path: ./themes/noid.json
''';

      final manifest = LumideManifest.fromYaml(yaml);

      expect(manifest.themes, hasLength(1));
      expect(manifest.themes[0].id, 'valid-theme');
    });

    test('empty manifest has empty theme lists', () {
      const yaml = '''
id: minimal
name: Minimal
version: 1.0.0
description: Minimal plugin
entry_point: bin/main.dart
''';

      final manifest = LumideManifest.fromYaml(yaml);

      expect(manifest.themes, isEmpty);
      expect(manifest.iconThemes, isEmpty);
      expect(manifest.launchProviders, isEmpty);
    });

    test('parses folder path configuration type', () {
      const yaml = '''
id: config-plugin
name: Config Plugin
version: 1.0.0
description: A config plugin
entry_point: bin/main.dart
configuration:
  - key: config-plugin.sdkPath
    type: folderPath
    description: SDK folder.
''';

      final manifest = LumideManifest.fromYaml(yaml);

      expect(manifest.configuration, hasLength(1));
      expect(manifest.configuration[0].type, ConfigPropertyType.folderPath);
    });

    test('parses contributes.launchProviders list', () {
      const yaml = '''
id: launch-plugin
name: Launch Plugin
version: 1.0.0
description: A launch plugin
entry_point: bin/main.dart
contributes:
  launchProviders:
    - id: flutter
      title: Flutter
      kinds: [run, debug, attach, test]
      defaultKinds: [run, debug]
      workspaceContains:
        - pubspec.yaml
      icon: play
      priority: 10
''';

      final manifest = LumideManifest.fromYaml(yaml);

      expect(manifest.launchProviders, hasLength(1));
      expect(manifest.launchProviders[0].id, 'flutter');
      expect(manifest.launchProviders[0].title, 'Flutter');
      expect(manifest.launchProviders[0].kinds, [
        LumideLaunchKind.run,
        LumideLaunchKind.debug,
        LumideLaunchKind.attach,
        LumideLaunchKind.test,
      ]);
      expect(manifest.launchProviders[0].workspacePatterns, ['pubspec.yaml']);
      expect(manifest.launchProviders[0].defaultKinds, [
        LumideLaunchKind.run,
        LumideLaunchKind.debug,
      ]);
      expect(manifest.launchProviders[0].icon, 'play');
      expect(manifest.launchProviders[0].priority, 10);
    });

    test('skips launch providers with missing required fields', () {
      const yaml = '''
id: launch-plugin
name: Launch Plugin
version: 1.0.0
description: A launch plugin
entry_point: bin/main.dart
contributes:
  launchProviders:
    - id: flutter
      title: Flutter
    - id: missing-title
    - title: Missing ID
''';

      final manifest = LumideManifest.fromYaml(yaml);

      expect(manifest.launchProviders, hasLength(1));
      expect(manifest.launchProviders[0].id, 'flutter');
      expect(manifest.launchProviders[0].kinds, [LumideLaunchKind.run]);
    });

    test('copyWith preserves and replaces theme lists', () {
      const yaml = '''
id: test
name: Test
version: 1.0.0
description: Test
entry_point: bin/main.dart
contributes:
  themes:
    - id: theme-a
      label: Theme A
      uiTheme: dark
      path: ./a.json
''';

      final manifest = LumideManifest.fromYaml(yaml);

      // Preserve
      final copy = manifest.copyWith(name: 'Updated');
      expect(copy.themes, hasLength(1));
      expect(copy.themes[0].id, 'theme-a');

      // Replace
      final replaced = manifest.copyWith(themes: []);
      expect(replaced.themes, isEmpty);
    });

    test('copyWith preserves and replaces launch providers', () {
      const yaml = '''
id: test
name: Test
version: 1.0.0
description: Test
entry_point: bin/main.dart
contributes:
  launchProviders:
    - id: flutter
      title: Flutter
''';

      final manifest = LumideManifest.fromYaml(yaml);

      final copy = manifest.copyWith(name: 'Updated');
      expect(copy.launchProviders, hasLength(1));
      expect(copy.launchProviders[0].id, 'flutter');

      final replaced = manifest.copyWith(launchProviders: []);
      expect(replaced.launchProviders, isEmpty);
    });

    test('parses declarative file nesting contributions', () {
      const yaml = r'''
id: generator-plugin
name: Generator Plugin
version: 1.0.0
description: Adds generated file nests
entry_point: bin/main.dart
contributes:
  fileNesting:
    "*.dart": "${capture}.serializer.dart, ${capture}.schema.json"
    "model.yaml":
      - "model.generated.dart"
      - "model.metadata.json"
    "ignored.txt": 42
''';

      final manifest = LumideManifest.fromYaml(yaml);

      expect(manifest.fileNestingPatterns, hasLength(2));
      expect(
        manifest.fileNestingPatterns[0].parentPattern,
        '*.dart',
      );
      expect(
        manifest.fileNestingPatterns[0].childPatterns,
        [r'${capture}.serializer.dart', r'${capture}.schema.json'],
      );
      expect(
        manifest.fileNestingPatterns[1].childPatterns,
        ['model.generated.dart', 'model.metadata.json'],
      );
    });

    test('copyWith preserves and replaces file nesting patterns', () {
      const pattern = ManifestFileNestingPattern(
        parentPattern: '*.dart',
        childPatterns: [r'${capture}.g.dart'],
      );
      const manifest = LumideManifest(
        id: 'test',
        name: 'Test',
        version: '1.0.0',
        description: '',
        entryPoint: 'bin/main.dart',
        fileNestingPatterns: [pattern],
      );

      expect(manifest.copyWith(name: 'Updated').fileNestingPatterns, [pattern]);
      expect(
        manifest.copyWith(fileNestingPatterns: []).fileNestingPatterns,
        isEmpty,
      );
    });

    test('parses declarative snippet contributions', () {
      const yaml = '''
id: snippet-plugin
name: Snippet Plugin
version: 1.0.0
description: Adds snippets
entry_point: bin/main.dart
contributes:
  snippets:
    - language: dart
      path: snippets/dart.json
    - path: snippets/global.code-snippets
    - language: ignored
      path: '  '
    - invalid
''';

      final manifest = LumideManifest.fromYaml(yaml);

      expect(manifest.snippets, hasLength(2));
      expect(manifest.snippets[0].language, 'dart');
      expect(manifest.snippets[0].path, 'snippets/dart.json');
      expect(manifest.snippets[1].language, isNull);
      expect(manifest.snippets[1].path, 'snippets/global.code-snippets');
    });

    test('copyWith preserves and replaces snippet contributions', () {
      const contribution = ManifestSnippetContribution(
        language: 'dart',
        path: 'snippets/dart.json',
      );
      const manifest = LumideManifest(
        id: 'test',
        name: 'Test',
        version: '1.0.0',
        description: '',
        entryPoint: 'bin/main.dart',
        snippets: [contribution],
      );

      expect(manifest.copyWith(name: 'Updated').snippets, [contribution]);
      expect(manifest.copyWith(snippets: []).snippets, isEmpty);
    });
  });

  group('LumideLaunchConfiguration', () {
    test('round-trips schema-driven launch options', () {
      const config = LumideLaunchConfiguration(
        id: 'current',
        label: 'Current',
        deduplicationKey: '/workspace/lib/main.dart',
        options: [
          LumideLaunchOption(
            id: 'flavor',
            label: 'Flavor',
            value: StringLaunchValue('staging'),
            description: 'Flutter flavor.',
            placeholder: 'production',
            icon: 'layers',
          ),
          LumideLaunchOption(
            id: 'buildMode',
            label: 'Build Mode',
            value: StringLaunchValue('debug'),
            choices: [
              LumideLaunchOptionChoice(
                value: 'debug',
                label: 'Debug',
                description: 'Hot reload',
              ),
              LumideLaunchOptionChoice(
                value: 'release',
                label: 'Release',
                description: '--release',
              ),
            ],
          ),
        ],
      );

      final roundTrip = LumideLaunchConfiguration.fromJson(config.toJson());

      expect(roundTrip.options, hasLength(2));
      expect(roundTrip.deduplicationKey, '/workspace/lib/main.dart');
      expect(roundTrip.options[0].id, 'flavor');
      expect(roundTrip.options[0].type, ConfigPropertyType.string);
      expect(roundTrip.options[0].value.raw, 'staging');
      expect(roundTrip.options[0].placeholder, 'production');
      expect(roundTrip.options[1].choices, hasLength(2));
      expect(roundTrip.options[1].choices?[0].value, 'debug');
      expect(roundTrip.options[1].choices?[0].label, 'Debug');
      expect(roundTrip.options[1].choices?[1].value, 'release');
    });
  });
}
