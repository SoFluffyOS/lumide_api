/// What started a test run Lumide asked a plugin for.
enum LumideTestRunTrigger {
  /// The user, from the Tests pane, the test explorer or a Run lens.
  user,

  /// Rerun on Save, after a file was saved.
  rerunOnSave,

  /// An agent, through Lumide's `run_tests` tool.
  agent,

  /// A trigger a newer Lumide reports that this SDK does not know yet.
  unknown,
}

/// A test run that ended in Lumide's Tests pane, from any plugin.
class LumideTestRunSummary {
  const LumideTestRunSummary({
    required this.title,
    required this.passed,
    required this.failed,
    required this.skipped,
    this.workspaceFolder,
    this.trigger,
  });

  factory LumideTestRunSummary.fromJson(Map<dynamic, dynamic> json) {
    final triggerName = json['trigger'];
    return LumideTestRunSummary(
      title: json['title'] as String? ?? '',
      passed: (json['passed'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
      skipped: (json['skipped'] as num?)?.toInt() ?? 0,
      workspaceFolder: json['workspaceFolder'] as String?,
      trigger: switch (triggerName) {
        null => null,
        _ => LumideTestRunTrigger.values
                .where((trigger) => trigger.name == triggerName)
                .firstOrNull ??
            LumideTestRunTrigger.unknown,
      },
    );
  }

  /// The run's title, as the Tests pane shows it.
  final String title;

  /// Tests that passed; groups are not counted, as in the Tests pane.
  final int passed;

  /// Tests that failed or errored.
  final int failed;
  final int skipped;

  /// The `file:` URI of the workspace folder holding the run's tests, when
  /// its results name files.
  final String? workspaceFolder;

  /// What started the run; null for runs Lumide did not ask for, such as
  /// one a plugin started on its own; `unknown` for a trigger this SDK
  /// does not know.
  final LumideTestRunTrigger? trigger;

  Map<String, Object?> toJson() => {
        'title': title,
        'passed': passed,
        'failed': failed,
        'skipped': skipped,
        if (workspaceFolder != null) 'workspaceFolder': workspaceFolder,
        if (trigger case final trigger?) 'trigger': trigger.name,
      };
}
