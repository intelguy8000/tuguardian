import '../models/sms_message.dart';

class DetectionService {
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
    RegExp(r'573\d{8}|32\d{8}', caseSensitive: false), // Números colombianos sospechosos
    
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
    'interrapidisimo.com', // Real vs fake (www3.interrapidisimo.com)
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
    'INTERRAPIDISIMO', 'INTER RAPIDISIMO', // Vs real Interrapidísimo
    'PROGRAMA OPORTUNIDAD FAMILIAR',
    'OPORTUNIDAD FAMILIAR',
  ];

  /// ANÁLISIS PRINCIPAL CON TUS DATOS REALES
  static SMSMessage analyzeMessage(String id, String sender, String message, DateTime timestamp) {
    int riskScore = calculateRiskScore(message, sender);
    List<String> suspiciousElements = identifySuspiciousElements(message, sender);
    bool shouldQuarantine = riskScore >= 75; // Más agresivo para proteger mejor
    
    return SMSMessage(
      id: id,
      sender: sender,
      message: message,
      timestamp: timestamp,
      riskScore: riskScore,
      isQuarantined: shouldQuarantine,
      suspiciousElements: suspiciousElements,
    );
  }
  
  /// CÁLCULO DE RIESGO MEJORADO
  static int calculateRiskScore(String message, String sender) {
    int score = 0;
    
    // VERIFICAR REMITENTE CONFIABLE PRIMERO
    if (_isKnownTrustedSender(sender)) {
      score -= 20; // Reducir riesgo para remitentes conocidos
    }
    
    // PATRONES SOSPECHOSOS (peso alto por datos reales)
    for (RegExp pattern in _suspiciousPatterns) {
      if (pattern.hasMatch(message)) {
        score += 25; // Aumentado porque son patrones reales
      }
    }
    
    // ANÁLISIS DE URLs (crítico)
    score += _analyzeUrlsEnhanced(message);
    
    // EMPRESAS FALSAS
    for (String company in _suspiciousCompanies) {
      if (message.toUpperCase().contains(company)) {
        score += 35; // Muy sospechoso
      }
    }
    
    // COMBINACIÓN LETAL: DINERO + URGENCIA + ENLACE
    if (_containsMoneyKeywords(message) && 
        _containsUrgencyKeywords(message) && 
        _containsLinks(message)) {
      score += 40; // Combinación de tus ejemplos reales
    }
    
    // ANÁLISIS DEL REMITENTE
    score += _analyzeSenderEnhanced(sender);
    
    // PATRONES ESPECÍFICOS DE TUS EJEMPLOS
    score += _analyzeSpecificPatterns(message);
    
    // MAYÚSCULAS EXCESIVAS (como en tus ejemplos)
    if (_hasExcessiveCapitals(message)) {
      score += 15;
    }
    
    // NÚMEROS SOSPECHOSOS (como 43.859, 87.717)
    if (_containsSuspiciousNumbers(message)) {
      score += 20;
    }
    
    return score.clamp(0, 100);
  }
  
  /// ANÁLISIS DE URLs MEJORADO
  static int _analyzeUrlsEnhanced(String message) {
    int urlScore = 0;
    
    // Buscar dominios maliciosos conocidos
    for (String domain in _maliciousDomains) {
      if (message.toLowerCase().contains(domain)) {
        urlScore += 45; // Muy alto para dominios conocidos maliciosos
      }
    }
    
    // URLs con patrones sospechosos de tus ejemplos
    if (RegExp(r'https?://[a-z0-9]+\.[a-z]{2,3}/[A-Za-z0-9]{6,}').hasMatch(message)) {
      urlScore += 25; // URLs con códigos largos
    }
    
    // URLs con números al final (patrón de tus ejemplos)
    if (RegExp(r'https?://.*\d{5,}').hasMatch(message)) {
      urlScore += 20;
    }
    
    return urlScore;
  }
  
  /// ANÁLISIS DE REMITENTE MEJORADO
  static int _analyzeSenderEnhanced(String sender) {
    int senderScore = 0;
    
    // Números largos como en tus ejemplos (+573001234567)
    if (RegExp(r'^\+?57[0-9]{10}$').hasMatch(sender)) {
      senderScore += 15; // Números colombianos largos sospechosos
    }
    
    // Códigos cortos desconocidos (no en lista confiable)
    if (RegExp(r'^\d{5,6}$').hasMatch(sender) && !_trustedSenders.contains(sender)) {
      senderScore += 25;
    }
    
    return senderScore;
  }
  
  /// PATRONES ESPECÍFICOS DE TUS EJEMPLOS
  static int _analyzeSpecificPatterns(String message) {
    int score = 0;
    
    // Patrón "JUAN" personalizado (muy común en smishing)
    if (RegExp(r'JUAN\s+(?:HOY|TU|DEUDA|FACTURA)', caseSensitive: false).hasMatch(message)) {
      score += 30;
    }
    
    // Patrón de cantidades específicas de tus ejemplos
    if (RegExp(r'43\.859|87\.717').hasMatch(message)) {
      score += 35; // Cantidades específicas de estafa
    }
    
    // Códigos de envío falsos
    if (RegExp(r'\d{12,15}').hasMatch(message)) {
      score += 15; // Códigos largos como 700127548075
    }
    
    return score;
  }
  
  /// IDENTIFICAR ELEMENTOS SOSPECHOSOS ESPECÍFICOS
  static List<String> identifySuspiciousElements(String message, String sender) {
    List<String> elements = [];
    
    // Verificar dominios maliciosos específicos
    for (String domain in _maliciousDomains) {
      if (message.toLowerCase().contains(domain)) {
        elements.add('Dominio malicioso conocido: $domain');
      }
    }
    
    // Empresas falsas
    for (String company in _suspiciousCompanies) {
      if (message.toUpperCase().contains(company)) {
        elements.add('Empresa falsa detectada');
      }
    }
    
    // Patrones de urgencia de tus ejemplos
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
    // Números específicos de tus ejemplos de estafa
    List<String> suspiciousNumbers = ['43.859', '87.717', '300,000', '15,000.00'];
    return suspiciousNumbers.any((number) => message.contains(number));
  }
}