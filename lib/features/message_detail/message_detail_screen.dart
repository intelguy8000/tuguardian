import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/providers/sms_provider.dart';
import '../../shared/models/sms_message.dart';
import '../../core/app_colors.dart';
import '../../detection/entities/official_entities_service.dart';

class MessageDetailScreen extends StatefulWidget {
  final SMSMessage message;

  const MessageDetailScreen({
    super.key,
    required this.message,
  });

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _replyController = TextEditingController();
  bool _isUnlocked = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isThreat = widget.message.isQuarantined || widget.message.isDangerous;
    final hasCallToAction = widget.message.suspiciousElements.isNotEmpty;
    final isVerification = _isVerificationMessage();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.primary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.message.sender,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isThreat)
              Text(
                'Mensaje Bloqueado',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            if (isVerification)
              Text(
                'Verificación Bancaria',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.primary),
            onSelected: (value) async {
              if (value == 'block') {
                await _blockSender(context);
              } else if (value == 'info') {
                _showMessageInfo();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Información del mensaje'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Bloquear remitente', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              _formatDate(widget.message.timestamp),
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildIncomingMessage(isDark, isThreat, isVerification),
                  const SizedBox(height: 16),
                  if (isThreat || hasCallToAction || isVerification)
                    _buildTuGuardianResponse(isDark, isThreat, isVerification),
                ],
              ),
            ),
          ),

          // Campo de respuesta estilo iOS
          _buildReplyField(isDark, isThreat),
        ],
      ),
    );
  }
  List<Widget> _buildIntegratedOfficialChannels() {
    List<Widget> widgets = [];
    
    for (var suggestion in widget.message.officialSuggestions ?? []) {
      // Nombre de la entidad
      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.business, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                suggestion.entityName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'VERIFICADO',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      
      widgets.add(const SizedBox(height: 8));
      
      // Botones de canales
      List<Widget> buttons = [];
      for (var channel in suggestion.channels) {
        switch (channel.type) {
          case ContactChannelType.whatsapp:
            buttons.add(
              Expanded(
                child: _buildIntegratedChannelButton(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => _openWhatsApp(context, channel.action, suggestion.entityName),
                ),
              ),
            );
            break;
          case ContactChannelType.website:
            buttons.add(
              Expanded(
                child: _buildIntegratedChannelButton(
                  icon: Icons.language,
                  label: 'Web',
                  color: Colors.white.withOpacity(0.9),
                  onTap: () => _openWebsite(context, channel.action, suggestion.entityName),
                ),
              ),
            );
            break;
          case ContactChannelType.app:
            buttons.add(
              Expanded(
                child: _buildIntegratedChannelButton(
                  icon: Icons.phone_android,
                  label: 'App',
                  color: const Color(0xFF8E24AA),
                  onTap: () => _showAppSuggestion(context, suggestion.entityName),
                ),
              ),
            );
            break;
        }
        
        if (buttons.length < suggestion.channels.length) {
          buttons.add(const SizedBox(width: 6));
        }
      }
      
      widgets.add(
        Row(children: buttons),
      );
    }
    
    return widgets;
  }

  Widget _buildIntegratedChannelButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color == Colors.white.withOpacity(0.9) ? AppColors.primary : Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color == Colors.white.withOpacity(0.9) ? AppColors.primary : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openWhatsApp(BuildContext context, String whatsappUrl, String entityName) async {
    try {
      final Uri url = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Abriendo WhatsApp oficial de $entityName'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _openWebsite(BuildContext context, String websiteUrl, String entityName) async {
    try {
      final Uri url = Uri.parse(websiteUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🌐 Abriendo página oficial de $entityName'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAppSuggestion(BuildContext context, String entityName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('App Oficial de $entityName'),
        content: Text('Para mayor seguridad, consulta en la app oficial de $entityName.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  bool _isVerificationMessage() {
    return widget.message.suspiciousElements.any(
      (element) => element.contains('Verificación bancaria legítima detectada')
    );
  }

  Widget _buildIncomingMessage(bool isDark, bool isThreat, bool isVerification) {
    Color containerColor;
    Border? containerBorder;

    if (isThreat) {
      // Mensaje peligroso: rojo suave con borde rojo
      containerColor = isDark ? Color(0xFF4A2020) : Color(0xFFFFEBEE);
      containerBorder = Border.all(
        color: isDark ? Color(0xFFE57373) : Color(0xFFEF5350),
        width: 2
      );
    } else if (isVerification) {
      containerColor = isDark ? Colors.orange.shade900.withOpacity(0.3) : Colors.orange.shade50;
      containerBorder = Border.all(color: Colors.orange.shade200, width: 1);
    } else {
      containerColor = isDark ? AppColors.darkCard : Colors.grey.shade200;
      containerBorder = null;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Stack(
            children: [
              // Mensaje real
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                    bottomLeft: Radius.circular(4),
                  ),
                  border: containerBorder,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isThreat) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.shield,
                            color: isDark ? Color(0xFF90CAF9) : Color(0xFF1976D2),
                            size: 14
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'TuGuardian bloqueó este mensaje',
                            style: TextStyle(
                              color: isDark ? Color(0xFF90CAF9) : Color(0xFF1976D2),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (isVerification) ...[
                      Row(
                        children: [
                          Icon(Icons.verified_user, color: Colors.orange, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Verificación bancaria detectada',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Para mensajes peligrosos: texto plano sin auto-link
                    // Para mensajes seguros: texto seleccionable
                    Text(
                      widget.message.message,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Capa invisible que bloquea TODOS los toques si es peligroso
              // IMPORTANTE: Este DEBE capturar los clicks ANTES que el sistema Android
              if (isThreat)
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showThreatWarning(),
                      onLongPress: () => _showThreatWarning(),
                      child: Container(),
                    ),
                  ),
                ),
              // GestureDetector para mensajes NO peligrosos
              if (!isThreat)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onLongPress: () => _showMessageOptions(isDark),
                    child: Container(color: Colors.transparent),
                  ),
                ),
            ],
          ),
          ),
        const Spacer(),
      ],
    );
  }

  Widget _buildTuGuardianResponse(bool isDark, bool isThreat, bool isVerification) {
    String responseText;
    String? intentSummary;

    // Use intent analysis if available
    if (widget.message.intentAnalysis != null) {
      responseText = widget.message.intentAnalysis!.userGuidance;
      intentSummary = widget.message.intentAnalysis!.intentSummary;
    } else if (isVerification) {
      responseText = 'Parece verificación legítima. Si reconoces la transacción, responde normalmente.';
    } else if (isThreat) {
      responseText = 'Amenaza detectada. Usa solo canales oficiales verificados.';
    } else {
      responseText = 'Verificación recomendada. Usa enlaces oficiales.';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Spacer(),
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  // Azul pastel en light mode, azul más fuerte en dark mode
                  color: isDark ? Color(0xFF1565C0) : Color(0xFFBBDEFB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intent badge if available
                    if (intentSummary != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Color(0xFF1976D2).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          intentSummary,
                          style: TextStyle(
                            color: isDark ? Colors.white : Color(0xFF0D47A1),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield,
                          color: isDark ? Colors.white : Color(0xFF0D47A1),
                          size: 18
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            responseText,
                            style: TextStyle(
                              color: isDark ? Colors.white : Color(0xFF0D47A1),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),

                    // Integrar widget de canales oficiales DENTRO del mensaje
                    if (widget.message.isQuarantined && widget.message.hasOfficialSuggestions) ...[
                      const SizedBox(height: 12),
                      ..._buildIntegratedOfficialChannels(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'TuGuardian • ${_formatTime(DateTime.now())}',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReplyField(bool isDark, bool isThreat) {
    final canReply = !isThreat || _isUnlocked;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Quick Reply Buttons (solo si puede responder)
            if (canReply) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      _buildQuickReplyButton('SÍ', isDark),
                      const SizedBox(width: 8),
                      _buildQuickReplyButton('NO', isDark),
                      const SizedBox(width: 8),
                      _buildQuickReplyButton('Más tarde', isDark),
                      const SizedBox(width: 8),
                      _buildQuickReplyButton('Gracias', isDark),
                    ],
                  ),
                ),
              ),
            ],

            if (isThreat && !_isUnlocked) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mensaje bloqueado. Desbloquea para responder.',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _showUnlockDialog,
                      child: Text('Desbloquear'),
                    ),
                  ],
                ),
              ),
            ],
            
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: canReply ? AppColors.primary : Colors.grey,
                  ),
                  onPressed: canReply ? () {} : null,
                ),
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
                      controller: _replyController,
                      enabled: canReply,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        color: canReply 
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.grey,
                      ),
                      decoration: InputDecoration(
                        hintText: canReply ? 'Mensaje de texto • SMS' : 'Bloqueado',
                        hintStyle: TextStyle(
                          color: canReply 
                            ? (isDark ? Colors.grey.shade400 : Colors.grey.shade500)
                            : Colors.grey.shade400,
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
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: canReply ? AppColors.primary : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: canReply && !_isSending ? _sendReply : null,
                    icon: _isSending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlockDialog() {
    bool acknowledgeRisk = false;
    bool sliderCompleted = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text('Desbloquear mensaje peligroso'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Este mensaje fue bloqueado por contener elementos maliciosos.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              
              CheckboxListTile(
                value: acknowledgeRisk,
                onChanged: (value) {
                  setDialogState(() {
                    acknowledgeRisk = value ?? false;
                  });
                },
                title: Text(
                  'Entiendo los riesgos y quiero proceder bajo mi responsabilidad',
                  style: TextStyle(fontSize: 13),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              
              if (acknowledgeRisk) ...[
                const SizedBox(height: 16),
                Text(
                  'Desliza para confirmar:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                GestureDetector(
                  onPanUpdate: (details) {
                    if (details.localPosition.dx > 200) {
                      setDialogState(() => sliderCompleted = true);
                    }
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: sliderCompleted ? Colors.red : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            sliderCompleted ? 'Mensaje desbloqueado' : 'Desliza para continuar',
                            style: TextStyle(
                              color: sliderCompleted ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 2,
                          top: 2,
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(23),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey.shade600,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            if (sliderCompleted)
              ElevatedButton(
                onPressed: () {
                  setState(() => _isUnlocked = true);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mensaje desbloqueado. Procede con precaución.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Desbloquear', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    // Abrir app SMS del sistema con texto pre-llenado
    await _openSMSApp(text);
  }

  Future<void> _openSMSApp(String prefilledText) async {
    final uri = Uri(
      scheme: 'sms',
      path: widget.message.sender,
      queryParameters: prefilledText.isNotEmpty
        ? {'body': prefilledText}
        : null,
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📱 Abriendo tu app de mensajes...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Limpiar el campo después de abrir
        _replyController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la app de mensajes'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Quick reply con texto predefinido
  Future<void> _quickReply(String text) async {
    _replyController.text = text;
    await _openSMSApp(text);
  }

  Widget _buildQuickReplyButton(String text, bool isDark) {
    return OutlinedButton(
      onPressed: () => _quickReply(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white : AppColors.primary,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.primary.withOpacity(0.5),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showMoreOptions(bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Más opciones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics, color: Colors.grey.shade700, size: 20),
              ),
              title: Text('Ver detalles técnicos'),
              subtitle: Text('Información sobre el análisis de este mensaje'),
              onTap: () {
                Navigator.pop(context);
                _showTechnicalDetails();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showTechnicalDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Análisis de Seguridad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riesgo detectado: ${widget.message.riskScore}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.message.isQuarantined ? Colors.red.shade800 : Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.message.suspiciousElements.isNotEmpty) ...[
              ...widget.message.suspiciousElements.map((element) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: Colors.red, fontSize: 16)),
                      Expanded(
                        child: Text(
                          element,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Este mensaje no presenta elementos sospechosos.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.report, color: Colors.red),
              title: Text('Reportar mensaje'),
              subtitle: Text('Ayuda a mejorar la detección'),
              onTap: () {
                Navigator.pop(context);
                _reportThreat();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageInfo() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Mensaje',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Remitente', widget.message.sender),
            _buildInfoRow('Fecha', _formatDate(widget.message.timestamp)),
            _buildInfoRow('Nivel de Riesgo', '${widget.message.riskScore}%'),
            _buildInfoRow('Estado', 
              widget.message.isQuarantined 
                ? 'Bloqueado por TuGuardian' 
                : _isVerificationMessage() 
                  ? 'Verificación bancaria'
                  : 'Mensaje legítimo'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _reportThreat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reportar Mensaje'),
        content: Text('¿Deseas reportar este mensaje para mejorar la detección?'),
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
                  content: Text('Mensaje reportado. Gracias.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Reportar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Sanitiza el mensaje para romper links y evitar auto-detección
  String _sanitizeMessage(String message) {
    // Inserta caracteres ZERO-WIDTH SPACE (invisible) para romper links
    // Android NO detecta estos caracteres pero los links quedan rotos
    const zeroWidth = '\u200B'; // Zero-width space (invisible)

    return message
        .replaceAll('http://', 'http$zeroWidth://')
        .replaceAll('https://', 'https$zeroWidth://')
        .replaceAll('www.', 'www$zeroWidth.')
        .replaceAll('.com', '$zeroWidth.com')
        .replaceAll('.net', '$zeroWidth.net')
        .replaceAll('.org', '$zeroWidth.org')
        .replaceAll('.co', '$zeroWidth.co');
  }

  void _showThreatWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.shield, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mensaje bloqueado por TuGuardian. No puedes copiar ni seleccionar contenido peligroso para tu protección.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Block sender dialog and action
  Future<void> _blockSender(BuildContext context) async {
    final smsProvider = Provider.of<SMSProvider>(context, listen: false);

    // Check if already blocked
    bool isBlocked = await smsProvider.isSenderBlocked(widget.message.sender);

    if (isBlocked) {
      // Show unblock dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Expanded(child: Text('Remitente bloqueado')),
            ],
          ),
          content: Text(
            '${widget.message.sender} ya está bloqueado.\n\n¿Deseas desbloquearlo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await smsProvider.unblockSender(widget.message.sender);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Remitente desbloqueado'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Desbloquear'),
            ),
          ],
        ),
      );
      return;
    }

    // Show block confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 12),
            Expanded(child: Text('Bloquear remitente')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Deseas bloquear todos los mensajes de este remitente?'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remitente:',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.message.sender,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              '• Los mensajes de este remitente se ocultarán\n• Puedes desbloquearlo en cualquier momento\n• Los SMS reales NO se eliminan del sistema',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await smsProvider.blockSender(
                widget.message.sender,
                reason: 'Bloqueado desde detalle de mensaje',
              );
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to messages list
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Remitente bloqueado: ${widget.message.sender}'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'DESHACER',
                    textColor: Colors.white,
                    onPressed: () async {
                      await smsProvider.unblockSender(widget.message.sender);
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Bloquear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}