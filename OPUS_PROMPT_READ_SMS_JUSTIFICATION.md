# PROMPT PARA OPUS - Justificación Permiso READ_SMS para Google Play

## CONTEXTO CRÍTICO ⚠️

Google Play es **MUY ESTRICTO** con el permiso `READ_SMS` porque es sensible. Muchas apps son rechazadas por no justificar correctamente este permiso.

**TuGuardian** NECESITA este permiso como funcionalidad CORE (no puede funcionar sin él), y debemos demostrar:
1. Es absolutamente necesario (no hay alternativa)
2. Es para seguridad del usuario (anti-fraud)
3. Se usa SOLO para el propósito declarado
4. No se envían datos a servidores (procesamiento local)

---

## INFORMACIÓN DE LA APP

### Nombre
**TuGuardian** - Anti-Smishing Security App

### Qué hace
Protege usuarios contra fraudes por SMS (smishing) mediante:
- Análisis automático de mensajes SMS entrantes en tiempo real
- Detección de patrones fraudulentos con IA
- Validación de dominios contra lista de entidades oficiales
- Bloqueo automático de enlaces peligrosos
- Alertas instantáneas de amenazas

### Por qué NECESITA READ_SMS
**Es la funcionalidad CORE de la app:**
- Sin leer SMS → no puede analizar → no puede proteger
- No hay API alternativa que permita análisis anti-fraude
- No es posible pedir al usuario que copie/pegue cada SMS (inseguro, impráctico)
- La detección debe ser automática para ser efectiva

### Procesamiento de datos
- **100% LOCAL**: Todo el análisis ocurre en el dispositivo
- **SIN SERVIDORES**: No enviamos SMS a ningún servidor externo
- **SIN ALMACENAMIENTO CLOUD**: Base de datos SQLite local
- **PRIVACIDAD TOTAL**: Nunca compartimos, vendemos o transmitimos SMS

---

## TAREA

Necesito que crees **2 documentos de justificación** profesionales para convencer a Google Play:

### 1. **DOCUMENTO FORMAL** (Declaration Form)

**Estructura requerida:**

#### A. App Information
- **App Name**: TuGuardian
- **Package Name**: io.github.intelguy8000.tuguardian
- **Developer**: Juan Andrés García
- **Category**: Security / Tools
- **Target Users**: General public (focus: adults 50+ vulnerable to SMS scams)

#### B. Permission Requested
- **Permission**: `android.permission.READ_SMS`
- **Additional**: `RECEIVE_SMS` (para detección en tiempo real)

#### C. Core Functionality Statement (CRÍTICO)
**Explicar por qué es CORE:**
- La app es exclusivamente una herramienta anti-smishing/anti-fraud
- La función principal ES analizar SMS para detectar fraudes
- Sin READ_SMS, la app no puede cumplir su único propósito
- No existe funcionalidad alternativa si se remueve este permiso

#### D. User Benefit Statement
**¿Cómo beneficia al usuario?**
- Protección automática contra pérdidas financieras por fraudes SMS
- Detección temprana de mensajes peligrosos antes de interactuar
- Bloqueo preventivo de enlaces maliciosos
- Alertas inmediatas de amenazas (especialmente importante para adultos mayores)

#### E. Data Handling (MUY IMPORTANTE)
**Declaración de privacidad:**
- Mensajes analizados SOLO en el dispositivo del usuario
- Motor de detección funciona 100% offline (no requiere internet para análisis)
- CERO transmisión de SMS a servidores externos
- No compartimos, vendemos ni almacenamos SMS en cloud
- Base de datos local SQLite (no sincronización)
- Cumplimiento total con GDPR y políticas de privacidad

#### F. Why No Alternative
**Por qué no hay otra forma:**
- APIs públicas de SMS no permiten acceso a contenido (solo metadata)
- ContentProvider de SMS requiere READ_SMS permission igual
- Soluciones manuales (copiar/pegar) son inseguras e imprácticas
- Detección automática en tiempo real es esencial para prevenir fraudes
- Usuarios objetivo (adultos mayores) no pueden hacer análisis manual

#### G. Compliance & Security
- Cumplimos políticas de Google Play sobre permisos SMS
- Política de privacidad pública: https://intelguy8000.github.io/tuguardian/privacy-policy-es
- Términos de servicio: https://intelguy8000.github.io/tuguardian/terms-of-service-es
- Disclaimer visible al usuario sobre limitaciones
- Código de conducta ético: no monetizamos datos de usuarios

---

### 2. **VIDEO SCRIPT** (30-60 segundos)

Para demostrar visualmente a Google Play reviewers:

**Estructura sugerida:**

