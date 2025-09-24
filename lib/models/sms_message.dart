import 'package:flutter/material.dart';

class SMSMessage {
  final String id;
  final String sender;
  final String message;
  final DateTime timestamp;
  final int riskScore;
  final bool isQuarantined;
  final List<String> suspiciousElements;
  
  SMSMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
    this.riskScore = 0,
    this.isQuarantined = false,
    this.suspiciousElements = const [],
  });
  
  // Getters para clasificación de riesgo
  bool get isSafe => riskScore < 30;
  bool get isModerate => riskScore >= 30 && riskScore < 70;
  bool get isDangerous => riskScore >= 70;
  
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
}