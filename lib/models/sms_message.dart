import 'package:flutter/material.dart';
import '../services/official_entities_service.dart';

class SMSMessage {
  final String id;
  final String sender;
  final String message;
  final DateTime timestamp;
  final int riskScore;
  final bool isQuarantined;
  final List<String> suspiciousElements;
  
  // 🆕 NUEVOS CAMPOS para entidades oficiales
  final List<OfficialEntity> detectedEntities;
  final List<OfficialContactSuggestion> officialSuggestions;
  
  SMSMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
    this.riskScore = 0,
    this.isQuarantined = false,
    this.suspiciousElements = const [],
    // 🆕 NUEVOS PARÁMETROS
    this.detectedEntities = const [],
    this.officialSuggestions = const [],
  });
  
  // Getters para clasificación de riesgo (mantiene lógica existente)
  bool get isSafe => riskScore < 30;
  bool get isModerate => riskScore >= 30 && riskScore < 70;
  bool get isDangerous => riskScore >= 70;
  
  // 🆕 GETTER: ¿Tiene sugerencias oficiales disponibles?
  bool get hasOfficialSuggestions => officialSuggestions.isNotEmpty;
  
  // 🆕 GETTER: ¿Suplanta entidades conocidas?
  bool get isImpersonating => detectedEntities.isNotEmpty && isDangerous;
  
  // Colores según el nivel de riesgo (mantiene lógica existente)
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
  
  // 🆕 GETTERS para UI mejorada
  String get entityNames {
    if (detectedEntities.isEmpty) return '';
    return detectedEntities.map((e) => e.name).join(', ');
  }
  
  String get securityAdvice {
    if (!isDangerous) return '';
    
    if (isImpersonating) {
      return 'Este mensaje suplanta a ${entityNames}. Contacta directamente con los canales oficiales.';
    }
    
    return 'Mensaje peligroso detectado. No hagas clic en enlaces ni proporciones información personal.';
  }
  
  // 🆕 MÉTODO: Obtener canales disponibles para una entidad específica
  List<ContactChannel> getChannelsForEntity(String entityName) {
    for (OfficialContactSuggestion suggestion in officialSuggestions) {
      if (suggestion.entityName == entityName) {
        return suggestion.channels;
      }
    }
    return [];
  }
  
  // 🆕 MÉTODO: ¿Tiene canal WhatsApp disponible?
  bool hasWhatsAppChannel() {
    return officialSuggestions.any((suggestion) =>
        suggestion.channels.any((channel) => 
            channel.type == ContactChannelType.whatsapp));
  }
  
  // 🆕 MÉTODO: ¿Tiene app oficial disponible?
  bool hasOfficialApp() {
    return officialSuggestions.any((suggestion) =>
        suggestion.channels.any((channel) => 
            channel.type == ContactChannelType.app));
  }
  
  // 🆕 MÉTODO: Obtener primer canal WhatsApp disponible
  ContactChannel? getFirstWhatsAppChannel() {
    for (OfficialContactSuggestion suggestion in officialSuggestions) {
      for (ContactChannel channel in suggestion.channels) {
        if (channel.type == ContactChannelType.whatsapp) {
          return channel;
        }
      }
    }
    return null;
  }
  
  // 🆕 MÉTODO: Crear copia con campos actualizados
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
    );
  }
  
  // 🆕 MÉTODO: Conversión a Map para base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'riskScore': riskScore,
      'isQuarantined': isQuarantined ? 1 : 0,
      'suspiciousElements': suspiciousElements.join('|'),
      'detectedEntities': detectedEntities.map((e) => e.name).join('|'),
      'hasOfficialSuggestions': hasOfficialSuggestions ? 1 : 0,
    };
  }
  
  // 🆕 MÉTODO: Crear desde Map (para base de datos)
  factory SMSMessage.fromMap(Map<String, dynamic> map) {
    return SMSMessage(
      id: map['id'] ?? '',
      sender: map['sender'] ?? '',
      message: map['message'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      riskScore: map['riskScore'] ?? 0,
      isQuarantined: (map['isQuarantined'] ?? 0) == 1,
      suspiciousElements: (map['suspiciousElements'] ?? '').split('|').where((e) => e.isNotEmpty).toList(),
      // Nota: detectedEntities y officialSuggestions se reconstruyen con DetectionService.analyzeMessage
    );
  }
  
  @override
  String toString() {
    return 'SMSMessage(id: $id, sender: $sender, riskScore: $riskScore, entities: ${entityNames})';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SMSMessage && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}