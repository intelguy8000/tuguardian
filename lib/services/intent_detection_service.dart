import '../detection/entities/official_entities_service.dart';
import 'detection_service.dart';

/// INTENTS: What is this message trying to make me do?
enum MessageIntent {
  // 🔴 HIGH RISK - Demands immediate action
  FINANCIAL_ACTION,      // Pay, verify account, update billing
  CREDENTIAL_REQUEST,    // Login, confirm identity, enter code
  URGENCY_PRESSURE,      // "Act now!", "Suspended!", "Today only!"

  // 🟡 MEDIUM RISK - Requests information
  INFORMATION_REQUEST,   // Update address, confirm details
  PRIZE_CLAIM,          // "You won!", "Claim reward"

  // 🟢 LOW RISK - Informational
  NOTIFICATION_ONLY,     // Status update, confirmation, receipt
  PROMOTIONAL,          // Offers, points (without urgency)
}

/// ACTIONS: What should the user do?
enum RecommendedAction {
  BLOCK_AND_SHOW_OFFICIAL,  // Block link, show official channels
  WARN_AND_SUGGEST,         // Warn user, suggest verification
  ALLOW_WITH_CAUTION,       // Low risk but stay alert
  ALLOW_SAFE,               // Appears legitimate
}

/// Result of intent analysis
class IntentAnalysisResult {
  final List<MessageIntent> detectedIntents;
  final RecommendedAction action;
  final String userGuidance;
  final bool shouldBlockLinks;
  final int intentRiskBoost;

  IntentAnalysisResult({
    required this.detectedIntents,
    required this.action,
    required this.userGuidance,
    required this.shouldBlockLinks,
    required this.intentRiskBoost,
  });

  bool get isHighRisk => detectedIntents.any((intent) =>
    intent == MessageIntent.FINANCIAL_ACTION ||
    intent == MessageIntent.CREDENTIAL_REQUEST ||
    intent == MessageIntent.URGENCY_PRESSURE
  );

  String get intentSummary {
    if (detectedIntents.isEmpty) return 'Mensaje informativo';

    if (detectedIntents.contains(MessageIntent.FINANCIAL_ACTION)) {
      return '💰 Solicita acción financiera';
    }
    if (detectedIntents.contains(MessageIntent.CREDENTIAL_REQUEST)) {
      return '🔐 Solicita credenciales';
    }
    if (detectedIntents.contains(MessageIntent.URGENCY_PRESSURE)) {
      return '⚠️ Presión de urgencia';
    }
    if (detectedIntents.contains(MessageIntent.PRIZE_CLAIM)) {
      return '🎁 Ofrece premio';
    }
    if (detectedIntents.contains(MessageIntent.INFORMATION_REQUEST)) {
      return '📝 Solicita información';
    }

    return '📬 Notificación';
  }
}

class IntentDetectionService {

