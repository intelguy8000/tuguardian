import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/sms_message.dart';

class SMSProvider with ChangeNotifier {
  List<SMSMessage> _allMessages = [];
  bool _isLoading = false;
  String? _error;
  bool _isRealModeEnabled = false;
  
  // Callback para alertas
  Function(BuildContext, SMSMessage)? onThreatDetected;
  
  // Getters
  List<SMSMessage> get allMessages => _allMessages;
  List<SMSMessage> get safeMessages => 
      _allMessages.where((msg) => msg.isSafe).toList();
  List<SMSMessage> get riskyMessages => 
      _allMessages.where((msg) => msg.isModerate || msg.isDangerous).toList();
  List<SMSMessage> get quarantinedMessages => 
      _allMessages.where((msg) => msg.isQuarantined).toList();
  
  int get totalMessages => _allMessages.length;
  int get blockedThreats => quarantinedMessages.length;
  int get riskyCount => riskyMessages.length;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isRealModeEnabled => _isRealModeEnabled;

  SMSProvider() {
    loadDemoMessages();
  }

  /// SIMULAR LLEGADA DE SMS MALICIOSO (para demo)
  void simulateThreatSMS(BuildContext context) {
    SMSMessage threatMessage = SMSMessage(
      id: 'threat_${DateTime.now().millisecondsSinceEpoch}',
      sender: '+573001234567',
      message: 'URGENTE! Tu cuenta bancaria será suspendida. Confirma tus datos AHORA: https://banco-falso.com/confirmar',
      timestamp: DateTime.now(),
      riskScore: 98,
      isQuarantined: true,
      suspiciousElements: ['Urgencia artificial', 'URL maliciosa', 'Phishing detectado'],
    );
    
    _allMessages.insert(0, threatMessage);
    notifyListeners();
    
    // Mostrar alerta inmediata
    _showThreatAlert(context, threatMessage);
  }

