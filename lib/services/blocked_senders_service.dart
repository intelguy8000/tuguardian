import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar senders bloqueados por el usuario
/// Permite bloquear/desbloquear números para filtrarlos de la vista
class BlockedSendersService {
  static const String _blockedSendersKey = 'blocked_senders';
  static const String _blockReasonPrefix = 'block_reason_';

  // Cache en memoria para evitar lecturas constantes de SharedPreferences
  static Set<String> _cachedBlockedSenders = {};
  static bool _cacheInitialized = false;

  // Getters públicos para acceso externo
  static Set<String> get cachedBlockedSenders => _cachedBlockedSenders;
  static bool get isCacheEmpty => _cachedBlockedSenders.isEmpty;

  /// Inicializar cache al arrancar la app
  static Future<void> initialize() async {
    if (_cacheInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> blocked = prefs.getStringList(_blockedSendersKey) ?? [];
    _cachedBlockedSenders = Set<String>.from(blocked);
    _cacheInitialized = true;

    print('✅ BlockedSendersService inicializado: ${_cachedBlockedSenders.length} senders bloqueados');
  }

  /// Verificar si un sender está bloqueado
  static Future<bool> isBlocked(String sender) async {
    await initialize(); // Asegurar inicialización
    return _cachedBlockedSenders.contains(normalizeSender(sender));
  }

  /// Bloquear un sender
  static Future<bool> blockSender(String sender, {String reason = 'Bloqueado por el usuario'}) async {
    await initialize();

    String normalized = normalizeSender(sender);

    // Si ya está bloqueado, no hacer nada
    if (_cachedBlockedSenders.contains(normalized)) {
      print('⚠️ Sender ya bloqueado: $normalized');
      return false;
    }

    // Agregar a cache
    _cachedBlockedSenders.add(normalized);

    // Persistir en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_blockedSendersKey, _cachedBlockedSenders.toList());
    await prefs.setString('$_blockReasonPrefix$normalized', reason);

    print('🚫 Sender bloqueado: $normalized - Razón: $reason');
    return true;
  }

  /// Desbloquear un sender
  static Future<bool> unblockSender(String sender) async {
    await initialize();

    String normalized = normalizeSender(sender);

    // Si no está bloqueado, no hacer nada
    if (!_cachedBlockedSenders.contains(normalized)) {
      print('⚠️ Sender no estaba bloqueado: $normalized');
      return false;
    }

    // Remover de cache
    _cachedBlockedSenders.remove(normalized);

    // Persistir en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_blockedSendersKey, _cachedBlockedSenders.toList());
    await prefs.remove('$_blockReasonPrefix$normalized');

    print('✅ Sender desbloqueado: $normalized');
    return true;
  }

  /// Obtener lista de todos los senders bloqueados
  static Future<List<String>> getBlockedSenders() async {
    await initialize();
    return _cachedBlockedSenders.toList()..sort();
  }

  /// Obtener razón de bloqueo de un sender
  static Future<String?> getBlockReason(String sender) async {
    await initialize();

    String normalized = normalizeSender(sender);
    if (!_cachedBlockedSenders.contains(normalized)) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_blockReasonPrefix$normalized') ?? 'Sin razón especificada';
  }

  /// Obtener cantidad de senders bloqueados
  static Future<int> getBlockedCount() async {
    await initialize();
    return _cachedBlockedSenders.length;
  }

  /// Limpiar todos los senders bloqueados (usar con precaución)
  static Future<void> clearAllBlocked() async {
    await initialize();

    final prefs = await SharedPreferences.getInstance();

    // Remover razones de bloqueo
    for (String sender in _cachedBlockedSenders) {
      await prefs.remove('$_blockReasonPrefix$sender');
    }

    // Limpiar lista
    _cachedBlockedSenders.clear();
    await prefs.remove(_blockedSendersKey);

    print('🗑️ Todos los senders bloqueados han sido eliminados');
  }

  /// Exportar lista de bloqueados (para backup)
  static Future<Map<String, String>> exportBlockedSenders() async {
    await initialize();

    Map<String, String> export = {};
    final prefs = await SharedPreferences.getInstance();

    for (String sender in _cachedBlockedSenders) {
      String reason = prefs.getString('$_blockReasonPrefix$sender') ?? 'Sin razón';
      export[sender] = reason;
    }

    return export;
  }

  /// Importar lista de bloqueados (para restore)
  static Future<void> importBlockedSenders(Map<String, String> senders) async {
    await initialize();

    final prefs = await SharedPreferences.getInstance();

    for (var entry in senders.entries) {
      String normalized = normalizeSender(entry.key);
      _cachedBlockedSenders.add(normalized);
      await prefs.setString('$_blockReasonPrefix$normalized', entry.value);
    }

    await prefs.setStringList(_blockedSendersKey, _cachedBlockedSenders.toList());

    print('📥 Importados ${senders.length} senders bloqueados');
  }

  /// Normalizar número de teléfono para consistencia
  /// Remueve espacios, guiones, paréntesis, prefijos internacionales
  static String normalizeSender(String sender) {
    // Remover caracteres especiales
    String normalized = sender
        .replaceAll(RegExp(r'[\s\-\(\)\+]'), '')
        .trim();

    // Si empieza con 57 (código Colombia) y tiene más de 10 dígitos, remover prefijo
    if (normalized.startsWith('57') && normalized.length > 10) {
      normalized = normalized.substring(2);
    }

    // Convertir a lowercase para códigos alfanuméricos
    return normalized.toLowerCase();
  }

  /// Toggle: si está bloqueado → desbloquear, si no → bloquear
  static Future<bool> toggleBlock(String sender, {String reason = 'Bloqueado por el usuario'}) async {
    bool isCurrentlyBlocked = await isBlocked(sender);

    if (isCurrentlyBlocked) {
      return await unblockSender(sender);
    } else {
      return await blockSender(sender, reason: reason);
    }
  }

  /// Obtener estadísticas de bloqueos
  static Future<Map<String, dynamic>> getBlockingStats() async {
    await initialize();

    int totalBlocked = _cachedBlockedSenders.length;
    int shortCodes = 0;
    int longNumbers = 0;
    int alphanumeric = 0;

    for (String sender in _cachedBlockedSenders) {
      if (RegExp(r'^\d{4,6}$').hasMatch(sender)) {
        shortCodes++;
      } else if (RegExp(r'^\d{10,}$').hasMatch(sender)) {
        longNumbers++;
      } else {
        alphanumeric++;
      }
    }

    return {
      'total': totalBlocked,
      'shortCodes': shortCodes,
      'longNumbers': longNumbers,
      'alphanumeric': alphanumeric,
    };
  }
}