  /// MAIN ANALYSIS: Detect intent and recommend action
  static IntentAnalysisResult analyzeIntent(String message, String sender) {
    List<MessageIntent> intents = _detectIntents(message);

    // Extract entities and links
    var entities = OfficialEntitiesService.detectEntitiesInMessage(message);
    var links = DetectionService.extractRealLinks(message);
    var hasCallToAction = DetectionService.hasCallToAction(message);

    // DECISION TREE
    RecommendedAction action;
    String guidance;
    bool blockLinks;
    int riskBoost;

    // RULE 1: High-risk intent + Entity mention + Link = BLOCK
    if (_isHighRiskIntent(intents) && entities.isNotEmpty && links.isNotEmpty) {
      action = RecommendedAction.BLOCK_AND_SHOW_OFFICIAL;
      guidance = _buildBlockGuidance(entities, intents);
      blockLinks = true;
      riskBoost = 50;
    }

    // RULE 2: High-risk intent + Entity mention + Call-to-action = BLOCK
    else if (_isHighRiskIntent(intents) && entities.isNotEmpty && hasCallToAction) {
      action = RecommendedAction.BLOCK_AND_SHOW_OFFICIAL;
      guidance = _buildBlockGuidance(entities, intents);
      blockLinks = true;
      riskBoost = 45;
    }

    // RULE 3: Urgency + Financial + Link = BLOCK (even without entity)
    else if (intents.contains(MessageIntent.URGENCY_PRESSURE) &&
             intents.contains(MessageIntent.FINANCIAL_ACTION) &&
             links.isNotEmpty) {
      action = RecommendedAction.BLOCK_AND_SHOW_OFFICIAL;
      guidance = 'Este mensaje combina urgencia, dinero y enlaces. Patrón típico de fraude.';
      blockLinks = true;
      riskBoost = 45;
    }

    // RULE 4: Prize claim + Link = WARN
    else if (intents.contains(MessageIntent.PRIZE_CLAIM) && links.isNotEmpty) {
      action = RecommendedAction.WARN_AND_SUGGEST;
      guidance = 'Ofertas de premios no solicitados son frecuentemente fraudes. Verifica con la empresa directamente.';
      blockLinks = false;
      riskBoost = 35;
    }

    // RULE 5: High-risk intent without link = WARN
    else if (_isHighRiskIntent(intents)) {
      action = RecommendedAction.WARN_AND_SUGGEST;
      guidance = 'Este mensaje solicita una acción. Verifica con los canales oficiales antes de actuar.';
      blockLinks = false;
      riskBoost = 25;
    }

    // RULE 6: Information request = CAUTION
    else if (intents.contains(MessageIntent.INFORMATION_REQUEST)) {
      action = RecommendedAction.ALLOW_WITH_CAUTION;
      guidance = 'Solicita información. Verifica que el remitente sea legítimo.';
      blockLinks = false;
      riskBoost = 15;
    }

    // RULE 7: Notification only = SAFE
    else {
      action = RecommendedAction.ALLOW_SAFE;
      guidance = 'Mensaje informativo sin solicitud de acción.';
      blockLinks = false;
      riskBoost = 0;
    }

    return IntentAnalysisResult(
      detectedIntents: intents,
      action: action,
      userGuidance: guidance,
      shouldBlockLinks: blockLinks,
      intentRiskBoost: riskBoost,
    );
  }

  /// Detect all intents in the message
  static List<MessageIntent> _detectIntents(String message) {
    List<MessageIntent> intents = [];
    String lower = message.toLowerCase();

    // FINANCIAL_ACTION
    if (_hasFinancialActionIntent(lower)) {
      intents.add(MessageIntent.FINANCIAL_ACTION);
    }

    // CREDENTIAL_REQUEST
    if (_hasCredentialRequestIntent(lower)) {
      intents.add(MessageIntent.CREDENTIAL_REQUEST);
    }

    // URGENCY_PRESSURE
    if (_hasUrgencyPressureIntent(lower)) {
      intents.add(MessageIntent.URGENCY_PRESSURE);
    }

    // INFORMATION_REQUEST
    if (_hasInformationRequestIntent(lower)) {
      intents.add(MessageIntent.INFORMATION_REQUEST);
    }

    // PRIZE_CLAIM
    if (_hasPrizeClaimIntent(lower)) {
      intents.add(MessageIntent.PRIZE_CLAIM);
    }

    // PROMOTIONAL
    if (_hasPromotionalIntent(lower) && !intents.contains(MessageIntent.URGENCY_PRESSURE)) {
      intents.add(MessageIntent.PROMOTIONAL);
    }

    // NOTIFICATION_ONLY (default if no action-demanding intents)
    if (intents.isEmpty || (!_isHighRiskIntent(intents) && !intents.contains(MessageIntent.INFORMATION_REQUEST))) {
      intents.add(MessageIntent.NOTIFICATION_ONLY);
    }

    return intents;
  }

