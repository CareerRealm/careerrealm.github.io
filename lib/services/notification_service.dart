import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:ui';
import 'dart:isolate';

/// Manages Android notification channels and notifications.
/// Creating a channel makes the app appear in Android's notification
/// and sound settings automatically.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'harmonitimer_default',
    'Career Realm Notifications',
    description: 'Timer alerts, focus reminders, and chat notifications',
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('notification'),
  );

  static const _ongoingChannel = AndroidNotificationChannel(
    'harmonitimer_ongoing_v3',
    'Active Timers (Fancy)',
    description: 'Ongoing timer countdown and controls',
    importance: Importance.max,
    playSound: false,
    showBadge: false,
  );

  bool _initialized = false;
  
  // Callback for notification actions
  void Function(String actionId)? onAction;

  /// Initialize the notification system. Call once at app start.
  Future<void> init() async {
    if (_initialized) return;
    // Only set up on Native Android, NOT Web on Android
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _initialized = true;
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId != null) {
          onAction?.call(response.actionId!);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final platform = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(_channel);
    await platform?.createNotificationChannel(_ongoingChannel);

    _initialized = true;

    // Register port for background actions to talk to the main UI isolate
    final port = ReceivePort();
    IsolateNameServer.removePortNameMapping('harmonitimer_actions');
    IsolateNameServer.registerPortWithName(port.sendPort, 'harmonitimer_actions');
    port.listen((message) {
      if (message is String) {
        onAction?.call(message);
      }
    });
  }

  /// Request notification permission (Android 13+).
  Future<bool> requestPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    final platform = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await platform?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Show a notification with the app's default channel (sound included).
  Future<void> show({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'harmonitimer_default',
          'Career Realm Notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
        ),
      ),
    );
  }

  /// Show a silent notification (no sound).
  Future<void> showSilent({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'harmonitimer_default',
          'HarmoniTimer Notifications',
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
        ),
      ),
    );
  }

  /// Show a notification with a progress bar.
  Future<void> showProgress({
    required int id,
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'harmonitimer_default',
          'HarmoniTimer Notifications',
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          showProgress: true,
          maxProgress: maxProgress,
          progress: progress,
          ongoing: true,
        ),
      ),
    );
  }

  /// Show an ongoing timer with chronometer and actions
  Future<void> showOngoingTimer({
    required String title,
    required String body,
    required int targetTimeMs,
    required bool isPaused,
    int id = 999,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    await _plugin.show(
      id,
      isPaused ? '⏸ $title' : '✨ $title',
      isPaused ? 'Timer paused. Tap to resume.' : body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'harmonitimer_ongoing_v3', // v3 channel for the ultra-premium notification
          'Active Timers (Fancy)',
          importance: Importance.max,
          priority: Priority.max,
          ongoing: true,
          autoCancel: false,
          color: const Color(0xFF6D28D9),
          colorized: true, // Premium full-color background if allowed by device
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(
            isPaused
                ? 'Your session is paused.\nReady to get back to focus?'
                : 'Keep pushing! Every second counts.\nStay focused and minimize distractions 💪',
            contentTitle: isPaused ? '⏸ $title' : '✨ $title',
            summaryText: 'HarmoniTimer Active Session',
          ),
          showWhen: !isPaused,
          when: isPaused ? null : targetTimeMs,
          usesChronometer: !isPaused,
          chronometerCountDown: !isPaused,
          actions: [
            if (!isPaused) const AndroidNotificationAction('pause_timer', 'Pause', cancelNotification: false, showsUserInterface: true),
            if (isPaused) const AndroidNotificationAction('resume_timer', 'Resume', cancelNotification: false, showsUserInterface: true),
            const AndroidNotificationAction('stop_sound', 'Mute Sound', cancelNotification: false, showsUserInterface: true),
          ],
        ),
      ),
    );
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  final action = response.actionId;
  if (action != null) {
    // Send action directly to main isolate!
    final SendPort? send = IsolateNameServer.lookupPortByName('harmonitimer_actions');
    send?.send(action);
  }
}
