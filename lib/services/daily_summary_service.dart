import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'daily_stats_service.dart';

/// Servicio para programar y mostrar el resumen diario
/// Filosofía "Guardián Silencioso": proteger sin molestar
class DailySummaryService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _keyEnabled = 'daily_summary_enabled';
  static const String _keyHour = 'daily_summary_hour';
  static const String _keyMinute = 'daily_summary_minute';

  static const int _notificationId = 888888; // ID fijo para resumen diario

  static bool _initialized = false;
  static late SharedPreferences _prefs;

  // Configuración por defecto
  static bool _isEnabled = true;
  static int _summaryHour = 18; // 6:00 PM
  static int _summaryMinute = 0;

  /// Inicializar servicio
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Inicializar timezone
      tz_data.initializeTimeZones();

      _prefs = await SharedPreferences.getInstance();
      _loadSettings();

      // Crear canal de notificación para resumen diario
      await _createNotificationChannel();

      _initialized = true;

      print('✅ DailySummaryService inicializado');
      print('   Habilitado: $_isEnabled');
      print('   Hora: ${_summaryHour.toString().padLeft(2, '0')}:${_summaryMinute.toString().padLeft(2, '0')}');

      // Programar si está habilitado (no bloquear si falla)
      if (_isEnabled) {
        try {
          await scheduleDaily();
        } catch (e) {
          print('⚠️ No se pudo programar resumen diario: $e');
        }
      }
    } catch (e) {
      print('❌ Error inicializando DailySummaryService: $e');
      _initialized = true; // Marcar como inicializado para no reintentar
    }
  }

  /// Cargar configuración desde SharedPreferences
  static void _loadSettings() {
    _isEnabled = _prefs.getBool(_keyEnabled) ?? true;
    _summaryHour = _prefs.getInt(_keyHour) ?? 18;
    _summaryMinute = _prefs.getInt(_keyMinute) ?? 0;
  }

  /// Crear canal de notificación para resumen diario
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'daily_summary',
      'Resumen Diario',
      description: 'Resumen diario de protección de Tu Guardián',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Programar notificación diaria
  static Future<void> scheduleDaily() async {
    if (!_initialized) await initialize();
    if (!_isEnabled) {
      print('⏸️ Resumen diario deshabilitado');
      return;
    }

    // Cancelar notificación anterior si existe
    await _notifications.cancel(_notificationId);

    // Calcular próxima hora de notificación
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _summaryHour,
      _summaryMinute,
    );

    // Si la hora ya pasó hoy, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Configurar notificación
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_summary',
      'Resumen Diario',
      channelDescription: 'Resumen diario de protección de Tu Guardián',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // Programar con zonedSchedule (se repite cada día)
    await _notifications.zonedSchedule(
      _notificationId,
      'Tu Guardián', // Título placeholder, se actualiza al mostrar
      'Resumen del día', // Cuerpo placeholder
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repetir diariamente
      payload: 'daily_summary',
    );

    print('📅 Resumen diario programado para ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}');
  }

  /// Mostrar resumen diario ahora (llamado por el trigger de la notificación)
  static Future<void> showDailySummary() async {
    if (!_initialized) await initialize();

    // Obtener estadísticas de hoy
    final stats = await DailyStatsService.getTodayStats();

    String title;
    String body;

    if (stats.blockedCount > 0) {
      // Hubo amenazas bloqueadas
      title = 'Hoy estuviste protegido';
      if (stats.blockedCount == 1) {
        body = 'Tu Guardián detuvo 1 intento de estafa. Tu cuenta está segura.';
      } else {
        body = 'Tu Guardián detuvo ${stats.blockedCount} intentos de estafa. Tu cuenta está segura.';
      }
    } else {
      // Día tranquilo
      title = 'Todo tranquilo hoy';
      body = 'Tu Guardián sigue vigilando. No hubo intentos de estafa.';
    }

    // Mostrar notificación
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_summary',
      'Resumen Diario',
      channelDescription: 'Resumen diario de protección de Tu Guardián',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: stats.totalCount > 0
            ? '${stats.totalCount} mensajes analizados'
            : null,
      ),
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      _notificationId + 1, // ID diferente para no cancelar el schedule
      title,
      body,
      details,
      payload: 'daily_summary_shown',
    );

    print('📊 Resumen diario mostrado: blocked=${stats.blockedCount}, total=${stats.totalCount}');

    // Re-programar para mañana
    await scheduleDaily();
  }

  /// Actualizar hora del resumen
  static Future<void> setScheduleTime(int hour, int minute) async {
    if (!_initialized) await initialize();

    _summaryHour = hour;
    _summaryMinute = minute;

    await _prefs.setInt(_keyHour, hour);
    await _prefs.setInt(_keyMinute, minute);

    print('⏰ Hora de resumen actualizada: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');

    // Re-programar con nueva hora
    if (_isEnabled) {
      await scheduleDaily();
    }
  }

  /// Habilitar/deshabilitar resumen diario
  static Future<void> setEnabled(bool enabled) async {
    if (!_initialized) await initialize();

    _isEnabled = enabled;
    await _prefs.setBool(_keyEnabled, enabled);

    if (enabled) {
      await scheduleDaily();
      print('✅ Resumen diario habilitado');
    } else {
      await _notifications.cancel(_notificationId);
      print('⏸️ Resumen diario deshabilitado');
    }
  }

  /// Mostrar resumen ahora (para testing)
  static Future<void> showNow() async {
    await showDailySummary();
  }

  // Getters
  static bool get isEnabled => _isEnabled;
  static int get summaryHour => _summaryHour;
  static int get summaryMinute => _summaryMinute;

  static String get formattedTime {
    return '${_summaryHour.toString().padLeft(2, '0')}:${_summaryMinute.toString().padLeft(2, '0')}';
  }

  static TimeOfDay get scheduleTimeOfDay {
    return TimeOfDay(hour: _summaryHour, minute: _summaryMinute);
  }
}
