import '../shared/models/sms_message.dart';
import '../shared/models/conversation_message.dart';

class ConversationService {

  /// Build all conversations from SMS list
  static List<Conversation> buildConversations(List<SMSMessage> allSMS) {
    // Group SMS by sender
    Map<String, List<SMSMessage>> groupedBySender = {};

    for (var sms in allSMS) {
      if (!groupedBySender.containsKey(sms.sender)) {
        groupedBySender[sms.sender] = [];
      }
      groupedBySender[sms.sender]!.add(sms);
    }

    // Build conversation for each sender
    List<Conversation> conversations = [];

    groupedBySender.forEach((sender, smsList) {
      conversations.add(_buildConversation(sender, smsList));
    });

    // Sort by last message time (most recent first)
    conversations.sort((a, b) {
      if (a.lastMessageTime == null) return 1;
      if (b.lastMessageTime == null) return -1;
      return b.lastMessageTime!.compareTo(a.lastMessageTime!);
    });

    return conversations;
  }

  /// Build single conversation from SMS list
  static Conversation _buildConversation(String sender, List<SMSMessage> smsList) {
    List<ConversationMessage> messages = [];

    // Sort SMS chronologically
    smsList.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (var sms in smsList) {
      // Add SMS received message (with originalSMS for color coding)
      messages.add(ConversationMessage(
        id: '${sms.id}_sms',
        type: ConversationMessageType.SMS_RECEIVED,
        content: sms.message,
        timestamp: sms.timestamp,
        originalSMS: sms, // Add this to enable color coding
      ));

      // Add TuGuardian analysis message
      messages.add(ConversationMessage(
        id: '${sms.id}_analysis',
        type: ConversationMessageType.TUGUARDIAN_ANALYSIS,
        content: TuGuardianAnalysisBuilder.buildAnalysisMessage(sms),
        timestamp: sms.timestamp,
        originalSMS: sms,
      ));
    }

    return Conversation(
      sender: sender,
      messages: messages,
    );
  }

  /// Get conversation for specific sender
  static Conversation? getConversationForSender(String sender, List<SMSMessage> allSMS) {
    var smsList = allSMS.where((sms) => sms.sender == sender).toList();
    if (smsList.isEmpty) return null;

    return _buildConversation(sender, smsList);
  }
}
