import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar el estado de lectura de mensajes SMS
/// Persiste los IDs de mensajes leídos en SharedPreferences
class ReadMessagesService {
  static const String _readMessageIdsKey = 'read_message_ids';

  // Cache en memoria para acceso rápido
  static Set<String> _cachedReadIds = {};
  static bool _cacheInitialized = false;

  // Getters públicos
  static Set<String> get cachedReadIds => _cachedReadIds;
  static bool get isCacheInitialized => _cacheInitialized;

  /// Inicializar cache al arrancar la app
  static Future<void> initialize() async {
    if (_cacheInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> readIds = prefs.getStringList(_readMessageIdsKey) ?? [];
    _cachedReadIds = Set<String>.from(readIds);
    _cacheInitialized = true;

    print('✅ ReadMessagesService inicializado: ${_cachedReadIds.length} mensajes leídos');
  }

  /// Verificar si un mensaje está leído
  static bool isRead(String messageId) {
    return _cachedReadIds.contains(messageId);
  }

  /// Marcar mensaje como leído
  static Future<void> markAsRead(String messageId) async {
    if (_cachedReadIds.contains(messageId)) return;

    _cachedReadIds.add(messageId);
    await _persist();
  }

  /// Marcar múltiples mensajes como leídos
  static Future<void> markMultipleAsRead(List<String> messageIds) async {
    bool changed = false;
    for (String id in messageIds) {
      if (!_cachedReadIds.contains(id)) {
        _cachedReadIds.add(id);
        changed = true;
      }
    }

    if (changed) {
      await _persist();
    }
  }

  /// Marcar mensaje como no leído
  static Future<void> markAsUnread(String messageId) async {
    if (!_cachedReadIds.contains(messageId)) return;

    _cachedReadIds.remove(messageId);
    await _persist();
  }

  /// Marcar múltiples mensajes como no leídos
  static Future<void> markMultipleAsUnread(List<String> messageIds) async {
    bool changed = false;
    for (String id in messageIds) {
      if (_cachedReadIds.contains(id)) {
        _cachedReadIds.remove(id);
        changed = true;
      }
    }

    if (changed) {
      await _persist();
    }
  }

  /// Obtener cantidad de mensajes leídos
  static int get readCount => _cachedReadIds.length;

  /// Limpiar historial de lectura (para testing)
  static Future<void> clearAll() async {
    _cachedReadIds.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_readMessageIdsKey);

    print('🗑️ Historial de lectura limpiado');
  }

  /// Persistir en SharedPreferences
  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readMessageIdsKey, _cachedReadIds.toList());
  }

  /// Limpiar IDs de mensajes que ya no existen (mantenimiento)
  static Future<void> cleanup(Set<String> existingMessageIds) async {
    int before = _cachedReadIds.length;
    _cachedReadIds.retainWhere((id) => existingMessageIds.contains(id));
    int removed = before - _cachedReadIds.length;

    if (removed > 0) {
      await _persist();
      print('🧹 Limpieza: $removed IDs obsoletos removidos');
    }
  }
}
