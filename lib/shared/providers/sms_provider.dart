import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/sms_message.dart';
import '../../services/detection_service.dart';
import '../../services/sms_listener_service.dart';
import '../../services/database_service.dart';
import '../../services/badge_service.dart';
import '../../services/blocked_senders_service.dart';

class SMSProvider with ChangeNotifier {
  // LISTAS SEPARADAS
  List<SMSMessage> _demoMessages = [];
  List<SMSMessage> _realMessages = [];

  bool _isLoading = false;
  String? _error;
  bool _isRealModeEnabled = false;

  // UNREAD TRACKING
  Set<String> _readMessageIds = <String>{};

  // SERVICIOS
  final SMSListenerService _listenerService = SMSListenerService();
  final DatabaseService _db = DatabaseService.instance;
  final BadgeService _badgeService = BadgeService.instance;
  
  Function(BuildContext, SMSMessage)? onThreatDetected;
  
  // GETTERS - VISTA UNIFICADA (con filtro de bloqueados)
  List<SMSMessage> get allMessages {
    List<SMSMessage> combined = [
      ..._realMessages,
      ..._demoMessages,
    ];
    return _filterBlockedSenders(combined)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Obtener TODOS los mensajes sin filtrar (para configuración)
  List<SMSMessage> get allMessagesUnfiltered {
    List<SMSMessage> combined = [
      ..._realMessages,
      ..._demoMessages,
    ];
    return combined..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  // FILTROS
  List<SMSMessage> get demoMessages => _demoMessages;
  List<SMSMessage> get realMessages => _realMessages;
  List<SMSMessage> get safeMessages => allMessages.where((m) => m.isSafe).toList();
  List<SMSMessage> get riskyMessages => allMessages.where((m) => m.isModerate || m.isDangerous).toList();
  List<SMSMessage> get quarantinedMessages => allMessages.where((m) => m.isQuarantined).toList();
  
  // ESTADÍSTICAS GENERALES
  int get totalMessages => allMessages.length;
  int get blockedThreats => quarantinedMessages.length;
  int get riskyCount => riskyMessages.length;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isRealModeEnabled => _isRealModeEnabled;

  // UNREAD COUNT - Only count real SMS messages (not demo)
  int get unreadCount {
    return _realMessages.where((msg) => !_readMessageIds.contains(msg.id)).length;
  }
  
  // ESTADÍSTICAS DEMO
  Map<String, dynamic> get demoStats => _calculateStats(_demoMessages);
  
  // ESTADÍSTICAS REAL
  Map<String, dynamic> get realStats => _calculateStats(_realMessages);
  
  // ANÁLISIS COMPARATIVO
  Map<String, dynamic> get comparisonStats {
    if (_realMessages.isEmpty) {
      return {
        'demo_dangerous_rate': _dangerousRate(_demoMessages),
        'real_dangerous_rate': 0.0,
        'correlation': 0.0,
        'false_positives': 0,
        'false_negatives': 0,
      };
    }
    
    return {
      'demo_dangerous_rate': _dangerousRate(_demoMessages),
      'real_dangerous_rate': _dangerousRate(_realMessages),
      'correlation': _calculateCorrelation(),
      'false_positives': _findFalsePositives(),
      'false_negatives': _findFalseNegatives(),
    };
  }

  SMSProvider() {
    _loadDemoMessages();
    _autoEnableRealMode(); // Auto-enable real-time protection
    BlockedSendersService.initialize(); // Initialize blocked senders
  }

  /// Auto-enable real mode on app start
  Future<void> _autoEnableRealMode() async {
    // Wait a bit for the app to initialize
    await Future.delayed(Duration(milliseconds: 500));

    try {
      bool hasPermissions = await _listenerService.hasPermissions();

      if (hasPermissions) {
        // If permissions already granted, enable silently
        await enableRealMode();
      } else {
        // Mark that we need to request permissions
        _isRealModeEnabled = false;
        notifyListeners();
      }
    } catch (e) {
      print('⚠️ Auto-enable failed: $e');
    }
  }

  /// ACTIVAR MODO REAL
  Future<bool> enableRealMode() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print('🚀 Activando modo real...');
      
      // 1. SOLICITAR PERMISOS
      bool granted = await _listenerService.requestPermissions();
      if (!granted) {
        _error = 'Permisos SMS rechazados. Necesitamos acceso para protegerte.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      print('✅ Permisos concedidos');
      
      // 2. CARGAR SMS HISTÓRICOS
      print('📚 Cargando SMS históricos...');
      List<SMSMessage> historicalSMS = await _listenerService.loadHistoricalSMS();
      _realMessages = historicalSMS;
      
      // Guardar en DB
      for (var msg in _realMessages) {
        await _db.insertMessage(msg);
      }
      
      print('✅ ${_realMessages.length} SMS cargados');

      // 3. INICIAR LISTENER PARA NUEVOS SMS
      print('🎧 Iniciando listener...');
      _listenerService.onMessageReceived = _handleNewSMS;
      await _listenerService.startListening();

      _isRealModeEnabled = true;
      _isLoading = false;

      // 4. UPDATE BADGE WITH INITIAL UNREAD COUNT
      _updateBadge();

      notifyListeners();
      
      print('🎉 MODO REAL ACTIVADO');
      print('📚 Demo: ${_demoMessages.length} mensajes');
      print('📱 Real: ${_realMessages.length} mensajes');
      
      return true;
      
    } catch (e) {
      _error = 'Error activando modo real: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Error: $e');
      return false;
    }
  }
  
