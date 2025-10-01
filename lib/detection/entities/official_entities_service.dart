class OfficialEntity {
  final String name;
  final String? whatsapp;
  final String? website;
  final bool hasApp;
  final List<String> aliases; // Variaciones del nombre

  const OfficialEntity({
    required this.name,
    this.whatsapp,
    this.website,
    this.hasApp = false,
    this.aliases = const [],
  });

  String get whatsappUrl => whatsapp != null ? 'https://wa.me/$whatsapp' : '';
  bool get hasWhatsApp => whatsapp != null && whatsapp!.isNotEmpty;
  bool get hasWebsite => website != null && website!.isNotEmpty;
}

class OfficialEntitiesService {
  // Base de datos de entidades oficiales con todos sus canales
  static final Map<String, OfficialEntity> _entities = {
    'bancolombia': OfficialEntity(
      name: 'Bancolombia',
      whatsapp: '573013536788',
      website: 'https://www.bancolombia.com',
      hasApp: true,
      aliases: ['banco colombia', 'banco de colombia', 'bancolombia s.a.'],
    ),
    
    'davivienda': OfficialEntity(
      name: 'Davivienda',
      website: 'https://www.davivienda.com',
      hasApp: true,
      aliases: ['banco davivienda', 'davivienda s.a.'],
    ),
    
    'banco_occidente': OfficialEntity(
      name: 'Banco de Occidente',
      whatsapp: '573186714836',
      website: 'https://www.bancodeoccidente.com.co',
      hasApp: true,
      aliases: ['occidente', 'banco occidente'],
    ),

    'banco_bogota': OfficialEntity(
      name: 'Banco de Bogotá',
      whatsapp: '573162222222',
      website: 'https://www.bancodebogota.com',
      hasApp: true,
      aliases: ['bogota', 'banco bogota', 'banco de bogotá'],
    ),

    'bank_of_america': OfficialEntity(
      name: 'Bank of America',
      website: 'https://www.bankofamerica.com',
      hasApp: true,
      aliases: ['bofa', 'boa', 'bank america'],
    ),

    'interrapidisimo': OfficialEntity(
      name: 'Inter Rapidísimo',
      website: 'https://www.interrapidisimo.com',
      hasApp: false,
      aliases: ['inter rapidísimo', 'inter rapidisimo', 'interrapidisimo', 'rapidisimo', 'inter.la'],
    ),
    
    'sura': OfficialEntity(
      name: 'Sura',
      whatsapp: '573152757888',
      website: 'https://www.sura.co/',
      hasApp: true,
      aliases: ['seguros sura', 'sura seguros', 'eps sura'],
    ),
    
    'claro': OfficialEntity(
      name: 'Claro',
      whatsapp: '573112000000',
      website: 'https://www.claro.com.co/',
      hasApp: true,
      aliases: ['claro colombia'],
    ),
    
    'netflix': OfficialEntity(
      name: 'Netflix',
      hasApp: true,
      aliases: [],
    ),
    
    'colpensiones': OfficialEntity(
      name: 'Colpensiones',
      whatsapp: '573169459307',
      website: 'https://www.colpensiones.gov.co/',
      hasApp: false,
      aliases: ['colpensiones colombia', 'administradora colpensiones'],
    ),
    
    'primax': OfficialEntity(
      name: 'Primax',
      website: 'https://www.primax.com.co/',
      hasApp: false,
      aliases: ['estaciones primax', 'gasolinera primax'],
    ),
    
    'dhl': OfficialEntity(
      name: 'DHL',
      website: 'https://www.dhl.com/',
      hasApp: true,
      aliases: ['dhl express', 'dhl colombia', 'paquete dhl', 'envío dhl', 'envio dhl'],
    ),

    'fedex': OfficialEntity(
      name: 'FedEx',
      website: 'https://www.fedex.com/',
      hasApp: true,
      aliases: ['fedex express', 'fedex colombia', 'paquete fedex'],
    ),

    'servientrega': OfficialEntity(
      name: 'Servientrega',
      website: 'https://www.servientrega.com/',
      hasApp: true,
      aliases: ['servientrega colombia', 'paquete servientrega'],
    ),

    'coordinadora': OfficialEntity(
      name: 'Coordinadora',
      website: 'https://www.coordinadora.com/',
      hasApp: true,
      aliases: ['coordinadora mercantil', 'paquete coordinadora'],
    ),
    
    'movistar': OfficialEntity(
      name: 'Movistar',
      whatsapp: '573152333333',
      website: 'https://www.movistar.com.co/',
      hasApp: true,
      aliases: ['telefónica movistar', 'movistar colombia','mi.movistar.co', 'movistar.co'],
    ),
  };

