import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service to manage app icon badge counter for unread messages
class BadgeService {
  static final BadgeService instance = BadgeService._internal();
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  BadgeService._internal();

  /// Update badge with specific count
  /// Uses both flutter_app_badger AND notification system for maximum compatibility
  Future<void> updateBadge(int count) async {
    try {
      // Method 1: Try flutter_app_badger (works on some launchers)
      try {
        if (count <= 0) {
          await FlutterAppBadger.removeBadge();
        } else {
          await FlutterAppBadger.updateBadgeCount(count);
        }
      } catch (e) {
        print('⚠️ flutter_app_badger failed: $e');
      }

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
