import '../models/sms_message.dart';
import 'official_entities_service.dart';

class DetectionService {
  static final List<RegExp> _suspiciousPatterns = [
    RegExp(r'HOY\s+VENCE|VENCE\s+HOY|SUSPENDIDA?|SUSPENSION', caseSensitive: false),
    RegExp(r'URGENTE|INMEDIATAMENTE|AHORA\s+MISMO|SOLO\s+POR\s+HOY', caseSensitive: false),
    RegExp(r'FACTURA\s+SERA?\s+SUSPENDIDA?|DEUDA\s+SERA?\s+SUSPENDIDA?', caseSensitive: false),
    RegExp(r'paga\s+hoy\s+solo|paga\s+tan\s+solo|solo\s+por\s+hoy', caseSensitive: false),
    RegExp(r'\d{2,3}\.\d{3}|\d{1,3},\d{3}|43\.859|87\.717', caseSensitive: false),
    RegExp(r'FELICIDADES?.*ganado|has\s+ganado|programa\s+oportunidad', caseSensitive: false),
    RegExp(r'recompensas?\s+sera?\s+de|premio|sorteo|bono', caseSensitive: false),
    RegExp(r'300,000\s+pesos?|500,000|15,000\.00', caseSensitive: false),
    RegExp(r'actualiza\s+la\s+direccion|direccion.*incorrecta', caseSensitive: false),
    RegExp(r'no\s+podemos\s+comunicarnos|articulos?\s+seran?\s+devueltos?', caseSensitive: false),
    RegExp(r'verification\s+code|codigo\s+de\s+verificacion', caseSensitive: false),
    RegExp(r'INTERRAPIDISIMO|inter\.la|mcpag\.li', caseSensitive: false),
    RegExp(r'seguridad\s+de\s+la\s+cuenta\s+microsoft', caseSensitive: false),
    RegExp(r'programa\s+oportunidad\s+familiar', caseSensitive: false),
    RegExp(r'bit\.ly|llihi\.cc|bly-faclr\.at|pagdsct[a-z0-9]+\.fi', caseSensitive: false),
    RegExp(r'inter\.la|mcpag\.li|ln\.run|sit-onclr\.de', caseSensitive: false),
    RegExp(r'www3\.interrapidisimo\.com.*ApiUrl', caseSensitive: false),
    RegExp(r'contactame\s+por\s+ws|por\s+favor\s+contactame', caseSensitive: false),
    RegExp(r'573\d{8}|32\d{8}', caseSensitive: false),
    RegExp(r'click\s+here|haga?\s+clic|ingresa\s+ya|descarga\s+la\s+factura', caseSensitive: false),
    RegExp(r'complete?\s+para\s+el\s+envio|ponte?\s+al\s+dia', caseSensitive: false),
  ];
  
  static final List<String> _maliciousDomains = [
    'bit.ly', 'llihi.cc', 'mcpag.li', 'inter.la', 'ln.run',
    'bly-faclr.at', 'sit-onclr.de', 'pagdscttoocl.fi',
    'www3.interrapidisimo.com', 'blilylcr.fj',
  ];
  
  static final List<String> _trustedDomains = [
    'sura.com', 'bancolombia.com', 'davivienda.com', 'bbva.co',
    'movistar.co', 'claro.com.co', 'tigo.com.co', 'etb.com.co',
    'google.com', 'apple.com', 'microsoft.com', 'amazon.com',
    'interrapidisimo.com', 'mi.movistar.co',
  ];
  
  static final List<String> _trustedSenders = [
    '891888', '899888', // SURA
    '85432', '85433', '891333', // Bancolombia
    '787878', // Movistar  
    '747474', // Claro
    '636363', // Tigo
    '3211033000', // Movistar oficial
  ];
  
  static final List<String> _suspiciousCompanies = [
    'INTERRAPIDISIMO', 'INTER RAPIDISIMO',
    'PROGRAMA OPORTUNIDAD FAMILIAR',
    'OPORTUNIDAD FAMILIAR',
  ];

