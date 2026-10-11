/// Line coverage of one file, reported with [LumideTestRun.setCoverage].
class LumideFileCoverage {
  const LumideFileCoverage({
    required this.uri,
    this.coveredLines = const [],
    this.uncoveredLines = const [],
  });

  /// Reads coverage leniently: lines that are not numbers are skipped, and
  /// a missing `uri` becomes empty.
  factory LumideFileCoverage.fromJson(Map<dynamic, dynamic> json) {
    List<int> lines(Object? value) => [
          if (value is List)
            for (final line in value)
              if (line is int) line,
        ];
    return LumideFileCoverage(
      uri: switch (json['uri']) {
        final String uri => uri,
        _ => '',
      },
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
