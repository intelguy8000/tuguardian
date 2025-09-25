import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sms_message.dart';
import '../services/official_entities_service.dart';

class OfficialSuggestionsWidget extends StatelessWidget {
  final SMSMessage smsMessage;

  const OfficialSuggestionsWidget({
    super.key,
    required this.smsMessage,
  });

  @override
  Widget build(BuildContext context) {
    // Solo mostrar para mensajes ROJOS con entidades detectadas
    if (!smsMessage.isDangerous || !smsMessage.hasOfficialSuggestions) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con ícono de escudo
          Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🛡️ Canales Oficiales Verificados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Mensaje de advertencia específico
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    smsMessage.securityAdvice,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de entidades con sus canales oficiales
          ...smsMessage.officialSuggestions.map((suggestion) =>
            _buildEntitySuggestion(context, suggestion)).toList(),
        ],
      ),
    );
  }

  Widget _buildEntitySuggestion(BuildContext context, OfficialContactSuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre de la entidad
          Text(
            suggestion.entityName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Para dudas o consultas, usa estos canales oficiales:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Botones de canales oficiales
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestion.channels.map((channel) =>
              _buildChannelButton(context, channel, suggestion.entityName)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelButton(BuildContext context, ContactChannel channel, String entityName) {
    IconData icon;
    Color color;
    
    switch (channel.type) {
      case ContactChannelType.whatsapp:
        icon = Icons.chat;
        color = Colors.green;
        break;
      case ContactChannelType.app:
        icon = Icons.mobile_app;
        color = Colors.blue;
        break;
      case ContactChannelType.website:
        icon = Icons.web;
        color = Colors.purple;
        break;
    }

    return ElevatedButton.icon(
      onPressed: () => _handleChannelTap(context, channel, entityName),
      icon: Icon(icon, size: 18),
      label: Text(
        channel.label,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.shade50,
        foregroundColor: color.shade700,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.shade200),
        ),
      ),
    );
  }

  void _handleChannelTap(BuildContext context, ContactChannel channel, String entityName) {
    switch (channel.type) {
      case ContactChannelType.whatsapp:
        _openWhatsApp(context, channel.action, entityName);
        break;
      case ContactChannelType.website:
        _openWebsite(context, channel.action, entityName);
        break;
      case ContactChannelType.app:
        _showAppSuggestion(context, entityName);
        break;
    }
  }

  void _openWhatsApp(BuildContext context, String whatsappUrl, String entityName) async {
    try {
      final Uri url = Uri.parse(whatsappUrl);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        
        // Mostrar confirmación
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Abriendo WhatsApp oficial de $entityName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw 'No se puede abrir WhatsApp';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error abriendo WhatsApp: $e'),
            backgroundColor: Colors.red,
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
        
        // Mostrar confirmación
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Abriendo página oficial de $entityName'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw 'No se puede abrir la página web';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error abriendo página web: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAppSuggestion(BuildContext context, String entityName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.mobile_app, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text('App Oficial de $entityName'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para mayor seguridad, consulta directamente en la app oficial de $entityName.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Las apps oficiales son el canal más seguro para consultas y transacciones.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }
}