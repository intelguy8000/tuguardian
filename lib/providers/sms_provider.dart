import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/sms_message.dart';
import '../services/detection_service.dart';

class SMSProvider with ChangeNotifier {
  List<SMSMessage> _allMessages = [];
  bool _isLoading = false;
  String? _error;
  bool _isRealModeEnabled = false;
  
  Function(BuildContext, SMSMessage)? onThreatDetected;
  
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

  void simulateThreatSMS(BuildContext context) {
    SMSMessage threatMessage = DetectionService.analyzeMessage(
      'threat_${DateTime.now().millisecondsSinceEpoch}',
      '+573001234567',
      'URGENTE! Tu cuenta bancaria será suspendida. Confirma tus datos AHORA: https://banco-falso.com/confirmar',
      DateTime.now(),
    );
    
    _allMessages.insert(0, threatMessage);
    notifyListeners();
    _showThreatAlert(context, threatMessage);
  }

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
            Text('SMS peligroso bloqueado:', style: TextStyle(fontWeight: FontWeight.w600)),
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
              style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
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

  Future<bool> enableRealMode() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print('🚀 Modo real se activará en dispositivo Android...');
      _isRealModeEnabled = true;
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

  void loadSMSMessages() {
    loadDemoMessages();
  }

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

  void loadDemoMessages() {
    _allMessages = [
      // MENSAJES LEGÍTIMOS - Creados manualmente
      SMSMessage(
        id: 'demo_1',
        sender: '891888',
        message: 'En SURA usamos los códigos cortos 891888 y 899888 para comunicarnos contigo de forma segura. Cuando los veas, confía: somos nosotros.',
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
        riskScore: 5,
        isQuarantined: false,
        suspiciousElements: [],
      ),
      
      SMSMessage(
        id: 'demo_5',
        sender: 'Movistar',
        message: 'Tu plan se renueva mañana. Para cambiar tu plan ingresa a mi.movistar.co',
        timestamp: DateTime.now().subtract(Duration(hours: 4)),
        riskScore: 8,
        isQuarantined: false,
        suspiciousElements: ['Contiene call-to-action - requiere verificación de enlace oficial'],
      ),

      SMSMessage(
        id: 'bank_verify_1',
        sender: '891333',
        message: 'Bancolombia: JUAN ANDRES, por seguridad hemos rechazado la compra por \$8,199,000.00 en MAC CENTER COLOMBIA el 20/03/2025 a las 20:50 con tu tarjeta Mastercard terminada en *8269. Fuiste tu? Responde SI o NO a este mensaje.',
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
        riskScore: 20,
        isQuarantined: false,
        suspiciousElements: ['Verificación bancaria legítima detectada - Datos específicos confirmados'],
      ),

      SMSMessage(
        id: 'bank_verify_2',
        sender: '891333',
        message: 'Bancolombia: JUAN ANDRES, esta transaccion fue aprobada: compra por \$15,340.00 en UBER RIDES el 07/09/2024 a las 19:52 con tu tarjeta Mastercard terminada en *8269. Para protegerte queremos confirmar hiciste esta transaccion? Responde SI o NO a este mensaje. Gracias!',
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        riskScore: 18,
        isQuarantined: false,
        suspiciousElements: ['Verificación bancaria legítima detectada - Transacción específica confirmada'],
      ),

      // MENSAJES PELIGROSOS - Usar DetectionService
      DetectionService.analyzeMessage(
        'demo_2',
        '+573001234567',
        'JUAN HOY VENCE TU FACTURA CLARO!. Ponte al dia y Paga tan solo 43.859 Por tu OBLIGACION de 87.717 Consulta con tu 3217726074: https://mcpag.li/c3',
        DateTime.now().subtract(Duration(hours: 1)),
      ),
      
      DetectionService.analyzeMessage(
        'demo_3',
        '890176',
        'Apreciado cliente INTERRAPIDISIMO, en el siguiente link descarga la factura de tu envio: https://inter.la/tQHIMEr/Mi83ODUwOTc5Ng==',
        DateTime.now().subtract(Duration(hours: 2)),
      ),
      
      DetectionService.analyzeMessage(
        'demo_4',
        '890176',
        'Estas dentro del Programa Oportunidad Familiar. Tu recompensas sera de 300,000 pesos. ¡Por favor contactame por WS para reclamar tu bono! 573106172605',
        DateTime.now().subtract(Duration(hours: 3)),
      ),
      
      DetectionService.analyzeMessage(
        'demo_6',
        '890176',
        'JUAN Tu DEUDA Sera SUSPENDIDA! Paga hoy solo 43.859 en lugar de 87.717 Ingresa ya: https://sit-onclr.de/ofic3',
        DateTime.now().subtract(Duration(hours: 5)),
      ),

      DetectionService.analyzeMessage(
        'img_1',
        '899771',
        'Servicio de Puntos Primax: Los 7999 puntos acumulados en su cuenta vencen hoy. Visite: https://www.primaxa.co/co para aprender a usarlos gratis.',
        DateTime.now().subtract(Duration(days: 2)),
      ),
      
      DetectionService.analyzeMessage(
        'img_2',
        '899771',
        'Aviso de canje de Occidente. Los 11600 puntos vencen hoy. Puedes canjearlos por un regalo especial en el sitio web oficial. Detalles: https://bit.ly/4oUHZTt',
        DateTime.now().subtract(Duration(days: 3)),
      ),
      
      DetectionService.analyzeMessage(
        'img_3',
        '899771',
        '¡Felicidades! Has sido seleccionado y puedes obtener 275.000 pesos. Envía un mensaje a mi WhatsApp ahora: http://wa.me/573027330063',
        DateTime.now().subtract(Duration(days: 5)),
      ),

      DetectionService.analyzeMessage(
        'new_1',
        'BANCOLOMBIA',
        'Su cuenta Bancolombia ha sido bloqueada. Ingrese ahora a http://bancolombia-seguro.co para verificar.',
        DateTime.now().subtract(Duration(minutes: 15)),
      ),

      DetectionService.analyzeMessage(
        'new_2',
        '+573001234567',
        'Felicidades! Eres el gran ganador de \$50.000.000. Reclama aquí: http://premios-colombia.net',
        DateTime.now().subtract(Duration(minutes: 30)),
      ),

      DetectionService.analyzeMessage(
        'new_3',
        'PENSIONES',
        'Su pensión ha sido suspendida. Comuníquese de inmediato al 01-800-XXX-XXX.',
        DateTime.now().subtract(Duration(hours: 1)),
      ),

      DetectionService.analyzeMessage(
        'new_4',
        'DHL',
        'Your package is waiting for delivery. Confirm payment here: http://dhl-secure-delivery.info',
        DateTime.now().subtract(Duration(hours: 2)),
      ),

      DetectionService.analyzeMessage(
        'new_5',
        'BANCO BOGOTA',
        'Banco de Bogotá: detectamos un intento de acceso sospechoso. Revise en https://bogota-seguridad.com',
        DateTime.now().subtract(Duration(hours: 3)),
      ),

      DetectionService.analyzeMessage(
        'new_6',
        'GIROS',
        '¡Atención! Ha recibido un giro internacional, confirme su identidad en http://giros-seguro.org',
        DateTime.now().subtract(Duration(hours: 4)),
      ),

      DetectionService.analyzeMessage(
        'new_7',
        'NETFLIX',
        'Netflix: su cuenta será suspendida hoy. Actualice su método de pago aquí: http://netflix-billing-update.net',
        DateTime.now().subtract(Duration(hours: 5)),
      ),

      DetectionService.analyzeMessage(
        'new_8',
        '+573009876543',
        'Estimado cliente, hemos notado actividad inusual en su tarjeta. Llame ahora al 01-800-123-4567.',
        DateTime.now().subtract(Duration(hours: 6)),
      ),

      DetectionService.analyzeMessage(
        'new_9',
        'APPLE',
        'Apple ID locked. Please verify immediately at http://appleid-support.net',
        DateTime.now().subtract(Duration(hours: 7)),
      ),

      DetectionService.analyzeMessage(
        'new_10',
        'DAVIVIENDA',
        'Tu cuenta Davivienda ha sido seleccionada para una actualización de seguridad. Ingresa a: http://davivienda-secure.com',
        DateTime.now().subtract(Duration(hours: 8)),
      ),
    ];
    
    notifyListeners();
  }

  Future<void> sendSMSResponse(String phoneNumber, String message) async {
    try {
      print('📱 Enviando SMS a $phoneNumber: $message');
      await Future.delayed(Duration(milliseconds: 500));
      print('✅ SMS enviado exitosamente');
    } catch (e) {
      print('❌ Error enviando SMS: $e');
      throw e;
    }
  }
}