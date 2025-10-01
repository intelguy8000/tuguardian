import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../shared/models/sms_message.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static int _safeMessageCount = 0;
  static DateTime? _lastSafeMessageDate;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization (optional for future)
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channels
    await _createNotificationChannels();

    _initialized = true;
    print('✅ NotificationService inicializado');
  }

  /// Create notification channels for different priority levels
  static Future<void> _createNotificationChannels() async {
    // CHANNEL 1: Grouped safe messages (low priority, silent)
    const AndroidNotificationChannel safeChannel = AndroidNotificationChannel(
      'safe_messages',
      'Mensajes Seguros',
      description: 'Notificaciones agrupadas de mensajes seguros',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    // CHANNEL 2: Dangerous messages (high priority, alert sound)
    const AndroidNotificationChannel dangerChannel = AndroidNotificationChannel(
      'danger_alerts',
      'Alertas de Amenazas',
      description: 'Alertas críticas de mensajes peligrosos detectados',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('system_default'),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(safeChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(dangerChannel);

    print('✅ Canales de notificación creados');
  }

  /// Show notification for dangerous message
  static Future<void> showDangerAlert(SMSMessage message) async {
    if (!_initialized) await initialize();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'danger_alerts',
      'Alertas de Amenazas',
      channelDescription: 'Alertas críticas de mensajes peligrosos detectados',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]), // Pattern: pause, vibrate, pause, vibrate
      ticker: '⚠️ Amenaza detectada',
      styleInformation: BigTextStyleInformation(
        'De: ${message.sender}\n${message.message.length > 100 ? message.message.substring(0, 100) + "..." : message.message}',
        contentTitle: '⚠️ Amenaza detectada - Mensaje bloqueado',
        summaryText: 'Riesgo: ${message.riskScore}%',
      ),
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      message.id.hashCode, // Unique ID per message
      '⚠️ Amenaza detectada',
      'Mensaje bloqueado de ${message.sender}',
      details,
      payload: 'danger:${message.id}',
    );

    print('🚨 Notificación de amenaza enviada para ${message.sender}');
  }

  /// Show or update grouped notification for safe messages
  static Future<void> showSafeMessageGrouped() async {
    if (!_initialized) await initialize();

    // Reset counter if it's a new day
    final now = DateTime.now();
    if (_lastSafeMessageDate == null ||
        !_isSameDay(_lastSafeMessageDate!, now)) {
      _safeMessageCount = 0;
      _lastSafeMessageDate = now;
    }

    _safeMessageCount++;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'safe_messages',
      'Mensajes Seguros',
      channelDescription: 'Notificaciones agrupadas de mensajes seguros',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
      groupKey: 'safe_messages_group',
      setAsGroupSummary: true,
      styleInformation: InboxStyleInformation(
        [],
        contentTitle: 'TuGuardian - $_safeMessageCount SMS seguros hoy',
        summaryText: 'Sin amenazas detectadas',
      ),
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      999999, // Fixed ID for grouped notification
      'TuGuardian',
      '$_safeMessageCount SMS seguros hoy',
      details,
      payload: 'safe:grouped',
    );

    print('✅ Notificación agrupada actualizada: $_safeMessageCount mensajes seguros');
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    if (payload.startsWith('danger:')) {
      final messageId = payload.substring(7);
      print('📱 Usuario tocó notificación de amenaza: $messageId');
      // TODO: Navigate to message detail screen
    } else if (payload.startsWith('safe:')) {
      print('📱 Usuario tocó notificación de mensajes seguros');
      // TODO: Navigate to safe messages list
    }
  }

  /// Request notification permissions (Android 13+)
  static Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      print(granted == true
          ? '✅ Permisos de notificación concedidos'
          : '❌ Permisos de notificación rechazados');
      return granted ?? false;
    }

    return true; // Default true for older Android versions
  }

  /// Helper to check if two dates are the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Reset safe message counter (for testing)
  static void resetSafeCounter() {
    _safeMessageCount = 0;
    _lastSafeMessageDate = null;
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
    print('🔕 Todas las notificaciones canceladas');
  }

  /// Cancel specific notification
  static Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}
