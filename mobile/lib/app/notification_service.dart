import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'settings_prefs.dart';

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

  static const _mealIds  = [100, 101, 102];
  // 24 water slots — enough for hourly reminders across a full day.
  static const _waterIds = [
    200, 201, 202, 203, 204, 205, 206, 207,
    208, 209, 210, 211, 212, 213, 214, 215,
    216, 217, 218, 219, 220, 221, 222, 223,
  ];

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Falls back to UTC — notifications will still fire, just offset.
    }

    try {
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
    } catch (_) {
      // Notifications not supported on this platform — all methods no-op via _ready.
    }
  }

  Future<void> _requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedules (or cancels) daily meal reminder notifications.
  ///
  /// [times] is a list of (hour, minute) pairs — one per meal.
  Future<void> setMealReminders(bool enabled, List<(int, int)> times) async {
    if (!_ready) return;
    for (final id in _mealIds) { await _plugin.cancel(id); }
    if (!enabled) return;

    await _requestPermission();

    final labels = ['Breakfast time', 'Lunch time', 'Dinner time'];
    for (var i = 0; i < times.length && i < _mealIds.length; i++) {
      final (hour, min) = times[i];
      await _plugin.zonedSchedule(
        _mealIds[i], labels[i], 'Log your meal in NutriFit.',
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

  /// Schedules (or cancels) repeating water reminders between [startH]:[startM]
  /// and [endH]:[endM], firing every [intervalMin] minutes.
  Future<void> setWaterReminders(
    bool enabled,
    int startH, int startM,
    int endH,   int endM,
    int intervalMin,
  ) async {
    if (!_ready) return;
    for (final id in _waterIds) { await _plugin.cancel(id); }
    if (!enabled) return;

    await _requestPermission();

    var totalMin = startH * 60 + startM;
    final endMin  = endH  * 60 + endM;
    final stepMin = intervalMin;
    var idx = 0;

    while (totalMin <= endMin && idx < _waterIds.length) {
      await _plugin.zonedSchedule(
        _waterIds[idx],
        'Stay hydrated',
        'Time to drink a glass of water.',
        _nextDailyInstance(totalMin ~/ 60, totalMin % 60),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelWater, 'Water Reminders',
            channelDescription: 'Hydration reminders',
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
      totalMin += stepMin;
      idx++;
    }
  }

  /// Cancels every meal and water reminder notification that this service
  /// could have scheduled. Call on logout and account deletion.
  Future<void> cancelAll() async {
    if (!_ready) return;
    for (final id in _mealIds)  { await _plugin.cancel(id); }
    for (final id in _waterIds) { await _plugin.cancel(id); }
  }

  /// Re-applies whatever the user has saved in [SettingsPrefs].
  /// Call on login, sign-up, and cold start (when the user is logged in)
  /// so notifications survive OS alarm-manager resets.
  Future<void> rescheduleFromPrefs() async {
    if (!_ready) return;
    final prefs = SettingsPrefs.instance;

    final mealPairs = prefs.mealReminderTimes.map(_parseHHMM).toList();
    await setMealReminders(prefs.mealReminders, mealPairs);

    final start = _parseHHMM(prefs.waterReminderStart);
    final end   = _parseHHMM(prefs.waterReminderEnd);
    await setWaterReminders(
      prefs.waterReminders,
      start.$1, start.$2,
      end.$1,   end.$2,
      prefs.waterReminderIntervalMinutes,
    );
  }

  static (int, int) _parseHHMM(String hhmm) {
    final parts = hhmm.split(':');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }

  tz.TZDateTime _nextDailyInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return t;
  }
}
