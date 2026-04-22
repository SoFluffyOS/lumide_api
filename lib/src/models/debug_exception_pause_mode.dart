LumideDebugExceptionPauseMode lumideDebugExceptionPauseModeFromJson(
  Object? value,
) {
  return switch (value) {
    'none' => LumideDebugExceptionPauseMode.none,
    'all' => LumideDebugExceptionPauseMode.all,
    _ => LumideDebugExceptionPauseMode.unhandled,
  };
}

/// Exception pause mode for a debug session.
enum LumideDebugExceptionPauseMode {
  none,
  unhandled,
  all,
}
