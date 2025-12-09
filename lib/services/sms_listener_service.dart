import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'detection_service.dart';
import 'notification_service.dart';
import 'database_service.dart';
import 'hidden_messages_service.dart';
import 'retention_settings_service.dart';
import '../shared/models/sms_message.dart';

/// Background message handler (must be top-level function with @pragma annotation)
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  try {
    print('📩 [BACKGROUND] SMS recibido:');
    print('   De: ${message.address}');
    print('   Mensaje: ${message.body?.substring(0, 50) ?? ''}...');

    // Analyze message
    SMSMessage analyzed = DetectionService.analyzeMessage(
      message.id.toString(),
      message.address ?? 'Desconocido',
      message.body ?? '',
      DateTime.fromMillisecondsSinceEpoch(
        message.date ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );

    print('   Score: ${analyzed.riskScore}');
    print('   Peligroso: ${analyzed.isDangerous}');

    // Initialize notification service
    await NotificationService.initialize();

    // Show appropriate notification
    if (analyzed.isDangerous) {
      await NotificationService.showDangerAlert(analyzed);
      print('🚨 [BACKGROUND] Alerta de amenaza enviada');
    } else if (analyzed.isSafe || analyzed.isModerate) {
      await NotificationService.showSafeMessageGrouped();
      print('✅ [BACKGROUND] Notificación agrupada actualizada');
    }

    // Save to database
    try {
      final db = DatabaseService.instance;
      await db.insertMessage(analyzed);
      print('💾 [BACKGROUND] Mensaje guardado en DB');
    } catch (e) {
      print('⚠️ [BACKGROUND] No se pudo guardar en DB: $e');
    }

  } catch (e) {
    print('❌ [BACKGROUND] Error: $e');
  }
}

class SMSListenerService {
  final Telephony telephony = Telephony.instance;
  
  Function(SMSMessage)? onMessageReceived;
  
