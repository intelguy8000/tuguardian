import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/sms_message.dart';
import 'detection_service.dart';

class SMSServiceReal {
  static const MethodChannel _channel = MethodChannel('guardian_sms/native');
  static final Telephony telephony = Telephony.instance;
  
  // Callbacks para la UI
  static Function(SMSMessage)? onNewSMSAnalyzed;
  static Function(SMSMessage)? onThreatDetected;
  static Function(String)? onError;

  /// INICIALIZAR SERVICIO SMS REAL
  static Future<bool> initialize() async {
    try {
      print('🚀 Inicializando TuGuardian Service...');
      
      // Verificar permisos primero
      bool hasPermissions = await _checkAllPermissions();
      if (!hasPermissions) {
        print('❌ Faltan permisos necesarios');
        return false;
      }
      
      // Configurar listener de SMS entrantes
      await _setupSMSListener();
      
      // Configurar canal nativo para interceptación avanzada
      await _setupNativeChannel();
      
      print('✅ TuGuardian Service inicializado correctamente');
      return true;
      
    } catch (e) {
      print('❌ Error inicializando SMS Service: $e');
      onError?.call('Error inicializando servicio: $e');
      return false;
    }
  }

  /// VERIFICAR TODOS LOS PERMISOS NECESARIOS
  static Future<bool> _checkAllPermissions() async {
    Map<Permission, PermissionStatus> permissions = await [
      Permission.sms,
      Permission.phone,
      Permission.notification,
    ].request();
    
    bool allGranted = permissions.values.every((status) => status.isGranted);
    
    if (!allGranted) {
      print('❌ Permisos faltantes:');
      permissions.forEach((permission, status) {
        if (!status.isGranted) {
          print('  - $permission: $status');
        }
      });
    }
    
    return allGranted;
  }

  /// CONFIGURAR LISTENER DE SMS
  static Future<void> _setupSMSListener() async {
    try {
      // Configurar listener para SMS entrantes en tiempo real
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage smsMessage) {
          _handleIncomingSMS(smsMessage);
        },
        onBackgroundMessage: _backgroundSMSHandler,
        listenInBackground: true,
      );
      