  static SMSMessage analyzeMessage(String id, String sender, String message, DateTime timestamp) {
    int riskScore = calculateRiskScore(message, sender);
    List<String> suspiciousElements = identifySuspiciousElements(message, sender);
    bool shouldQuarantine = riskScore >= 75;
    
    List<OfficialEntity> detectedEntities = OfficialEntitiesService.detectEntitiesInMessage(message);
    print('DEBUG: Mensaje: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');
    print('DEBUG: Remitente: $sender (${_isTrustedSender(sender) ? "VERIFICADO" : "NO VERIFICADO"})');
    print('DEBUG: Entidades detectadas: ${detectedEntities.length}');
    for (var entity in detectedEntities) {
      print('DEBUG: - ${entity.name}');
    }

    List<OfficialContactSuggestion> officialSuggestions = 
        OfficialEntitiesService.generateContactSuggestions(detectedEntities);
    print('DEBUG: Sugerencias generadas: ${officialSuggestions.length}');
    print('DEBUG: Score final: $riskScore');

    if (detectedEntities.isNotEmpty && riskScore >= 70) {
      suspiciousElements.add('Suplanta entidad conocida: ${detectedEntities.map((e) => e.name).join(', ')}');
      riskScore = (riskScore + 10).clamp(0, 100);
    }
    
    return SMSMessage(
      id: id,
      sender: sender,
      message: message,
      timestamp: timestamp,
      riskScore: riskScore,
      isQuarantined: shouldQuarantine,
      suspiciousElements: suspiciousElements,
      detectedEntities: detectedEntities,
      officialSuggestions: officialSuggestions,
    );
  }
  
  static int calculateRiskScore(String message, String sender) {
    int score = 0;
    
    // Remitente verificado reduce riesgo
    if (_isKnownTrustedSender(sender)) {
      score -= 20;
    }
    
    // NUEVO: Remitente texto (no numérico) + URL = MUY SOSPECHOSO
    if (!_isTrustedSender(sender) && !RegExp(r'^\d+$').hasMatch(sender) && _containsLinks(message)) {
      score += 35; // Remitente texto con URL es automáticamente sospechoso
    }
    
    // NUEVO: Detectar dominios bancarios/empresariales falsos
    score += _detectFakeDomains(message);
    
    for (RegExp pattern in _suspiciousPatterns) {
      if (pattern.hasMatch(message)) {
        score += 25;
      }
    }
    
    score += _analyzeUrlsEnhanced(message);
    
    for (String company in _suspiciousCompanies) {
      if (message.toUpperCase().contains(company)) {
        score += 35;
      }
    }
    
    if (_containsMoneyKeywords(message) && 
        _containsUrgencyKeywords(message) && 
        _containsLinks(message)) {
      score += 40;
    }
    
    score += _analyzeSenderEnhanced(sender);
    score += _analyzeSpecificPatterns(message);
    
    if (_hasExcessiveCapitals(message)) {
      score += 15;
    }
    
    if (_containsSuspiciousNumbers(message)) {
      score += 20;
    }
    
    return score.clamp(0, 100);
  }
  
