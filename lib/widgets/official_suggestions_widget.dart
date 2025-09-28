import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sms_message.dart';
import '../services/official_entities_service.dart';
import '../core/app_colors.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header compacto
          Row(
            children: [
              Icon(
                Icons.verified_user,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Canales Oficiales Verificados',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Lista compacta de entidades
          ...(smsMessage.officialSuggestions ?? []).map((suggestion) =>
            _buildCompactEntity(context, suggestion)).toList(),
        ],
      ),
    );
  }

  Widget _buildCompactEntity(BuildContext context, OfficialContactSuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.lightBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre de entidad con badge compacto
          Row(
            children: [
              Text(
                suggestion.entityName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'VERIFICADO',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Botones horizontales compactos
          Row(
            children: _buildCompactButtons(context, suggestion),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCompactButtons(BuildContext context, OfficialContactSuggestion suggestion) {
    List<Widget> buttons = [];
    
    for (int i = 0; i < suggestion.channels.length; i++) {
      ContactChannel channel = suggestion.channels[i];
      
      Widget button;
      switch (channel.type) {
        case ContactChannelType.whatsapp:
          button = _buildCompactButton(
            context: context,
            onPressed: () => _openWhatsApp(context, channel.action, suggestion.entityName),
            icon: Icons.chat,
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
          );
          break;
        case ContactChannelType.website:
          button = _buildCompactButton(
            context: context,
            onPressed: () => _openWebsite(context, channel.action, suggestion.entityName),
            icon: Icons.language,
            label: 'Web',
            color: AppColors.primary,
          );
          break;
        case ContactChannelType.app:
          button = _buildCompactButton(
            context: context,
            onPressed: () => _showAppSuggestion(context, suggestion.entityName),
            icon: Icons.phone_android,
            label: 'App',
            color: const Color(0xFF8E24AA),
          );
          break;
      }
      
      buttons.add(Expanded(child: button));
      
      // Espaciado entre botones
      if (i < suggestion.channels.length - 1) {
        buttons.add(const SizedBox(width: 6));
      }
    }
    
    return buttons;
  }

  Widget _buildCompactButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
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
              Icon(
                icon,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
        _showSuccessSnackBar(context, '✅ Abriendo WhatsApp oficial de $entityName');
      } else {
        throw 'No se puede abrir WhatsApp';
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Error abriendo WhatsApp: $e');
    }
  }

  void _openWebsite(BuildContext context, String websiteUrl, String entityName) async {
    try {
      final Uri url = Uri.parse(websiteUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        _showSuccessSnackBar(context, '🌐 Abriendo página oficial de $entityName');
      } else {
        throw 'No se puede abrir la página web';
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Error abriendo página web: $e');
    }
  }

  void _showAppSuggestion(BuildContext context, String entityName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('App Oficial de $entityName'),
          content: Text(
            'Para mayor seguridad, consulta directamente en la app oficial de $entityName.',
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

  void _showSuccessSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}