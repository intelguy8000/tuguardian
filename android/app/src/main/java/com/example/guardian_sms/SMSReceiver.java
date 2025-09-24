package com.example.guardian_sms;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.telephony.SmsMessage;
import android.util.Log;
import io.flutter.plugin.common.MethodChannel;

public class SMSReceiver extends BroadcastReceiver {
    private static final String TAG = "GuardianSMS_Receiver";
    private static final String CHANNEL = "guardian_sms/native";
    
    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d(TAG, "📱 SMS recibido - Action: " + intent.getAction());
        
        if (intent.getAction() != null && 
            (intent.getAction().equals("android.provider.Telephony.SMS_RECEIVED") ||
             intent.getAction().equals("android.provider.Telephony.SMS_DELIVER"))) {
            
            try {
                Bundle bundle = intent.getExtras();
                if (bundle != null) {
                    Object[] pdus = (Object[]) bundle.get("pdus");
                    String format = bundle.getString("format");
                    
                    if (pdus != null && pdus.length > 0) {
                        for (Object pdu : pdus) {
                            SmsMessage smsMessage;
                            
                            // Compatibilidad con diferentes versiones Android
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                                smsMessage = SmsMessage.createFromPdu((byte[]) pdu, format);
                            } else {
                                smsMessage = SmsMessage.createFromPdu((byte[]) pdu);
                            }
                            
                            if (smsMessage != null) {
                                String sender = smsMessage.getOriginatingAddress();
                                String messageBody = smsMessage.getMessageBody();
                                long timestamp = smsMessage.getTimestampMillis();
                                
                                Log.d(TAG, "🔍 SMS de: " + sender + " - Mensaje: " + messageBody.substring(0, Math.min(50, messageBody.length())));
                                
                                // Enviar a Flutter para análisis
                                sendSMSToFlutter(context, sender, messageBody, timestamp);
                            }
                        }
                    }
                }
            } catch (Exception e) {
                Log.e(TAG, "❌ Error procesando SMS: " + e.getMessage(), e);
            }
        }
    }
    
    private void sendSMSToFlutter(Context context, String sender, String message, long timestamp) {
        try {
            Intent serviceIntent = new Intent(context, GuardianService.class);
            serviceIntent.putExtra("action", "ANALYZE_SMS");
            serviceIntent.putExtra("sender", sender);
            serviceIntent.putExtra("message", message);
            serviceIntent.putExtra("timestamp", timestamp);
            
            // Iniciar servicio para procesar SMS
            context.startService(serviceIntent);
            
            Log.d(TAG, "✅ SMS enviado a GuardianService para análisis");
            
        } catch (Exception e) {
            Log.e(TAG, "❌ Error enviando SMS a Flutter: " + e.getMessage(), e);
        }
    }
}