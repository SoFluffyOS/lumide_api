/// Capabilities exposed by a debug backend.
class LumideDebugCapabilities {
  const LumideDebugCapabilities({
    this.canLaunch = false,
    this.canContinue = false,
    this.canPause = false,
    this.canStepOver = false,
    this.canStepInto = false,
    this.canStepOut = false,
    this.canStop = false,
    this.canSetBreakpoints = false,
    this.canEvaluate = false,
  });

  final bool canLaunch;
  final bool canContinue;
  final bool canPause;
  final bool canStepOver;
  final bool canStepInto;
  final bool canStepOut;
  final bool canStop;
  final bool canSetBreakpoints;
  final bool canEvaluate;

  Map<String, dynamic> toJson() {
    return {
      'canLaunch': canLaunch,
      'canContinue': canContinue,
      'canPause': canPause,
      'canStepOver': canStepOver,
      'canStepInto': canStepInto,
      'canStepOut': canStepOut,
      'canStop': canStop,
      'canSetBreakpoints': canSetBreakpoints,
      'canEvaluate': canEvaluate,
    };
  }

  factory LumideDebugCapabilities.fromJson(Map json) {
    return LumideDebugCapabilities(
      canLaunch: json['canLaunch'] as bool? ?? false,
      canContinue: json['canContinue'] as bool? ?? false,
      canPause: json['canPause'] as bool? ?? false,
      canStepOver: json['canStepOver'] as bool? ?? false,
      canStepInto: json['canStepInto'] as bool? ?? false,
      canStepOut: json['canStepOut'] as bool? ?? false,
      canStop: json['canStop'] as bool? ?? false,
      canSetBreakpoints: json['canSetBreakpoints'] as bool? ?? false,
      canEvaluate: json['canEvaluate'] as bool? ?? false,
    );
  }
}
