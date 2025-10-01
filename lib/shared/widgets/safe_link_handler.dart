import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sms_message.dart';
import '../../services/detection_service.dart';

/// Widget to handle link clicks safely based on intent analysis
class SafeLinkHandler {

  /// Show warning dialog before opening a link
  static Future<void> handleLinkClick({
    required BuildContext context,
    required String url,
    required SMSMessage message,
  }) async {
    // Check if link should be blocked based on intent
    if (message.intentAnalysis?.shouldBlockLinks == true) {
      await _showBlockedLinkDialog(context, url, message);
    } else if (message.riskScore >= 40) {
      await _showWarningDialog(context, url, message);
    } else {
      // Safe to open directly
      await _openLink(url);
    }
  }

  /// Show dialog for blocked links (high-risk intents)
  static Future<void> _showBlockedLinkDialog(
    BuildContext context,
    String url,
    SMSMessage message,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Enlace Bloqueado',
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TuGuardian bloqueó este enlace por tu seguridad:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Text(
                url,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red.shade800,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Show detected intent
            if (message.intentAnalysis != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
                        const SizedBox(width: 6),
                        Text(
                          'Intención detectada:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.intentAnalysis!.intentSummary,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Show official channels if available
            if (message.detectedEntities != null && message.detectedEntities!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified, size: 16, color: Colors.green.shade800),
                        const SizedBox(width: 6),
                        Text(
                          'Usa los canales oficiales:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message.detectedEntities!.map((e) => e.name).join(', '),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (message.hasOfficialSuggestions)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Show official channels (would open message detail with channels)
              },
              icon: Icon(Icons.shield, color: Colors.green),
              label: Text('Ver Canales Oficiales'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green.shade700,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendido'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// Show warning dialog for moderate-risk links
  static Future<void> _showWarningDialog(
    BuildContext context,
    String url,
    SMSMessage message,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Text('Advertencia de Seguridad'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Este enlace proviene de un mensaje sospechoso:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                url,
                style: TextStyle(fontSize: 13, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '⚠️ Nivel de riesgo: ${message.riskScore}/100',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade800,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openLink(url);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Abrir de todas formas', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Actually open the link
  static Future<void> _openLink(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening link: $e');
    }
  }

  /// Extract and validate domain from URL
  static String? extractDomain(String url) {
    return DetectionService.extractDomain(url);
  }
}
