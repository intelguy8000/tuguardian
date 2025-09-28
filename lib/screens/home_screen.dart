import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sms_provider.dart';
import '../providers/theme_provider.dart';
import '../models/sms_message.dart';
import '../core/app_colors.dart';
import 'settings_screen.dart';
import 'message_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // Simular mensajes leídos/no leídos
  Set<String> _readMessages = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Solo SMS y CHAT
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
        leading: Container(
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.only(left: 16),
          child: GestureDetector(
            onTap: () {},
            child: Text(
              'Editar',
              style: TextStyle(
                color: AppColors.primaryTech,
                fontSize: 17,
                fontWeight: FontWeight.w400,
      ),
    ),
  ),
),
leadingWidth: 80, // Agregar esta línea después del leading
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab, // Línea completa bajo cada tab
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'SMS'),
                Tab(text: 'CHAT'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSMSTab(isDark),
          _buildChatTab(isDark),
        ],
      ),
    );
  }

  Widget _buildSMSTab(bool isDark) {
    return Column(
      children: [
        // Filtros horizontales
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFilterChip('Todos', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('Mensajes', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('Amenazas', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('Seguros', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('Spam', isDark),
            ],
          ),
        ),
        
        // Lista de mensajes estilo iOS Messages
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
        
        // Barra de búsqueda inferior
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
                  color: AppColors.primaryTech, // Azul tecnológico
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Composer próximamente'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageRow(SMSMessage message, bool isDark) {
    final isThreat = message.riskScore >= 70;
    // Lógica de leído/no leído
    final isUnread = !_readMessages.contains(message.id);
    
    return GestureDetector(
      onTap: () {
        // Marcar como leído al hacer tap
        setState(() {
          _readMessages.add(message.id);
        });
        
        // Navegar a vista detalle SIEMPRE - la lógica de amenaza está ahí
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
            // PUNTO AZUL ESTILO iOS - AL INICIO DE LA FILA (IZQUIERDA DEL AVATAR)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isUnread ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            
            // Avatar circular - AZUL CLARO ARMONIZADO
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryLight, // Azul claro armonizado
                borderRadius: BorderRadius.circular(25),
                border: isThreat ? Border.all(
                  color: Colors.red,
                  width: 2,
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
            const SizedBox(width: 12),
            
            // Contenido del mensaje
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila superior: Nombre y hora
                  Row(
                    children: [
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
                        _formatTime(message.timestamp),
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
                  
                  // Contenido del mensaje
                  Text(
                    message.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  // REMOVIDO EL BADGE DE RIESGO
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              'Estilo Wickr Me - En desarrollo',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
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

  List<SMSMessage> _getFilteredMessages(List<SMSMessage> messages) {
    List<SMSMessage> filtered = messages;

    switch (_selectedFilter) {
      case 'Amenazas':
        filtered = filtered.where((m) => m.riskScore >= 70).toList();
        break;
      case 'Seguros':
        filtered = filtered.where((m) => m.riskScore < 30).toList();
        break;
      case 'Spam':
        filtered = filtered.where((m) => m.riskScore >= 50 && m.riskScore < 70).toList();
        break;
      case 'Mensajes':
        filtered = filtered.where((m) => m.riskScore < 50).toList();
        break;
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((m) =>
          m.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.sender.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return filtered;
  }

  Color _getRiskColor(int riskScore) {
    if (riskScore >= 70) return Colors.red;
    if (riskScore >= 50) return Colors.orange;
    if (riskScore >= 30) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  // INTERCEPTOR DE AMENAZAS - GUARDIAN DE SEGURIDAD
  void _showThreatInterceptor(SMSMessage message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.shield,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'TuGuardian te protege',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text(
                '🚨 Hemos bloqueado este link sospechoso',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Detectamos que este mensaje contiene:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            ...message.suspiciousElements.map((element) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: Colors.red, fontSize: 16)),
                  Expanded(
                    child: Text(
                      element,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Te guiamos al sitio oficial',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getSafeGuidance(message.sender),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Ignorar mensaje',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSafeGuidance(message.sender);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ir al sitio oficial',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _getSafeGuidance(String sender) {
    if (sender.contains('CLARO') || sender.contains('Claro')) {
      return 'Para revisar tu factura Claro de forma segura, te llevamos al portal oficial mi.claro.com.co';
    }
    if (sender.contains('banco') || sender.contains('Banco')) {
      return 'Para verificar tu cuenta bancaria, utiliza la app oficial de tu banco o visita una sucursal';
    }
    if (sender.contains('INTER') || sender.toLowerCase().contains('rapidisimo')) {
      return 'Para rastrear envíos de Interrápidísimo, visita su sitio oficial interrapidisimo.com';
    }
    return 'Te ayudamos a contactar la empresa por canales oficiales y seguros';
  }

  void _showSafeGuidance(String sender) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Redirigiendo al sitio oficial seguro...'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}