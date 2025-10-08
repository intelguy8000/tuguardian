import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/sms_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/models/sms_message.dart';
import '../../shared/models/conversation_message.dart';
import '../../services/conversation_service.dart';
import '../../core/app_colors.dart';
import '../settings/settings_screen.dart';
import '../message_detail/message_detail_screen.dart';
import '../conversation/conversation_screen.dart';
import '../../shared/widgets/disclaimer_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // late TabController _tabController; // COMMENTED: For future CHAT tab implementation
  String _selectedFilter = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _readMessages = <String>{};
  Set<String> _readConversations = <String>{}; // Track read conversations by sender

  // Edit mode variables
  bool _isEditMode = false;
  Set<String> _selectedConversations = <String>{}; // Track selected conversations by sender

  @override
  void initState() {
    super.initState();
    // _tabController = TabController(length: 2, vsync: this); // COMMENTED: For future CHAT tab

    // Mostrar disclaimer la primera vez
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DisclaimerBottomSheet.showIfNeeded(context);
    });
  }

  @override
  void dispose() {
    // _tabController.dispose(); // COMMENTED: For future CHAT tab
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final smsProvider = Provider.of<SMSProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final unreadCount = smsProvider.unreadCount;

    print('🏠 HOME DEBUG: unreadCount=$unreadCount');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        elevation: 0,
        leading: Container(
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.only(left: 16),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isEditMode = !_isEditMode;
                if (!_isEditMode) {
                  // Clear selections when exiting edit mode
                  _selectedConversations.clear();
                }
              });
            },
            child: Text(
              _isEditMode ? 'Listo' : 'Editar',
              style: TextStyle(
                color: AppColors.primaryTech,
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          'TuGuardian',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.menu,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        // COMMENTED: TabBar for future CHAT tab implementation (Wickr-style)
        // bottom: PreferredSize(
        //   preferredSize: const Size.fromHeight(50),
        //   child: Container(
        //     decoration: BoxDecoration(
        //       border: Border(
        //         bottom: BorderSide(
        //           color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
        //         ),
        //       ),
        //     ),
        //     child: TabBar(
        //       controller: _tabController,
        //       labelColor: AppColors.primary,
        //       unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        //       indicatorColor: AppColors.primary,
        //       indicatorWeight: 3,
        //       indicatorSize: TabBarIndicatorSize.tab,
        //       labelStyle: const TextStyle(
        //         fontSize: 16,
        //         fontWeight: FontWeight.w600,
        //       ),
        //       unselectedLabelStyle: const TextStyle(
        //         fontSize: 16,
        //         fontWeight: FontWeight.w500,
        //       ),
        //       tabs: const [
        //         Tab(text: 'SMS'),
        //         Tab(text: 'CHAT'),
        //       ],
        //     ),
        //   ),
        // ),
      ),
      body: _buildConversationsTab(isDark), // Show only SMS conversations (CHAT tab commented for future)
      // COMMENTED: TabBarView for future CHAT tab implementation (Wickr-style)
      // body: TabBarView(
      //   controller: _tabController,
      //   children: [
      //     _buildConversationsTab(isDark), // SMS tab shows conversations
      //     _buildChatTab(isDark), // Chat tab for future secure chat
      //   ],
      // ),
      bottomNavigationBar: _isEditMode ? _buildEditModeToolbar(isDark) : null,
    );
  }

  /// Build toolbar for edit mode with actions
  Widget _buildEditModeToolbar(bool isDark) {
    final smsProvider = Provider.of<SMSProvider>(context, listen: false);
    int selectedCount = _selectedConversations.length;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
          // Mark as Read button
          _buildToolbarButton(
            icon: Icons.mark_email_read_outlined,
            label: 'Leído',
            enabled: selectedCount > 0,
            onTap: () {
              for (String sender in _selectedConversations) {
                smsProvider.markMessagesAsRead(sender);
                _readConversations.add(sender);
              }
              setState(() {
                _selectedConversations.clear();
                _isEditMode = false;
              });
            },
            isDark: isDark,
          ),

          // Mark as Unread button
          _buildToolbarButton(
            icon: Icons.mark_email_unread_outlined,
            label: 'No leído',
            enabled: selectedCount > 0,
            onTap: () {
              // Remove from read conversations locally
              for (String sender in _selectedConversations) {
                _readConversations.remove(sender);
              }

              // Mark as unread in provider (updates badge)
              smsProvider.markMessagesAsUnread(_selectedConversations.toList());

              setState(() {
                _selectedConversations.clear();
                _isEditMode = false;
              });
            },
            isDark: isDark,
          ),

          // Delete button
          _buildToolbarButton(
            icon: Icons.delete_outline,
            label: 'Eliminar',
            enabled: selectedCount > 0,
            onTap: () => _showDeleteConfirmation(isDark),
            isDark: isDark,
            isDestructive: true,
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    final color = !enabled
        ? Colors.grey.shade400
        : isDestructive
            ? Colors.red
            : AppColors.primaryTech;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar ${_selectedConversations.length} conversaciones'),
        content: const Text(
          'Estas conversaciones se eliminarán solo de TuGuardian. Los mensajes permanecerán en otras apps de SMS.\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Get provider from context
              final smsProvider = Provider.of<SMSProvider>(context, listen: false);

              // Delete conversations from TuGuardian database
              await smsProvider.deleteConversations(_selectedConversations.toList());

              // Also remove from local read tracking
              for (String sender in _selectedConversations) {
                _readConversations.remove(sender);
              }

              setState(() {
                _selectedConversations.clear();
                _isEditMode = false;
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversaciones eliminadas de TuGuardian'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSMSTab(bool isDark) {
    return Column(
      children: [
        // Filtros horizontales - CORREGIDOS
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFilterChip('Todos', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('🎭 Demo', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('🔴 Real', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('Peligrosos', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('Seguros', isDark),
            ],
          ),
        ),
        
        Expanded(
          child: Consumer<SMSProvider>(
            builder: (context, smsProvider, child) {
              List<SMSMessage> filteredMessages = _getFilteredMessages(smsProvider.allMessages);
              
              if (filteredMessages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 64,
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay mensajes',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: filteredMessages.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                  indent: 80,
                ),
                itemBuilder: (context, index) {
                  final message = filteredMessages[index];
                  return _buildMessageRow(message, isDark);
                },
              );
            },
          ),
        ),
        
        SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.grey.shade50,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryTech,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    onPressed: () {
                      final smsProvider = Provider.of<SMSProvider>(context, listen: false);
                      smsProvider.simulateThreatSMS(context);
                    },
                    icon: const Icon(
                      Icons.warning,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageRow(SMSMessage message, bool isDark) {
    // CORREGIDO: Umbral correcto para amenazas
    final isThreat = message.riskScore >= 40; // Cambio crítico
    final isUnread = !_readMessages.contains(message.id);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _readMessages.add(message.id);
        });
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageDetailScreen(message: message),
          ),
        );
      },
      child: Container(
        color: isDark ? AppColors.darkBackground : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Punto azul iOS
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isUnread ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            
            // Avatar con borde rojo si es amenaza
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(25),
                    border: isThreat ? Border.all(
                      color: Colors.red,
                      width: 3, // Más grueso
                    ) : null,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                // Badge DEMO/REAL en la esquina
                if (message.isDemo || message.riskScore >= 40)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: message.isDemo ? Colors.purple : Colors.red,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          message.isDemo ? 'D' : '!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Badge DEMO/REAL
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: message.isDemo ? Colors.purple[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: message.isDemo ? Colors.purple : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          message.badge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: message.isDemo ? Colors.purple[800] : Colors.red[800],
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          message.sender,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        message.timeAgo,
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade400,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsTab(bool isDark) {
    return Consumer<SMSProvider>(
      builder: (context, smsProvider, child) {
        // Build conversations from all messages
        List<Conversation> conversations = ConversationService.buildConversations(
          smsProvider.allMessages,
        );

        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay conversaciones',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return Scrollbar(
          thickness: 8,
          radius: Radius.circular(4),
          thumbVisibility: false,
          child: ListView.separated(
            padding: EdgeInsets.only(top: 8, bottom: 160), // Extra bottom padding for Samsung nav bar
            itemCount: conversations.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
              indent: 70,
            ),
            itemBuilder: (context, index) {
              return _buildConversationRow(conversations[index], isDark);
            },
          ),
        );
      },
    );
  }

  Widget _buildConversationRow(Conversation conversation, bool isDark) {
    // Check if conversation is unread
    bool isUnread = !_readConversations.contains(conversation.sender);

    // Get the actual SMS content for preview (not TuGuardian's analysis)
    String previewMessage = '';
    if (conversation.messages.isNotEmpty) {
      // Find the last SMS_RECEIVED message (not TuGuardian analysis)
      for (int i = conversation.messages.length - 1; i >= 0; i--) {
        if (conversation.messages[i].isFromSender) {
          previewMessage = conversation.messages[i].content;
          break;
        }
      }
    }

    // Determine border color based on risk (OPTION A: only red for dangerous, neutral for everything else)
    Color? borderColor;
    if (conversation.hasDangerousMessages) {
      borderColor = Colors.red; // Only red for dangerous (score >= 70)
    } else {
      borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300; // Neutral gray for moderate + safe
    }

    bool isSelected = _selectedConversations.contains(conversation.sender);

    return GestureDetector(
      onTap: () {
        if (_isEditMode) {
          // In edit mode, toggle selection
          setState(() {
            if (isSelected) {
              _selectedConversations.remove(conversation.sender);
            } else {
              _selectedConversations.add(conversation.sender);
            }
          });
        } else {
          // Normal mode: open conversation
          final smsProvider = Provider.of<SMSProvider>(context, listen: false);

          // Mark as read when tapped
          setState(() {
            _readConversations.add(conversation.sender);
          });

          // Mark messages as read in provider (updates badge)
          smsProvider.markMessagesAsRead(conversation.sender);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationScreen(conversation: conversation),
            ),
          );
        }
      },
      child: Container(
        color: isDark ? AppColors.darkBackground : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Checkbox in edit mode OR Blue dot in normal mode
            if (_isEditMode)
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.shade400,
                    width: 2,
                  ),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              )
            else
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isUnread ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

            // Avatar with colored border (red/orange/green)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: borderColor,
                  width: 2.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Conversation info (iOS style: sender + time on same line, then preview)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.sender,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.lastMessageTime != null)
                        Text(
                          _formatConversationTime(conversation.lastMessageTime!),
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    previewMessage.isEmpty ? 'Sin mensajes' : previewMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  String _formatConversationTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      return 'Ayer';
    } else if (now.difference(timestamp).inDays < 7) {
      final weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return weekdays[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year % 100}';
    }
  }

  Widget _buildChatTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chat Seguro',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mensajería cifrada end-to-end\nPróximamente disponible',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary 
              : (isDark ? AppColors.darkCard : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? Colors.white 
                : (isDark ? Colors.white : Colors.black),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // CORREGIDO: Filtros con umbrales correctos
  List<SMSMessage> _getFilteredMessages(List<SMSMessage> messages) {
    List<SMSMessage> filtered = messages;

    switch (_selectedFilter) {
      case '🎭 Demo':
        filtered = filtered.where((m) => m.isDemo).toList();
        break;
      case '🔴 Real':
        filtered = filtered.where((m) => !m.isDemo).toList();
        break;
      case 'Peligrosos':
        filtered = filtered.where((m) => m.riskScore >= 40).toList(); // CORREGIDO
        break;
      case 'Seguros':
        filtered = filtered.where((m) => m.riskScore < 40).toList(); // CORREGIDO
        break;
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((m) =>
          m.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.sender.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return filtered;
  }
}