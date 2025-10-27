// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationSettings _$NotificationSettingsFromJson(
  Map<String, dynamic> json,
) => NotificationSettings(
  isEnabled: json['isEnabled'] as bool? ?? true,
  assignmentRemindersEnabled:
      json['assignmentRemindersEnabled'] as bool? ?? true,
  defaultReminderMinutes:
      (json['defaultReminderMinutes'] as num?)?.toInt() ?? 60,
  newAssignmentNotifications:
      json['newAssignmentNotifications'] as bool? ?? true,
  assignmentUpdateNotifications:
      json['assignmentUpdateNotifications'] as bool? ?? true,
  enabledCourseIds:
      (json['enabledCourseIds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  quietHoursStart: (json['quietHoursStart'] as num?)?.toInt(),
  quietHoursEnd: (json['quietHoursEnd'] as num?)?.toInt(),
  soundEnabled: json['soundEnabled'] as bool? ?? true,
  vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
);

Map<String, dynamic> _$NotificationSettingsToJson(
  NotificationSettings instance,
) => <String, dynamic>{
  'isEnabled': instance.isEnabled,
  'assignmentRemindersEnabled': instance.assignmentRemindersEnabled,
  'defaultReminderMinutes': instance.defaultReminderMinutes,
  'newAssignmentNotifications': instance.newAssignmentNotifications,
  'assignmentUpdateNotifications': instance.assignmentUpdateNotifications,
  'enabledCourseIds': instance.enabledCourseIds,
  'quietHoursStart': instance.quietHoursStart,
  'quietHoursEnd': instance.quietHoursEnd,
  'soundEnabled': instance.soundEnabled,
  'vibrationEnabled': instance.vibrationEnabled,
};
