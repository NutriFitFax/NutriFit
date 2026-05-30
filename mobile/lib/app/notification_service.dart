import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Manages meal and water reminder notifications.
///
/// Call [init] once at app startup before scheduling anything.
/// Call [setMealReminders] / [setWaterReminders] when the user flips
/// the toggle in Settings — they cancel old notifications and re-schedule
/// new ones as needed.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;

  static const _channelMeal  = 'nutrifit_meal_reminders';
  static const _channelWater = 'nutrifit_water_reminders';

  // Fixed notification IDs — stable so cancel always hits the right one.
  static const _mealIds  = [100, 101, 102];
  static const _waterIds = [200, 201, 202, 203, 204, 205, 206,
                             207, 208, 209, 210, 211, 212, 213, 214];

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Falls back to UTC — notifications will still fire, just offset.
    }

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Don't ask for permission at init — ask when the user enables a reminder.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  Future<void> _requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedules (or cancels) the three daily meal reminder notifications.
  Future<void> setMealReminders(bool enabled) async {
    if (!_ready) return;
    for (final id in _mealIds) { await _plugin.cancel(id); }
    if (!enabled) return;

    await _requestPermission();

    const meals = [
      (100,  8,  0, 'Breakfast time',  'Log your breakfast in NutriFit.'),
      (101, 12, 30, 'Lunch time',      'Log your lunch in NutriFit.'),
      (102, 18, 30, 'Dinner time',     'Log your dinner in NutriFit.'),
    ];

    for (final (id, hour, min, title, body) in meals) {
      await _plugin.zonedSchedule(
        id, title, body,
        _nextDailyInstance(hour, min),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelMeal, 'Meal Reminders',
            channelDescription: 'Daily reminders to log your meals',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Schedules (or cancels) hourly water reminders from 8 AM to 10 PM.
  Future<void> setWaterReminders(bool enabled) async {
    if (!_ready) return;
    for (final id in _waterIds) { await _plugin.cancel(id); }
    if (!enabled) return;

    await _requestPermission();

    for (var i = 0; i < _waterIds.length; i++) {
      await _plugin.zonedSchedule(
        _waterIds[i],
        'Stay hydrated',
        'Time to drink a glass of water.',
        _nextDailyInstance(8 + i, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelWater, 'Water Reminders',
            channelDescription: 'Hourly hydration reminders',
            importance: Importance.low,
            priority: Priority.low,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  tz.TZDateTime _nextDailyInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return t;
  }
}
