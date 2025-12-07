import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_feedback.dart';

class LocalFeedbackService {
  static const String _feedbackKey = 'message_feedback_history';
  static const String _patternStatsKey = 'pattern_statistics';

  // Cache en memoria para rendimiento
  Map<String, MessageFeedback>? _feedbackCache;
  Map<String, PatternStats>? _statsCache;

  // Singleton
  static final LocalFeedbackService _instance = LocalFeedbackService._internal();
  factory LocalFeedbackService() => _instance;
  LocalFeedbackService._internal();

  /// Inicializar caché desde SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Cargar feedback
    final feedbackJson = prefs.getString(_feedbackKey);
    if (feedbackJson != null) {
      final Map<String, dynamic> decoded = json.decode(feedbackJson);
      _feedbackCache = decoded.map(
        (key, value) => MapEntry(key, MessageFeedback.fromJson(value))
      );
    } else {
      _feedbackCache = {};
    }

    // Cargar estadísticas de patrones
    final statsJson = prefs.getString(_patternStatsKey);
    if (statsJson != null) {
      final Map<String, dynamic> decoded = json.decode(statsJson);
      _statsCache = decoded.map(
        (key, value) => MapEntry(key, PatternStats.fromJson(value))
      );
    } else {
      _statsCache = {};
    }

