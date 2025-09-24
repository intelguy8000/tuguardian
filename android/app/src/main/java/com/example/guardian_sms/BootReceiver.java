package com.example.guardian_sms;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class BootReceiver extends BroadcastReceiver {
    private static final String TAG = "GuardianSMS_Boot";
    
    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        Log.d(TAG, "🚀 Boot event recibido: " + action);
        
        if (Intent.ACTION_BOOT_COMPLETED.equals(action) ||
            Intent.ACTION_MY_PACKAGE_REPLACED.equals(action) ||
            Intent.ACTION_PACKAGE_REPLACED.equals(action)) {
            
            try {
                // Verificar si GuardianSMS está habilitado
                // (aquí podrías verificar SharedPreferences si el usuario activó protección)
                
                // Iniciar servicio de protección automáticamente
                Intent serviceIntent = new Intent(context, GuardianService.class);
                serviceIntent.putExtra("action", "AUTO_START");
                context.startService(serviceIntent);
                
                Log.d(TAG, "✅ GuardianService iniciado automáticamente tras reboot");
                
            } catch (Exception e) {
                Log.e(TAG, "❌ Error iniciando GuardianService tras reboot: " + e.getMessage(), e);
            }
        }
    }
}