  // NUEVO: Detectar dominios falsos que imitan empresas legítimas
  static int _detectFakeDomains(String message) {
    List<Map<String, dynamic>> fakeDomainPatterns = [
      // Bancos
      {'pattern': 'bancolombia-seguro', 'score': 50, 'type': 'Phishing bancario'},
      {'pattern': 'bancolombia-verificacion', 'score': 50, 'type': 'Phishing bancario'},
      {'pattern': 'bancolombia-secure', 'score': 50, 'type': 'Phishing bancario'},
      {'pattern': 'davivienda-secure', 'score': 50, 'type': 'Phishing bancario'},
      {'pattern': 'davivienda-seguridad', 'score': 50, 'type': 'Phishing bancario'},
      {'pattern': 'bbva-seguridad', 'score': 50, 'type': 'Phishing bancario'},
      {'pattern': 'bogota-seguridad', 'score': 50, 'type': 'Phishing bancario'},
      {'pattern': 'banco-verificacion', 'score': 50, 'type': 'Phishing bancario'},
      
      // Otros servicios
      {'pattern': 'netflix-billing', 'score': 45, 'type': 'Phishing servicio'},
      {'pattern': 'appleid-support', 'score': 45, 'type': 'Phishing servicio'},
      {'pattern': 'dhl-secure-delivery', 'score': 45, 'type': 'Phishing logística'},
      {'pattern': 'primaxa.co', 'score': 40, 'type': 'Dominio falso (real: primax.com.co)'},
      {'pattern': 'premios-colombia', 'score': 40, 'type': 'Premio falso'},
      {'pattern': 'giros-seguro', 'score': 40, 'type': 'Giro falso'},
    ];
    
    String lowerMessage = message.toLowerCase();
    
    for (var pattern in fakeDomainPatterns) {
      if (lowerMessage.contains(pattern['pattern'])) {
        print('DEBUG: Dominio falso detectado: ${pattern['pattern']} (+${pattern['score']})');
        return pattern['score'] as int;
      }
    }
    
    return 0;
  }
  
  static int _analyzeUrlsEnhanced(String message) {
    int urlScore = 0;
    
    for (String domain in _maliciousDomains) {
      if (message.toLowerCase().contains(domain)) {
        urlScore += 45;
      }
    }
    
    if (RegExp(r'https?://[a-z0-9]+\.[a-z]{2,3}/[A-Za-z0-9]{6,}').hasMatch(message)) {
      urlScore += 25;
    }
    
    if (RegExp(r'https?://.*\d{5,}').hasMatch(message)) {
      urlScore += 20;
    }
    
    return urlScore;
  }
  
  static int _analyzeSenderEnhanced(String sender) {
    int senderScore = 0;
    
    if (RegExp(r'^\+?57[0-9]{10}$').hasMatch(sender)) {
      senderScore += 15;
    }
    
    if (RegExp(r'^\d{5,6}$').hasMatch(sender) && !_trustedSenders.contains(sender)) {
      senderScore += 25;
    }
    
    return senderScore;
  }
  
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
  
  static List<String> identifySuspiciousElements(String message, String sender) {
    List<String> elements = [];
    
    // NUEVO: Advertencia si remitente es texto con URL
    if (!RegExp(r'^\d+$').hasMatch(sender) && _containsLinks(message)) {
      elements.add('Remitente no verificado con enlace - Alto riesgo');
    }
    
    for (String domain in _maliciousDomains) {
      if (message.toLowerCase().contains(domain)) {
        elements.add('Dominio malicioso conocido: $domain');
      }
    }
    
    for (String company in _suspiciousCompanies) {
      if (message.toUpperCase().contains(company)) {
        elements.add('Empresa falsa detectada');
      }
    }
    
    if (RegExp(r'HOY\s+VENCE|SUSPENDIDA?', caseSensitive: false).hasMatch(message)) {
      elements.add('Urgencia artificial detectada');
    }
    
    if (RegExp(r'43\.859|87\.717|300,000').hasMatch(message)) {
      elements.add('Cantidades típicas de estafa');
    }
    
    if (RegExp(r'JUAN\s+(?:HOY|TU)', caseSensitive: false).hasMatch(message)) {
      elements.add('Personalización falsa detectada');
    }
    
    return elements;
  }
  
  static bool _isKnownTrustedSender(String sender) {
    return _trustedSenders.contains(sender);
  }
  
  static bool _isTrustedSender(String sender) {
    return _trustedSenders.contains(sender) || RegExp(r'^\d{4,}$').hasMatch(sender);
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