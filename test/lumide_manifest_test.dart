import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

void main() {
  group('LumideManifest.fromYaml', () {
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
  });
}
