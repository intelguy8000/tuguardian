import 'sms_message.dart';

/// Type of message in conversation
enum ConversationMessageType {
  SMS_RECEIVED,       // SMS recibido del remitente
  TUGUARDIAN_ANALYSIS, // Análisis de TuGuardian
  SMS_SENT,          // SMS enviado por el usuario
}

/// Message in a conversation (can be SMS or TuGuardian response)
class ConversationMessage {
  final String id;
  final ConversationMessageType type;
  final String content;
  final DateTime timestamp;
  final SMSMessage? originalSMS; // Si es análisis, referencia al SMS original

  ConversationMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    this.originalSMS,
  });

  bool get isFromUser => type == ConversationMessageType.SMS_SENT;
  bool get isFromSender => type == ConversationMessageType.SMS_RECEIVED;
  bool get isFromTuGuardian => type == ConversationMessageType.TUGUARDIAN_ANALYSIS;
}

/// Conversation with a specific sender
class Conversation {
  final String sender;
  final List<ConversationMessage> messages;

  Conversation({
    required this.sender,
    required this.messages,
  });

  /// Get last message in conversation
  ConversationMessage? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.last;
  }

  /// Get timestamp of last message
  DateTime? get lastMessageTime {
    return lastMessage?.timestamp;
  }

  /// Check if conversation has any dangerous messages
  bool get hasDangerousMessages {
    return messages.any((msg) =>
      msg.isFromTuGuardian &&
      msg.originalSMS != null &&
      msg.originalSMS!.isDangerous
    );
  }

  /// Count of dangerous messages
  int get dangerousMessageCount {
    return messages.where((msg) =>
      msg.isFromTuGuardian &&
      msg.originalSMS != null &&
      msg.originalSMS!.isDangerous
    ).length;
  }

  /// Get preview text for conversation list
  String get previewText {
    if (lastMessage == null) return '';

    if (lastMessage!.isFromTuGuardian) {
      // Show TuGuardian's analysis
      if (lastMessage!.originalSMS?.isDangerous ?? false) {
        return 'TuGuardian bloqueó este mensaje';
      } else if (lastMessage!.originalSMS?.isModerate ?? false) {
        return 'Mensaje sospechoso - Verifica antes de actuar';
      } else {
        return 'Mensaje seguro';
      }
    }

    // Show SMS content (truncated)
    return lastMessage!.content.length > 50
        ? '${lastMessage!.content.substring(0, 50)}...'
        : lastMessage!.content;
  }

  /// Get badge icon for conversation
  String get badgeIcon {
    if (hasDangerousMessages) return '🔴';

    // Check if has moderate messages
    bool hasModerate = messages.any((msg) =>
      msg.originalSMS?.isModerate ?? false
    );

    if (hasModerate) return '⚠️';
    return '✅';
  }
}

/// Helper to build TuGuardian analysis message
class TuGuardianAnalysisBuilder {

  /// Build analysis message content based on SMS risk
  static String buildAnalysisMessage(SMSMessage sms) {
    if (sms.isDangerous) {
      return _buildDangerousAnalysis(sms);
    } else if (sms.isModerate) {
      return _buildModerateAnalysis(sms);
    } else {
      return _buildSafeAnalysis(sms);
    }
  }

  static String _buildDangerousAnalysis(SMSMessage sms) {
    List<String> reasons = [];

    if (sms.intentAnalysis != null) {
      var intents = sms.intentAnalysis!.detectedIntents;

      if (intents.any((i) => i.toString().contains('FINANCIAL'))) {
        reasons.add('💰 Solicita acción financiera');
      }
      if (intents.any((i) => i.toString().contains('CREDENTIAL'))) {
        reasons.add('🔐 Solicita credenciales');
      }
      if (intents.any((i) => i.toString().contains('URGENCY'))) {
        reasons.add('⚡ Presión de urgencia');
      }
    }

    if (sms.suspiciousElements.isNotEmpty) {
      reasons.add('🔗 Link sospechoso');
    }

    String reasonsText = reasons.join('\n');

    // No mostrar canales de entidades - podemos detectar incorrectamente
    // El mensaje es peligroso, la acción correcta es ignorarlo
    return '🚫 Bloqueé este mensaje\n\n$reasonsText\n🔴 Muy Peligroso';
  }

  static String _buildModerateAnalysis(SMSMessage sms) {
    String warning = '🟡 Sospechoso\n\n';
    warning += 'Verifica antes de actuar';

    return warning;
  }

  static String _buildSafeAnalysis(SMSMessage sms) {
    if (sms.detectedEntities != null && sms.detectedEntities!.isNotEmpty) {
      return '✅ Mensaje seguro\n🔗 Link oficial verificado';
    }
    return '📬 Notificación sin riesgo';
  }
}
