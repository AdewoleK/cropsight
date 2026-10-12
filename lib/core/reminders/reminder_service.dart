import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A to-do with a due date ("re-check the maize", "spray again"), optionally
/// tied to a field.
class Reminder {
  Reminder({
    required this.id,
    required this.title,
    required this.due,
    this.fieldId,
    this.done = false,
  });

  /// Also the notification id, so it must fit in a 32-bit int.
  final int id;
  final String title;
  final DateTime due;
  final String? fieldId;
  bool done;

  bool get isOverdue => !done && due.isBefore(DateTime.now());

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'due': due.toIso8601String(),
        'fieldId': fieldId,
        'done': done,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as int,
        title: json['title'] as String,
        due: DateTime.parse(json['due'] as String),
        fieldId: json['fieldId'] as String?,
        done: json['done'] as bool,
      );
}

/// Stores reminders on the phone and schedules them as local notifications.
/// No push server, no account: the OS fires them even with no signal.
class ReminderService extends ChangeNotifier {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final List<Reminder> _reminders = [];
  late final File _file;
  bool _loaded = false;
  bool _askedPermission = false;

  /// Lets the screenshot harness set reminders without the system
  /// permission alert covering the screen.
  @visibleForTesting
  bool askForPermission = true;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'field_reminders',
      'Field reminders',
      channelDescription: 'Reminders to re-check or treat a field',
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Open reminders, soonest first.
  List<Reminder> get open =>
      _reminders.where((r) => !r.done).toList()..sort((a, b) => a.due.compareTo(b.due));

  List<Reminder> openFor(String fieldId) =>
      open.where((r) => r.fieldId == fieldId).toList();

  Future<void> load() async {
    if (_loaded) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is asked for when the first reminder is set, not at
        // launch — a prompt with no context gets denied.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    final docs = await getApplicationDocumentsDirectory();
    _file = File('${docs.path}/reminders.json');
    if (await _file.exists()) {
      try {
        final raw = jsonDecode(await _file.readAsString()) as List;
        _reminders.addAll(raw.map((e) => Reminder.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        // Corrupt file: start empty rather than crash the app.
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    await _file.writeAsString(jsonEncode(_reminders.map((r) => r.toJson()).toList()));
    notifyListeners();
  }

  Future<void> _ensurePermission() async {
    if (_askedPermission || !askForPermission) return;
    _askedPermission = true;
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Notification ids must fit in an int32, so ids count up from 1 rather
  /// than reusing timestamps.
  int _nextId() =>
      _reminders.fold<int>(0, (m, r) => r.id > m ? r.id : m) + 1;

  Future<Reminder> add({
    required String title,
    required DateTime due,
    String? fieldId,
  }) async {
    await _ensurePermission();
    final reminder = Reminder(
      id: _nextId(),
      title: title.trim(),
      due: due,
      fieldId: fieldId,
    );
    _reminders.add(reminder);
    await _save();
    try {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: 'CropSight',
        body: reminder.title,
        // An absolute instant, so the phone's time zone setting can't shift it.
        scheduledDate: tz.TZDateTime.from(due.toUtc(), tz.UTC),
        notificationDetails: _details,
        // Inexact is fine for "check your field" and needs no special
        // exact-alarm permission on Android 14+.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Notifications denied/unavailable: the reminder still shows in-app.
    }
    return reminder;
  }

  Future<void> complete(Reminder reminder) async {
    reminder.done = true;
    await _plugin.cancel(id: reminder.id);
    await _save();
  }

  Future<void> deleteForField(String fieldId) async {
    for (final r in _reminders.where((r) => r.fieldId == fieldId)) {
      await _plugin.cancel(id: r.id);
    }
    _reminders.removeWhere((r) => r.fieldId == fieldId);
    await _save();
  }
}