  Future<bool> requestPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.sms,
      ].request();
      
      bool smsGranted = statuses[Permission.sms]?.isGranted ?? false;
      
      if (smsGranted) {
        print('✅ Permisos SMS concedidos');
        return true;
      } else {
        print('❌ Permisos SMS rechazados');
        return false;
      }
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      return false;
    }
  }
  
  Future<bool> hasPermissions() async {
    bool sms = await Permission.sms.isGranted;
    return sms;
  }
  
  Future<void> startListening() async {
    try {
      bool? hasPermission = await telephony.requestSmsPermissions;

      if (hasPermission != null && hasPermission) {
        // Initialize notification service first
        await NotificationService.initialize();
        await NotificationService.requestPermissions();

        // Enable BACKGROUND listening with proper handler
        telephony.listenIncomingSms(
          onNewMessage: _handleIncomingSMS,
          onBackgroundMessage: backgroundMessageHandler,
          listenInBackground: true, // ✅ ACTIVADO - Detecta con app cerrada
        );

        print('✅ SMS Listener activado - MODO BACKGROUND');
        print('   📱 Detecta SMS con app abierta');
        print('   🔔 Detecta SMS con app cerrada (notificaciones)');
      } else {
        print('❌ No se pudo activar listener - Permisos insuficientes');
      }
    } catch (e) {
      print('❌ Error iniciando listener: $e');
      rethrow;
    }
  }
  
  void _handleIncomingSMS(SmsMessage message) async {
    try {
      print('📩 [FOREGROUND] SMS recibido:');
      print('   De: ${message.address}');
      print('   Mensaje: ${message.body?.substring(0, 50)}...');

      SMSMessage analyzed = DetectionService.analyzeMessage(
        message.id.toString(),
        message.address ?? 'Desconocido',
        message.body ?? '',
        DateTime.fromMillisecondsSinceEpoch(message.date ?? DateTime.now().millisecondsSinceEpoch),
      );

      print('   Score: ${analyzed.riskScore}');
      print('   Peligroso: ${analyzed.isDangerous}');

      // Show notification (foreground also gets notifications)
      if (analyzed.isDangerous) {
        await NotificationService.showDangerAlert(analyzed);
      } else if (analyzed.isSafe || analyzed.isModerate) {
        await NotificationService.showSafeMessageGrouped();
      }

      // Update UI through callback
      onMessageReceived?.call(analyzed);

    } catch (e) {
      print('❌ Error procesando SMS: $e');
    }
  }
  
  Future<List<SMSMessage>> loadHistoricalSMS() async {
    try {
      final stopwatch = Stopwatch()..start();
      print('📚 Cargando SMS históricos...');

      // Inicializar servicios
      await HiddenMessagesService.initialize();
      await RetentionSettingsService.initialize();

      // Obtener configuración de retención
      final retentionPeriod = RetentionSettingsService.currentPeriod;
      final cutoffTimestamp = retentionPeriod.cutoffTimestamp;

      print('⚙️ Período de retención: ${retentionPeriod.label}');

      // Construir query con filtro de fecha si aplica
      List<SmsMessage> messages;

      if (cutoffTimestamp != null) {
        // OPTIMIZACIÓN: Filtrar por fecha a nivel de query (nativo)
        print('🔍 Filtrando mensajes desde: ${retentionPeriod.cutoffDate}');

        messages = await telephony.getInboxSms(
          columns: [
            SmsColumn.ADDRESS,
            SmsColumn.BODY,
            SmsColumn.DATE,
            SmsColumn.ID,
          ],
          filter: SmsFilter.where(SmsColumn.DATE)
              .greaterThan(cutoffTimestamp.toString()),
          sortOrder: [
            OrderBy(SmsColumn.DATE, sort: Sort.DESC),
          ],
        );
      } else {
        // Sin filtro de fecha (modo "Todos")
        print('⚠️ Modo "Todos" - cargando todos los SMS (puede ser lento)');

        messages = await telephony.getInboxSms(
          columns: [
            SmsColumn.ADDRESS,
            SmsColumn.BODY,
            SmsColumn.DATE,
            SmsColumn.ID,
          ],
          sortOrder: [
            OrderBy(SmsColumn.DATE, sort: Sort.DESC),
          ],
        );
      }

      final queryTime = stopwatch.elapsedMilliseconds;
      print('📱 Query completado en ${queryTime}ms - ${messages.length} SMS encontrados');

      // Filtrar mensajes de senders ocultos
      List<SmsMessage> visibleMessages = messages.where((msg) {
        String sender = msg.address ?? 'Desconocido';
        return !HiddenMessagesService.isHiddenSync(sender);
      }).toList();

      int hiddenCount = messages.length - visibleMessages.length;
      if (hiddenCount > 0) {
        print('🙈 $hiddenCount SMS ocultos (conversaciones eliminadas)');
      }

      // Analizar todos los mensajes visibles (ya no hay .take(100))
      final analysisStart = stopwatch.elapsedMilliseconds;

      List<SMSMessage> analyzed = visibleMessages.map((msg) {
        return DetectionService.analyzeMessage(
          msg.id.toString(),
          msg.address ?? 'Desconocido',
          msg.body ?? '',
          DateTime.fromMillisecondsSinceEpoch(msg.date ?? DateTime.now().millisecondsSinceEpoch),
        );
      }).toList();

      final analysisTime = stopwatch.elapsedMilliseconds - analysisStart;
      stopwatch.stop();

      print('✅ ${analyzed.length} SMS analizados en ${analysisTime}ms');
      print('   Peligrosos: ${analyzed.where((m) => m.isDangerous).length}');
      print('   Moderados: ${analyzed.where((m) => m.isModerate).length}');
      print('   Seguros: ${analyzed.where((m) => m.isSafe).length}');
      print('⏱️ TIEMPO TOTAL: ${stopwatch.elapsedMilliseconds}ms');

      return analyzed;

    } catch (e) {
      print('❌ Error cargando SMS históricos: $e');
      return [];
    }
  }
  
  void stopListening() {
    onMessageReceived = null;
    print('⏹️ SMS Listener detenido');
  }
  
  Future<void> sendSMS(String phoneNumber, String message) async {
    try {
      await telephony.sendSms(
        to: phoneNumber,
        message: message,
      );
      print('✅ SMS enviado a $phoneNumber');
    } catch (e) {
      print('❌ Error enviando SMS: $e');
      rethrow;
    }
  }
}