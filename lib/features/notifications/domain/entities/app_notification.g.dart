// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      priority:
          $enumDecodeNullable(
            _$NotificationPriorityEnumMap,
            json['priority'],
          ) ??
          NotificationPriority.normal,
      scheduledAt:
          json['scheduledAt'] == null
              ? null
              : DateTime.parse(json['scheduledAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      isShown: json['isShown'] as bool? ?? false,
      assignmentId: (json['assignmentId'] as num?)?.toInt(),
      courseId: (json['courseId'] as num?)?.toInt(),
      data: json['data'] as Map<String, dynamic>?,
      deepLink: json['deepLink'] as String?,
    );

Map<String, dynamic> _$AppNotificationToJson(AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'priority': _$NotificationPriorityEnumMap[instance.priority]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'scheduledAt': instance.scheduledAt?.toIso8601String(),
      'isRead': instance.isRead,
      'isShown': instance.isShown,
      'assignmentId': instance.assignmentId,
      'courseId': instance.courseId,
      'data': instance.data,
      'deepLink': instance.deepLink,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.assignmentReminder: 'assignment_reminder',
  NotificationType.newAssignment: 'new_assignment',
  NotificationType.assignmentUpdate: 'assignment_update',
  NotificationType.syncComplete: 'sync_complete',
  NotificationType.syncError: 'sync_error',
};

const _$NotificationPriorityEnumMap = {
  NotificationPriority.low: 'low',
  NotificationPriority.normal: 'normal',
  NotificationPriority.high: 'high',
  NotificationPriority.urgent: 'urgent',
};
