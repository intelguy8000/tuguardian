import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/conversation_message.dart';
import '../providers/theme_provider.dart';
import '../../core/app_colors.dart';
import 'protected_text_widget.dart';
import 'tuguardian_analysis_widget.dart';

/// Chat bubble widget that displays SMS or TuGuardian messages
class MessageBubble extends StatelessWidget {
  final ConversationMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (message.isFromTuGuardian) {
      return _buildTuGuardianBubble(isDark);
    } else if (message.isFromSender) {
      return _buildSMSBubble(isDark);
    } else {
      // SMS_SENT (user sent)
      return _buildUserSentBubble(isDark);
    }
  }

  /// TuGuardian analysis bubble (left side, with shield icon)
  Widget _buildTuGuardianBubble(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TuGuardian avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 8),

          // Message bubble
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getBackgroundColor(isDark),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(
                  color: _getBorderColor(isDark),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TuGuardian label
                  Row(
                    children: [
                      Text(
                        'TuGuardian',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _getLabelColor(),
                        ),
                      ),
                      SizedBox(width: 4),
                      _getRiskBadge(),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Analysis content with interactive buttons
                  if (message.originalSMS != null)
                    TuGuardianAnalysisWidget(
                      sms: message.originalSMS!,
                      baseStyle: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                    )
                  else
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                    ),

                  // Timestamp
                  SizedBox(height: 6),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// SMS received bubble (right side, with sender)
  Widget _buildSMSBubble(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Message bubble
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SMS content with link protection
                  ProtectedTextWidget(
                    text: message.content,
                    originalSMS: message.originalSMS,
                    isDangerousMessage: message.originalSMS?.isDangerous ?? false,
                    baseStyle: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),

                  // Timestamp
                  SizedBox(height: 6),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: 8),

          // SMS icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sms,
              color: isDark ? Colors.white : Colors.black54,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// User sent SMS bubble (left side, blue)
  Widget _buildUserSentBubble(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 8),

          // Message bubble
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(
                  color: Colors.blue.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(bool isDark) {
    if (message.originalSMS?.isDangerous ?? false) {
      return isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50;
    }
    if (message.originalSMS?.isModerate ?? false) {
      return isDark ? Colors.orange.shade900.withOpacity(0.3) : Colors.orange.shade50;
    }
    return isDark ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50;
  }

  Color _getBorderColor(bool isDark) {
    if (message.originalSMS?.isDangerous ?? false) {
      return Colors.red.shade400;
    }
    if (message.originalSMS?.isModerate ?? false) {
      return Colors.orange.shade400;
    }
    return Colors.green.shade400;
  }

  Color _getLabelColor() {
    if (message.originalSMS?.isDangerous ?? false) {
      return Colors.red.shade700;
    }
    if (message.originalSMS?.isModerate ?? false) {
      return Colors.orange.shade700;
    }
    return Colors.green.shade700;
  }

  Widget _getRiskBadge() {
    if (message.originalSMS?.isDangerous ?? false) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '🚫 BLOQUEADO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }
    if (message.originalSMS?.isModerate ?? false) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade600,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '⚠️ CUIDADO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '✅ SEGURO',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      return 'Ayer ${DateFormat('HH:mm').format(timestamp)}';
    } else if (now.difference(timestamp).inDays < 7) {
      // Use weekday names without locale to avoid LocaleDataException
      final weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return '${weekdays[timestamp.weekday - 1]} ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      return DateFormat('dd/MM/yy HH:mm').format(timestamp);
    }
  }
}
