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
    if ((!smsMessage.isModerate && !smsMessage.isDangerous) || !smsMessage.hasOfficialSuggestions) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${smsMessage.officialSuggestions!.first.entityName} - Contacto Seguro',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700], size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Suplanta a ${smsMessage.officialSuggestions!.first.entityName}. Verifica por canales oficiales',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildChannelButtons(context, smsMessage.officialSuggestions!.first),
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
          buttons.add(_buildCompactButton(
            context,
            icon: Icons.chat_bubble,
            label: 'WhatsApp',
            color: Colors.green,
            onTap: () => _openWhatsApp(context, channel.action, suggestion.entityName),
          ));
          break;
        case ContactChannelType.website:
          buttons.add(_buildCompactButton(
            context,
            icon: Icons.language,
            label: 'Web',
            color: Colors.blue,
            onTap: () => _openWebsite(context, channel.action, suggestion.entityName),
          ));
          break;
        case ContactChannelType.app:
          buttons.add(_buildCompactButton(
            context,
            icon: Icons.phone_android,
            label: 'App',
            color: Colors.purple,
            onTap: () => _showAppSuggestion(context, suggestion.entityName),
          ));
          break;
      }
    }
    
    return buttons;
  }

  Widget _buildCompactButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openWhatsApp(BuildContext context, String whatsappUrl, String entityName) async {
    try {
      final Uri url = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error abriendo WhatsApp'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openWebsite(BuildContext context, String websiteUrl, String entityName) async {
    try {
      final Uri url = Uri.parse(websiteUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error abriendo sitio web'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAppSuggestion(BuildContext context, String entityName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('App Oficial de $entityName'),
          content: Text('Descarga la app oficial de $entityName desde tu tienda de aplicaciones para mayor seguridad.'),
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