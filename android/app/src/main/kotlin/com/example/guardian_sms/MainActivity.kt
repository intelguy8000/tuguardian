package com.example.guardian_sms

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {

    // Lista de dominios oficiales permitidos (extraídos del OfficialEntitiesService)
    private val allowedDomains = setOf(
        // Bancos
        "bancolombia.com",
        "davivienda.com",
        "bancodeoccidente.com.co",
        "bancodebogota.com",
        "bankofamerica.com",

        // Mensajería/Paquetes
        "interrapidisimo.com",
        "dhl.com",
        "fedex.com",
        "servientrega.com",
        "coordinadora.com",

        // Seguros/Pensiones
        "sura.co",
        "colpensiones.gov.co",

        // Telefonía
        "claro.com.co",
        "movistar.com.co",

        // Otros servicios
        "primax.com.co",

        // WhatsApp oficial
        "wa.me",
        "api.whatsapp.com",
        "whatsapp.com"
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun startActivity(intent: Intent?) {
        // Interceptar intentos de abrir URLs
        if (intent?.action == Intent.ACTION_VIEW && intent.data != null) {
            val url = intent.data.toString()
            val host = intent.data?.host

            // Verificar si el dominio está en la lista de permitidos
            val isAllowed = allowedDomains.any { allowedDomain ->
                host?.endsWith(allowedDomain) == true
            }

            if (!isAllowed) {
                // Bloquear y mostrar advertencia
                Toast.makeText(
                    this,
                    "🛡️ TuGuardian bloqueó este enlace sospechoso por tu seguridad",
                    Toast.LENGTH_LONG
                ).show()
                return // NO abrir el link
            }
        }

        // Si es permitido o no es un URL, permitir
        super.startActivity(intent)
    }
}