  /// MANEJAR NUEVO SMS EN TIEMPO REAL
  void _handleNewSMS(SMSMessage message) {
    print('🆕 Nuevo SMS capturado:');
    print('   De: ${message.sender}');
    print('   Score: ${message.riskScore}');

    // Agregar a lista
    _realMessages.insert(0, message);

    // Guardar en DB
    _db.insertMessage(message);

    // Limpiar mensajes antiguos
    _db.cleanOldRealMessages();

    // Update badge with new unread count
    _updateBadge();

    notifyListeners();

    // Notificar si es peligroso (sin notificaciones por ahora)
    if (message.isDangerous || message.isQuarantined) {
      print('⚠️ AMENAZA DETECTADA');
    }
  }

  /// SIMULAR AMENAZA (PARA TESTING)
  void simulateThreatSMS(BuildContext context) {
    SMSMessage threatMessage = DetectionService.analyzeMessage(
      'threat_${DateTime.now().millisecondsSinceEpoch}',
      '+573001234567',
      'URGENTE! Tu cuenta bancaria será suspendida. Confirma tus datos AHORA: https://banco-falso.com/confirmar',
      DateTime.now(),
    );
    
    // Marcar como NO demo (simular real)
    threatMessage = threatMessage.copyWith(isDemo: false);
    
    _realMessages.insert(0, threatMessage);
    notifyListeners();
    
    _showThreatAlert(context, threatMessage);
  }

  /// MOSTRAR ALERTA EN UI
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

