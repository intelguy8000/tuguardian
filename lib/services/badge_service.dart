// import 'package:flutter_app_badger/flutter_app_badger.dart'; // Temporarily disabled (discontinued)
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service to manage app icon badge counter for unread messages
class BadgeService {
  static final BadgeService instance = BadgeService._internal();
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  BadgeService._internal();

  /// Update badge with specific count
  /// Uses notification system for badge display (works on Samsung/modern Android)
  Future<void> updateBadge(int count) async {
    try {
      // Method 1: flutter_app_badger temporarily disabled (discontinued package)
      // TODO: Replace with alternative badge solution if needed

      // Method 2 (now primary): Use notification badge (works on Samsung/modern Android)

      // Method 2: Use notification badge (works on Samsung/modern Android)
      if (count <= 0) {
        // Remove summary notification
        await _notifications.cancel(9999);
        print('✅ Badge removed (count: 0)');
      } else {
        // Show summary notification with badge
        await _showSummaryNotification(count);
        print('✅ Badge updated: $count');
      }
    } catch (e) {
      print('❌ Error updating badge: $e');
    }
  }

  /// Show a summary notification that triggers the badge
  /// Samsung/Android shows badges when there are active notifications
  Future<void> _showSummaryNotification(int count) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'unread_summary',
      'Mensajes no leídos',
      channelDescription: 'Resumen de mensajes SMS no leídos',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
      ongoing: false,
      autoCancel: true,
      showWhen: false,
      onlyAlertOnce: true,
      number: count, // THIS is what shows the badge number
      category: AndroidNotificationCategory.message,
      styleInformation: InboxStyleInformation(
        ['$count mensajes no leídos'],
        contentTitle: 'TuGuardian',
        summaryText: '$count no leídos',
      ),
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      9999, // Persistent ID for summary
      'TuGuardian',
      '$count mensajes no leídos',
      details,
    );
  }

  /// Clear badge (set to 0)
  Future<void> clearBadge() async {
    await updateBadge(0);
  }
}
