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
    // Solo mostrar para mensajes BLOQUEADOS con entidades detectadas
    if ((!smsMessage.isModerate && !smsMessage.isDangerous) || !smsMessage.hasOfficialSuggestions) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con ícono de escudo
          Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.blue[700],
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Canales Oficiales Verificados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
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
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    smsMessage.securityAdvice,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de entidades con sus canales oficiales
          ...smsMessage.officialSuggestions!.map((suggestion) =>
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
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre de la entidad + "Canales Oficiales"
          Text(
            '${suggestion.entityName} - Canales Oficiales',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Botones de canales oficiales - horizontales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _buildChannelButtons(context, suggestion),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChannelButtons(BuildContext context, OfficialContactSuggestion suggestion) {
    List<Widget> buttons = [];
    
    for (ContactChannel channel in suggestion.channels) {
      switch (channel.type) {
        case ContactChannelType.whatsapp:
          buttons.add(_buildWhatsAppButton(context, channel, suggestion.entityName));
          break;
        case ContactChannelType.website:
          buttons.add(_buildWebButton(context, channel, suggestion.entityName));
          break;
        case ContactChannelType.app:
          buttons.add(_buildAppButton(context, suggestion.entityName));
          break;
      }
    }
    
    // Si solo tiene app, mostrar mensaje simple
    if (buttons.length == 1 && suggestion.channels.first.type == ContactChannelType.app) {
      return [_buildSimpleAppMessage(context, suggestion.entityName)];
    }
    
    return buttons;
  }

  Widget _buildWhatsAppButton(BuildContext context, ContactChannel channel, String entityName) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () => _openWhatsApp(context, channel.action, entityName),
        icon: const Icon(Icons.chat, size: 18, color: Colors.white),
        label: const Text('WhatsApp', style: TextStyle(fontSize: 12, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _buildWebButton(BuildContext context, ContactChannel channel, String entityName) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () => _openWebsite(context, channel.action, entityName),
        icon: const Icon(Icons.language, size: 18, color: Colors.white),
        label: const Text('Web Oficial', style: TextStyle(fontSize: 12, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _buildAppButton(BuildContext context, String entityName) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () => _showAppSuggestion(context, entityName),
        icon: const Icon(Icons.phone_android, size: 18, color: Colors.white),
        label: const Text('App Oficial', style: TextStyle(fontSize: 12, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _buildSimpleAppMessage(BuildContext context, String entityName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_android, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Text(
            'Consultar en app oficial',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
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
              Icon(Icons.phone_android, color: Colors.blue[700]),
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
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Las apps oficiales son el canal más seguro para consultas y transacciones.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
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