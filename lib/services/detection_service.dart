import '../shared/models/sms_message.dart';
import '../detection/entities/official_entities_service.dart';
import 'intent_detection_service.dart';

class DetectionService {
  // ⛔ PATRONES CRÍTICOS: SEGURIDAD BANCARIA (score +40)
  // Protección especial para adultos mayores contra fraudes de "clave generada"
  static final List<RegExp> _criticalSecurityPatterns = [
    RegExp(r'\bclave\s+(principal|dinamica|segura?|de\s+acceso)\s+(fue|ha\s+sido)?\s*(generada?|cambiada?|modificada?|actualizada?)', caseSensitive: false),
    RegExp(r'\b(pin|password|contraseña)\s+(fue|ha\s+sido)?\s*(generado?a?|cambiado?a?|modificado?a?)', caseSensitive: false),
    RegExp(r'\b(tarjeta|cuenta|acceso)\s+(bloqueada?|suspendida?|inhabilitada?|clonada?)', caseSensitive: false),
    RegExp(r'\bmovimiento\s+no\s+reconocido|transaccion\s+no\s+autorizada', caseSensitive: false),
  ];

  // PATRONES BASADOS EN TUS SMS REALES
  static final List<RegExp> _suspiciousPatterns = [
    // URGENCIA EXTREMA (de tus ejemplos)
    RegExp(r'HOY\s+VENCE|VENCE\s+HOY|SUSPENDIDA?|SUSPENSION', caseSensitive: false),
    RegExp(r'URGENTE|INMEDIATAMENTE|AHORA\s+MISMO|SOLO\s+POR\s+HOY', caseSensitive: false),
    
    // DINERO Y FACTURAS (patrones reales de tus SMS)
    RegExp(r'FACTURA\s+SERA?\s+SUSPENDIDA?|DEUDA\s+SERA?\s+SUSPENDIDA?', caseSensitive: false),
    RegExp(r'paga\s+hoy\s+solo|paga\s+tan\s+solo|solo\s+por\s+hoy', caseSensitive: false),
    RegExp(r'\d{2,3}\.\d{3}|\d{1,3},\d{3}|43\.859|87\.717', caseSensitive: false),
    
    // PREMIOS Y OPORTUNIDADES FALSAS
    RegExp(r'FELICIDADES?.*ganado|has\s+ganado|programa\s+oportunidad', caseSensitive: false),
    RegExp(r'recompensas?\s+sera?\s+de|premio|sorteo|bono', caseSensitive: false),
    RegExp(r'300,000\s+pesos?|500,000|15,000\.00', caseSensitive: false),
    
    // VERIFICACIÓN Y ACTUALIZACIONES FALSAS
    RegExp(r'actualiza\s+la\s+direccion|direccion.*incorrecta', caseSensitive: false),
    RegExp(r'no\s+podemos\s+comunicarnos|articulos?\s+seran?\s+devueltos?', caseSensitive: false),
    RegExp(r'verification\s+code|codigo\s+de\s+verificacion', caseSensitive: false),
    
    // EMPRESAS Y SERVICIOS FALSOS
    RegExp(r'INTERRAPIDISIMO|inter\.la|mcpag\.li', caseSensitive: false),
    RegExp(r'seguridad\s+de\s+la\s+cuenta\s+microsoft', caseSensitive: false),
    RegExp(r'programa\s+oportunidad\s+familiar', caseSensitive: false),
    
    // ENLACES SOSPECHOSOS REALES
    RegExp(r'bit\.ly|llihi\.cc|bly-faclr\.at|pagdsct[a-z0-9]+\.fi', caseSensitive: false),
    RegExp(r'inter\.la|mcpag\.li|ln\.run|sit-onclr\.de', caseSensitive: false),
    RegExp(r'www3\.interrapidisimo\.com.*ApiUrl', caseSensitive: false),
    
    // CONTACTO SOSPECHOSO
    RegExp(r'contactame\s+por\s+ws|por\s+favor\s+contactame', caseSensitive: false),
    RegExp(r'573\d{8}|32\d{8}', caseSensitive: false),
    
    // ACCIONES URGENTES
    RegExp(r'click\s+here|haga?\s+clic|ingresa\s+ya|descarga\s+la\s+factura', caseSensitive: false),
    RegExp(r'complete?\s+para\s+el\s+envio|ponte?\s+al\s+dia', caseSensitive: false),
  ];
  
