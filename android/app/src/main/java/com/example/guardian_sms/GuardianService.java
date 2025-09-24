package com.example.guardian_sms;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;
import androidx.core.app.NotificationCompat;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodChannel;

public class GuardianService extends Service {
    private static final String TAG = "GuardianService";
    private static final String CHANNEL_ID = "guardian_sms_protection";
    private static final String THREAT_CHANNEL_ID = "guardian_sms_threats";
    private static final int NOTIFICATION_ID = 1001;
    
    private static MethodChannel methodChannel;
    private NotificationManager notificationManager;
    
    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "🛡️ GuardianService creado");
        
        notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        createNotificationChannels();
    }
    
    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "🚀 GuardianService iniciado");
        
        if (intent != null) {
            String action = intent.getStringExtra("action");
            
            if ("ANALYZE_SMS".equals(action)) {
                // SMS recibido para análisis
                String sender = intent.getStringExtra("sender");
                String message = intent.getStringExtra("message");
                long timestamp = intent.getLongExtra("timestamp", System.currentTimeMillis());
                
                analyzeSMS(sender, message, timestamp);
                
            } else if ("AUTO_START".equals(action)) {
                // Inicio automático tras reboot
                Log.d(TAG, "📱 Protección SMS activada automáticamente");
            }
        }
        
        // Crear notificación de servicio activo
        startForeground(NOTIFICATION_ID, createProtectionNotification());
        
        // Reiniciar servicio si es terminado por el sistema
        return START_STICKY;
    }
    
    private void analyzeSMS(String sender, String message, long timestamp) {
        Log.d(TAG, "🔍 Analizando SMS de: " + sender);
        
        try {
            // Enviar SMS a Flutter para análisis con IA
            if (methodChannel != null) {
                methodChannel.invokeMethod("onSMSReceived", new java.util.HashMap<String, Object>() {{
                    put("id", String.valueOf(timestamp));
                    put("sender", sender);
                    put("body", message);
                    put("timestamp", timestamp);
                }});
                
                Log.d(TAG, "✅ SMS enviado a Flutter para análisis con IA");
            } else {
                Log.w(TAG, "⚠️ MethodChannel no disponible, SMS no analizado");
            }
            
        } catch (Exception e) {
            Log.e(TAG, "❌ Error analizando SMS: " + e.getMessage(), e);
        }
    }
    
    public void showThreatNotification(String title, String body, String sender, int riskScore) {
        Log.d(TAG, "🚨 Mostrando notificación de amenaza: " + sender + " (Score: " + riskScore + ")");
        
        try {
            Intent intent = new Intent(this, MainActivity.class);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent, 
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
            
            NotificationCompat.Builder builder = new NotificationCompat.Builder(this, THREAT_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(new NotificationCompat.BigTextStyle().bigText(body))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .setColor(0xFFFF0000); // Rojo para amenazas
            
            notificationManager.notify((int) System.currentTimeMillis(), builder.build());
            
        } catch (Exception e) {
            Log.e(TAG, "❌ Error mostrando notificación de amenaza: " + e.getMessage(), e);
        }
    }
    
    private Notification createProtectionNotification() {
        Intent intent = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent, 
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        
        return new NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🛡️ GuardianSMS Activo")
            .setContentText("Protegiendo contra SMS maliciosos")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build();
    }
    
    private void createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Canal para servicio de protección
            NotificationChannel serviceChannel = new NotificationChannel(
                CHANNEL_ID,
                "Protección SMS",
                NotificationManager.IMPORTANCE_LOW
            );
            serviceChannel.setDescription("Notificaciones del servicio de protección SMS");
            
            // Canal para amenazas detectadas
            NotificationChannel threatChannel = new NotificationChannel(
                THREAT_CHANNEL_ID,
                "Amenazas SMS",
                NotificationManager.IMPORTANCE_HIGH
            );
            threatChannel.setDescription("Alertas de SMS maliciosos detectados");
            threatChannel.enableVibration(true);
            threatChannel.setVibrationPattern(new long[]{100, 200, 300, 400, 500});
            
            notificationManager.createNotificationChannel(serviceChannel);
            notificationManager.createNotificationChannel(threatChannel);
        }
    }
    
    public static void setMethodChannel(MethodChannel channel) {
        methodChannel = channel;
        Log.d(TAG, "✅ MethodChannel configurado para comunicación con Flutter");
    }
    
    @Override
    public IBinder onBind(Intent intent) {
        return null; // Servicio no vinculado
    }
    
    @Override
    public void onDestroy() {
        Log.d(TAG, "🛑 GuardianService destruido");
        super.onDestroy();
    }
}