  /// CARGAR MENSAJES DEMO
  void _loadDemoMessages() {
    _demoMessages = [
      // MENSAJES LEGÍTIMOS
      SMSMessage(
        id: 'demo_1',
        sender: '891888',
        message: 'En SURA usamos los códigos cortos 891888 y 899888 para comunicarnos contigo de forma segura. Cuando los veas, confía: somos nosotros.',
        timestamp: DateTime.now().subtract(Duration(days: 30)),
        riskScore: 5,
        isQuarantined: false,
        suspiciousElements: [],
        isDemo: true, // IMPORTANTE
      ),
      
      DetectionService.analyzeMessage(
        'demo_5',
        'Movistar',
        'Tu plan se renueva mañana. Para cambiar tu plan ingresa a mi.movistar.co',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),

      SMSMessage(
        id: 'bank_verify_1',
        sender: '891333',
        message: 'Bancolombia: JUAN ANDRES, por seguridad hemos rechazado la compra por \$8,199,000.00 en MAC CENTER COLOMBIA el 20/03/2025 a las 20:50 con tu tarjeta Mastercard terminada en *8269. Fuiste tu? Responde SI o NO a este mensaje.',
        timestamp: DateTime.now().subtract(Duration(days: 30)),
        riskScore: 20,
        isQuarantined: false,
        suspiciousElements: ['Verificación bancaria legítima detectada'],
        isDemo: true,
      ),

      SMSMessage(
        id: 'bank_verify_2',
        sender: '891333',
        message: 'Bancolombia: JUAN ANDRES, esta transaccion fue aprobada: compra por \$15,340.00 en UBER RIDES el 07/09/2024 a las 19:52 con tu tarjeta Mastercard terminada en *8269. Para protegerte queremos confirmar hiciste esta transaccion? Responde SI o NO a este mensaje. Gracias!',
        timestamp: DateTime.now().subtract(Duration(days: 30)),
        riskScore: 18,
        isQuarantined: false,
        suspiciousElements: ['Verificación bancaria legítima detectada'],
        isDemo: true,
      ),

      // MENSAJES PELIGROSOS
      DetectionService.analyzeMessage(
        'demo_2',
        '+573001234567',
        'JUAN HOY VENCE TU FACTURA CLARO!. Ponte al dia y Paga tan solo 43.859 Por tu OBLIGACION de 87.717 Consulta con tu 3217726074: https://mcpag.li/c3',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),
      
      DetectionService.analyzeMessage(
        'demo_3',
        '890176',
        'Apreciado cliente INTERRAPIDISIMO, en el siguiente link descarga la factura de tu envio: https://inter.la/tQHIMEr/Mi83ODUwOTc5Ng==',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),
      
      DetectionService.analyzeMessage(
        'demo_4',
        '890176',
        'Estas dentro del Programa Oportunidad Familiar. Tu recompensas sera de 300,000 pesos. ¡Por favor contactame por WS para reclamar tu bono! 573106172605',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),
      
      DetectionService.analyzeMessage(
        'demo_6',
        '890176',
        'JUAN Tu DEUDA Sera SUSPENDIDA! Paga hoy solo 43.859 en lugar de 87.717 Ingresa ya: https://sit-onclr.de/ofic3',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),

      DetectionService.analyzeMessage(
        'img_1',
        '899771',
        'Servicio de Puntos Primax: Los 7999 puntos acumulados en su cuenta vencen hoy. Visite: https://www.primaxa.co/co para aprender a usarlos gratis.',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),
      
      DetectionService.analyzeMessage(
        'img_2',
        '899771',
        'Aviso de canje de Occidente. Los 11600 puntos vencen hoy. Puedes canjearlos por un regalo especial en el sitio web oficial. Detalles: https://bit.ly/4oUHZTt',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),
      
      DetectionService.analyzeMessage(
        'img_3',
        '899771',
        '¡Felicidades! Has sido seleccionado y puedes obtener 275.000 pesos. Envía un mensaje a mi WhatsApp ahora: http://wa.me/573027330063',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),

      DetectionService.analyzeMessage(
        'new_1',
        'BANCOLOMBIA',
        'Su cuenta Bancolombia ha sido bloqueada. Ingrese ahora a http://bancolombia-seguro.co para verificar.',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),

      DetectionService.analyzeMessage(
        'new_2',
        '+573001234567',
        'Felicidades! Eres el gran ganador de \$50.000.000. Reclama aquí: http://premios-colombia.net',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),

      DetectionService.analyzeMessage(
        'new_3',
        'PENSIONES',
        'Su pensión ha sido suspendida. Comuníquese de inmediato al 01-800-XXX-XXX.',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),

      DetectionService.analyzeMessage(
        'new_4',
        'DHL',
        'Your package is waiting for delivery. Confirm payment here: http://dhl-secure-delivery.info',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),

      DetectionService.analyzeMessage(
        'new_5',
        'BANCO BOGOTA',
        'Banco de Bogotá: detectamos un intento de acceso sospechoso. Revise en https://bogota-seguridad.com',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),

      DetectionService.analyzeMessage(
        'new_6',
        'GIROS',
        '¡Atención! Ha recibido un giro internacional, confirme su identidad en http://giros-seguro.org',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),

      DetectionService.analyzeMessage(
        'new_7',
        'NETFLIX',
        'Netflix: su cuenta será suspendida hoy. Actualice su método de pago aquí: http://netflix-billing-update.net',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),

      DetectionService.analyzeMessage(
        'new_8',
        '+573009876543',
        'Estimado cliente, hemos notado actividad inusual en su tarjeta. Llame ahora al 01-800-123-4567.',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),

      // ⛔ CASO REAL: Mensaje que recibió el padre del desarrollador (70 años)
      // Este mensaje lo asustó tanto que corrió al cajero a cambiar su clave
      // EXACTAMENTE el tipo de fraude que TuGuardian debe prevenir
      DetectionService.analyzeMessage(
        'critical_dad_case',
        '87400',
        'Bancolombia te notifica que la Clave Principal fue generada exitosamente. Si desconoces esta solicitud, comunicate de inmediato con nuestra linea 0345109095/018000931987.',
        DateTime.now().subtract(Duration(days: 1)), // Hace 1 día (reciente)
      ).copyWith(isDemo: true),

      DetectionService.analyzeMessage(
        'new_9',
        'APPLE',
        'Apple ID locked. Please verify immediately at http://appleid-support.net',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),

      DetectionService.analyzeMessage(
        'new_10',
        'DAVIVIENDA',
        'Tu cuenta Davivienda ha sido seleccionada para una actualización de seguridad. Ingresa a: http://davivienda-secure.com',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),

      DetectionService.analyzeMessage(
        'new_11',
        'BOFA',
        'Bank of America: Suspicious activity detected on your account. Verify immediately at http://bofa-security.net',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),

      DetectionService.analyzeMessage(
        'new_12',
        '+15551234567',
        'URGENT: Your Bank of America account has been locked. Click here to unlock: http://bankofamerica-verify.com',
        DateTime.now().subtract(Duration(days: 30)),
      ).copyWith(isDemo: true),
    ];
    
    // Guardar demos en DB
    for (var msg in _demoMessages) {
      _db.insertMessage(msg);
    }
    
    notifyListeners();
    print('✅ ${_demoMessages.length} mensajes DEMO cargados');
  }

