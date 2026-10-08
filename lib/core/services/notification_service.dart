import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final _storage = const FlutterSecureStorage();

  void Function(String?)? onNotificationTap;

  Future<void> init({void Function(String?)? onNotificationClick}) async {
    onNotificationTap = onNotificationClick;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (onNotificationTap != null) {
          onNotificationTap!(details.payload);
        }
      },
    );

    // Default channel
    await _createChannel('default');

    await requestPermissions();
  }

  Future<void> _createChannel(String soundMode) async {
    final channelId = 'attendance_reminder_$soundMode';
    final androidChannel = AndroidNotificationChannel(
      channelId,
      'Nhắc nhở điểm danh & Lịch dạy',
      description: 'Nhắc nhở xác nhận điểm danh và lịch dạy',
      importance: Importance.high,
      sound: null,
      playSound: soundMode != 'silent',
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<String?> getInitialPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      return details.notificationResponse?.payload;
    }
    return null;
  }

  Future<bool> _shouldNotify() async {
    final enabled = await _storage.read(key: 'notifications_enabled');
    return enabled != 'false';
  }

  Future<AndroidNotificationDetails> _getNotificationDetails() async {
    final sound = await _storage.read(key: 'notification_sound') ?? 'default';
    
    // Ensure the channel exists for the selected sound
    await _createChannel(sound);

    return AndroidNotificationDetails(
      'attendance_reminder_$sound',
      'Nhắc nhở điểm danh & Lịch dạy',
      channelDescription: 'Nhắc nhở xác nhận điểm danh và lịch dạy',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_launcher',
      sound: null,
      playSound: sound != 'silent',
    );
  }

  Future<bool?> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final notificationPermission =
        await android?.requestNotificationsPermission();
    final canScheduleExact = await android?.canScheduleExactNotifications();
    if (canScheduleExact == false) {
      await android?.requestExactAlarmsPermission();
    }
    return notificationPermission;
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    final canScheduleExact = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.canScheduleExactNotifications();
    return canScheduleExact == false
        ? AndroidScheduleMode.inexactAllowWhileIdle
        : AndroidScheduleMode.exactAllowWhileIdle;
  }

  Future<void> scheduleSessionStartNotification({
    required int id,
    required String sessionId,
    required String sessionName,
    required DateTime startTime,
  }) async {
    if (!await _shouldNotify()) return;

    final scheduledTime = tz.TZDateTime.from(startTime, tz.local);
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    final details = await _getNotificationDetails();

    await _plugin.zonedSchedule(
      id,
      'Lịch dạy sắp bắt đầu',
      'Ca học "$sessionName" chuẩn bị bắt đầu.',
      scheduledTime,
      NotificationDetails(android: details),
      payload: sessionId,
      androidScheduleMode: await _scheduleMode(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleSessionEndNotification({
    required int id,
    required String sessionId,
    required String sessionName,
    required DateTime endTime,
  }) async {
    if (!await _shouldNotify()) return;

    final scheduledTime = tz.TZDateTime.from(endTime, tz.local);
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    final details = await _getNotificationDetails();

    await _plugin.zonedSchedule(
      id,
      'Xác nhận điểm danh',
      'Ca học "$sessionName" vừa kết thúc. Bấm để xác nhận điểm danh!',
      scheduledTime,
      NotificationDetails(android: details),
      payload: sessionId,
      androidScheduleMode: await _scheduleMode(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!await _shouldNotify()) return;

    final details = await _getNotificationDetails();

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: details),
      payload: payload,
    );
  }
}