  // DOMINIOS MALICIOSOS REALES DE TUS SMS
  static final List<String> _maliciousDomains = [
    'bit.ly', 'llihi.cc', 'mcpag.li', 'inter.la', 'ln.run',
    'bly-faclr.at', 'sit-onclr.de', 'pagdscttoocl.fi',
    'www3.interrapidisimo.com', 'blilylcr.fj',
  ];
  
  // DOMINIOS LEGÍTIMOS (para evitar falsos positivos)
  static final List<String> _trustedDomains = [
    'sura.com', 'bancolombia.com', 'davivienda.com', 'bbva.co',
    'movistar.co', 'claro.com.co', 'tigo.com.co', 'etb.com.co',
    'google.com', 'apple.com', 'microsoft.com', 'amazon.com',
    'interrapidisimo.com', 'primax.com.co', 'netflix.com',
    'colpensiones.gov.co', 'dhl.com',
  ];
  
  // NÚMEROS LEGÍTIMOS (códigos cortos conocidos)
  static final List<String> _trustedSenders = [
    '891888', '899888', // SURA
    '85432', '85433', // Bancolombia
    '787878', // Movistar  
    '747474', // Claro
    '636363', // Tigo
  ];
  
  // PALABRAS DE EMPRESAS FALSAS/SOSPECHOSAS
  static final List<String> _suspiciousCompanies = [
    'INTERRAPIDISIMO', 'INTER RAPIDISIMO',
    'PROGRAMA OPORTUNIDAD FAMILIAR',
    'OPORTUNIDAD FAMILIAR',
  ];

  /// NUEVA FUNCIONALIDAD: Extraer URLs reales del mensaje
  static List<String> extractRealLinks(String message) {
    final urlPattern = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );
    
