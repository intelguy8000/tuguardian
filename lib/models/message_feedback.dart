class MessageFeedback {
  final String messageId;
  final String messageHash;
  final DateTime timestamp;
  final int detectedRisk;
  final List<String> triggeredPatterns;
  final String userFeedback; // "correct" | "false_positive" | "false_negative"

  MessageFeedback({
    required this.messageId,
    required this.messageHash,
    required this.timestamp,
    required this.detectedRisk,
    required this.triggeredPatterns,
    required this.userFeedback,
  });

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'hash': messageHash,
    'timestamp': timestamp.toIso8601String(),
    'risk': detectedRisk,
    'patterns': triggeredPatterns,
    'feedback': userFeedback,
  };

  factory MessageFeedback.fromJson(Map<String, dynamic> json) => MessageFeedback(
    messageId: json['messageId'] as String,
    messageHash: json['hash'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    detectedRisk: json['risk'] as int,
    triggeredPatterns: List<String>.from(json['patterns'] as List),
    userFeedback: json['feedback'] as String,
  );
}

class PatternStats {
  final String patternId;
  int totalDetections;
  int correctDetections;
  int falsePositives;
  int falseNegatives;
  double weight;

  PatternStats({
    required this.patternId,
    this.totalDetections = 0,
    this.correctDetections = 0,
    this.falsePositives = 0,
    this.falseNegatives = 0,
    this.weight = 1.0,
  });

  double get accuracy => totalDetections > 0
      ? correctDetections / totalDetections
      : 0.5;

  Map<String, dynamic> toJson() => {
    'patternId': patternId,
    'totalDetections': totalDetections,
    'correctDetections': correctDetections,
    'falsePositives': falsePositives,
    'falseNegatives': falseNegatives,
    'weight': weight,
  };

  factory PatternStats.fromJson(Map<String, dynamic> json) => PatternStats(
    patternId: json['patternId'] as String,
    totalDetections: json['totalDetections'] as int? ?? 0,
    correctDetections: json['correctDetections'] as int? ?? 0,
    falsePositives: json['falsePositives'] as int? ?? 0,
    falseNegatives: json['falseNegatives'] as int? ?? 0,
    weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
  );
}
