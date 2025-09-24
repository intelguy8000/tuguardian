import 'package:flutter/material.dart';
import '../models/sms_message.dart';

class SMSCard extends StatelessWidget {
  final SMSMessage message;
  final VoidCallback onTap;

  const SMSCard({
    Key? key,
    required this.message,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con remitente y indicador de riesgo
              Row(
                children: [
                  // Indicador de riesgo
                  _buildRiskIndicator(),
                  SizedBox(width: 12),
                  
                  // Info del remitente
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatSender(message.sender),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Iconos de estado
                  _buildStatusIcons(),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Contenido del mensaje
              _buildMessageContent(),
              
              // Elementos sospechosos (si los hay)
              if (message.suspiciousElements.isNotEmpty) ...[
                SizedBox(height: 12),
                _buildSuspiciousElements(),
              ],
              
              // Botones de acción para mensajes riesgosos
              if (message.isModerate || message.isDangerous) ...[
                SizedBox(height: 12),
                _buildActionButtons(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: message.riskColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: message.riskColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            message.riskIcon,
            size: 16,
            color: message.riskColor,
          ),
          SizedBox(width: 6),
          Text(
            message.riskLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: message.riskColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcons() {
    List<Widget> icons = [];
    
    if (message.isQuarantined) {
      icons.add(
        Tooltip(
          message: 'Mensaje bloqueado',
          child: Icon(
            Icons.block,
            color: Colors.red[400],
            size: 20,
          ),
        ),
      );
    }
    
    if (message.isDangerous && !message.isQuarantined) {
      icons.add(
        Tooltip(
          message: 'Mensaje peligroso',
          child: Icon(
            Icons.warning,
            color: Colors.red[400],
            size: 20,
          ),
        ),
      );
    }
    
    // Indicador de score numérico
    icons.add(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: message.riskColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${message.riskScore}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: message.riskColor,
          ),
        ),
      ),
    );
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: icons.map((icon) => Padding(
        padding: EdgeInsets.only(left: 8),
        child: icon,
      )).toList(),
    );
  }

  Widget _buildMessageContent() {
    String displayMessage = message.message;
    int maxLines = message.isQuarantined ? 2 : 4;
    
    // Si el mensaje está en cuarentena, censurar parcialmente
    if (message.isQuarantined) {
      displayMessage = _censorMessage(message.message);
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isQuarantined 
            ? Colors.red[50] 
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: message.isQuarantined 
            ? Border.all(color: Colors.red[200]!, width: 1)
            : null,
      ),
      child: Text(
        displayMessage,
        style: TextStyle(
          fontSize: 15,
          color: message.isQuarantined 
              ? Colors.red[700]
              : Colors.grey[700],
          height: 1.4,
          fontStyle: message.isQuarantined 
              ? FontStyle.italic 
              : FontStyle.normal,
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSuspiciousElements() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: message.suspiciousElements.take(3).map((element) =>
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: message.riskColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: message.riskColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 12,
                color: message.riskColor,
              ),
              SizedBox(width: 4),
              Text(
                element,
                style: TextStyle(
                  fontSize: 11,
                  color: message.riskColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
      ).toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Botón "Es seguro"
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _markAsSafe(context),
            icon: Icon(Icons.check, size: 16),
            label: Text('Es seguro', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green[600],
              side: BorderSide(color: Colors.green[300]!),
              padding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        
        SizedBox(width: 8),
        
        // Botón "Bloquear"
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _blockMessage(context),
            icon: Icon(Icons.block, size: 16),
            label: Text('Bloquear', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[600],
              side: BorderSide(color: Colors.red[300]!),
              padding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Color _getBorderColor() {
    if (message.isQuarantined) {
      return Colors.red.withOpacity(0.5);
    } else if (message.isDangerous) {
      return Colors.red.withOpacity(0.3);
    } else if (message.isModerate) {
      return Colors.orange.withOpacity(0.3);
    } else {
      return Colors.green.withOpacity(0.2);
    }
  }

  String _formatSender(String sender) {
    // Formatear el remitente para mejor legibilidad
    if (sender.startsWith('+')) {
      // Es un número de teléfono
      return sender.length > 10 ? '${sender.substring(0, 10)}...' : sender;
    }
    
    // Es un nombre/texto
    return sender.length > 20 ? '${sender.substring(0, 20)}...' : sender;
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }

  String _censorMessage(String message) {
    // Censurar URLs y números de teléfono en mensajes bloqueados
    String censored = message;
    
    // Censurar URLs
    censored = censored.replaceAll(
      RegExp(r'http[s]?://[^\s]+'),
      '[ENLACE BLOQUEADO]',
    );
    
    // Censurar números de teléfono largos
    censored = censored.replaceAll(
      RegExp(r'\+?\d{10,}'),
      '[NÚMERO BLOQUEADO]',
    );
    
    return censored;
  }

  void _markAsSafe(BuildContext context) {
    // TODO: Implementar lógica para marcar como seguro
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mensaje marcado como seguro'),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  void _blockMessage(BuildContext context) {
    // TODO: Implementar lógica para bloquear mensaje
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mensaje bloqueado permanentemente'),
        backgroundColor: Colors.red[600],
      ),
    );
  }
}