import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_sms/services/intent_detection_service.dart';
import 'package:guardian_sms/services/detection_service.dart';

void main() {
  group('Intent Detection Tests', () {

    test('Test 1: Bancolombia phishing - Should BLOCK', () {
      const message = 'Bancolombia: Tu cuenta será suspendida. Ingresa a http://fake-banco.com';
      const sender = '+573001234567';

      final result = IntentDetectionService.analyzeIntent(message, sender);

      print('\n=== TEST 1: Bancolombia Phishing ===');
      print('Message: $message');
      print('Intents: ${result.detectedIntents}');
      print('Action: ${result.action}');
      print('Should Block Links: ${result.shouldBlockLinks}');
      print('Risk Boost: +${result.intentRiskBoost}');
      print('Guidance: ${result.userGuidance}');

      expect(result.shouldBlockLinks, true);
      expect(result.action, RecommendedAction.BLOCK_AND_SHOW_OFFICIAL);
      expect(result.isHighRisk, true);
    });

    test('Test 2: Movistar legitimate - Should WARN', () {
      const message = 'Tu plan se renueva mañana. Para cambiar tu plan ingresa a mi.movistar.co';
      const sender = 'Movistar';

      final result = IntentDetectionService.analyzeIntent(message, sender);

      print('\n=== TEST 2: Movistar Legitimate ===');
      print('Message: $message');
      print('Intents: ${result.detectedIntents}');
      print('Action: ${result.action}');
      print('Should Block Links: ${result.shouldBlockLinks}');
      print('Risk Boost: +${result.intentRiskBoost}');
      print('Guidance: ${result.userGuidance}');

      expect(result.shouldBlockLinks, true); // Has entity + call to action
      expect(result.isHighRisk, true);
    });

    test('Test 3: Prize scam - Should WARN', () {
      const message = 'Felicidades! Has ganado \$50.000.000. Reclama aquí: http://premios-colombia.net';
      const sender = '+573009876543';

      final result = IntentDetectionService.analyzeIntent(message, sender);

      print('\n=== TEST 3: Prize Scam ===');
      print('Message: $message');
      print('Intents: ${result.detectedIntents}');
      print('Action: ${result.action}');
      print('Should Block Links: ${result.shouldBlockLinks}');
      print('Risk Boost: +${result.intentRiskBoost}');
      print('Guidance: ${result.userGuidance}');

      expect(result.detectedIntents, contains(MessageIntent.PRIZE_CLAIM));
      expect(result.action, RecommendedAction.WARN_AND_SUGGEST);
    });

    test('Test 4: Urgency + Financial + Link - Should BLOCK', () {
      const message = 'URGENTE! Paga tu factura HOY: http://bit.ly/pago123';
      const sender = '890176';

      final result = IntentDetectionService.analyzeIntent(message, sender);

      print('\n=== TEST 4: Urgency + Financial Pressure ===');
      print('Message: $message');
      print('Intents: ${result.detectedIntents}');
      print('Action: ${result.action}');
      print('Should Block Links: ${result.shouldBlockLinks}');
      print('Risk Boost: +${result.intentRiskBoost}');
      print('Guidance: ${result.userGuidance}');

      expect(result.shouldBlockLinks, true);
      expect(result.detectedIntents, contains(MessageIntent.URGENCY_PRESSURE));
      expect(result.detectedIntents, contains(MessageIntent.FINANCIAL_ACTION));
    });

    test('Test 5: Safe notification - Should ALLOW', () {
      const message = 'Tu pedido #12345 ha sido enviado y llegará mañana.';
      const sender = '891888';

      final result = IntentDetectionService.analyzeIntent(message, sender);

      print('\n=== TEST 5: Safe Notification ===');
      print('Message: $message');
      print('Intents: ${result.detectedIntents}');
      print('Action: ${result.action}');
      print('Should Block Links: ${result.shouldBlockLinks}');
      print('Risk Boost: +${result.intentRiskBoost}');
      print('Guidance: ${result.userGuidance}');

      expect(result.shouldBlockLinks, false);
      expect(result.action, RecommendedAction.ALLOW_SAFE);
      expect(result.intentRiskBoost, 0);
    });

    test('Test 6: Credential request - Should BLOCK', () {
      const message = 'Verifica tu identidad ingresando tu código de seguridad en: http://verify-account.com';
      const sender = 'SECURITY';

      final result = IntentDetectionService.analyzeIntent(message, sender);

      print('\n=== TEST 6: Credential Request ===');
      print('Message: $message');
      print('Intents: ${result.detectedIntents}');
      print('Action: ${result.action}');
      print('Should Block Links: ${result.shouldBlockLinks}');
      print('Risk Boost: +${result.intentRiskBoost}');
      print('Guidance: ${result.userGuidance}');

      expect(result.detectedIntents, contains(MessageIntent.CREDENTIAL_REQUEST));
      expect(result.isHighRisk, true);
    });

    test('Test 7: Full analysis with DetectionService integration', () {
      const message = 'JUAN HOY VENCE TU FACTURA CLARO! Paga tan solo 43.859. Consulta: https://mcpag.li/c3';
      const sender = '+573001234567';

      // Analyze with full detection service
      final smsMessage = DetectionService.analyzeMessage(
        'test_id',
        sender,
        message,
        DateTime.now(),
      );

      print('\n=== TEST 7: Full Analysis Integration ===');
      print('Message: $message');
      print('Base Risk Score: ${smsMessage.riskScore}');
      print('Is Quarantined: ${smsMessage.isQuarantined}');
      print('Intent Summary: ${smsMessage.intentAnalysis?.intentSummary}');
      print('Should Block Links: ${smsMessage.intentAnalysis?.shouldBlockLinks}');
      print('Suspicious Elements: ${smsMessage.suspiciousElements.length}');
      print('Has Official Suggestions: ${smsMessage.hasOfficialSuggestions}');

      expect(smsMessage.riskScore, greaterThan(70));
      expect(smsMessage.isQuarantined, true);
      expect(smsMessage.intentAnalysis?.shouldBlockLinks, true);
    });

    test('Test 8: Entity detection with official channels', () {
      const message = 'Bancolombia: actualiza tus datos aquí: http://fake-site.com';
      const sender = 'BANCO';

      final smsMessage = DetectionService.analyzeMessage(
        'test_id',
        sender,
        message,
        DateTime.now(),
      );

      print('\n=== TEST 8: Entity Detection ===');
      print('Message: $message');
      print('Detected Entities: ${smsMessage.detectedEntities?.map((e) => e.name).join(", ")}');
      print('Has Official Suggestions: ${smsMessage.hasOfficialSuggestions}');
      print('Should Block: ${smsMessage.intentAnalysis?.shouldBlockLinks}');

      if (smsMessage.officialSuggestions != null) {
        for (var suggestion in smsMessage.officialSuggestions!) {
          print('  - ${suggestion.entityName}: ${suggestion.channels.length} channels');
          for (var channel in suggestion.channels) {
            print('    • ${channel.label}');
          }
        }
      }

      expect(smsMessage.detectedEntities, isNotEmpty);
      expect(smsMessage.hasOfficialSuggestions, true);
      expect(smsMessage.intentAnalysis?.shouldBlockLinks, true);
    });
  });

  group('Intent Pattern Detection Tests', () {

    test('Financial action patterns', () {
      final messages = [
        'Paga tu factura ahora',
        'Actualiza tu método de pago',
        'Confirma tu cuenta bancaria',
        'Valida esta transacción',
      ];

      for (var msg in messages) {
        final result = IntentDetectionService.analyzeIntent(msg, 'test');
        print('Testing: "$msg" -> Contains FINANCIAL_ACTION: ${result.detectedIntents.contains(MessageIntent.FINANCIAL_ACTION)}');
        expect(result.detectedIntents, contains(MessageIntent.FINANCIAL_ACTION));
      }
    });

    test('Urgency pressure patterns', () {
      final messages = [
        'URGENTE: actúa ahora',
        'HOY VENCE tu suscripción',
        'Último día para renovar',
        'Tu cuenta será suspendida inmediatamente',
      ];

      for (var msg in messages) {
        final result = IntentDetectionService.analyzeIntent(msg, 'test');
        print('Testing: "$msg" -> Contains URGENCY_PRESSURE: ${result.detectedIntents.contains(MessageIntent.URGENCY_PRESSURE)}');
        expect(result.detectedIntents, contains(MessageIntent.URGENCY_PRESSURE));
      }
    });

    test('Credential request patterns', () {
      final messages = [
        'Ingresa a tu cuenta',
        'Verifica tu identidad',
        'Actualiza tu contraseña',
        'Código de verificación: 123456',
      ];

      for (var msg in messages) {
        final result = IntentDetectionService.analyzeIntent(msg, 'test');
        print('Testing: "$msg" -> Contains CREDENTIAL_REQUEST: ${result.detectedIntents.contains(MessageIntent.CREDENTIAL_REQUEST)}');
        expect(result.detectedIntents, contains(MessageIntent.CREDENTIAL_REQUEST));
      }
    });
  });
}
