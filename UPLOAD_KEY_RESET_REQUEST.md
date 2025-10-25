# Solicitud de Reset de Upload Key - TuGuardian

## Información de la aplicación
- **Nombre:** TuGuardian
- **Package Name:** io.github.intelguy8000.tuguardian
- **Versión actual en Play Store:** 1.0.0 (código: 1)

## Motivo de la solicitud
Perdí acceso al upload keystore original debido a la pérdida del equipo donde fue creado.
La aplicación tiene Google Play App Signing activado, por lo que solicito el registro de un nuevo upload key.

## Información del nuevo upload key

### Huellas digitales:
- **SHA1:** `10:A5:1C:B5:6D:C0:0C:EA:6C:45:F1:D2:F1:66:FF:4A:C5:9F:33:56`
- **SHA256:** `54:E1:FE:C2:0D:98:C0:28:6B:0C:70:E7:23:3A:CA:2F:3E:2A:9A:4D:A9:4E:22:5E:04:F5:91:15:6E:2B:30:8D`

### Certificado PEM:
Ubicación: `/Users/juanus/tuguardian/android/app/upload_certificate.pem`

## Pasos para contactar a Google Play Support:

1. Ve a [Google Play Console](https://play.google.com/console)
2. Selecciona tu app "TuGuardian"
3. Haz clic en el ícono de ayuda **(?)** en la esquina superior derecha
4. Selecciona **"Contactar con el equipo de asistencia"** o **"Contact support"**
5. Categoría: **"App signing"** o **"Firma de aplicaciones"**
6. Asunto: **"Solicitud de reset de upload keystore - TuGuardian"**

## Mensaje sugerido para el soporte:

```
Asunto: Perdí mi upload keystore - Solicitud de reset

Hola equipo de Google Play,

Perdí acceso al upload keystore original de mi aplicación "TuGuardian"
(io.github.intelguy8000.tuguardian) debido a la pérdida del equipo donde fue creado.

La aplicación tiene Google Play App Signing activado, por lo que solicito
registrar un nuevo upload key para poder continuar actualizando la app.

Adjunto el certificado PEM del nuevo upload key.

Información del nuevo upload key:
- SHA1: 10:A5:1C:B5:6D:C0:0C:EA:6C:45:F1:D2:F1:66:FF:4A:C5:9F:33:56
- SHA256: 54:E1:FE:C2:0D:98:C0:28:6B:0C:70:E7:23:3A:CA:2F:3E:2A:9A:4D:A9:4E:22:5E:04:F5:91:15:6E:2B:30:8D

Agradezco su ayuda.

Saludos,
[Tu nombre]
```

## Archivos a adjuntar:
- `upload_certificate.pem` (ubicado en `/Users/juanus/tuguardian/android/app/`)

## Tiempo estimado de respuesta:
1-3 días hábiles

## Una vez aprobado:
Podrás subir el app bundle generado en:
`/Users/juanus/tuguardian/build/app/outputs/bundle/release/app-release.aab`

---
**Nota:** Guarda este documento y los archivos del keystore en un lugar seguro (backup en la nube).
