import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/sms_message.dart';
import '../core/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    // Auto-scroll al final al abrir (como iOS Messages)
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isThreat = widget.message.riskScore >= 70;

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
          // Fecha centrada estilo iOS
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

          // Contenido del mensaje estilo chat
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  
                  // MENSAJE ORIGINAL (IZQUIERDA - ENTRADA)
                  _buildIncomingMessage(isDark),
                  
                  const SizedBox(height: 16),
                  
                  // RESPUESTA DE TUGUARDIAN (DERECHA - SALIDA)
                  if (isThreat) _buildTuGuardianResponse(isDark),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Bottom sin acciones
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.grey.shade50,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatAnalysis(bool isDark) {
    final userIntent = _detectUserIntentLocal(widget.message.message);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          // SECCIÓN PRINCIPAL - SOLUCIÓN DIRECTA
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.security, color: Colors.blue.shade700, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Amenaza Detectada',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (userIntent['detected']) ...[
                  Text(
                    'Detectamos que quieres ${userIntent['action']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // BOTÓN PRINCIPAL - ESTILO SIMPLE CON FONDO AZUL
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _redirectToOfficialSite(userIntent),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: isDark ? Colors.white : Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        userIntent['buttonText'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // ENLACE SIMPLE PARA MÁS OPCIONES
                  Center(
                    child: GestureDetector(
                      onTap: () => _showMoreOptions(isDark),
                      child: Text(
                        'Más información y opciones',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  
                ] else ...[
                  Text(
                    'Este mensaje contiene elementos sospechosos que podrían comprometer tu seguridad.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // ENLACE PARA OPCIONES CUANDO NO HAY DETECCIÓN
                  Center(
                    child: GestureDetector(
                      onTap: () => _showMoreOptions(isDark),
                      child: Text(
                        'Más información y opciones',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
            
            // DETALLES TÉCNICOS
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
              subtitle: Text('Información sobre por qué se bloqueó este mensaje'),
              onTap: () {
                Navigator.pop(context);
                _showTechnicalDetails();
              },
            ),
            
            const SizedBox(height: 8),
            
            // ABRIR ENLACE ORIGINAL
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning, color: Colors.red, size: 20),
              ),
              title: Text('Abrir enlace original'),
              subtitle: Text('Proceder bajo tu propio riesgo'),
              onTap: () {
                Navigator.pop(context);
                _showDangerousLinkOptions();
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
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 12),
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

  void _showDangerousLinkOptions() {
    bool _acknowledgeRisk = false;
    bool _sliderCompleted = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text('Proceder bajo tu riesgo'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Solo procede si entiendes completamente los riesgos.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              
              CheckboxListTile(
                value: _acknowledgeRisk,
                onChanged: (value) {
                  setDialogState(() {
                    _acknowledgeRisk = value ?? false;
                  });
                },
                title: Text(
                  'Entiendo que este enlace puede ser malicioso y podría comprometer mis datos personales',
                  style: TextStyle(fontSize: 13),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              
              if (_acknowledgeRisk) ...[
                const SizedBox(height: 16),
                Text(
                  'Desliza para liberar el acceso:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                GestureDetector(
                  onPanUpdate: (details) {
                    if (details.localPosition.dx > 200) {
                      setDialogState(() => _sliderCompleted = true);
                    }
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: _sliderCompleted ? Colors.red : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            _sliderCompleted ? 'Enlace desbloqueado' : 'Desliza para continuar',
                            style: TextStyle(
                              color: _sliderCompleted ? Colors.white : Colors.grey.shade600,
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
                
                if (_sliderCompleted) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _openDangerousLink();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Abrir enlace malicioso'),
                    ),
                  ),
                ],
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerousLinkAccess() {
    return StatefulBuilder(
      builder: (context, setState) {
        bool _acknowledgeRisk = false;
        bool _sliderCompleted = false;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Solo procede si entiendes completamente los riesgos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            CheckboxListTile(
              value: _acknowledgeRisk,
              onChanged: (value) {
                setState(() {
                  _acknowledgeRisk = value ?? false;
                });
              },
              title: Text(
                'Entiendo que este enlace puede ser malicioso y podría comprometer mis datos personales',
                style: TextStyle(fontSize: 13),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
            
            if (_acknowledgeRisk) ...[
              const SizedBox(height: 16),
              Text(
                'Desliza para liberar el acceso:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              GestureDetector(
                onPanUpdate: (details) {
                  if (details.localPosition.dx > 200) {
                    setState(() => _sliderCompleted = true);
                  }
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: _sliderCompleted ? Colors.red : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          _sliderCompleted ? 'Enlace desbloqueado' : 'Desliza para continuar',
                          style: TextStyle(
                            color: _sliderCompleted ? Colors.white : Colors.grey.shade600,
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
              
              if (_sliderCompleted) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openDangerousLink(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Abrir enlace malicioso'),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  Map<String, dynamic> _detectUserIntentLocal(String message) {
    final lowerMessage = message.toLowerCase();
    
    // CLARO - Facturas y pagos
    if ((lowerMessage.contains('claro') || lowerMessage.contains('factura')) && 
        (lowerMessage.contains('pag') || lowerMessage.contains('venc') || lowerMessage.contains('consulta'))) {
      return {
        'detected': true,
        'action': 'pagar tu factura Claro',
        'company': 'Claro',
        'officialUrl': 'https://www.claro.com.co/personas/autogestion/portal-pagos/',
        'buttonText': 'Pagar factura Claro de forma segura',
        'description': 'Te dirigimos al portal oficial de pagos de Claro donde puedes consultar y pagar tu factura de forma completamente segura.'
      };
    }
    
    // MOVISTAR - Planes y servicios
    if (lowerMessage.contains('movistar') && 
        (lowerMessage.contains('plan') || lowerMessage.contains('renovar'))) {
      return {
        'detected': true,
        'action': 'gestionar tu plan Movistar',
        'company': 'Movistar',
        'officialUrl': 'https://mi.movistar.co/',
        'buttonText': 'Ir a Mi Movistar de forma segura',
        'description': 'Te conectamos con el portal oficial Mi Movistar para gestionar tu plan y servicios.'
      };
    }
    
    // TIGO - Servicios móviles
    if (lowerMessage.contains('tigo') && 
        (lowerMessage.contains('recarga') || lowerMessage.contains('plan') || lowerMessage.contains('pago'))) {
      return {
        'detected': true,
        'action': 'gestionar tu cuenta Tigo',
        'company': 'Tigo',
        'officialUrl': 'https://www.tigo.com.co/mi-tigo',
        'buttonText': 'Ir a Mi Tigo de forma segura',
        'description': 'Te dirigimos al portal oficial de Tigo para gestionar tu cuenta y servicios.'
      };
    }
    
    // BANCOS - Consultas y transacciones
    if (lowerMessage.contains('banco') || lowerMessage.contains('cuenta') || 
        lowerMessage.contains('bancolombia') || lowerMessage.contains('suspendida')) {
      return {
        'detected': true,
        'action': 'revisar tu cuenta bancaria',
        'company': 'tu banco',
        'officialUrl': 'https://www.bancolombia.com/',
        'buttonText': 'Ir al sitio oficial del banco',
        'description': 'Para tu seguridad, usa siempre la app oficial de tu banco o visita una sucursal física.'
      };
    }
    
    // INTERRÁPIDÍSIMO - Rastreo de pedidos
    if (lowerMessage.contains('inter') || lowerMessage.contains('pedido') || 
        lowerMessage.contains('envio') || lowerMessage.contains('paquete')) {
      return {
        'detected': true,
        'action': 'rastrear tu pedido',
        'company': 'Interrápidísimo',
        'officialUrl': 'https://www.interrapidisimo.com/',
        'buttonText': 'Rastrear pedido de forma segura',
        'description': 'Te conectamos con el sitio oficial de Interrápidísimo para rastrear tu envío.'
      };
    }
    
    return {'detected': false};
  }

  Widget _buildIncomingMessage(bool isDark) {
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
                color: Colors.red.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: Colors.red.shade300, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

  Widget _buildTuGuardianResponse(bool isDark) {
    final userIntent = _detectUserIntentLocal(widget.message.message);
    
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
                    if (userIntent['detected']) ...[
                      Text(
                        'Amenaza detectada',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Quieres ${userIntent['action']}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // BOTÓN INTEGRADO EN LA RESPUESTA
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _redirectToOfficialSite(userIntent),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            userIntent['buttonText'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      GestureDetector(
                        onTap: () => _showMoreOptions(isDark),
                        child: Text(
                          'Más opciones',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white70,
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Este mensaje contiene elementos sospechosos que podrían comprometer tu seguridad.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showMoreOptions(isDark),
                        child: Text(
                          'Más información y opciones',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white70,
                          ),
                        ),
                      ),
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
              subtitle: Text('Ayuda a mejorar la detección de amenazas'),
              onTap: () {
                Navigator.pop(context);
                _reportThreat();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Eliminar mensaje'),
              subtitle: Text('Eliminar de la conversación'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _redirectToOfficialSite(Map<String, dynamic> intent) {
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.security, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Redirección Segura',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Te sugerimos este sitio que creemos es el oficial. Verifica siempre que sea correcto antes de ingresar datos.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link, color: Colors.green.shade700, size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      intent['officialUrl'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Simular apertura del enlace
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Abriendo ${intent['officialUrl']} en tu navegador...'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                          action: SnackBarAction(
                            label: 'Abrir',
                            textColor: Colors.white,
                            onPressed: () {
                              // Aquí iría url_launcher en producción
                              // launch(intent['officialUrl']);
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Continuar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDangerousLink() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Última advertencia'),
        content: Text('Estás a punto de abrir un enlace que TuGuardian identificó como malicioso. ¿Estás seguro?'),
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
                  content: Text('TuGuardian no puede protegerte más. Ten mucho cuidado.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Proceder', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(bool isDark, bool isThreat) {
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (!isThreat) ...[
              _buildActionButton(
                icon: Icons.reply,
                label: 'Responder',
                onTap: () => _showReplyOptions(),
                isDark: isDark,
              ),
              _buildActionButton(
                icon: Icons.forward,
                label: 'Reenviar',
                onTap: () => _showForwardOptions(),
                isDark: isDark,
              ),
            ] else ...[
              _buildActionButton(
                icon: Icons.report,
                label: 'Reportar',
                onTap: () => _reportThreat(),
                isDark: isDark,
                color: Colors.red,
              ),
              _buildActionButton(
                icon: Icons.security,
                label: 'Guía Segura',
                onTap: () => _showSafeAlternatives(),
                isDark: isDark,
                color: Colors.green,
              ),
            ],
            _buildActionButton(
              icon: Icons.delete_outline,
              label: 'Eliminar',
              onTap: () => _confirmDelete(),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    final buttonColor = color ?? (isDark ? Colors.white : Colors.black);
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: buttonColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              icon,
              color: buttonColor,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: buttonColor,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  bool _containsSuspiciousLink(String message) {
    final suspiciousDomains = ['mcpag.li', 'inter.la', 'sit-onclr.de', 'ma.sv'];
    return suspiciousDomains.any((domain) => message.toLowerCase().contains(domain));
  }

  void _showThreatWarning() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.shield, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '🚨 Link Bloqueado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'TuGuardian ha bloqueado este enlace porque contiene patrones de smishing conocidos.\n\n¿Te guiamos al sitio oficial seguro?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSafeAlternatives();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Ir al sitio oficial', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSafeAlternatives() {
    final guidance = _getSafeGuidance(widget.message.sender);
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
            Row(
              children: [
                Icon(Icons.security, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Alternativa Segura',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              guidance,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Redirigiendo al sitio oficial...'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Continuar de forma segura', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _getSafeGuidance(String sender) {
    // Esta función ya no se usa - la lógica está ahora en _detectUserIntent
    return 'Te conectamos con los canales oficiales y verificados de esta empresa.';
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
            _buildInfoRow('Hora', _formatTime(widget.message.timestamp)),
            _buildInfoRow('Nivel de Riesgo', '${widget.message.riskScore}%'),
            if (widget.message.riskScore >= 70)
              _buildInfoRow('Estado', 'Bloqueado por TuGuardian'),
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

  void _showReplyOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Función de respuesta próximamente')),
    );
  }

  void _showForwardOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Función de reenvío próximamente')),
    );
  }

  void _reportThreat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reportar Amenaza'),
        content: Text('¿Deseas reportar este mensaje como amenaza de smishing para ayudar a proteger a otros usuarios?'),
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
                  content: Text('Amenaza reportada. Gracias por ayudar a proteger la comunidad.'),
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Mensaje'),
        content: Text('¿Estás seguro de que quieres eliminar este mensaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Volver a la lista
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Mensaje eliminado')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar', style: TextStyle(color: Colors.white)),
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
    } else if (difference.inDays < 7) {
      final weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return weekdays[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}