import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'detection_service.dart';
import '../models/sms_message.dart';

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
        telephony.listenIncomingSms(
          onNewMessage: _handleIncomingSMS,
          listenInBackground: true,
        );
        
        print('✅ SMS Listener activado - Escuchando mensajes...');
      } else {
        print('❌ No se pudo activar listener - Permisos insuficientes');
      }
    } catch (e) {
      print('❌ Error iniciando listener: $e');
      rethrow;
    }
  }
  
  void _handleIncomingSMS(SmsMessage message) {
    try {
      print('📩 SMS recibido:');
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