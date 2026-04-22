/// State of an active debug session.
enum LumideDebugSessionState {
  launching,
  running,
  paused,
  terminated,
}

/// Parses a wire value into a [LumideDebugSessionState].
LumideDebugSessionState lumideDebugSessionStateFromJson(Object? value) {
  return switch (value) {
    'running' => LumideDebugSessionState.running,
    'paused' => LumideDebugSessionState.paused,
    'terminated' => LumideDebugSessionState.terminated,
    _ => LumideDebugSessionState.launching,
  };
}
