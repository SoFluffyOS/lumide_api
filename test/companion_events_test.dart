import 'package:lumide_api/lumide_api.dart';
import 'package:test/test.dart';

import 'support/rpc_harness.dart';

/// Records the `enabled` flags the plugin sends for [method].
List<bool> _recordSubscriptions(RpcHarness harness, String method) {
  final subscriptions = <bool>[];
  harness.host.registerMethod(method, (params) {
    subscriptions.add((params.value as Map)['enabled'] as bool);
    return null;
  });
  return subscriptions;
}

void main() {
  const agent = LumideAgent(
    id: 'chat:1',
    name: 'Claude Code',
    kind: LumideAgentKind.chat,
    state: LumideAgentState.waitingForInput,
    title: 'Fix the tests',
    workspaceFolder: 'file:///work/app',
    tokenUsage: LumideAgentTokenUsage(
      used: 14250,
      size: 200000,
      costAmount: 0.04,
      costCurrency: 'USD',
    ),
  );

  group('agents', () {
    test('state listeners subscribe while listening and decode events',
        () async {
      final harness = RpcHarness.create();
      final subscriptions = _recordSubscriptions(
        harness,
        PluginMethods.agentsSetStateSubscription,
      );
      final events = <LumideAgentStateEvent>[];
      final first = harness.context.agents.onDidChangeState(events.add);
      final second = harness.context.agents.onDidChangeState((_) {});
      await pumpEventQueue();

      harness.host.sendNotification(
        HostMethods.agentsDidChangeState,
        const LumideAgentStateEvent(
          agent: agent,
          previousState: LumideAgentState.working,
        ).toJson(),
      );
      await pumpEventQueue();

      final event = events.single;
      expect(event.previousState, LumideAgentState.working);
      expect(event.agent.state, LumideAgentState.waitingForInput);
      expect(event.agent.kind, LumideAgentKind.chat);
      expect(event.agent.name, 'Claude Code');
      expect(event.agent.workspaceFolder, 'file:///work/app');
      expect(event.agent.tokenUsage?.used, 14250);
      expect(event.agent.tokenUsage?.costCurrency, 'USD');

      first.dispose();
      await pumpEventQueue();
      expect(subscriptions, [true]);

      second.dispose();
      await pumpEventQueue();
      expect(subscriptions, [true, false]);
    });

    test('getAgents lists the host agents', () async {
      final harness = RpcHarness.create();
      harness.host.registerMethod(PluginMethods.agentsGetAgents, (_) {
        return [
          agent.toJson(),
          const LumideAgent(
            id: 'terminal:7',
            name: 'Codex',
            kind: LumideAgentKind.terminal,
            state: LumideAgentState.ended,
            title: 'codex',
          ).toJson(),
        ];
      });

      final agents = await harness.context.agents.getAgents();

      expect(agents.map((agent) => agent.id), ['chat:1', 'terminal:7']);
      expect(agents.last.kind, LumideAgentKind.terminal);
      expect(agents.last.state, LumideAgentState.ended);
      expect(agents.last.tokenUsage, isNull);
      expect(agents.last.workspaceFolder, isNull);
    });

    test('getAgents is empty on hosts without agents', () async {
      final harness = RpcHarness.create();

      expect(await harness.context.agents.getAgents(), isEmpty);
    });
  });

  test('test run end listeners subscribe and decode summaries', () async {
    final harness = RpcHarness.create();
    final subscriptions = _recordSubscriptions(
      harness,
      PluginMethods.testsSetRunEndSubscription,
    );
    final summaries = <LumideTestRunSummary>[];
    final listener = harness.context.tests.onDidEndRun(summaries.add);
    await pumpEventQueue();

    harness.host.sendNotification(
      HostMethods.testsDidEndRun,
      const LumideTestRunSummary(
        title: 'widget_test.dart',
        passed: 3,
        failed: 1,
        skipped: 2,
        workspaceFolder: 'file:///work/app',
        trigger: LumideTestRunTrigger.rerunOnSave,
      ).toJson(),
    );
    harness.host.sendNotification(HostMethods.testsDidEndRun, {
      'title': 'plugin run',
      'passed': 1,
      'failed': 0,
      'skipped': 0,
    });
    await pumpEventQueue();

    expect(summaries.first.passed, 3);
    expect(summaries.first.failed, 1);
    expect(summaries.first.skipped, 2);
    expect(summaries.first.workspaceFolder, 'file:///work/app');
    expect(summaries.first.trigger, LumideTestRunTrigger.rerunOnSave);
    expect(summaries.last.trigger, isNull);

    listener.dispose();
    await pumpEventQueue();
    expect(subscriptions, [true, false]);
  });

  test('focus listeners subscribe and receive focus changes', () async {
    final harness = RpcHarness.create();
    final subscriptions = _recordSubscriptions(
      harness,
      PluginMethods.windowSetFocusSubscription,
    );
    final focus = <bool>[];
    final listener = harness.context.window.onDidChangeFocus(focus.add);
    await pumpEventQueue();

    harness.host
      ..sendNotification(HostMethods.windowDidChangeFocus, {'focused': false})
      ..sendNotification(HostMethods.windowDidChangeFocus, {'focused': true});
    await pumpEventQueue();
    expect(focus, [false, true]);

    listener.dispose();
    await pumpEventQueue();
    expect(subscriptions, [true, false]);
  });

  test('subscriptions are ignored by hosts that do not know them', () async {
    final harness = RpcHarness.create();

    final listeners = [
      harness.context.agents.onDidChangeState((_) {}),
      harness.context.tests.onDidEndRun((_) {}),
      harness.context.window.onDidChangeFocus((_) {}),
    ];
    await pumpEventQueue();

    for (final listener in listeners) {
      listener.dispose();
    }
    await pumpEventQueue();
  });
}