  /// ANÁLISIS Y ESTADÍSTICAS
  Map<String, dynamic> _calculateStats(List<SMSMessage> messages) {
    if (messages.isEmpty) {
      return {
        'total': 0,
        'dangerous': 0,
        'moderate': 0,
        'safe': 0,
        'dangerous_rate': 0,
      };
    }
    
    int dangerous = messages.where((m) => m.isDangerous).length;
    int moderate = messages.where((m) => m.isModerate).length;
    int safe = messages.where((m) => m.isSafe).length;
    
    return {
      'total': messages.length,
      'dangerous': dangerous,
      'moderate': moderate,
      'safe': safe,
      'dangerous_rate': (dangerous / messages.length * 100).round(),
    };
  }
  
  double _dangerousRate(List<SMSMessage> messages) {
    if (messages.isEmpty) return 0.0;
    int dangerous = messages.where((m) => m.isDangerous).length;
    return dangerous / messages.length;
  }
  
  double _calculateCorrelation() {
    double demoRate = _dangerousRate(_demoMessages);
    double realRate = _dangerousRate(_realMessages);
    
    if (demoRate == 0 || realRate == 0) return 0.0;
    
    return (1 - (demoRate - realRate).abs()).clamp(0.0, 1.0);
  }
  
  int _findFalsePositives() {
    return _realMessages.where((msg) {
      return msg.isDangerous && msg.suspiciousElements.length < 2;
    }).length;
  }
  
