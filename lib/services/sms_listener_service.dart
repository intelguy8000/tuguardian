import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'detection_service.dart';
import 'notification_service.dart';
import 'database_service.dart';
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
        Permission.phone,
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
    bool phone = await Permission.phone.isGranted;
    return sms && phone;
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
      print('📚 Cargando SMS históricos...');
      
      List<SmsMessage> messages = await telephony.getInboxSms(
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
      
      print('📱 Encontrados ${messages.length} SMS en dispositivo');
      
      List<SMSMessage> analyzed = messages.take(100).map((msg) {
        return DetectionService.analyzeMessage(
          msg.id.toString(),
          msg.address ?? 'Desconocido',
          msg.body ?? '',
          DateTime.fromMillisecondsSinceEpoch(msg.date ?? DateTime.now().millisecondsSinceEpoch),
        );
      }).toList();
      
      print('✅ ${analyzed.length} SMS analizados');
      print('   Peligrosos: ${analyzed.where((m) => m.isDangerous).length}');
      print('   Moderados: ${analyzed.where((m) => m.isModerate).length}');
      print('   Seguros: ${analyzed.where((m) => m.isSafe).length}');
      
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