    // Limpiar feedback antiguo (>180 días) al iniciar
    await cleanOldFeedback();
  }

  /// Hash SHA-256 para privacidad (one-way)
  String _hashMessage(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Registrar feedback del usuario para un mensaje
  Future<void> recordMessageFeedback({
    required String messageId,
    required String messageContent,
    required int detectedRisk,
    required List<String> triggeredPatterns,
    required String userFeedback, // "correct" | "false_positive" | "false_negative"
  }) async {
    await _ensureInitialized();

    final messageHash = _hashMessage(messageContent);

    final feedback = MessageFeedback(
      messageId: messageId,
      messageHash: messageHash,
      timestamp: DateTime.now(),
      detectedRisk: detectedRisk,
      triggeredPatterns: triggeredPatterns,
      userFeedback: userFeedback,
    );

    // Guardar en caché
    _feedbackCache![messageHash] = feedback;

    // Actualizar pesos de patrones
    await _updatePatternWeights(
      patterns: triggeredPatterns,
      feedback: userFeedback,
      detectedRisk: detectedRisk,
    );

    // Persistir
    await _saveFeedback();
  }

  /// Actualizar pesos de patrones basado en feedback
  Future<void> _updatePatternWeights({
    required List<String> patterns,
    required String feedback,
    required int detectedRisk,
  }) async {
    await _ensureInitialized();

    for (final patternId in patterns) {
      final stats = _statsCache![patternId] ?? PatternStats(patternId: patternId);

      stats.totalDetections++;

      if (feedback == 'correct') {
        stats.correctDetections++;
        // Aumentar peso ligeramente (buen patrón)
        stats.weight = (stats.weight * 0.95) + (1.2 * 0.05);
      } else if (feedback == 'false_positive') {
        stats.falsePositives++;
        // Reducir peso (patrón sobre-detecta)
        stats.weight = (stats.weight * 0.95) + (0.8 * 0.05);
      } else if (feedback == 'false_negative') {
        stats.falseNegatives++;
        // Aumentar peso (patrón sub-detecta)
        stats.weight = (stats.weight * 0.95) + (1.1 * 0.05);
      }

      // Limitar peso entre 0.5 y 1.5
      stats.weight = stats.weight.clamp(0.5, 1.5);

      _statsCache![patternId] = stats;
    }

    await _savePatternStats();
  }

  /// Obtener peso aprendido para un patrón
  double getPatternWeight(String patternId) {
    if (_statsCache == null) return 1.0;
    return _statsCache![patternId]?.weight ?? 1.0;
  }

  /// Calcular riesgo ajustado basado en pesos aprendidos
  int calculateAdjustedRisk({
    required int baseRisk,
    required List<String> triggeredPatterns,
  }) {
    if (triggeredPatterns.isEmpty || _statsCache == null) {
      return baseRisk;
    }

    // Promedio de pesos de patrones activados
    double avgWeight = 0.0;
    int validPatterns = 0;

    for (final patternId in triggeredPatterns) {
      final stats = _statsCache![patternId];
      if (stats != null && stats.totalDetections >= 3) {
        // Solo considerar patrones con suficiente historia
        avgWeight += stats.weight;
        validPatterns++;
      }
    }

    if (validPatterns == 0) return baseRisk;

    avgWeight = avgWeight / validPatterns;
    final adjustedRisk = (baseRisk * avgWeight).round().clamp(0, 100);

    return adjustedRisk;
  }

  /// Verificar si un mensaje ya tiene feedback
  bool hasUserFeedback(String messageContent) {
    if (_feedbackCache == null) return false;
    final hash = _hashMessage(messageContent);
    return _feedbackCache!.containsKey(hash);
  }

  /// Obtener feedback existente para un mensaje
  MessageFeedback? getFeedbackForMessage(String messageContent) {
    if (_feedbackCache == null) return null;
    final hash = _hashMessage(messageContent);
    return _feedbackCache![hash];
  }

  /// Obtener estadísticas de un patrón
  PatternStats? getPatternStats(String patternId) {
    return _statsCache?[patternId];
  }

  /// Obtener todas las estadísticas de patrones
  Map<String, PatternStats> getAllPatternStats() {
    return Map.from(_statsCache ?? {});
  }

  /// Exportar feedback (para respaldo/análisis)
  Future<String> exportFeedback() async {
    await _ensureInitialized();

    final data = {
      'feedback': _feedbackCache!.map((k, v) => MapEntry(k, v.toJson())),
      'stats': _statsCache!.map((k, v) => MapEntry(k, v.toJson())),
      'exportDate': DateTime.now().toIso8601String(),
    };

    return json.encode(data);
  }

  /// Importar feedback (restaurar desde respaldo)
  Future<void> importFeedback(String jsonData) async {
    final data = json.decode(jsonData) as Map<String, dynamic>;

    final feedbackMap = data['feedback'] as Map<String, dynamic>;
    _feedbackCache = feedbackMap.map(
      (k, v) => MapEntry(k, MessageFeedback.fromJson(v))
    );

    final statsMap = data['stats'] as Map<String, dynamic>;
    _statsCache = statsMap.map(
      (k, v) => MapEntry(k, PatternStats.fromJson(v))
    );

    await _saveFeedback();
    await _savePatternStats();
  }

  /// Limpiar feedback antiguo (>6 meses)
  Future<void> cleanOldFeedback() async {
    await _ensureInitialized();

    final cutoffDate = DateTime.now().subtract(const Duration(days: 180));

    _feedbackCache!.removeWhere(
      (key, feedback) => feedback.timestamp.isBefore(cutoffDate)
    );

    await _saveFeedback();
  }

  // ========== HELPERS PRIVADOS ==========

  Future<void> _ensureInitialized() async {
    if (_feedbackCache == null || _statsCache == null) {
      await initialize();
    }
  }

  Future<void> _saveFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _feedbackCache!.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_feedbackKey, json.encode(data));
  }

  Future<void> _savePatternStats() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _statsCache!.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_patternStatsKey, json.encode(data));
  }

  // ========== ESTADÍSTICAS GLOBALES ==========

  /// Obtener resumen de aprendizaje
  Map<String, dynamic> getLearningStats() {
    if (_feedbackCache == null || _statsCache == null) {
      return {
        'totalFeedback': 0,
        'patternsLearned': 0,
        'avgAccuracy': 0.0,
      };
    }

    int totalCorrect = 0;
    int totalFalsePositive = 0;
    int totalFalseNegative = 0;

    for (final feedback in _feedbackCache!.values) {
      if (feedback.userFeedback == 'correct') totalCorrect++;
      if (feedback.userFeedback == 'false_positive') totalFalsePositive++;
      if (feedback.userFeedback == 'false_negative') totalFalseNegative++;
    }

    final totalFeedback = _feedbackCache!.length;
    final avgAccuracy = totalFeedback > 0 ? totalCorrect / totalFeedback : 0.0;

    return {
      'totalFeedback': totalFeedback,
      'patternsLearned': _statsCache!.length,
      'avgAccuracy': avgAccuracy,
      'correct': totalCorrect,
      'falsePositives': totalFalsePositive,
      'falseNegatives': totalFalseNegative,
    };
  }
}
