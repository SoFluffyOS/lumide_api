/// A structured log record.
class LumideLogRecord {
  const LumideLogRecord({
    required this.level,
    required this.message,
    this.name,
    this.error,
    this.stackTrace,
    this.time,
  });

  /// Log level (e.g. 'INFO', 'WARN', 'ERROR').
  final String level;

  /// Log message.
  final String message;

  /// Logger name.
  final String? name;

  /// Error details, if any.
  final String? error;

  /// Stack trace, if any.
  final String? stackTrace;

  /// Time of the log event.
  final DateTime? time;

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'message': message,
      if (name != null) 'name': name,
      if (error != null) 'error': error,
      if (stackTrace != null) 'stackTrace': stackTrace,
      if (time != null) 'time': time!.toIso8601String(),
    };
  }

  factory LumideLogRecord.fromJson(Map json) {
    return LumideLogRecord(
      level: json['level'] as String,
      message: json['message'] as String,
      name: json['name'] as String?,
      error: json['error'] as String?,
      stackTrace: json['stackTrace'] as String?,
      time: json['time'] != null
          ? DateTime.tryParse(json['time'] as String)
          : null,
    );
  }
}
