import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sms_message.dart';

/// Widget that displays text with link protection
/// For dangerous messages, links are disabled/blurred
/// For safe messages, links are clickable
class ProtectedTextWidget extends StatelessWidget {
  final String text;
  final SMSMessage? originalSMS;
  final TextStyle? baseStyle;
  final bool isDangerousMessage;

  const ProtectedTextWidget({
    super.key,
    required this.text,
    this.originalSMS,
    this.baseStyle,
    this.isDangerousMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    // Extract all links from text
    final linkRegex = RegExp(
      r'(https?://[^\s]+|www\.[^\s]+)',
      caseSensitive: false,
    );

    final matches = linkRegex.allMatches(text);

    if (matches.isEmpty) {
      // No links, display normal text
      return Text(text, style: baseStyle);
    }

    // Build text spans with link protection
    List<TextSpan> spans = [];
    int lastIndex = 0;

    for (final match in matches) {
      // Add text before link
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      // Add link (protected or clickable)
      String linkText = match.group(0)!;
      spans.add(_buildLinkSpan(linkText, context));

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  TextSpan _buildLinkSpan(String linkText, BuildContext context) {
    // DANGER: Disable dangerous links
    if (isDangerousMessage || (originalSMS?.isDangerous ?? false)) {
      return TextSpan(
        text: linkText,
        style: baseStyle?.copyWith(
          decoration: TextDecoration.lineThrough,
          color: Colors.red.shade300,
          fontWeight: FontWeight.w600,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            _showBlockedLinkDialog(context, linkText);
          },
      );
    }

    // MODERATE: Show warning before opening
    if (originalSMS?.isModerate ?? false) {
      return TextSpan(
        text: linkText,
        style: baseStyle?.copyWith(
          decoration: TextDecoration.underline,
          color: Colors.orange.shade600,
          fontWeight: FontWeight.w500,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            _showWarningDialog(context, linkText);
          },
      );
    }

    // SAFE: Allow click
    return TextSpan(
      text: linkText,
      style: baseStyle?.copyWith(
        decoration: TextDecoration.underline,
        color: Colors.blue,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          _launchURL(linkText);
        },
    );
  }

  void _showBlockedLinkDialog(BuildContext context, String link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('🚫 Link Bloqueado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Este enlace ha sido bloqueado por tu seguridad:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: SelectableText(
                link,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red.shade900,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '⚠️ NO abras este enlace. Puede ser peligroso.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (originalSMS?.detectedEntities != null &&
                originalSMS!.detectedEntities!.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                '✅ Usa canales oficiales:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              ...originalSMS!.detectedEntities!.map((entity) =>
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${entity.hasApp ? "📱" : ""} ${entity.name}${entity.hasWebsite ? " - ${entity.website}" : ""}',
                    style: TextStyle(fontSize: 13),
                  ),
                )
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

  void _showWarningDialog(BuildContext context, String link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('⚠️ Advertencia'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Este enlace podría no ser seguro:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: SelectableText(
                link,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '💡 Verifica que sea esperado antes de continuar.',
              style: TextStyle(color: Colors.orange.shade700),
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
              _launchURL(link);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text('Abrir de todos modos'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    // Add https:// if missing
    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'https://$url';
    }

    final uri = Uri.parse(formattedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