      print('✅ SMS Listener configurado');
    } catch (e) {
      print('❌ Error configurando SMS Listener: $e');
      throw e;
    }
  }

  /// HANDLER PARA SMS EN BACKGROUND (CRÍTICO)
  @pragma('vm:entry-point')
  static Future<void> _backgroundSMSHandler(SmsMessage message) async {
    print('📱 SMS recibido en background desde: ${message.address}');
    
    try {
      // Analizar mensaje inmediatamente
      SMSMessage analyzedMessage = DetectionService.analyzeMessage(
        DateTime.now().millisecondsSinceEpoch.toString(),
        message.address ?? 'Desconocido',
        message.body ?? '',
        DateTime.now(),
      );
      onNewSMSAnalyzed?.call(analyzedMessage);
      // Si es peligroso, mostrar notificación inmediata
      if (analyzedMessage.isDangerous || analyzedMessage.isQuarantined) {
        onThreatDetected?.call(analyzedMessage);
        await _showThreatNotification(analyzedMessage);
      }
      
      // Guardar en base de datos local
      await _saveAnalyzedMessage(analyzedMessage);
      
    } catch (e) {
      print('❌ Error analizando SMS en background: $e');
    }
  }

  /// HANDLER PARA SMS EN FOREGROUND
  static void _handleIncomingSMS(SmsMessage smsMessage) {
    print('📱 SMS recibido en foreground desde: ${smsMessage.address}');
    
    try {
      // Analizar con nuestra IA
      SMSMessage analyzedMessage = DetectionService.analyzeMessage(
        smsMessage.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        smsMessage.address ?? 'Desconocido',
        smsMessage.body ?? '',
        DateTime.fromMillisecondsSinceEpoch(smsMessage.date ?? DateTime.now().millisecondsSinceEpoch),
      );
      
      print('🔍 Análisis completado - Score: ${analyzedMessage.riskScore}');
      
      // Notificar a la UI
      onNewSMSAnalyzed?.call(analyzedMessage);
      
      // Si es amenaza, acción inmediata
      if (analyzedMessage.isDangerous || analyzedMessage.isQuarantined) {
        print('🚨 AMENAZA DETECTADA!');
        onThreatDetected?.call(analyzedMessage);
        _showThreatNotification(analyzedMessage);
      }
      
    } catch (e) {
      print('❌ Error procesando SMS: $e');
      onError?.call('Error procesando SMS: $e');
    }
  }

  /// MOSTRAR NOTIFICACIÓN DE AMENAZA
  static Future<void> _showThreatNotification(SMSMessage message) async {
    try {
      await _channel.invokeMethod('showThreatNotification', {
        'title': '🚨 AMENAZA SMS DETECTADA',
        'body': 'Mensaje peligroso de ${message.sender} (Score: ${message.riskScore})',
        'sender': message.sender,
        'riskScore': message.riskScore,
        'message': message.message.length > 100 
            ? '${message.message.substring(0, 100)}...'
            : message.message,
      });
    } catch (e) {
      print('❌ Error mostrando notificación: $e');
    }
  }

  /// CARGAR SMS EXISTENTES DEL DISPOSITIVO
  static Future<List<SMSMessage>> loadExistingSMS({int limit = 100}) async {
    try {
      print('📥 Cargando SMS existentes...');
      
      // Obtener SMS de los últimos 30 días
      DateTime thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      
      List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ID, SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE, SmsColumn.TYPE],
        filter: SmsFilter.where(SmsColumn.DATE)
            .greaterThan(thirtyDaysAgo.millisecondsSinceEpoch.toString()),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      print('📨 ${messages.length} SMS encontrados, analizando...');

      // Analizar cada mensaje con nuestra IA
      List<SMSMessage> analyzedMessages = [];
      
      for (int i = 0; i < messages.length && i < limit; i++) {
        SmsMessage sms = messages[i];
        
        SMSMessage analyzedMessage = DetectionService.analyzeMessage(
          sms.id?.toString() ?? 'existing_$i',
          sms.address ?? 'Desconocido',
          sms.body ?? '',
          DateTime.fromMillisecondsSinceEpoch(sms.date ?? 0),
        );
        
        analyzedMessages.add(analyzedMessage);
        
        // Log para debugging
        if (analyzedMessage.riskScore > 70) {
          print('🚨 Amenaza encontrada: ${analyzedMessage.sender} - Score: ${analyzedMessage.riskScore}');
        }
      }

      print('✅ ${analyzedMessages.length} SMS analizados');
      return analyzedMessages;
      
    } catch (e) {
      print('❌ Error cargando SMS existentes: $e');
      onError?.call('Error cargando SMS: $e');
      return [];
    }
  }

  /// CONFIGURAR CANAL NATIVO PARA FUNCIONES AVANZADAS
  static Future<void> _setupNativeChannel() async {
    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'onSMSReceived':
          // SMS interceptado por código nativo
          Map<String, dynamic> data = Map<String, dynamic>.from(call.arguments);
          _handleNativeSMS(data);
          break;
          
        case 'onPermissionResult':
          // Resultado de permisos desde código nativo
          bool granted = call.arguments['granted'];
          print('📋 Permiso resultado: $granted');
          break;
          
        default:
          print('❓ Método nativo desconocido: ${call.method}');
      }
    });
  }

  /// MANEJAR SMS DESDE CÓDIGO NATIVO
  static void _handleNativeSMS(Map<String, dynamic> data) {
    try {
      SMSMessage analyzedMessage = DetectionService.analyzeMessage(
        data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        data['sender'] ?? 'Desconocido',
        data['body'] ?? '',
        DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      );
      
      onNewSMSAnalyzed?.call(analyzedMessage);
      
      if (analyzedMessage.isDangerous) {
        onThreatDetected?.call(analyzedMessage);
      }
      
    } catch (e) {
      print('❌ Error procesando SMS nativo: $e');
    }
  }

  /// GUARDAR MENSAJE ANALIZADO
  static Future<void> _saveAnalyzedMessage(SMSMessage message) async {
    // TODO: Implementar base de datos local (SQLite)
    // Por ahora solo log
    print('💾 Guardando mensaje: ${message.id} - Score: ${message.riskScore}');
  }

  /// VERIFICAR SI ES APP SMS POR DEFECTO
  static Future<bool> isDefaultSMSApp() async {
    try {
      // Simplificado para evitar errores de API
      return false; // TODO: Implementar cuando tengamos Android real
    } catch (e) {
      print('❌ Error verificando app SMS por defecto: $e');
      return false;
    }
  }

  /// SOLICITAR SER APP SMS POR DEFECTO
  static Future<bool> requestDefaultSMSApp() async {
    try {
      final result = await telephony.requestSmsPermissions;
      if (result != null && result) {
        return await telephony.requestPhoneAndSmsPermissions ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Error solicitando ser app SMS por defecto: $e');
      return false;
    }
  }

  /// OBTENER ESTADÍSTICAS DE PROTECCIÓN
  static Future<Map<String, dynamic>> getProtectionStats() async {
    try {
      List<SMSMessage> messages = await loadExistingSMS(limit: 1000);
      
      int totalMessages = messages.length;
      int safeMessages = messages.where((msg) => msg.isSafe).length;
      int riskyMessages = messages.where((msg) => msg.isModerate || msg.isDangerous).length;
      int blockedThreats = messages.where((msg) => msg.isQuarantined).length;
      
      return {
        'totalMessages': totalMessages,
        'safeMessages': safeMessages,
        'riskyMessages': riskyMessages,
        'blockedThreats': blockedThreats,
        'protectionRate': totalMessages > 0 ? 
            ((safeMessages / totalMessages) * 100).round() : 100,
        'lastScan': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {
        'totalMessages': 0,
        'safeMessages': 0,
        'riskyMessages': 0,
        'blockedThreats': 0,
        'protectionRate': 0,
        'lastScan': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }
}