# TuGuardian

**Protección inteligente contra smishing y mensajes fraudulentos**

TuGuardian es una aplicación Android que protege a los usuarios contra fraudes por SMS, detectando automáticamente mensajes de phishing, smishing y estafas financieras.

---

## 🎯 Estado del Proyecto

**Versión actual:** 1.0.5 (versionCode: 5)
**Estado:** 🟢 **PUBLICADO EN INTERNAL TESTING**
**Fecha de publicación:** 25 de Octubre, 2025
**Próximo milestone:** Lanzamiento público en Google Play Store

---

## 📱 Características Principales

- ✅ **Detección automática de fraudes** - Análisis en tiempo real de SMS
- ✅ **Procesamiento 100% local** - Sin envío de datos a servidores externos
- ✅ **Notificaciones instantáneas** - Alertas inmediatas de mensajes peligrosos
- ✅ **Análisis detallado** - Explicación de por qué un mensaje es fraudulento
- ✅ **Bloqueo de remitentes** - Prevención de mensajes de números conocidos como maliciosos
- ✅ **Interfaz intuitiva** - Diseño simple y fácil de usar
- ✅ **Modo oscuro** - Compatible con tema oscuro del sistema

---

## 🛠️ Tecnologías Utilizadas

- **Framework:** Flutter 3.x
- **Lenguaje:** Dart
- **Platform:** Android (API 23+)
- **Dependencias principales:**
  - `telephony` - Lectura de SMS
  - `permission_handler` - Gestión de permisos
  - `flutter_local_notifications` - Notificaciones
  - `provider` - Gestión de estado
  - `sqflite` - Base de datos local

---

## 🚀 Getting Started

### Requisitos Previos

- Flutter SDK 3.0.0 o superior
- Android SDK (API 23-36)
- Android Studio / VS Code con extensión de Flutter
- JDK 11 o superior

### Instalación

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/intelguy8000/tuguardian.git
   cd tuguardian
   ```

2. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```

3. **Ejecutar la app:**
   ```bash
   flutter run
   ```

### Build de Release

**Generar AAB para Google Play:**
```bash
flutter build appbundle --release
```

El AAB se generará en: `build/app/outputs/bundle/release/app-release.aab`

---

## 🔐 Configuración de Firma

El proyecto está configurado con signing para releases.

**Archivos de configuración:**
- `android/key.properties` - Credenciales del keystore (NO incluido en Git)
- `android/app/upload-keystore.jks` - Keystore de firma (NO incluido en Git)

**Para desarrolladores:**
Contacta al administrador del proyecto para obtener las credenciales de firma.

---

## 📂 Estructura del Proyecto

```
tuguardian/
├── lib/
│   ├── main.dart                 # Punto de entrada
│   ├── screens/                  # Pantallas de la app
│   ├── services/                 # Lógica de negocio
│   ├── models/                   # Modelos de datos
│   └── widgets/                  # Componentes reutilizables
├── android/                      # Configuración Android
├── assets/                       # Recursos (imágenes, iconos)
├── docs/                         # Documentación adicional
└── legal/                        # Políticas y términos

```

---

## 📄 Documentación

- [Checklist de Publicación](PLAY_STORE_SUBMISSION_CHECKLIST.md)
- [Resumen de Internal Testing](INTERNAL_TESTING_PUBLISHED.md)
- [Declaración READ_SMS](READ_SMS_DECLARATION.md)
- [Política de Privacidad](https://intelguy8000.github.io/tuguardian/privacy-policy-es)
- [Términos de Servicio](https://intelguy8000.github.io/tuguardian/terms-of-service-es)

---

## 🧪 Testing

### Internal Testing (Actual)

**Estado:** ✅ Activo
**Versión:** 1.0.5
**Testers:** Configurados
**Plataforma:** Google Play Console Internal Testing

### Testing Local

```bash
# Ejecutar tests
flutter test

# Análisis de código
flutter analyze
```

---

## 🌍 Distribución

### Play Store

**Package name:** `io.github.intelguy8000.tuguardian`
**Estado actual:** Internal Testing
**Dispositivos compatibles:** 15,611 dispositivos Android
**Mercado objetivo:** Colombia (inicialmente)

---

## 🔒 Privacidad y Seguridad

TuGuardian respeta la privacidad del usuario:

- ✅ **Procesamiento local** - Todos los análisis se realizan en el dispositivo
- ✅ **Sin servidores externos** - No se envían SMS a ningún servidor
- ✅ **Sin recopilación de datos** - No se almacenan datos personales
- ✅ **Código abierto** - El código está disponible para auditoría
- ✅ **Transparente** - Política de privacidad clara y accesible

**Permiso READ_SMS:**
La app requiere permiso READ_SMS para funcionar. Este permiso se usa exclusivamente para analizar mensajes en busca de fraudes. Los mensajes nunca se envían fuera del dispositivo.

Ver [READ_SMS_DECLARATION.md](READ_SMS_DECLARATION.md) para más detalles.

---

## 🤝 Contribuir

Este es un proyecto privado en desarrollo. Para contribuir:

1. Contacta al equipo de desarrollo
2. Revisa las guidelines de código
3. Crea un branch para tu feature
4. Envía un pull request

---

## 📞 Contacto y Soporte

- **Email:** 300hbk117@gmail.com
- **GitHub:** https://github.com/intelguy8000/tuguardian
- **Website:** https://intelguy8000.github.io/tuguardian

---

## 📜 Licencia

Copyright © 2025 TuGuardian. Todos los derechos reservados.

---

## 🎉 Agradecimientos

Desarrollado con ❤️ para proteger a usuarios de habla hispana contra fraudes digitales.

**Última actualización:** 25 de Octubre, 2025
