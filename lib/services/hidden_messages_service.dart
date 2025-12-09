import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar conversaciones ocultas/eliminadas por el usuario
/// Los mensajes se ocultan de TuGuardian pero permanecen en el inbox de Android
class HiddenMessagesService {
  static const String _hiddenSendersKey = 'hidden_senders';

  // Cache en memoria para filtrado rápido
  static Set<String> _cachedHiddenSenders = {};
  static bool _cacheInitialized = false;

  // Getters públicos
  static Set<String> get cachedHiddenSenders => _cachedHiddenSenders;
  static bool get isCacheEmpty => _cachedHiddenSenders.isEmpty;

  /// Inicializar cache al arrancar la app
  static Future<void> initialize() async {
    if (_cacheInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> hidden = prefs.getStringList(_hiddenSendersKey) ?? [];
    _cachedHiddenSenders = Set<String>.from(hidden);
    _cacheInitialized = true;

    print('✅ HiddenMessagesService inicializado: ${_cachedHiddenSenders.length} conversaciones ocultas');
  }

  /// Verificar si un sender está oculto
  static Future<bool> isHidden(String sender) async {
    await initialize();
    return _cachedHiddenSenders.contains(_normalizeSender(sender));
  }

  /// Verificar si está oculto (versión síncrona usando cache)
  static bool isHiddenSync(String sender) {
    return _cachedHiddenSenders.contains(_normalizeSender(sender));
  }

  /// Ocultar conversación de un sender
  static Future<bool> hideSender(String sender) async {
    await initialize();

    String normalized = _normalizeSender(sender);

    if (_cachedHiddenSenders.contains(normalized)) {
      print('⚠️ Sender ya oculto: $normalized');
      return false;
    }

    // Agregar a cache
    _cachedHiddenSenders.add(normalized);

    // Persistir
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hiddenSendersKey, _cachedHiddenSenders.toList());

    print('🙈 Conversación oculta: $normalized');
    return true;
  }

  /// Mostrar conversación de un sender (deshacer ocultar)
  static Future<bool> unhideSender(String sender) async {
    await initialize();

    String normalized = _normalizeSender(sender);

    if (!_cachedHiddenSenders.contains(normalized)) {
      print('⚠️ Sender no estaba oculto: $normalized');
      return false;
    }

    // Remover de cache
    _cachedHiddenSenders.remove(normalized);

    // Persistir
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hiddenSendersKey, _cachedHiddenSenders.toList());

    print('👁️ Conversación restaurada: $normalized');
    return true;
  }

  /// Obtener lista de senders ocultos
  static Future<List<String>> getHiddenSenders() async {
    await initialize();
    return _cachedHiddenSenders.toList()..sort();
  }

  /// Obtener cantidad de conversaciones ocultas
  static Future<int> getHiddenCount() async {
    await initialize();
    return _cachedHiddenSenders.length;
  }

  /// Limpiar todos los ocultos (restaurar todo)
  static Future<void> clearAllHidden() async {
    await initialize();

    _cachedHiddenSenders.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hiddenSendersKey);

    print('🗑️ Todas las conversaciones han sido restauradas');
  }

  /// Normalizar sender para consistencia
  static String _normalizeSender(String sender) {
    String normalized = sender
        .replaceAll(RegExp(r'[\s\-\(\)\+]'), '')
        .trim();

    // Remover prefijo Colombia si aplica
    if (normalized.startsWith('57') && normalized.length > 10) {
      normalized = normalized.substring(2);
    }

    return normalized.toLowerCase();
  }

  /// Verificar si un mensaje debe ser filtrado (método de conveniencia)
  static bool shouldFilter(String sender) {
    return isHiddenSync(sender);
  }
}
