package com.example.guardian_sms;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.util.HashMap;
import java.util.Map;

public class MainActivity extends FlutterActivity {
    private static final String TAG = "GuardianSMS_Main";
    private static final String CHANNEL = "guardian_sms/native";
    private static final int PERMISSION_REQUEST_CODE = 1000;
    
    private MethodChannel methodChannel;
    private GuardianService guardianService;
    
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        Log.d(TAG, "🚀 Configurando Flutter Engine y MethodChannel");
        
        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        
        // Configurar MethodChannel en GuardianService
        GuardianService.setMethodChannel(methodChannel);
        
        methodChannel.setMethodCallHandler((call, result) -> {
            Log.d(TAG, "📞 Método llamado desde Flutter: " + call.method);
            
            switch (call.method) {
                case "requestPermissions":
                    requestAllPermissions(result);
                    break;
                    
                case "startSMSProtection":
                    startSMSProtection(result);
                    break;
                    
                case "stopSMSProtection":
                    stopSMSProtection(result);
                    break;
                    
                case "showThreatNotification":
                    showThreatNotification(call.arguments, result);
                    break;
                    
                case "checkPermissions":
                    checkAllPermissions(result);
                    break;
                    
                default:
                    Log.w(TAG, "❓ Método no implementado: " + call.method);
                    result.notImplemented();
                    break;
            }
        });
        
        Log.d(TAG, "✅ MethodChannel configurado correctamente");
    }
    
    private void requestAllPermissions(MethodChannel.Result result) {
        Log.d(TAG, "📋 Solicitando permisos SMS...");
        
        String[] permissions = {
            Manifest.permission.READ_SMS,
            Manifest.permission.RECEIVE_SMS,
            Manifest.permission.SEND_SMS,
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.CALL_PHONE
        };
        
        // Agregar permiso de notificaciones para Android 13+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            String[] extendedPermissions = new String[permissions.length + 1];
            System.arraycopy(permissions, 0, extendedPermissions, 0, permissions.length);
            extendedPermissions[permissions.length] = Manifest.permission.POST_NOTIFICATIONS;
            permissions = extendedPermissions;
        }
        
        ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE);
        result.success(true);
    }
    
    private void checkAllPermissions(MethodChannel.Result result) {
        Map<String, Boolean> permissionStatus = new HashMap<>();
        
        permissionStatus.put("READ_SMS", hasPermission(Manifest.permission.READ_SMS));
        permissionStatus.put("RECEIVE_SMS", hasPermission(Manifest.permission.RECEIVE_SMS));
        permissionStatus.put("SEND_SMS", hasPermission(Manifest.permission.SEND_SMS));
        permissionStatus.put("READ_PHONE_STATE", hasPermission(Manifest.permission.READ_PHONE_STATE));
        permissionStatus.put("CALL_PHONE", hasPermission(Manifest.permission.CALL_PHONE));
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissionStatus.put("POST_NOTIFICATIONS", hasPermission(Manifest.permission.POST_NOTIFICATIONS));
        }
        
        Log.d(TAG, "📋 Estado de permisos: " + permissionStatus.toString());
        result.success(permissionStatus);
    }
    
    private boolean hasPermission(String permission) {
        return ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED;
    }
    
    private void startSMSProtection(MethodChannel.Result result) {
        Log.d(TAG, "🛡️ Iniciando protección SMS...");
        
        try {
            Intent serviceIntent = new Intent(this, GuardianService.class);
            serviceIntent.putExtra("action", "START_PROTECTION");
            startService(serviceIntent);
            
            Log.d(TAG, "✅ Protección SMS iniciada correctamente");
            result.success(true);
            
        } catch (Exception e) {
            Log.e(TAG, "❌ Error iniciando protección SMS: " + e.getMessage(), e);
            result.error("START_ERROR", e.getMessage(), null);
        }
    }
    
    private void stopSMSProtection(MethodChannel.Result result) {
        Log.d(TAG, "🛑 Deteniendo protección SMS...");
        
        try {
            Intent serviceIntent = new Intent(this, GuardianService.class);
            stopService(serviceIntent);
            
            Log.d(TAG, "✅ Protección SMS detenida");
            result.success(true);
            
        } catch (Exception e) {
            Log.e(TAG, "❌ Error deteniendo protección SMS: " + e.getMessage(), e);
            result.error("STOP_ERROR", e.getMessage(), null);
        }
    }
    
    private void showThreatNotification(Object arguments, MethodChannel.Result result) {
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> args = (Map<String, Object>) arguments;
            
            String title = (String) args.get("title");
            String body = (String) args.get("body");
            String sender = (String) args.get("sender");
            Integer riskScore = (Integer) args.get("riskScore");
            
            Log.d(TAG, "🚨 Mostrando notificación de amenaza: " + sender + " (Score: " + riskScore + ")");
            
            // Buscar instancia del servicio activo y mostrar notificación
            Intent serviceIntent = new Intent(this, GuardianService.class);
            serviceIntent.putExtra("action", "SHOW_THREAT_NOTIFICATION");
            serviceIntent.putExtra("title", title);
            serviceIntent.putExtra("body", body);
            serviceIntent.putExtra("sender", sender);
            serviceIntent.putExtra("riskScore", riskScore != null ? riskScore : 0);
            
            startService(serviceIntent);
            
            result.success(true);
            
        } catch (Exception e) {
            Log.e(TAG, "❌ Error mostrando notificación de amenaza: " + e.getMessage(), e);
            result.error("NOTIFICATION_ERROR", e.getMessage(), null);
        }
    }
    
    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, 
                                         @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            Log.d(TAG, "📋 Resultado de permisos recibido");
            
            Map<String, Boolean> results = new HashMap<>();
            for (int i = 0; i < permissions.length; i++) {
                boolean granted = grantResults[i] == PackageManager.PERMISSION_GRANTED;
                results.put(permissions[i], granted);
                Log.d(TAG, "  " + permissions[i] + ": " + (granted ? "✅" : "❌"));
            }
            
            // Notificar a Flutter sobre resultado de permisos
            if (methodChannel != null) {
                methodChannel.invokeMethod("onPermissionResult", results);
            }
        }
    }
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(TAG, "🚀 MainActivity creada - GuardianSMS iniciando");
    }
    
    @Override
    protected void onDestroy() {
        Log.d(TAG, "🛑 MainActivity destruida");
        super.onDestroy();
    }
}