  /// Check if any intent is high-risk
  static bool _isHighRiskIntent(List<MessageIntent> intents) {
    return intents.any((intent) =>
      intent == MessageIntent.FINANCIAL_ACTION ||
      intent == MessageIntent.CREDENTIAL_REQUEST ||
      intent == MessageIntent.URGENCY_PRESSURE
    );
  }

  /// Build guidance for blocked messages
  static String _buildBlockGuidance(List<OfficialEntity> entities, List<MessageIntent> intents) {
    String entityNames = entities.map((e) => e.name).join(', ');

    if (intents.contains(MessageIntent.FINANCIAL_ACTION)) {
      return '🚫 Este mensaje solicita acción financiera mencionando $entityNames. NO uses los enlaces del SMS. Accede solo por canales oficiales.';
    }

    if (intents.contains(MessageIntent.CREDENTIAL_REQUEST)) {
      return '🚫 Este mensaje solicita credenciales mencionando $entityNames. NUNCA ingreses datos por enlaces de SMS. Usa la app oficial.';
    }

    if (intents.contains(MessageIntent.URGENCY_PRESSURE)) {
      return '🚫 Este mensaje usa urgencia falsa mencionando $entityNames. Las empresas legítimas NO presionan por SMS. Verifica directamente.';
    }

    return '🚫 Este mensaje menciona $entityNames y solicita acción. Contacta a la empresa por canales oficiales.';
  }

  // ============================================
  // INTENT DETECTION PATTERNS
  // ============================================

  static bool _hasFinancialActionIntent(String message) {
    final patterns = [
      // Payment actions
      RegExp(r'\b(paga|pagar|pagad|pague|abona|abonar|cancela|cancelar)\b'),
      RegExp(r'\b(actualiza.*pago|actualizar.*pago|metodo.*pago|forma.*pago)\b'),

      // Account verification
      RegExp(r'\b(verifica.*cuenta|verificar.*cuenta|confirma.*cuenta|confirmar.*cuenta)\b'),
      RegExp(r'\b(actualiza.*datos.*bancarios|actualizar.*datos.*bancarios)\b'),
      RegExp(r'\b(valida.*transaccion|validar.*transaccion)\b'),

      // Financial terms
      RegExp(r'\b(factura|deuda|saldo|tarjeta|cuenta.*suspendida|cuenta.*bloqueada)\b'),
      RegExp(r'\b(reembolso|devolucion|cargo|cobro)\b'),
    ];

    return patterns.any((p) => p.hasMatch(message));
  }

  static bool _hasCredentialRequestIntent(String message) {
    final patterns = [
      // Login/access (Spanish)
      RegExp(r'\b(ingresa|ingresar|accede|acceder|entra|entrar|inicia.*sesion|iniciar.*sesion)\b', caseSensitive: false),

      // Login/access (English)
      RegExp(r'\b(login|log.*in|sign.*in|access|enter|unlock)\b', caseSensitive: false),
      RegExp(r'\b(click.*here|tap.*here|go.*to)\b', caseSensitive: false),

      // Verification (Spanish)
      RegExp(r'\b(verifica.*identidad|verificar.*identidad|confirma.*identidad|confirmar.*identidad)\b', caseSensitive: false),
      RegExp(r'\b(codigo.*verificacion|codigo.*seguridad)\b', caseSensitive: false),

      // Verification (English)
      RegExp(r'\b(verify|verification|confirm|validate)\b', caseSensitive: false),
      RegExp(r'\b(verification.*code|security.*code)\b', caseSensitive: false),

      // Review/Check (Spanish)
      RegExp(r'\b(revise|revisar|consulta|consultar|comprueba|comprobar)\b', caseSensitive: false),
      RegExp(r'\b(detectamos.*intento|intento.*acceso|acceso.*sospechoso)\b', caseSensitive: false),

      // Review/Check (English)
      RegExp(r'\b(review|check|examine|inspect)\b', caseSensitive: false),
      RegExp(r'\b(suspicious.*activity|activity.*detected|unusual.*activity)\b', caseSensitive: false),

      // Updates (Spanish)
      RegExp(r'\b(actualiza.*contrasena|actualizar.*contrasena|cambia.*clave|cambiar.*clave)\b', caseSensitive: false),
      RegExp(r'\b(actualiza.*datos|actualizar.*datos|actualiza.*informacion)\b', caseSensitive: false),

      // Updates (English)
      RegExp(r'\b(update.*password|change.*password|reset.*password)\b', caseSensitive: false),
      RegExp(r'\b(update.*info|update.*details)\b', caseSensitive: false),
    ];

    return patterns.any((p) => p.hasMatch(message));
  }

