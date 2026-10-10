/// Signals a plugin can send to a spawned process with `shell.kill`.
///
/// Windows only supports [kill]; other signals fall back to it there.
enum LumideProcessSignal {
  interrupt('SIGINT'),
  terminate('SIGTERM'),
  kill('SIGKILL'),
  hangup('SIGHUP');

  const LumideProcessSignal(this.wireName);

  /// The POSIX signal name sent over JSON-RPC.
  final String wireName;

  static LumideProcessSignal? fromWireName(String? name) {
    for (final signal in values) {
      if (signal.wireName == name) return signal;
    }
    return null;
  }
}
