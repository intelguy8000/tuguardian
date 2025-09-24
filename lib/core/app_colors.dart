import 'package:flutter/material.dart';

class AppColors {
  // PALETA DE AZULES ARMONIZADA
  static const Color primary = Color(0xFF007AFF);        // Azul principal iOS
  static const Color primaryLight = Color(0xFF64B5F6);   // Azul claro círculos
  static const Color primaryTech = Color(0xFF2196F3);    // Azul tecnológico settings/edit
  static const Color primaryDark = Color(0xFF0056CC);
  
  static const Color secondary = Color(0xFF34C759);
  static const Color accent = Color(0xFFFF9500);
  
  // Colores de estado
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);
  
  // Colores de riesgo
  static const Color riskHigh = Color(0xFFFF3B30);    // 70-100%
  static const Color riskMedium = Color(0xFFFF9500);  // 50-69%
  static const Color riskLow = Color(0xFFFFC107);     // 30-49%
  static const Color riskSafe = Color(0xFF34C759);    // 0-29%
  
  // Tema claro
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8F9FA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E5EA);
  static const Color lightText = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF6D6D80);
  
  // Tema oscuro
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkCard = Color(0xFF2C2C2E);
  static const Color darkBorder = Color(0xFF38383A);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF99999E);
  
  // Colores iOS específicos
  static const Color iosBlue = Color(0xFF007AFF);
  static const Color iosGreen = Color(0xFF34C759);
  static const Color iosRed = Color(0xFFFF3B30);
  static const Color iosOrange = Color(0xFFFF9500);
  static const Color iosYellow = Color(0xFFFFC107);
  static const Color iosPurple = Color(0xFFAF52DE);
  static const Color iosPink = Color(0xFFFF2D92);
  static const Color iosTeal = Color(0xFF5AC8FA);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF007AFF), Color(0xFF0056CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF34C759), Color(0xFF28A745)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFF9500), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFFF3B30), Color(0xFFDC3545)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Métodos helper
  static Color getRiskColor(int riskScore) {
    if (riskScore >= 70) return riskHigh;
    if (riskScore >= 50) return riskMedium;
    if (riskScore >= 30) return riskLow;
    return riskSafe;
  }
  
  static Color getTextColor(bool isDark) {
    return isDark ? darkText : lightText;
  }
  
  static Color getSecondaryTextColor(bool isDark) {
    return isDark ? darkTextSecondary : lightTextSecondary;
  }
  
  static Color getBackgroundColor(bool isDark) {
    return isDark ? darkBackground : lightBackground;
  }
  
  static Color getCardColor(bool isDark) {
    return isDark ? darkCard : lightCard;
  }
  
  static Color getBorderColor(bool isDark) {
    return isDark ? darkBorder : lightBorder;
  }
  
  static Color getSurfaceColor(bool isDark) {
    return isDark ? darkSurface : lightSurface;
  }
}