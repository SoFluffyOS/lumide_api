/// How a [LumideAgent] runs in Lumide.
enum LumideAgentKind {
  /// An Agent Chat, talking to its agent over ACP.
  chat,

  /// A coding agent's program in a terminal, such as `claude`.
  terminal,
}

/// What a [LumideAgent] is doing.
enum LumideAgentState {
  /// Its turn runs.
  working,

  /// It waits on the user: a permission request, a question, signing in.
  /// A terminal agent waits after it rings the bell or sends a
  /// notification, until the user types in its terminal.
  waitingForInput,

  /// Its turn finished, or it has not started one yet.
  done,

  /// Its connection or session failed.
  failed,

  /// Its chat closed, or its program exited.
  ended,
}

/// The context window an Agent Chat's session uses, as its agent reports
/// it.
class LumideAgentTokenUsage {
  const LumideAgentTokenUsage({
    required this.used,
    required this.size,
    this.costAmount,
    this.costCurrency,
  });

  factory LumideAgentTokenUsage.fromJson(Map<dynamic, dynamic> json) {
    return LumideAgentTokenUsage(
      used: (json['used'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      costAmount: (json['costAmount'] as num?)?.toDouble(),
      costCurrency: json['costCurrency'] as String?,
    );
  }

  /// Tokens in the context window so far.
  final int used;

  /// The context window's size in tokens; 0 when unknown.
  final int size;

  /// The session's cost so far, when the agent reports it.
  final double? costAmount;

  /// The currency of [costAmount], such as `USD`.
  final String? costCurrency;

  Map<String, Object?> toJson() => {
        'used': used,
        'size': size,
        if (costAmount != null) 'costAmount': costAmount,
        if (costCurrency != null) 'costCurrency': costCurrency,
      };
}

/// A coding agent running in Lumide: an Agent Chat or a terminal agent.
class LumideAgent {
  const LumideAgent({
    required this.id,
    required this.name,
    required this.kind,
    required this.state,
    required this.title,
    this.workspaceFolder,
    this.tokenUsage,
  });

  factory LumideAgent.fromJson(Map<dynamic, dynamic> json) {
    final kindName = json['kind'] as String?;
    final stateName = json['state'] as String?;
    return LumideAgent(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Agent',
      kind: LumideAgentKind.values.firstWhere(
        (kind) => kind.name == kindName,
        orElse: () => LumideAgentKind.chat,
      ),
      state: LumideAgentState.values.firstWhere(
        (state) => state.name == stateName,
        orElse: () => LumideAgentState.working,
      ),
      title: json['title'] as String? ?? '',
      workspaceFolder: json['workspaceFolder'] as String?,
      tokenUsage: switch (json['tokenUsage']) {
        final Map usage => LumideAgentTokenUsage.fromJson(usage),
        _ => null,
      },
    );
  }

  /// Stays the same while the chat is open or the terminal runs.
  final String id;

  /// Which agent, such as `Claude Code`.
  final String name;
  final LumideAgentKind kind;
  final LumideAgentState state;

  /// What it works on: the chat's title, or the title the agent gives its
  /// terminal.
  final String title;

  /// The `file:` URI of the workspace folder it works in, or of its
  /// working directory when that is outside every folder. Null when
  /// unknown.
  final String? workspaceFolder;

  /// Only Agent Chats whose agent reports usage have it; terminal agents
  /// never do.
  final LumideAgentTokenUsage? tokenUsage;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'state': state.name,
        'title': title,
        if (workspaceFolder != null) 'workspaceFolder': workspaceFolder,
        if (tokenUsage case final usage?) 'tokenUsage': usage.toJson(),
      };
}

/// An agent's state changed: [agent] as it is now.
class LumideAgentStateEvent {
  const LumideAgentStateEvent({required this.agent, this.previousState});

  factory LumideAgentStateEvent.fromJson(Map<dynamic, dynamic> json) {
    final previousName = json['previousState'] as String?;
    return LumideAgentStateEvent(
      agent: LumideAgent.fromJson(json['agent'] as Map),
      previousState: LumideAgentState.values
          .where((state) => state.name == previousName)
          .firstOrNull,
    );
  }

  final LumideAgent agent;

  /// Its state before, or null for an agent Lumide had not reported yet.
  final LumideAgentState? previousState;

  Map<String, Object?> toJson() => {
        'agent': agent.toJson(),
        if (previousState case final state?) 'previousState': state.name,
      };
}
