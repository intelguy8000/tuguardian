import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/models/conversation_message.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/widgets/message_bubble.dart';
import '../../core/app_colors.dart';

/// Conversation screen showing SMS + TuGuardian responses in chat format
class ConversationScreen extends StatefulWidget {
  final Conversation conversation;

  const ConversationScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Avatar with colored border (like in conversation list)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _getBorderColor(),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 12),

            // Sender info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.sender,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.conversation.hasDangerousMessages)
                    Text(
                      '${widget.conversation.dangerousMessageCount} amenazas bloqueadas',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // More options
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.white : Colors.black,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20),
                    SizedBox(width: 8),
                    Text('Bloquear número'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 20),
                    SizedBox(width: 8),
                    Text('Reportar spam'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'block') {
                _showBlockDialog();
              } else if (value == 'report') {
                _showReportDialog();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Divider
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.conversation.messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(
                  message: widget.conversation.messages[index],
                );
              },
            ),
          ),

          // Message input (for future send functionality)
          _buildMessageInput(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            // Text input
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enviar mensaje...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),

            SizedBox(width: 8),

            // Send button
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () {
                  // TODO: Implement send SMS functionality
                  if (_messageController.text.trim().isNotEmpty) {
                    _showComingSoonDialog();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Bloquear número?'),
        content: Text(
          '¿Deseas bloquear ${widget.conversation.sender}?\n\n'
          'No recibirás más mensajes de este número.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🚫 Número bloqueado'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Bloquear'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reportar spam'),
        content: Text(
          '¿Reportar ${widget.conversation.sender} como spam?\n\n'
          'Esto ayudará a mejorar la detección para todos los usuarios.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Spam reportado. Gracias por tu ayuda.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text('Reportar'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🚧 Próximamente'),
        content: Text(
          'La función de enviar SMS estará disponible pronto.\n\n'
          'Por ahora TuGuardian protege tus mensajes recibidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (widget.conversation.hasDangerousMessages) {
      return Colors.red;
    }

    // Check if has moderate messages
    bool hasModerate = widget.conversation.messages.any((msg) =>
      msg.originalSMS?.isModerate ?? false
    );

    if (hasModerate) {
      return Colors.orange;
    }

    // Safe messages - neutral gray
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
  }
}