```
[ESCENA 1 - 5 seg]
- Mostrar mensaje SMS fraudulento llegando al dispositivo
- Narración: "Fraudulent SMS messages are a growing threat..."

[ESCENA 2 - 10 seg]
- TuGuardian detecta automáticamente el SMS
- Análisis visible en pantalla (riesgo alto, link bloqueado)
- Narración: "TuGuardian automatically analyzes incoming SMS..."

[ESCENA 3 - 5 seg]
- Notificación de alerta aparece
- Narración: "And alerts users immediately about threats..."

[ESCENA 4 - 10 seg]
- Usuario ve análisis detallado
- Links marcados como bloqueados
- Narración: "Dangerous links are blocked at OS level..."

[ESCENA 5 - 5 seg]
- Mostrar Settings → Privacy Policy
- Narración: "All analysis happens locally. No data sent to servers."

[ESCENA 6 - 5 seg]
- Texto en pantalla: "READ_SMS is core functionality - without it, fraud detection is impossible"
- Narración: "READ_SMS permission is essential for this security feature to work."

[CIERRE - 5 seg]
- Logo TuGuardian + "Protecting users from SMS fraud"
```

**Puntos clave a mostrar:**
1. SMS llegando automáticamente
2. Detección sin intervención del usuario
3. Notificación de amenaza
4. Link bloqueado (no clickeable)
5. Disclaimer de privacidad visible

---

## ARGUMENTOS CLAVE (incluir en ambos documentos)

### ✅ ARGUMENTOS A FAVOR

1. **Security Tool Category**: Es una app de SEGURIDAD, no social/messaging
2. **Core Functionality**: READ_SMS es literalmente lo que hace la app
3. **User Protection**: Previene pérdidas financieras reales
4. **Privacy-First**: Procesamiento 100% local, cero transmisión
5. **Vulnerable Users**: Protege especialmente a adultos mayores
6. **No Alternatives**: No existe otra forma de lograr protección automática
7. **Transparent**: Políticas legales públicas, disclaimer visible
8. **Non-Commercial Data Use**: No vendemos ni monetizamos SMS

### ❌ EVITAR DECIR

- "Guardamos todos los SMS" → ❌ Di: "Analizamos y descartamos"
- "Necesitamos para marketing" → ❌ NUNCA mencionar comercialización
- "También hacemos X" → ❌ Solo enfocarse en anti-fraude
- "Puede funcionar sin permiso" → ❌ Ser claro: es CORE functionality
- Términos vagos como "mejorar experiencia" → ❌ Ser específico: "detectar fraudes"

---

## POLÍTICAS GOOGLE PLAY (cumplir)

Según [Google Play SMS/Call Log Policy](https://support.google.com/googleplay/android-developer/answer/9047303):

**Apps permitidas con READ_SMS:**
✅ Default SMS/Phone apps
✅ **Companion device apps (smartwatches)**
✅ **Security/anti-fraud apps** ← TuGuardian entra aquí
✅ Task automation apps (con user consent)

**Requisitos:**
✅ Debe ser core functionality (SÍ cumple)
✅ Declaración en-app visible (SÍ tenemos disclaimer)
✅ Privacy policy accesible (SÍ: GitHub Pages)
✅ No transmitir data fuera del dispositivo (SÍ cumple)

---

## OUTPUT ESPERADO

### Archivo 1: `READ_SMS_DECLARATION.md`
```markdown
# READ_SMS Permission Declaration - TuGuardian

## App Information
[...completar según estructura arriba...]

## Core Functionality Statement
[...argumentación sólida...]

## Data Handling & Privacy
[...declaración detallada...]

## Compliance
[...referencias a políticas...]
```

### Archivo 2: `VIDEO_SCRIPT.md`
```markdown
# Video Script - READ_SMS Justification

## Purpose
Demonstrate to Google Play reviewers why READ_SMS is essential

## Duration
45 seconds

## Scenes
[...script detallado según estructura arriba...]

## Key Messages
[...bullet points principales...]
```

---

## RECURSOS DE REFERENCIA

- Google Play SMS Policy: https://support.google.com/googleplay/android-developer/answer/9047303
- Privacy Policy: https://intelguy8000.github.io/tuguardian/privacy-policy-es
- Terms: https://intelguy8000.github.io/tuguardian/terms-of-service-es

---

## TONO

- **Profesional y formal** (es un documento legal/técnico)
- **Claro y directo** (reviewers leen muchas apps, ser conciso)
- **Transparente** (admitir limitaciones, enfatizar ética)
- **Técnicamente preciso** (usar terminología correcta Android)
- **Respetuoso** (entendemos preocupación de Google por privacidad)

---

**¿Listo? Necesito ambos documentos para adjuntar en la submission a Play Store. ¡Muchas gracias!**
