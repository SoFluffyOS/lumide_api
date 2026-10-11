/// Line coverage of one file, reported with [LumideTestRun.setCoverage].
class LumideFileCoverage {
  const LumideFileCoverage({
    required this.uri,
    this.coveredLines = const [],
    this.uncoveredLines = const [],
  });

  factory LumideFileCoverage.fromJson(Map<dynamic, dynamic> json) {
    List<int> lines(Object? value) => [
          for (final line in value as List? ?? const [])
            if (line is int) line,
        ];
    return LumideFileCoverage(
      uri: json['uri'] as String,
      coveredLines: lines(json['coveredLines']),
      uncoveredLines: lines(json['uncoveredLines']),
    );
  }

  /// `file:` URI of the source file.
  final String uri;

  /// 1-based lines that ran.
  final List<int> coveredLines;

  /// 1-based lines that could run but did not.
  final List<int> uncoveredLines;

  Map<String, Object?> toJson() => {
        'uri': uri,
        'coveredLines': coveredLines,
        'uncoveredLines': uncoveredLines,
      };
}
