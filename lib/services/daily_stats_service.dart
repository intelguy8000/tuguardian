import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Servicio para trackear estadísticas diarias de mensajes
/// Persiste contadores por día para el resumen diario
class DailyStatsService {
  static const String _keyPrefix = 'daily_stats_';
  static const String _keySafe = '_safe';
  static const String _keyCaution = '_caution';
  static const String _keyBlocked = '_blocked';

  static bool _initialized = false;
  static late SharedPreferences _prefs;

  // Cache en memoria
  static int _todaySafe = 0;
  static int _todayCaution = 0;
  static int _todayBlocked = 0;
  static String _currentDateKey = '';

  /// Inicializar servicio
  static Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    _currentDateKey = _getTodayKey();
    _loadTodayStats();
    _initialized = true;

    print('✅ DailyStatsService inicializado: ${_currentDateKey}');
    print('   Seguros: $_todaySafe | Sospechosos: $_todayCaution | Bloqueados: $_todayBlocked');
  }

  /// Obtener key de hoy (formato: daily_stats_2025-01-25)
  static String _getTodayKey() {
    return _keyPrefix + DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Cargar estadísticas de hoy desde SharedPreferences
  static void _loadTodayStats() {
    _todaySafe = _prefs.getInt('$_currentDateKey$_keySafe') ?? 0;
    _todayCaution = _prefs.getInt('$_currentDateKey$_keyCaution') ?? 0;
    _todayBlocked = _prefs.getInt('$_currentDateKey$_keyBlocked') ?? 0;
  }

  /// Verificar si cambió el día y resetear si es necesario
  static void _checkAndResetIfNewDay() {
    String todayKey = _getTodayKey();
    if (todayKey != _currentDateKey) {
      print('📅 Nuevo día detectado: $todayKey');
      _currentDateKey = todayKey;
      _todaySafe = 0;
      _todayCaution = 0;
      _todayBlocked = 0;
    }
  }

  /// Incrementar contador de mensajes seguros
  static Future<void> incrementSafe() async {
    if (!_initialized) await initialize();
    _checkAndResetIfNewDay();

    _todaySafe++;
    await _prefs.setInt('$_currentDateKey$_keySafe', _todaySafe);
    print('📊 Stats: +1 seguro (total hoy: $_todaySafe)');
  }

  /// Incrementar contador de mensajes sospechosos
  static Future<void> incrementCaution() async {
    if (!_initialized) await initialize();
    _checkAndResetIfNewDay();

    _todayCaution++;
    await _prefs.setInt('$_currentDateKey$_keyCaution', _todayCaution);
    print('📊 Stats: +1 sospechoso (total hoy: $_todayCaution)');
  }

  /// Incrementar contador de mensajes bloqueados
  static Future<void> incrementBlocked() async {
    if (!_initialized) await initialize();
    _checkAndResetIfNewDay();

    _todayBlocked++;
    await _prefs.setInt('$_currentDateKey$_keyBlocked', _todayBlocked);
    print('📊 Stats: +1 bloqueado (total hoy: $_todayBlocked)');
  }

  /// Obtener estadísticas de hoy
  static Future<DailyStats> getTodayStats() async {
    if (!_initialized) await initialize();
    _checkAndResetIfNewDay();

    return DailyStats(
      date: DateTime.now(),
      safeCount: _todaySafe,
      cautionCount: _todayCaution,
      blockedCount: _todayBlocked,
    );
  }

  /// Obtener estadísticas de una fecha específica
  static Future<DailyStats> getStatsForDate(DateTime date) async {
    if (!_initialized) await initialize();

    String dateKey = _keyPrefix + DateFormat('yyyy-MM-dd').format(date);

    return DailyStats(
      date: date,
      safeCount: _prefs.getInt('$dateKey$_keySafe') ?? 0,
      cautionCount: _prefs.getInt('$dateKey$_keyCaution') ?? 0,
      blockedCount: _prefs.getInt('$dateKey$_keyBlocked') ?? 0,
    );
  }

  /// Resetear estadísticas de hoy (para testing)
  static Future<void> resetToday() async {
    if (!_initialized) await initialize();

    _todaySafe = 0;
    _todayCaution = 0;
    _todayBlocked = 0;

    await _prefs.setInt('$_currentDateKey$_keySafe', 0);
    await _prefs.setInt('$_currentDateKey$_keyCaution', 0);
    await _prefs.setInt('$_currentDateKey$_keyBlocked', 0);

    print('🗑️ Estadísticas de hoy reseteadas');
  }

  /// Limpiar estadísticas antiguas (más de 30 días)
  static Future<void> cleanupOldStats() async {
    if (!_initialized) await initialize();

    final keys = _prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList();
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    int removed = 0;

    for (String key in keys) {
      try {
        // Extraer fecha del key (daily_stats_2025-01-25_safe -> 2025-01-25)
        String dateStr = key.replaceFirst(_keyPrefix, '').split('_')[0];
        DateTime keyDate = DateFormat('yyyy-MM-dd').parse(dateStr);

        if (keyDate.isBefore(cutoffDate)) {
          await _prefs.remove(key);
          removed++;
        }
      } catch (e) {
        // Ignorar keys con formato inválido
      }
    }

    if (removed > 0) {
      print('🧹 Limpieza: $removed estadísticas antiguas eliminadas');
    }
  }

  // Getters para acceso rápido
  static int get todaySafe => _todaySafe;
  static int get todayCaution => _todayCaution;
  static int get todayBlocked => _todayBlocked;
  static int get todayTotal => _todaySafe + _todayCaution + _todayBlocked;
}

/// Modelo para estadísticas diarias
class DailyStats {
  final DateTime date;
  final int safeCount;
  final int cautionCount;
  final int blockedCount;

  DailyStats({
    required this.date,
    required this.safeCount,
    required this.cautionCount,
    required this.blockedCount,
  });

  int get totalCount => safeCount + cautionCount + blockedCount;

  bool get hadThreats => blockedCount > 0;

  String get formattedDate => DateFormat('dd/MM/yyyy').format(date);

  @override
  String toString() {
    return 'DailyStats($formattedDate: safe=$safeCount, caution=$cautionCount, blocked=$blockedCount)';
  }
}