    return urlPattern.allMatches(message)
      .map((match) => match.group(0)!)
      .toList();
  }

  /// NUEVO: Extraer dominios escritos como texto plano (sin https://)
  static List<String> extractPlainTextDomains(String message) {
    // Patrón para dominios escritos como texto: ejemplo.com, mi.movistar.co
    final domainPattern = RegExp(
      r'\b(?:www\.)?([a-z0-9-]+\.)+[a-z]{2,6}\b',
      caseSensitive: false,
    );
    
    return domainPattern.allMatches(message)
      .map((match) => match.group(0)!)
      .toList();
  }

  /// NUEVO: Detectar calls-to-action que sugieren ingresar a un sitio
  static bool hasCallToAction(String message) {
    final actionPatterns = [
      RegExp(r'ingresa\s+(a|en|al|por)', caseSensitive: false),
      RegExp(r'visita\s+(a|el|la|nuestro|nuestra)', caseSensitive: false),
      RegExp(r'accede\s+(a|al|en)', caseSensitive: false),
      RegExp(r'entra\s+(a|en|al)', caseSensitive: false),
      RegExp(r'haz\s+clic|haga\s+clic|click\s+here', caseSensitive: false),
      RegExp(r'consulta\s+(en|tu|con)', caseSensitive: false),
      RegExp(r'descarga\s+(la|el|tu)', caseSensitive: false),
      RegExp(r'actualiza\s+(tu|tus|la)', caseSensitive: false),
      RegExp(r'verifica\s+(tu|tus|en)', caseSensitive: false),
      RegExp(r'confirma\s+(tu|tus|en)', caseSensitive: false),
    ];
    
    return actionPatterns.any((pattern) => pattern.hasMatch(message));
  }

  /// NUEVA FUNCIONALIDAD: Extraer dominio de una URL
  static String? extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.toLowerCase();
    } catch (e) {
      return null;
    }
  }

  /// NUEVA FUNCIONALIDAD: Verificar si un dominio es confiable
  static bool isDomainTrusted(String domain) {
    return _trustedDomains.any((trusted) => 
      domain == trusted || domain.endsWith('.$trusted')
    );
  }

  /// NUEVA FUNCIONALIDAD: Determinar si debe mostrar canales oficiales
  /// FILOSOFÍA: Desconfianza por defecto + Protección ante calls-to-action
  static bool shouldShowOfficialChannels(String message, int riskScore) {
    // Detectar entidades oficiales mencionadas
    var entities = OfficialEntitiesService.detectEntitiesInMessage(message);
    
    // Extraer links completos (https://...)
    var links = extractRealLinks(message);
    
    // Extraer dominios en texto plano (ejemplo.com)
    var plainDomains = extractPlainTextDomains(message);
    
    // Detectar calls-to-action (ingresa a, visita, etc.)
    bool hasAction = hasCallToAction(message);
    
    // REGLA 1: Entidad + URL completa → Mostrar canales
    if (entities.isNotEmpty && links.isNotEmpty) {
      return true;
    }
    
    // REGLA 2: Entidad + dominio texto plano → Mostrar canales
    if (entities.isNotEmpty && plainDomains.isNotEmpty) {
      return true;
    }
    
    // REGLA 3: Entidad + call-to-action → Mostrar canales
    // Protege contra mensajes que dictan acción sobre el usuario
    if (entities.isNotEmpty && hasAction) {
      return true;
    }
    
    // REGLA 4: Mensaje peligroso (riskScore >= 70) → Mostrar canales
    if (riskScore >= 70) {
      return true;
    }
    
    return false;
  }

  /// ANÁLISIS PRINCIPAL CON TUS DATOS REALES + INTENT DETECTION
  static SMSMessage analyzeMessage(String id, String sender, String message, DateTime timestamp) {
    // 1. INTENT ANALYSIS (nuevo sistema)
    IntentAnalysisResult intentAnalysis = IntentDetectionService.analyzeIntent(message, sender);

    // 2. PATTERN-BASED RISK SCORE (sistema existente)
    int baseRiskScore = calculateRiskScore(message, sender);

    // 3. BOOST SCORE BASED ON INTENT
    int finalRiskScore = (baseRiskScore + intentAnalysis.intentRiskBoost).clamp(0, 100);

    // 4. IDENTIFY SUSPICIOUS ELEMENTS
    List<String> suspiciousElements = identifySuspiciousElements(message, sender);

    // Add intent-based guidance to suspicious elements
    if (intentAnalysis.isHighRisk) {
      suspiciousElements.insert(0, intentAnalysis.userGuidance);
    }

    // 5. QUARANTINE DECISION
    bool shouldQuarantine = finalRiskScore >= 75 || intentAnalysis.shouldBlockLinks;

    // 6. DETECT ENTITIES
    var detectedEntities = OfficialEntitiesService.detectEntitiesInMessage(message);

    // 7. GENERATE OFFICIAL SUGGESTIONS IF NEEDED
    List<OfficialContactSuggestion>? officialSuggestions;
    if (detectedEntities.isNotEmpty && intentAnalysis.shouldBlockLinks) {
      officialSuggestions = OfficialEntitiesService.generateContactSuggestions(detectedEntities);
    }

    return SMSMessage(
      id: id,
      sender: sender,
      message: message,
      timestamp: timestamp,
      riskScore: finalRiskScore,
      isQuarantined: shouldQuarantine,
      suspiciousElements: suspiciousElements,
      detectedEntities: detectedEntities.isNotEmpty ? detectedEntities : null,
      officialSuggestions: officialSuggestions,
      intentAnalysis: intentAnalysis,
    );
  }
  
  /// CÁLCULO DE RIESGO MEJORADO
  static int calculateRiskScore(String message, String sender) {
    int score = 0;

    // VERIFICAR REMITENTE CONFIABLE PRIMERO
    if (_isKnownTrustedSender(sender)) {
      score -= 20;
    }

    // ⛔ MÁXIMA PRIORIDAD: PATRONES CRÍTICOS DE SEGURIDAD BANCARIA (+40)
    // Detecta fraudes que asustan adultos mayores (ej: "clave generada")
    for (RegExp pattern in _criticalSecurityPatterns) {
      if (pattern.hasMatch(message)) {
        score += 40; // BOOST FUERTE - protección para vulnerables
        break; // Solo contar una vez
      }
    }

    // PATRONES SOSPECHOSOS
    for (RegExp pattern in _suspiciousPatterns) {
      if (pattern.hasMatch(message)) {
        score += 25;
      }
    }
    
    // ANÁLISIS DE URLs MEJORADO
    score += _analyzeUrlsEnhanced(message);
    
    // NUEVA: Análisis de discrepancia entre texto y links
    score += _analyzeUrlTextDiscrepancy(message);
    
    // EMPRESAS FALSAS
    for (String company in _suspiciousCompanies) {
      if (message.toUpperCase().contains(company)) {
        score += 35;
      }
    }
    
    // COMBINACIÓN LETAL: DINERO + URGENCIA + ENLACE
    if (_containsMoneyKeywords(message) && 
        _containsUrgencyKeywords(message) && 
        _containsLinks(message)) {
      score += 40;
    }
    
    // ANÁLISIS DEL REMITENTE
    score += _analyzeSenderEnhanced(sender);
    
    // PATRONES ESPECÍFICOS
    score += _analyzeSpecificPatterns(message);
    
    // MAYÚSCULAS EXCESIVAS
    if (_hasExcessiveCapitals(message)) {
      score += 15;
    }
    
    // NÚMEROS SOSPECHOSOS
    if (_containsSuspiciousNumbers(message)) {
      score += 20;
    }
    
    return score.clamp(0, 100);
  }

  /// NUEVA: Analizar discrepancia entre texto visible y URLs reales
  /// ENFOQUE CONSERVADOR: No validamos legitimidad, solo detectamos inconsistencias
  static int _analyzeUrlTextDiscrepancy(String message) {
    int score = 0;
    
    // Extraer links reales
    var links = extractRealLinks(message);
    if (links.isEmpty) return 0;
    
    // Detectar si menciona entidades oficiales
    var entities = OfficialEntitiesService.detectEntitiesInMessage(message);
    
    // Si menciona entidad oficial + tiene links = Sospechoso por defecto
    // No intentamos validar si el link es legítimo
    if (entities.isNotEmpty && links.isNotEmpty) {
      score += 30; // SOSPECHOSO: Entidad mencionada + link presente
    }
    
    // URLs acortadas (siempre aumentan sospecha)
    for (var link in links) {
      String? domain = extractDomain(link);
      if (domain != null && (
        domain.contains('bit.ly') ||
        domain.contains('tinyurl') ||
        domain.contains('goo.gl') ||
        domain.length < 10
      )) {
        score += 25;
      }
    }
    
    return score;
  }
  
  /// ANÁLISIS DE URLs MEJORADO
  static int _analyzeUrlsEnhanced(String message) {
    int urlScore = 0;
    
    // Buscar dominios maliciosos conocidos
    for (String domain in _maliciousDomains) {
      if (message.toLowerCase().contains(domain)) {
        urlScore += 45;
      }
    }
    
    // URLs con patrones sospechosos
    if (RegExp(r'https?://[a-z0-9]+\.[a-z]{2,3}/[A-Za-z0-9]{6,}').hasMatch(message)) {
      urlScore += 25;
    }
    
    // URLs con números al final
    if (RegExp(r'https?://.*\d{5,}').hasMatch(message)) {
      urlScore += 20;
    }
    
    return urlScore;
  }
  
  /// ANÁLISIS DE REMITENTE MEJORADO
  static int _analyzeSenderEnhanced(String sender) {
    int senderScore = 0;
    
    // Números largos colombianos
    if (RegExp(r'^\+?57[0-9]{10}$').hasMatch(sender)) {
      senderScore += 15;
    }
    
    // Códigos cortos desconocidos
    if (RegExp(r'^\d{5,6}$').hasMatch(sender) && !_trustedSenders.contains(sender)) {
      senderScore += 25;
    }
    
    return senderScore;
  }
  
  /// PATRONES ESPECÍFICOS
  static int _analyzeSpecificPatterns(String message) {
    int score = 0;
    
    if (RegExp(r'JUAN\s+(?:HOY|TU|DEUDA|FACTURA)', caseSensitive: false).hasMatch(message)) {
      score += 30;
    }
    
    if (RegExp(r'43\.859|87\.717').hasMatch(message)) {
      score += 35;
    }
    
    if (RegExp(r'\d{12,15}').hasMatch(message)) {
      score += 15;
    }
    
    return score;
  }
  
  /// IDENTIFICAR ELEMENTOS SOSPECHOSOS - ENFOQUE REALISTA AMPLIADO
  static List<String> identifySuspiciousElements(String message, String sender) {
    List<String> elements = [];

    // ⛔ PRIORIDAD 1: ALERTA CRÍTICA DE SEGURIDAD BANCARIA
    for (RegExp pattern in _criticalSecurityPatterns) {
      if (pattern.hasMatch(message)) {
        elements.add('⛔ ALERTA CRÍTICA: Mensaje menciona cambio de claves/acceso bancario');
        break; // Solo agregar una vez
      }
    }

    // Verificar dominios maliciosos conocidos
    for (String domain in _maliciousDomains) {
      if (message.toLowerCase().contains(domain)) {
        elements.add('Dominio malicioso conocido: $domain');
      }
    }

    // Detectar entidades mencionadas
    var entities = OfficialEntitiesService.detectEntitiesInMessage(message);
    var links = extractRealLinks(message);
    var plainDomains = extractPlainTextDomains(message);
    bool hasAction = hasCallToAction(message);
    
    // Si menciona entidad + URL completa
    if (entities.isNotEmpty && links.isNotEmpty) {
      elements.add('Link detectado - Verifica con canales oficiales');
    }
    
    // Si menciona entidad + dominio texto plano
    if (entities.isNotEmpty && plainDomains.isNotEmpty && links.isEmpty) {
      elements.add('Dominio mencionado - Verifica con canales oficiales');
    }
    
    // Si menciona entidad + call-to-action
    if (entities.isNotEmpty && hasAction) {
      elements.add('Mensaje solicita acción - Usa solo canales oficiales');
    }
    
    // Empresas falsas
    for (String company in _suspiciousCompanies) {
      if (message.toUpperCase().contains(company)) {
        elements.add('Empresa falsa detectada');
      }
    }
    
    // Patrones de urgencia
    if (RegExp(r'HOY\s+VENCE|SUSPENDIDA?', caseSensitive: false).hasMatch(message)) {
      elements.add('Urgencia artificial detectada');
    }
    
    // Cantidades sospechosas
    if (RegExp(r'43\.859|87\.717|300,000').hasMatch(message)) {
      elements.add('Cantidades típicas de estafa');
    }
    
    // Personalización falsa
    if (RegExp(r'JUAN\s+(?:HOY|TU)', caseSensitive: false).hasMatch(message)) {
      elements.add('Personalización falsa detectada');
    }
    
    return elements;
  }
  
  /// FUNCIONES AUXILIARES
  static bool _isKnownTrustedSender(String sender) {
    return _trustedSenders.contains(sender);
  }
  
  static bool _containsLinks(String message) {
    return RegExp(r'https?://').hasMatch(message);
  }
  
  static bool _containsMoneyKeywords(String message) {
    List<String> moneyKeywords = [
      'factura', 'deuda', 'pago', 'pesos', 'dinero', 'money',
      'cuenta', 'banco', 'tarjeta', 'recompensa', 'premio'
    ];
    return moneyKeywords.any((keyword) => 
        message.toLowerCase().contains(keyword));
  }
  
  static bool _containsUrgencyKeywords(String message) {
    List<String> urgencyKeywords = [
      'hoy', 'urgente', 'suspendida', 'vence', 'inmediatamente',
      'ahora', 'solo por hoy', 'último día'
    ];
    return urgencyKeywords.any((keyword) => 
        message.toLowerCase().contains(keyword));
  }
  
  static bool _hasExcessiveCapitals(String message) {
    if (message.length < 10) return false;
    int capitals = message.split('').where((char) => 
        char == char.toUpperCase() && char != char.toLowerCase()).length;
    return (capitals / message.length) > 0.4;
  }
  
  static bool _containsSuspiciousNumbers(String message) {
    List<String> suspiciousNumbers = ['43.859', '87.717', '300,000', '15,000.00'];
    return suspiciousNumbers.any((number) => message.contains(number));
  }
}