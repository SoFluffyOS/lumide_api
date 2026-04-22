import 'package:lumide_api/src/models/debug_capabilities.dart';
import 'package:lumide_api/src/models/debug_exception_pause_mode.dart';
import 'package:lumide_api/src/models/debug_session_state.dart';

/// Metadata and state for a single debug session.
class LumideDebugSession {
  const LumideDebugSession({
    required this.id,
    required this.name,
    required this.state,
    this.capabilities = const LumideDebugCapabilities(),
    this.outputChannelId,
    this.stoppedReason,
    this.statusMessage,
    this.activeFrameId,
    this.exceptionPauseMode = LumideDebugExceptionPauseMode.unhandled,
  });

  final String id;
  final String name;
  final LumideDebugSessionState state;
  final LumideDebugCapabilities capabilities;

  /// Existing IDE output channel id that should render session logs.
  final String? outputChannelId;

  /// Optional paused reason such as `breakpoint` or `exception`.
  final String? stoppedReason;

  /// Optional status message for the current session state.
  final String? statusMessage;

  /// Optional selected stack frame id.
  final int? activeFrameId;

  /// Current exception pause mode.
  final LumideDebugExceptionPauseMode exceptionPauseMode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state': state.name,
      'capabilities': capabilities.toJson(),
      if (outputChannelId != null) 'outputChannelId': outputChannelId,
      if (stoppedReason != null) 'stoppedReason': stoppedReason,
      if (statusMessage != null) 'statusMessage': statusMessage,
      if (activeFrameId != null) 'activeFrameId': activeFrameId,
      'exceptionPauseMode': exceptionPauseMode.name,
    };
  }

  factory LumideDebugSession.fromJson(Map json) {
    final capabilitiesJson = json['capabilities'] as Map? ?? const {};
    return LumideDebugSession(
      id: json['id'] as String,
      name: json['name'] as String,
      state: lumideDebugSessionStateFromJson(json['state']),
      capabilities: LumideDebugCapabilities.fromJson(capabilitiesJson),
      outputChannelId: json['outputChannelId'] as String?,
      stoppedReason: json['stoppedReason'] as String?,
      statusMessage: json['statusMessage'] as String?,
      activeFrameId: json['activeFrameId'] as int?,
      exceptionPauseMode: lumideDebugExceptionPauseModeFromJson(
        json['exceptionPauseMode'],
      ),
    );
  }
}
