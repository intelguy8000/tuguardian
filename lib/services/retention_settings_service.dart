import 'package:shared_preferences/shared_preferences.dart';

/// Períodos de retención disponibles para mensajes SMS
enum RetentionPeriod {
  oneMonth(30, '1 mes'),
  threeMonths(90, '3 meses'),
  sixMonths(180, '6 meses'),
  oneYear(365, '1 año'),
  unlimited(0, 'Todos');

  final int days;
  final String label;

  const RetentionPeriod(this.days, this.label);

  /// Obtener DateTime de corte para este período
  DateTime? get cutoffDate {
    if (days == 0) return null; // Sin límite
    return DateTime.now().subtract(Duration(days: days));
  }

  /// Obtener timestamp en milliseconds para filtros
  int? get cutoffTimestamp {
    return cutoffDate?.millisecondsSinceEpoch;
  }
}

/// Servicio para gestionar la configuración de retención de mensajes
class RetentionSettingsService {
  static const String _retentionKey = 'sms_retention_period';

  // Cache
  static RetentionPeriod? _cachedPeriod;
  static bool _initialized = false;

  /// Período por defecto: 6 meses
  static const RetentionPeriod defaultPeriod = RetentionPeriod.sixMonths;

  /// Inicializar servicio y cargar preferencia guardada
  static Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_retentionKey);

    if (savedIndex != null && savedIndex < RetentionPeriod.values.length) {
      _cachedPeriod = RetentionPeriod.values[savedIndex];
    } else {
      _cachedPeriod = defaultPeriod;
    }

    _initialized = true;
    print('✅ RetentionSettingsService inicializado: ${_cachedPeriod!.label}');
  }

  /// Obtener período actual (sincrónico, usa cache)
  static RetentionPeriod get currentPeriod {
    return _cachedPeriod ?? defaultPeriod;
  }

  /// Obtener período actual (asincrónico, garantiza inicialización)
  static Future<RetentionPeriod> getCurrentPeriod() async {
    await initialize();
    return _cachedPeriod ?? defaultPeriod;
  }

  /// Guardar nuevo período de retención
  static Future<bool> setPeriod(RetentionPeriod period) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_retentionKey, period.index);
      _cachedPeriod = period;

      print('✅ Período de retención actualizado: ${period.label} (${period.days} días)');
      return true;
    } catch (e) {
      print('❌ Error guardando período de retención: $e');
      return false;
    }
  }

  /// Obtener timestamp de corte actual
  static int? get currentCutoffTimestamp {
    return currentPeriod.cutoffTimestamp;
  }

  /// Obtener fecha de corte actual
  static DateTime? get currentCutoffDate {
    return currentPeriod.cutoffDate;
  }

  /// Descripción del período actual para UI
  static String get currentPeriodDescription {
    final period = currentPeriod;
    if (period == RetentionPeriod.unlimited) {
      return 'Mostrando todos los mensajes';
    }
    return 'Mostrando últimos ${period.label}';
  }
}