  int _findFalseNegatives() {
    return _realMessages.where((msg) {
      return msg.isSafe && 
             (msg.message.toLowerCase().contains('urgente') ||
              msg.message.toLowerCase().contains('suspendida'));
    }).length;
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

  void loadSMSMessages() {
    _loadDemoMessages();
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

  /// Mark messages from a specific sender as read
  void markMessagesAsRead(String sender) {
    // Find all messages from this sender and mark as read
    List<SMSMessage> senderMessages = _realMessages.where((msg) => msg.sender == sender).toList();

    for (var msg in senderMessages) {
      _readMessageIds.add(msg.id);
    }

    // Update badge
    _updateBadge();

    notifyListeners();
  }

  /// Mark a specific message as read
  void markMessageAsRead(String messageId) {
    _readMessageIds.add(messageId);
    _updateBadge();
    notifyListeners();
  }

  /// Mark messages from specific senders as unread
  void markMessagesAsUnread(List<String> senders) {
    // Find all messages from these senders and mark as unread
    for (String sender in senders) {
      List<SMSMessage> senderMessages = _realMessages.where((msg) => msg.sender == sender).toList();

      for (var msg in senderMessages) {
        _readMessageIds.remove(msg.id);
      }
    }

    // Update badge
    _updateBadge();

    notifyListeners();
  }

  /// Update the app badge with current unread count
  void _updateBadge() {
    print('🔔 Actualizando badge: $unreadCount mensajes no leídos');
    _badgeService.updateBadge(unreadCount);
  }

  /// Clear all read status (for testing)
  void clearReadStatus() {
    _readMessageIds.clear();
    _updateBadge();
    notifyListeners();
  }

  /// Delete conversations from specific senders (local database only)
  Future<void> deleteConversations(List<String> senders) async {
    try {
      for (String sender in senders) {
        // Find all messages from this sender
        List<SMSMessage> messagesToDelete = _realMessages.where((msg) => msg.sender == sender).toList();

        // Delete from local database
        for (var msg in messagesToDelete) {
          await _db.deleteMessage(msg.id);

          // Remove from read tracking if it was there
          _readMessageIds.remove(msg.id);
        }

        // Remove from in-memory list
        _realMessages.removeWhere((msg) => msg.sender == sender);
      }

      // Update badge count
      _updateBadge();

      notifyListeners();

      print('✅ Eliminadas ${senders.length} conversaciones de TuGuardian');
    } catch (e) {
      print('❌ Error eliminando conversaciones: $e');
      throw e;
    }
  }

  /// BLOCKED SENDERS FUNCTIONALITY

  /// Block a sender (hide their messages from view)
  Future<bool> blockSender(String sender, {String reason = 'Bloqueado por el usuario'}) async {
    bool success = await BlockedSendersService.blockSender(sender, reason: reason);
    if (success) {
      notifyListeners(); // Refresh UI to hide messages
    }
    return success;
  }

  /// Unblock a sender
  Future<bool> unblockSender(String sender) async {
    bool success = await BlockedSendersService.unblockSender(sender);
    if (success) {
      notifyListeners(); // Refresh UI to show messages again
    }
    return success;
  }

  /// Check if a sender is blocked
  Future<bool> isSenderBlocked(String sender) async {
    return await BlockedSendersService.isBlocked(sender);
  }

  /// Get list of all blocked senders
  Future<List<String>> getBlockedSenders() async {
    return await BlockedSendersService.getBlockedSenders();
  }

  /// Get reason why a sender was blocked
  Future<String?> getBlockReason(String sender) async {
    return await BlockedSendersService.getBlockReason(sender);
  }

  /// Get count of blocked senders
  Future<int> getBlockedSendersCount() async {
    return await BlockedSendersService.getBlockedCount();
  }

  /// Filter messages to exclude blocked senders
  List<SMSMessage> _filterBlockedSenders(List<SMSMessage> messages) {
    // If no blocked senders, return all messages
    if (BlockedSendersService.isCacheEmpty) {
      return messages;
    }

    // Filter out messages from blocked senders
    return messages.where((msg) {
      String normalized = BlockedSendersService.normalizeSender(msg.sender);
      return !BlockedSendersService.cachedBlockedSenders.contains(normalized);
    }).toList();
  }

  /// Get statistics about blocked senders
  Future<Map<String, dynamic>> getBlockingStats() async {
    return await BlockedSendersService.getBlockingStats();
  }
}