import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;
import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

import 'support/rpc_harness.dart';

void main() {
  test('the manifest lists templates with their fields', () {
    final manifest = LumideManifest.fromYaml('''
name: flutter
activation_events:
  - onProjectTemplate:flutter.app
contributes:
  projectTemplates:
    - id: flutter.app
      name: App
      description: A Flutter application
      group: Flutter
      nameHint: my_app
      namePattern: '^[a-z][a-z0-9_]*\$'
      nameRule: Lowercase letters, digits and underscores
      fields:
        - id: platforms
          type: multiSelect
          label: Platforms
          options: [android, ios]
          default: [android, ios]
          required: true
        - id: org
          type: text
          label: Organization
          default: com.example
          remember: true
          note: Becomes the bundle ID
        - id: androidLanguage
          type: select
          label: Android Language
          options:
            - { value: kotlin, label: Kotlin }
            - { value: java, label: Java }
          default: kotlin
          advanced: true
        - id: offline
          type: boolean
          label: Offline
        - id: broken
          type: select
          label: No Options
        - id: unknown
          type: slider
          label: Unknown
    - name: No Id
''');

    final [template] = manifest.projectTemplates;
    expect(template.id, 'flutter.app');
    expect(template.group, 'Flutter');
    expect(template.nameHint, 'my_app');
    expect(RegExp(template.namePattern ?? '').hasMatch('my_app'), isTrue);
    expect([
      for (final field in template.fields) field.id
    ], [
      'platforms',
      'org',
      'androidLanguage',
      'offline',
    ]);

    final [platforms, org, language, offline] = template.fields;
    expect(platforms.type, LumideProjectFieldType.multiSelect);
    expect(platforms.defaultValue, ['android', 'ios']);
    expect(platforms.required, isTrue);
    expect([
      for (final option in platforms.options) option.label
    ], [
      'android',
      'ios',
    ]);
    expect(org.remember, isTrue);
    expect(org.note, 'Becomes the bundle ID');
    expect(language.options.first.label, 'Kotlin');
    expect(language.advanced, isTrue);
    expect(offline.type, LumideProjectFieldType.boolean);
    expect(manifest.executable, isTrue);
  });

  test('the host asks the plugin to create a project from a template',
      () async {
    final harness = RpcHarness.create();
    LumideProjectCreateRequest? received;
    harness.context.projects.onCreate('flutter.app', (request) async {
      received = request;
      return const LumideProjectCreation(openFiles: ['lib/main.dart']);
    });

    final result = await harness.host.sendRequest(HostMethods.projectCreate, {
      'templateId': 'flutter.app',
      'name': 'my_app',
      'parent': '/projects',
      'path': '/projects/my_app',
      'values': {
        'platforms': ['ios'],
        'org': 'dev.lumide',
        'offline': true,
      },
    });

    expect(result, {
      'openFiles': ['lib/main.dart'],
    });
    expect(received?.path, '/projects/my_app');
    expect(received?.choices('platforms'), ['ios']);
    expect(received?.text('org'), 'dev.lumide');
    expect(received?.flag('offline'), isTrue);
    expect(received?.text('missing'), '');
  });

  test("a failed creation reaches the host as the error's message", () async {
    final harness = RpcHarness.create();
    harness.context.projects.onCreate('flutter.app', (request) async {
      throw Exception('flutter create failed');
    });

    final failure = harness.host.sendRequest(HostMethods.projectCreate, {
      'templateId': 'flutter.app',
      'name': 'my_app',
      'parent': '/projects',
      'path': '/projects/my_app',
    });

    await expectLater(
      failure,
      throwsA(
        isA<RpcException>().having(
          (error) => error.message,
          'message',
          'flutter create failed',
        ),
      ),
    );
  });
}