  /// MOSTRAR ALERTA DE AMENAZA
  void _showThreatAlert(BuildContext context, SMSMessage message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[50],
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '🚨 AMENAZA DETECTADA',
                style: TextStyle(
                  color: Colors.red[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SMS peligroso bloqueado:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('De: ${message.sender}'),
            SizedBox(height: 4),
            Text('Score: ${message.riskScore}/100'),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Text(
                message.message.length > 100 
                    ? '${message.message.substring(0, 100)}...'
                    : message.message,
                style: TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(height: 12),
            Text(
              '✅ TuGuardian te protegió automáticamente',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Ver Detalles'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// ACTIVAR MODO REAL (SMS del dispositivo) - SIMPLIFICADO
  Future<bool> enableRealMode() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print('🚀 Modo real se activará en dispositivo Android...');
      
      // Por ahora, simular que se activó
      _isRealModeEnabled = true;
      
      // Mantener mensajes demo pero marcar como "modo real"
      loadDemoMessages();
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _error = 'Error activando modo real: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// CARGAR MENSAJES (UNIFICADO)
  void loadSMSMessages() {
    loadDemoMessages();
  }

  /// OBTENER ESTADÍSTICAS DE PROTECCIÓN
  Map<String, dynamic> getProtectionStats() {
    return {
      'totalMessages': totalMessages,
      'safeMessages': safeMessages.length,
      'riskyMessages': riskyMessages.length,
      'blockedThreats': blockedThreats,
      'protectionRate': totalMessages > 0 ? 
          ((safeMessages.length / totalMessages) * 100).round() : 100,
      'isRealMode': _isRealModeEnabled,
    };
  }

  /// AGREGAR MENSAJES DE DEMOSTRACIÓN CON DATOS REALES - BASE DE DATOS COMPLETA
  void loadDemoMessages() {
    _allMessages = [
      // MENSAJES ORIGINALES
      SMSMessage(
        id: 'demo_1',
        sender: '891888',
        message: 'En SURA usamos los códigos cortos 891888 y 899888 para comunicarnos contigo de forma segura. Cuando los veas, confía: somos nosotros.',
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
        riskScore: 5,
        suspiciousElements: [],
      ),
      
      SMSMessage(
        id: 'demo_2',
        sender: '+573001234567',
        message: 'JUAN HOY VENCE TU FACTURA CLARO!. Ponte al dia y Paga tan solo 43.859 Por tu OBLIGACION de 87.717 Consulta con tu 3217726074: https://mcpag.li/c3',
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
        riskScore: 95,
        isQuarantined: true,
        suspiciousElements: ['Dominio malicioso conocido: mcpag.li', 'Cantidades típicas de estafa', 'Personalización falsa detectada', 'Urgencia artificial detectada'],
      ),
      
      SMSMessage(
        id: 'demo_3',
        sender: '890176',
        message: 'Apreciado cliente INTERRAPIDISIMO, en el siguiente link descarga la factura de tu envio: https://inter.la/tQHIMEr/Mi83ODUwOTc5Ng==',
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        riskScore: 88,
        isQuarantined: true,
        suspiciousElements: ['Empresa falsa detectada', 'Dominio malicioso conocido: inter.la'],
      ),
      
      SMSMessage(
        id: 'demo_4',
        sender: '890176',
        message: 'Estas dentro del Programa Oportunidad Familiar. Tu recompensas sera de 300,000 pesos. ¡Por favor contactame por WS para reclamar tu bono! 573106172605',
        timestamp: DateTime.now().subtract(Duration(hours: 3)),
        riskScore: 92,
        isQuarantined: true,
        suspiciousElements: ['Empresa falsa detectada', 'Cantidades típicas de estafa'],
      ),
      
      SMSMessage(
        id: 'demo_5',
        sender: 'Movistar',
        message: 'Tu plan se renueva mañana. Para cambiar tu plan ingresa a mi.movistar.co',
        timestamp: DateTime.now().subtract(Duration(hours: 4)),
        riskScore: 10,
        suspiciousElements: [],
      ),
      
      SMSMessage(
        id: 'demo_6',
        sender: '890176',
        message: 'JUAN Tu DEUDA Sera SUSPENDIDA! Paga hoy solo 43.859 en lugar de 87.717 Ingresa ya: https://sit-onclr.de/ofic3',
        timestamp: DateTime.now().subtract(Duration(hours: 5)),
        riskScore: 96,
        isQuarantined: true,
        suspiciousElements: ['Dominio malicioso conocido: sit-onclr.de', 'Cantidades típicas de estafa', 'Personalización falsa detectada', 'Urgencia artificial detectada'],
      ),

      // NUEVOS MENSAJES DE LAS IMÁGENES
      SMSMessage(
        id: 'img_1',
        sender: '899771',
        message: 'Servicio de Puntos Primax: Los 7999 puntos acumulados en su cuenta vencen hoy. Visite: https://www.primaxa.co/co para aprender a usarlos gratis.',
        timestamp: DateTime.now().subtract(Duration(days: 2)),
        riskScore: 87,
        isQuarantined: true,
        suspiciousElements: ['Dominio falso detectado: primaxa.co (real: primax.com.co)', 'Urgencia artificial: "vencen hoy"', 'Cantidades específicas sospechosas'],
      ),
      
      SMSMessage(
        id: 'img_2',
        sender: '899771',
        message: 'Aviso de canje de Occidente. Los 11600 puntos vencen hoy. Puedes canjearlos por un regalo especial en el sitio web oficial. Detalles: https://bit.ly/4oUHZTt',
        timestamp: DateTime.now().subtract(Duration(days: 3)),
        riskScore: 92,
        isQuarantined: true,
        suspiciousElements: ['Dominio acortado sospechoso: bit.ly', 'Urgencia artificial: "vencen hoy"', 'Cantidades específicas sospechosas', 'Empresa falsificada'],
      ),
      
      SMSMessage(
        id: 'img_3',
        sender: '899771',
        message: '¡Felicidades! Has sido seleccionado y puedes obtener 275.000 pesos. Envía un mensaje a mi WhatsApp ahora: http://wa.me/573027330063',
        timestamp: DateTime.now().subtract(Duration(days: 5)),
        riskScore: 96,
        isQuarantined: true,
        suspiciousElements: ['Premio falso detectado', 'Cantidades típicas de estafa: 275.000 pesos', 'Redirección a WhatsApp personal', 'Urgencia artificial'],
      ),

      // NUEVOS MENSAJES DEL TEXTO
      SMSMessage(
        id: 'new_1',
        sender: 'BANCOLOMBIA',
        message: 'Su cuenta Bancolombia ha sido bloqueada. Ingrese ahora a http://bancolombia-seguro.co para verificar.',
        timestamp: DateTime.now().subtract(Duration(minutes: 15)),
        riskScore: 98,
        isQuarantined: true,
        suspiciousElements: ['Dominio falso detectado: bancolombia-seguro.co', 'Empresa bancaria falsificada', 'Urgencia artificial: "ahora"', 'Phishing bancario detectado'],
      ),

      SMSMessage(
        id: 'new_2',
        sender: '+573001234567',
        message: 'Felicidades! Eres el gran ganador de \$50.000.000. Reclama aquí: http://premios-colombia.net',
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
        riskScore: 95,
        isQuarantined: true,
        suspiciousElements: ['Premio falso detectado', 'Cantidad excesiva sospechosa: 50 millones', 'Dominio genérico: premios-colombia.net', 'Urgencia emocional'],
      ),

      SMSMessage(
        id: 'new_3',
        sender: 'PENSIONES',
        message: 'Su pensión ha sido suspendida. Comuníquese de inmediato al 01-800-XXX-XXX.',
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
        riskScore: 89,
        isQuarantined: true,
        suspiciousElements: ['Entidad gubernamental falsificada', 'Urgencia artificial: "de inmediato"', 'Número genérico sospechoso', 'Amenaza de suspensión'],
      ),

      SMSMessage(
        id: 'new_4',
        sender: 'DHL',
        message: 'Your package is waiting for delivery. Confirm payment here: http://dhl-secure-delivery.info',
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        riskScore: 91,
        isQuarantined: true,
        suspiciousElements: ['Empresa de envíos falsificada', 'Dominio falso: dhl-secure-delivery.info', 'Solicitud de pago sospechosa', 'Idioma inglés inconsistente'],
      ),

      SMSMessage(
        id: 'new_5',
        sender: 'BANCO BOGOTA',
        message: 'Banco de Bogotá: detectamos un intento de acceso sospechoso. Revise en https://bogota-seguridad.com',
        timestamp: DateTime.now().subtract(Duration(hours: 3)),
        riskScore: 94,
        isQuarantined: true,
        suspiciousElements: ['Banco falsificado', 'Dominio falso: bogota-seguridad.com', 'Alarma de seguridad falsa', 'Phishing bancario detectado'],
      ),

      SMSMessage(
        id: 'new_6',
        sender: 'GIROS',
        message: '¡Atención! Ha recibido un giro internacional, confirme su identidad en http://giros-seguro.org',
        timestamp: DateTime.now().subtract(Duration(hours: 4)),
        riskScore: 88,
        isQuarantined: true,
        suspiciousElements: ['Giro internacional falso', 'Dominio genérico: giros-seguro.org', 'Solicitud de identidad sospechosa', 'Urgencia artificial'],
      ),

      SMSMessage(
        id: 'new_7',
        sender: 'NETFLIX',
        message: 'Netflix: su cuenta será suspendida hoy. Actualice su método de pago aquí: http://netflix-billing-update.net',
        timestamp: DateTime.now().subtract(Duration(hours: 5)),
        riskScore: 93,
        isQuarantined: true,
        suspiciousElements: ['Empresa tecnológica falsificada', 'Dominio falso: netflix-billing-update.net', 'Urgencia artificial: "hoy"', 'Solicitud de datos de pago'],
      ),

      SMSMessage(
        id: 'new_8',
        sender: '+573009876543',
        message: 'Estimado cliente, hemos notado actividad inusual en su tarjeta. Llame ahora al 01-800-123-4567.',
        timestamp: DateTime.now().subtract(Duration(hours: 6)),
        riskScore: 86,
        isQuarantined: true,
        suspiciousElements: ['Entidad bancaria genérica', 'Número genérico sospechoso', 'Urgencia artificial: "ahora"', 'Alarma de seguridad falsa'],
      ),

      SMSMessage(
        id: 'new_9',
        sender: 'APPLE',
        message: 'Apple ID locked. Please verify immediately at http://appleid-support.net',
        timestamp: DateTime.now().subtract(Duration(hours: 7)),
        riskScore: 90,
        isQuarantined: true,
        suspiciousElements: ['Empresa tecnológica falsificada', 'Dominio falso: appleid-support.net', 'Urgencia artificial: "immediately"', 'Idioma inglés inconsistente'],
      ),

      SMSMessage(
        id: 'new_10',
        sender: 'DAVIVIENDA',
        message: 'Tu cuenta Davivienda ha sido seleccionada para una actualización de seguridad. Ingresa a: http://davivienda-secure.com',
        timestamp: DateTime.now().subtract(Duration(hours: 8)),
        riskScore: 97,
        isQuarantined: true,
        suspiciousElements: ['Banco falsificado', 'Dominio falso: davivienda-secure.com', 'Actualización de seguridad falsa', 'Phishing bancario detectado'],
      ),
    ];
    
    notifyListeners();
  }
}