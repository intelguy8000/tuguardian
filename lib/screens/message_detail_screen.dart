import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../providers/sms_provider.dart';
import '../models/sms_message.dart';
import '../core/app_colors.dart';
import '../services/official_entities_service.dart';

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
    final isThreat = widget.message.isQuarantined;
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
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: AppColors.primary,
            ),
            onPressed: () => _showMessageInfo(),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildIncomingMessage(isDark, isThreat, isVerification),
                  const SizedBox(height: 16),
                  if (isThreat || hasCallToAction || isVerification) 
                    _buildTuGuardianResponse(isDark, isThreat, isVerification),
                  const SizedBox(height: 40),
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
      containerColor = Colors.red.shade100;
      containerBorder = Border.all(color: Colors.red.shade300, width: 1);
    } else if (isVerification) {
      containerColor = Colors.orange.shade50;
      containerBorder = Border.all(color: Colors.orange.shade200, width: 1);
    } else {
      containerColor = Colors.grey.shade200;
      containerBorder = null;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: GestureDetector(
            onLongPress: () => _showMessageOptions(isDark),
            child: Container(
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
                        Icon(Icons.shield, color: Colors.red, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'TuGuardian bloqueó este mensaje',
                          style: TextStyle(
                            color: Colors.red,
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
                  SelectableText(
                    widget.message.message,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildTuGuardianResponse(bool isDark, bool isThreat, bool isVerification) {
    String responseText;
    if (isVerification) {
      responseText = 'Parece verificación legítima. Si reconoces la transacción, responde normalmente.';
    } else if (isThreat) {
      responseText = 'Mensaje falso detectado. Usa solo canales oficiales verificados.';
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
                  color: AppColors.primary,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            responseText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                            maxLines: 3,
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

    setState(() => _isSending = true);

    try {
      final smsProvider = Provider.of<SMSProvider>(context, listen: false);
      await smsProvider.sendSMSResponse(widget.message.sender, text);
      
      _replyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mensaje enviado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error enviando mensaje'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
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
}