  /// Detectar entidades mencionadas en un mensaje SMS sospechoso
  static List<OfficialEntity> detectEntitiesInMessage(String message) {
    List<OfficialEntity> detectedEntities = [];
    String lowerMessage = message.toLowerCase();
    
    for (String key in _entities.keys) {
      OfficialEntity entity = _entities[key]!;
      
      // Buscar nombre principal
      if (lowerMessage.contains(entity.name.toLowerCase())) {
        if (!detectedEntities.contains(entity)) {
          detectedEntities.add(entity);
        }
        continue;
      }
      
      // Buscar en aliases
      for (String alias in entity.aliases) {
        if (lowerMessage.contains(alias.toLowerCase())) {
          if (!detectedEntities.contains(entity)) {
            detectedEntities.add(entity);
          }
          break;
        }
      }
    }
    
    return detectedEntities;
  }

  /// Obtener todas las entidades disponibles
  static List<OfficialEntity> getAllEntities() {
    return _entities.values.toList();
  }

  /// Check if a link domain matches any official entity
  static OfficialEntity? findEntityByDomain(String link) {
    try {
      Uri uri = Uri.parse(link.toLowerCase());
      String domain = uri.host;

      for (OfficialEntity entity in _entities.values) {
        if (entity.website == null) continue;

        Uri officialUri = Uri.parse(entity.website!.toLowerCase());
        String officialDomain = officialUri.host;

        // Exact match or subdomain match
        if (domain == officialDomain || domain.endsWith('.$officialDomain')) {
          return entity;
        }
      }
    } catch (e) {
      // Invalid URI
    }

    return null;
  }

  /// Check if a link is suspicious (doesn't match detected entities)
  static bool isLinkSuspicious(String link, List<OfficialEntity> detectedEntities) {
    if (detectedEntities.isEmpty) return true; // No entity = can't verify

    OfficialEntity? entityFromLink = findEntityByDomain(link);

    // Link doesn't match any known official entity
    if (entityFromLink == null) return true;

    // Link matches an entity, but NOT the one mentioned in message
    return !detectedEntities.contains(entityFromLink);
  }

  /// Buscar entidad específica por nombre
  static OfficialEntity? getEntityByName(String name) {
    String lowerName = name.toLowerCase();

    for (String key in _entities.keys) {
      OfficialEntity entity = _entities[key]!;

      if (entity.name.toLowerCase() == lowerName) {
        return entity;
      }

      // Buscar en aliases
      for (String alias in entity.aliases) {
        if (alias.toLowerCase() == lowerName) {
          return entity;
        }
      }
    }
    
    return null;
  }

  /// Generar sugerencias de contacto oficial para UI
  static List<OfficialContactSuggestion> generateContactSuggestions(List<OfficialEntity> entities) {
    List<OfficialContactSuggestion> suggestions = [];
    
    for (OfficialEntity entity in entities) {
      suggestions.add(OfficialContactSuggestion(
        entityName: entity.name,
        channels: _generateChannelOptions(entity),
      ));
    }
    
    return suggestions;
  }

  static List<ContactChannel> _generateChannelOptions(OfficialEntity entity) {
    List<ContactChannel> channels = [];
    
    // WhatsApp (prioridad alta)
    if (entity.hasWhatsApp) {
      channels.add(ContactChannel(
        type: ContactChannelType.whatsapp,
        label: 'WhatsApp Oficial',
        action: entity.whatsappUrl,
        icon: 'whatsapp',
        priority: 1,
      ));
    }
    
    // App oficial (prioridad media-alta)
    if (entity.hasApp) {
      channels.add(ContactChannel(
        type: ContactChannelType.app,
        label: 'App Oficial ${entity.name}',
        action: 'app_suggestion',
        icon: 'mobile_app',
        priority: 2,
      ));
    }
    
    // Website (prioridad media)
    if (entity.hasWebsite) {
      channels.add(ContactChannel(
        type: ContactChannelType.website,
        label: 'Página Oficial',
        action: entity.website!,
        icon: 'web',
        priority: 3,
      ));
    }
    
    // Ordenar por prioridad
    channels.sort((a, b) => a.priority.compareTo(b.priority));
    
    return channels;
  }
}

// Modelos de datos para las sugerencias
class OfficialContactSuggestion {
  final String entityName;
  final List<ContactChannel> channels;

  OfficialContactSuggestion({
    required this.entityName,
    required this.channels,
  });
}

class ContactChannel {
  final ContactChannelType type;
  final String label;
  final String action; // URL o acción
  final String icon;
  final int priority;

  ContactChannel({
    required this.type,
    required this.label,
    required this.action,
    required this.icon,
    required this.priority,
  });
}

enum ContactChannelType {
  whatsapp,
  app,
  website,
}