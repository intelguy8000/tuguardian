import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sms_message.dart';

class MessageDetailsModal extends StatelessWidget {
  final SMSMessage message;

  const MessageDetailsModal({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              _buildHeader(context),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRiskAssessment(),
                      SizedBox(height: 20),
                      _buildMessageContent(),
                      SizedBox(height: 20),
                      _buildAnalysisDetails(),
                      SizedBox(height: 20),
                      _buildRecommendations(),
                      SizedBox(height: 20),
                      _buildActionButtons(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: message.riskColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              message.riskIcon,
              color: message.riskColor,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Análisis de Mensaje',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'De: ${message.sender}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAssessment() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: message.riskColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: message.riskColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: message.riskColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Evaluación de Riesgo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: message.riskColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Puntuación: ',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: message.riskColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${message.riskScore}/100',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getRiskDescription(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: message.riskScore / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(message.riskColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.message, color: Colors.grey[600], size: 20),
            SizedBox(width: 8),
            Text(
              'Contenido del Mensaje',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Spacer(),
            IconButton(
              onPressed: () => _copyToClipboard(message.message),
              icon: Icon(Icons.copy, size: 20, color: Colors.grey[600]),
              tooltip: 'Copiar mensaje',
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            message.message,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Colors.grey[800],
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Recibido: ${_formatFullTime(message.timestamp)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.psychology, color: Colors.blue[600], size: 20),
            SizedBox(width: 8),
            Text(
              'Análisis Detallado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        
        if (message.suspiciousElements.isNotEmpty) ...[
          Text(
            'Elementos Sospechosos Detectados:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          ...message.suspiciousElements.map((element) => 
            Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.orange[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      element,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        ] else ...[
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                SizedBox(width: 8),
                Text(
                  'No se detectaron elementos sospechosos',
                  style: TextStyle(fontSize: 13, color: Colors.green[700]),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecommendations() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue[600], size: 20),
              SizedBox(width: 8),
              Text(
                'Recomendaciones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            _getRecommendationText(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _markAsSafe(context),
                icon: Icon(Icons.check),
                label: Text('Marcar como Seguro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _blockMessage(context),
                icon: Icon(Icons.block),
                label: Text('Bloquear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _reportMessage(context),
            icon: Icon(Icons.report),
            label: Text('Reportar como Fraude'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange[600],
              side: BorderSide(color: Colors.orange[300]!),
            ),
          ),
        ),
      ],
    );
  }

  String _getRiskDescription() {
    if (message.riskScore >= 80) {
      return 'Altamente peligroso - No interactuar';
    } else if (message.riskScore >= 60) {
      return 'Riesgoso - Verificar antes de actuar';
    } else if (message.riskScore >= 30) {
      return 'Sospechoso - Proceder con precaución';
    } else {
      return 'Seguro - Sin amenazas detectadas';
    }
  }

  String _getRecommendationText() {
    if (message.riskScore >= 80) {
      return 'Este mensaje contiene múltiples indicadores de smishing. NO hagas clic en ningún enlace ni proporciones información personal. Si es de tu banco, contacta directamente usando los números oficiales.';
    } else if (message.riskScore >= 60) {
      return 'Este mensaje presenta características sospechosas. Antes de tomar cualquier acción, verifica la información contactando directamente a la organización por canales oficiales.';
    } else if (message.riskScore >= 30) {
      return 'Aunque no parece altamente peligroso, ten precaución. Si solicita información personal o pagos, verifica la autenticidad del remitente.';
    } else {
      return 'Este mensaje parece legítimo, pero siempre mantén la precaución con enlaces y solicitudes de información personal.';
    }
  }

  String _formatFullTime(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} a las ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  void _markAsSafe(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mensaje marcado como seguro')),
    );
  }

  void _blockMessage(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mensaje bloqueado')),
    );
  }

  void _reportMessage(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mensaje reportado como fraude')),
    );
  }
}