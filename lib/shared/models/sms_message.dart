import 'package:flutter/material.dart';
import '../../detection/entities/official_entities_service.dart';
import '../../services/intent_detection_service.dart';

class SMSMessage {
  final String id;
  final String sender;
  final String message;
  final DateTime timestamp;
  final int riskScore;
  final bool isQuarantined;
  final List<String> suspiciousElements;
  final List<OfficialEntity>? detectedEntities;
  final List<OfficialContactSuggestion>? officialSuggestions;
  final bool isDemo; // NUEVO - Para sistema dual
  final IntentAnalysisResult? intentAnalysis; // NUEVO - Intent detection
  
  SMSMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
    this.riskScore = 0,
    this.isQuarantined = false,
    this.suspiciousElements = const [],
    this.detectedEntities,
    this.officialSuggestions,
    this.isDemo = false, // NUEVO - Por defecto es REAL
    this.intentAnalysis, // NUEVO - Intent analysis
  });
  
  // Getters para clasificación de riesgo
  bool get isSafe => riskScore < 40;
  bool get isModerate => riskScore >= 30 && riskScore < 70;
  bool get isDangerous => riskScore >= 70;

  // ⛔ NUEVO: Detectar si es mensaje CRÍTICO de seguridad bancaria
  bool get isCriticalSecurity {
    return suspiciousElements.any((element) =>
      element.contains('⛔ ALERTA CRÍTICA')
    );
  }
  
  // NUEVO - Badge para UI
  String get badge => isDemo ? '🎭 DEMO' : '🔴 REAL';
  
  // NUEVO - Tiempo relativo
  String get timeAgo {
    if (isDemo) return 'Ejemplo';
    
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Ahora';
    if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes}min';
    if (difference.inHours < 24) return 'Hace ${difference.inHours}h';
    if (difference.inDays < 7) return 'Hace ${difference.inDays}d';
    return 'Hace más de una semana';
  }
  
  // ¿Tiene sugerencias oficiales disponibles?
  bool get hasOfficialSuggestions => 
      officialSuggestions != null && officialSuggestions!.isNotEmpty;
  
  // ¿Suplanta entidades conocidas?
  bool get isImpersonating => 
      detectedEntities != null && detectedEntities!.isNotEmpty && isDangerous;
  
  // Colores según el nivel de riesgo
  Color get riskColor {
    if (isSafe) return Colors.green;
    if (isModerate) return Colors.orange;
    return Colors.red;
  }
  
  String get riskLabel {
    if (isSafe) return 'Seguro';
    if (isModerate) return 'Sospechoso';
    return 'Peligroso';
  }
  
  IconData get riskIcon {
    if (isSafe) return Icons.check_circle;
    if (isModerate) return Icons.warning;
    return Icons.dangerous;
  }
  
  // Nombres de entidades detectadas
  String get entityNames {
    if (detectedEntities == null || detectedEntities!.isEmpty) return '';
    return detectedEntities!.map((e) => e.name).join(', ');
  }
  
  // Consejo de seguridad personalizado
  String get securityAdvice {
    if (!isDangerous) return '';
    
    if (isImpersonating) {
      return 'Este mensaje suplanta a $entityNames. Contacta directamente con los canales oficiales.';
    }
    
    return 'Mensaje peligroso detectado. No hagas clic en enlaces ni proporciones información personal.';
  }
  
  // Obtener canales disponibles para una entidad específica
  List<ContactChannel> getChannelsForEntity(String entityName) {
    if (officialSuggestions == null) return [];
    
    for (OfficialContactSuggestion suggestion in officialSuggestions!) {
      if (suggestion.entityName == entityName) {
        return suggestion.channels;
      }
    }
    return [];
  }
  
  // ¿Tiene canal WhatsApp disponible?
  bool hasWhatsAppChannel() {
    if (officialSuggestions == null) return false;
    
    return officialSuggestions!.any((suggestion) =>
        suggestion.channels.any((channel) => 
            channel.type == ContactChannelType.whatsapp));
  }
  
  // ¿Tiene app oficial disponible?
  bool hasOfficialApp() {
    if (officialSuggestions == null) return false;
    
    return officialSuggestions!.any((suggestion) =>
        suggestion.channels.any((channel) => 
            channel.type == ContactChannelType.app));
  }
  
  // Obtener primer canal WhatsApp disponible
  ContactChannel? getFirstWhatsAppChannel() {
    if (officialSuggestions == null) return null;
    
    for (OfficialContactSuggestion suggestion in officialSuggestions!) {
      for (ContactChannel channel in suggestion.channels) {
        if (channel.type == ContactChannelType.whatsapp) {
          return channel;
        }
      }
    }
    return null;
  }
  
  // Crear copia con campos actualizados
  SMSMessage copyWith({
    String? id,
    String? sender,
    String? message,
    DateTime? timestamp,
    int? riskScore,
    bool? isQuarantined,
    List<String>? suspiciousElements,
    List<OfficialEntity>? detectedEntities,
    List<OfficialContactSuggestion>? officialSuggestions,
    bool? isDemo, // NUEVO
    IntentAnalysisResult? intentAnalysis, // NUEVO
  }) {
    return SMSMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      riskScore: riskScore ?? this.riskScore,
      isQuarantined: isQuarantined ?? this.isQuarantined,
      suspiciousElements: suspiciousElements ?? this.suspiciousElements,
      detectedEntities: detectedEntities ?? this.detectedEntities,
      officialSuggestions: officialSuggestions ?? this.officialSuggestions,
      isDemo: isDemo ?? this.isDemo, // NUEVO
      intentAnalysis: intentAnalysis ?? this.intentAnalysis, // NUEVO
    );
  }
  
  // Conversión a Map para base de datos - ACTUALIZADO
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'riskScore': riskScore,
      'isQuarantined': isQuarantined ? 1 : 0,
      'suspiciousElements': suspiciousElements.join('|'),
      'detectedEntities': detectedEntities?.map((e) => e.name).join('|') ?? '',
      'hasOfficialSuggestions': hasOfficialSuggestions ? 1 : 0,
      'isDemo': isDemo ? 1 : 0, // NUEVO
    };
  }
  
  // Crear desde Map (para base de datos) - ACTUALIZADO
  factory SMSMessage.fromMap(Map<String, dynamic> map) {
    return SMSMessage(
      id: map['id'] ?? '',
      sender: map['sender'] ?? '',
      message: map['message'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      riskScore: map['riskScore'] ?? 0,
      isQuarantined: (map['isQuarantined'] ?? 0) == 1,
      suspiciousElements: (map['suspiciousElements'] ?? '').split('|').where((e) => e.isNotEmpty).toList(),
      isDemo: (map['isDemo'] ?? 0) == 1, // NUEVO
    );
  }
  
  @override
  String toString() {
    return 'SMSMessage(id: $id, sender: $sender, riskScore: $riskScore, entities: $entityNames, isDemo: $isDemo)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SMSMessage && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}