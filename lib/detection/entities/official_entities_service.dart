class OfficialEntity {
  final String name;
  final String? whatsapp;
  final String? website;
  final bool hasApp;
  final String? playStoreUrl; // NUEVO: URL oficial de Play Store
  final List<String> aliases; // Variaciones del nombre

  const OfficialEntity({
    required this.name,
    this.whatsapp,
    this.website,
    this.hasApp = false,
    this.playStoreUrl,
    this.aliases = const [],
  });

  String get whatsappUrl => whatsapp != null ? 'https://wa.me/$whatsapp' : '';
  bool get hasWhatsApp => whatsapp != null && whatsapp!.isNotEmpty;
  bool get hasWebsite => website != null && website!.isNotEmpty;
  bool get hasPlayStoreUrl => playStoreUrl != null && playStoreUrl!.isNotEmpty;
}

class OfficialEntitiesService {
  // Base de datos de entidades oficiales con todos sus canales
  static final Map<String, OfficialEntity> _entities = {
    'bancolombia': OfficialEntity(
      name: 'Bancolombia',
      whatsapp: '573013536788',
      website: 'https://www.bancolombia.com',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=co.com.bancolombia.personas.superapp',
      aliases: ['banco colombia', 'banco de colombia', 'bancolombia s.a.'],
    ),

    'davivienda': OfficialEntity(
      name: 'Davivienda',
      website: 'https://www.davivienda.com',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.davivienda.daviviendaapp',
      aliases: ['banco davivienda', 'davivienda s.a.'],
    ),

    'banco_occidente': OfficialEntity(
      name: 'Banco de Occidente',
      whatsapp: '573186714836',
      website: 'https://www.bancodeoccidente.com.co',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.grupoavaloc1.bancamovil',
      aliases: ['occidente', 'banco occidente'],
    ),

    'banco_bogota': OfficialEntity(
      name: 'Banco de Bogotá',
      whatsapp: '573162222222',
      website: 'https://www.bancodebogota.com',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.bancodebogota.bancamovil',
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
      playStoreUrl: 'https://play.google.com/store/apps/details?id=co.com.sura.seguros',
      aliases: ['seguros sura', 'sura seguros', 'eps sura'],
    ),

    'claro': OfficialEntity(
      name: 'Claro',
      whatsapp: '573112000000',
      website: 'https://www.claro.com.co/',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.clarocolombia.miclaro',
      aliases: ['claro colombia'],
    ),

    'netflix': OfficialEntity(
      name: 'Netflix',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.netflix.mediaclient',
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
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.dhl.exp.dhlmobile',
      aliases: ['dhl express', 'dhl colombia', 'paquete dhl', 'envío dhl', 'envio dhl'],
    ),

    'fedex': OfficialEntity(
      name: 'FedEx',
      website: 'https://www.fedex.com/',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.fedex.ida.android',
      aliases: ['fedex express', 'fedex colombia', 'paquete fedex'],
    ),

    'servientrega': OfficialEntity(
      name: 'Servientrega',
      website: 'https://www.servientrega.com/',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.servientrega',
      aliases: ['servientrega colombia', 'paquete servientrega'],
    ),

    'coordinadora': OfficialEntity(
      name: 'Coordinadora',
      website: 'https://www.coordinadora.com/',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.coordinadora.goo.app',
      aliases: ['coordinadora mercantil', 'paquete coordinadora'],
    ),
    
    'movistar': OfficialEntity(
      name: 'Movistar',
      whatsapp: '573152333333',
      website: 'https://www.movistar.com.co/',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=movistar.android.app',
      aliases: ['telefónica movistar', 'movistar colombia','mi.movistar.co', 'movistar.co'],
    ),

    // E-commerce & Retail (Critical for December)
    'mercadolibre': OfficialEntity(
      name: 'MercadoLibre',
      website: 'https://www.mercadolibre.com.co',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.mercadolibre',
      aliases: ['mercado libre', 'meli', 'mercadolibre colombia', 'ml'],
    ),

    'mercadopago': OfficialEntity(
      name: 'MercadoPago',
      website: 'https://www.mercadopago.com.co',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.mercadopago.wallet',
      aliases: ['mercado pago', 'mpago'],
    ),

    'amazon': OfficialEntity(
      name: 'Amazon',
      website: 'https://www.amazon.com',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.amazon.mShop.android.shopping',
      aliases: ['amazon.com', 'amazon prime', 'prime'],
    ),

    'falabella': OfficialEntity(
      name: 'Falabella',
      website: 'https://www.falabella.com.co',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.falabella.falabellaApp',
      aliases: ['falabella colombia', 'saga falabella'],
    ),

    'exito': OfficialEntity(
      name: 'Éxito',
      website: 'https://www.exito.com',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.exito.appcompania',
      aliases: ['exito', 'almacenes exito', 'grupo exito'],
    ),

    'rappi': OfficialEntity(
      name: 'Rappi',
      website: 'https://www.rappi.com.co',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.grability.rappi',
      aliases: ['rappi colombia'],
    ),

    'aliexpress': OfficialEntity(
      name: 'AliExpress',
      website: 'https://www.aliexpress.com',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.alibaba.aliexpresshd',
      aliases: ['ali express'],
    ),

    // Digital Wallets/Fintech (CRITICAL - High smishing target)
    'nequi': OfficialEntity(
      name: 'Nequi',
      website: 'https://www.nequi.com.co',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.nequi.MobileApp',
      aliases: ['nequi colombia', 'app nequi'],
    ),

    'daviplata': OfficialEntity(
      name: 'DaviPlata',
      website: 'https://www.daviplata.com',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.davivienda.daviplataapp',
      aliases: ['davi plata', 'daviplata davivienda'],
    ),

    'paypal': OfficialEntity(
      name: 'PayPal',
      website: 'https://www.paypal.com',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.paypal.android.p2pmobile',
      aliases: ['paypal.com'],
    ),

    // Additional Shipping (December surge)
    'tcc': OfficialEntity(
      name: 'TCC',
      website: 'https://www.tcc.com.co',
      hasApp: false,
      aliases: ['tcc mensajeria', 'transportes tcc'],
    ),

    'envia': OfficialEntity(
      name: 'Envía',
      website: 'https://www.envia.com',
      hasApp: true,
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.enviaclientapp',
      aliases: ['envia.com', 'envia colombia'],
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

    // App oficial con Play Store URL (prioridad media-alta)
    if (entity.hasApp && entity.hasPlayStoreUrl) {
      channels.add(ContactChannel(
        type: ContactChannelType.playstore,
        label: 'Descargar App Oficial',
        action: entity.playStoreUrl!,
        icon: 'get_app',
        priority: 2,
      ));
    } else if (entity.hasApp) {
      // Fallback si no tiene Play Store URL
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
  playstore, // NUEVO: Enlace directo a Play Store
  website,
}