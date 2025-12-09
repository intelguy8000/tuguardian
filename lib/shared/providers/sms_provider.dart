import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/sms_message.dart';
import '../../services/detection_service.dart';
import '../../services/sms_listener_service.dart';
import '../../services/database_service.dart';
import '../../services/badge_service.dart';
import '../../services/blocked_senders_service.dart';
import '../../services/hidden_messages_service.dart';

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
    _autoEnableRealMode(); // Auto-enable real-time protection
    BlockedSendersService.initialize(); // Initialize blocked senders
    HiddenMessagesService.initialize(); // Initialize hidden messages tracking
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

  /// Check if a message is read
  bool isMessageRead(String messageId) {
    return _readMessageIds.contains(messageId);
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

  /// Delete conversations from specific senders (persists across app restarts)
  Future<void> deleteConversations(List<String> senders) async {
    try {
      for (String sender in senders) {
        // 1. PERSISTIR: Marcar sender como oculto (sobrevive reinicios)
        await HiddenMessagesService.hideSender(sender);

        // 2. Limpiar tracking de lectura
        List<SMSMessage> messagesToDelete = _realMessages.where((msg) => msg.sender == sender).toList();
        for (var msg in messagesToDelete) {
          _readMessageIds.remove(msg.id);
        }

        // 3. Remover de memoria para efecto inmediato
        _realMessages.removeWhere((msg) => msg.sender == sender);
      }

      // Update badge count
      _updateBadge();

      notifyListeners();

      print('✅ Eliminadas ${senders.length} conversaciones de TuGuardian (persistente)');
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