  static bool _hasUrgencyPressureIntent(String message) {
    final patterns = [
      // Time pressure (Spanish)
      RegExp(r'\b(urgente|inmediatamente|ahora.*mismo|ya|rapido|rapidamente)\b', caseSensitive: false),
      RegExp(r'\b(hoy.*vence|vence.*hoy|ultimo.*dia|ultima.*oportunidad)\b', caseSensitive: false),
      RegExp(r'\b(solo.*por.*hoy|solo.*hoy|expira.*hoy)\b', caseSensitive: false),

      // Time pressure (English)
      RegExp(r'\b(urgent|immediately|right.*now|asap|quickly)\b', caseSensitive: false),
      RegExp(r'\b(expires.*today|today.*only|last.*chance|final.*notice)\b', caseSensitive: false),
      RegExp(r'\b(act.*now|respond.*now|must.*act)\b', caseSensitive: false),

      // Threats (Spanish)
      RegExp(r'\b(suspendida|suspendido|suspender|bloqueada|bloqueado|bloquear)\b', caseSensitive: false),
      RegExp(r'\b(cancelada|cancelado|cancelar|perderas|perdera)\b', caseSensitive: false),
      RegExp(r'\b(sera.*suspendida|sera.*bloqueada|sera.*cancelada)\b', caseSensitive: false),

      // Threats (English)
      RegExp(r'\b(suspended|suspend|blocked|block|locked|lock)\b', caseSensitive: false),
      RegExp(r'\b(cancelled|cancel|terminated|terminate)\b', caseSensitive: false),
      RegExp(r'\b(will.*be.*suspended|will.*be.*blocked|will.*be.*locked)\b', caseSensitive: false),
    ];

    return patterns.any((p) => p.hasMatch(message));
  }

  static bool _hasInformationRequestIntent(String message) {
    final patterns = [
      RegExp(r'\b(actualiza.*direccion|actualizar.*direccion|confirma.*direccion)\b'),
      RegExp(r'\b(actualiza.*telefono|actualizar.*telefono|confirma.*telefono)\b'),
      RegExp(r'\b(proporciona.*informacion|proporcionar.*informacion)\b'),
      RegExp(r'\b(completa.*datos|completar.*datos|registra.*datos)\b'),
    ];

    return patterns.any((p) => p.hasMatch(message));
  }

  static bool _hasPrizeClaimIntent(String message) {
    final patterns = [
      RegExp(r'\b(felicidades|ganaste|ganador|ganadora|has.*ganado)\b'),
      RegExp(r'\b(premio|recompensa|bono|regalo|sorteo)\b'),
      RegExp(r'\b(reclama|reclamar|cobra|cobrar|retira|retirar)\b'),
      RegExp(r'\b(seleccionado|seleccionada|elegido|elegida)\b'),
    ];

    return patterns.any((p) => p.hasMatch(message));
  }

  static bool _hasPromotionalIntent(String message) {
    final patterns = [
      RegExp(r'\b(oferta|descuento|promocion|rebaja)\b'),
      RegExp(r'\b(puntos|millas|beneficio|ventaja)\b'),
      RegExp(r'\b(plan|paquete|servicio)\b'),
    ];

    return patterns.any((p) => p.hasMatch(message));
  }
}
