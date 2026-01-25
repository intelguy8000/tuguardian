import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sms_message.dart';

/// Widget that displays TuGuardian analysis with interactive official channel buttons
class TuGuardianAnalysisWidget extends StatelessWidget {
  final SMSMessage sms;
  final TextStyle baseStyle;

  const TuGuardianAnalysisWidget({
    super.key,
    required this.sms,
    required this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (sms.isDangerous) {
      return _buildDangerousAnalysis(context);
    } else if (sms.isModerate) {
      return _buildModerateAnalysis(context);
    } else {
      return _buildSafeAnalysis(context);
    }
  }

  Widget _buildDangerousAnalysis(BuildContext context) {
    List<Widget> widgets = [];

    // Header
    widgets.add(
      Row(
        children: [
          Text('🚫 Bloqueé este mensaje', style: baseStyle.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
    widgets.add(SizedBox(height: 12));

    // Reasons
    List<String> reasons = [];
    if (sms.intentAnalysis != null) {
      var intents = sms.intentAnalysis!.detectedIntents;
      if (intents.any((i) => i.toString().contains('FINANCIAL'))) {
        reasons.add('💰 Solicita acción financiera');
      }
      if (intents.any((i) => i.toString().contains('CREDENTIAL'))) {
        reasons.add('🔐 Solicita credenciales');
      }
      if (intents.any((i) => i.toString().contains('URGENCY'))) {
        reasons.add('⚡ Presión de urgencia');
      }
    }
    if (sms.suspiciousElements.isNotEmpty) {
      reasons.add('🔗 Link sospechoso');
    }

    for (var reason in reasons) {
      widgets.add(Text(reason, style: baseStyle));
    }

    widgets.add(SizedBox(height: 8));
    // CORRECCIÓN 3: Mostrar texto en vez de porcentaje
    widgets.add(Text('🔴 Muy Peligroso', style: baseStyle.copyWith(fontWeight: FontWeight.w600, color: Colors.red.shade700)));

    // CORRECCIÓN 1: No mostrar canales de entidades - podemos detectar incorrectamente
    // El mensaje es peligroso, la acción correcta es ignorarlo

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildModerateAnalysis(BuildContext context) {
    // CORRECCIÓN 3: Texto simple y claro para Silver Tech
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🟡 Sospechoso', style: baseStyle.copyWith(fontWeight: FontWeight.w700, color: Colors.orange.shade700)),
        SizedBox(height: 8),
        Text('Verifica antes de actuar', style: baseStyle),
      ],
    );
  }

  Widget _buildSafeAnalysis(BuildContext context) {
    if (sms.detectedEntities != null && sms.detectedEntities!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('✅ Mensaje seguro', style: baseStyle.copyWith(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('🔗 Link oficial verificado', style: baseStyle),
        ],
      );
    }
    return Text('📬 Notificación sin riesgo', style: baseStyle);
  }

  Widget _buildChannelButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue.shade700),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue.shade700),
          ],
        ),
      ),
    );
  }

  void _showAppSuggestion(BuildContext context, String entityName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.phone_android, color: Colors.blue),
            SizedBox(width: 8),
            Text('App oficial'),
          ],
        ),
        content: Text(
          'Descarga la app oficial de $entityName desde:\n\n'
          '📱 Google Play Store\n'
          '🍎 Apple App Store\n\n'
          'Busca "$entityName oficial" en la tienda de aplicaciones de tu dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      // Add https:// if missing
      String formattedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        formattedUrl = 'https://$url';
      }

      print('🔗 Attempting to launch: $formattedUrl');

      final uri = Uri.parse(formattedUrl);

      // Try to launch
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (launched) {
        print('✅ Successfully launched: $formattedUrl');
      } else {
        print('❌ Failed to launch: $formattedUrl');
      }
    } catch (e) {
      print('❌ Error launching URL: $e');
    }
  }
}
