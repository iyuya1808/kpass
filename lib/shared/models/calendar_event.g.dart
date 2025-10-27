// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalendarEvent _$CalendarEventFromJson(Map<String, dynamic> json) =>
    CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      startTime: DateTime.parse(json['start_at'] as String),
      description: json['description'] as String?,
      endTime:
          json['end_at'] == null
              ? null
              : DateTime.parse(json['end_at'] as String),
      location: json['location_name'] as String?,
      isAllDay: json['all_day'] as bool?,
      workflowState: json['workflow_state'] as String?,
      contextCode: json['context_code'] as String?,
      contextName: json['context_name'] as String?,
      contextType: json['context_type'] as String?,
      userId: (json['user_id'] as num?)?.toInt(),
      effectiveContextCode: json['effective_context_code'] as String?,
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] == null
              ? null
              : DateTime.parse(json['updated_at'] as String),
      appointmentGroupId: (json['appointment_group_id'] as num?)?.toInt(),
      appointmentGroupUrl: json['appointment_group_url'] as String?,
      ownReservation: json['own_reservation'] as bool?,
      reserveUrl: json['reserve_url'] as String?,
      reserved: json['reserved'] as bool?,
      participantType: json['participant_type'] as String?,
      url: json['url'] as String?,
      htmlUrl: json['html_url'] as String?,
      duplicates:
          (json['duplicates'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList(),
      assignment: json['assignment'] as Map<String, dynamic>?,
      assignmentOverrides:
          (json['assignment_overrides'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList(),
      importantDates: json['important_dates'] as bool?,
      parentEventId: json['parent_event_id'] as String?,
      hidden: json['hidden'] as bool?,
      childEventsCount: (json['child_events_count'] as num?)?.toInt(),
      childEvents:
          (json['child_events'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList(),
      seriesUuid: json['series_uuid'] as String?,
      rrule: json['rrule'] as String?,
      seriesHead: json['series_head'] as bool?,
      seriesNaturalLanguage: json['series_natural_language'] as String?,
      blackoutDate: json['blackout_date'] as bool?,
    );

Map<String, dynamic> _$CalendarEventToJson(CalendarEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'start_at': instance.startTime.toIso8601String(),
      'end_at': instance.endTime?.toIso8601String(),
      'location_name': instance.location,
      'all_day': instance.isAllDay,
      'workflow_state': instance.workflowState,
      'context_code': instance.contextCode,
      'context_name': instance.contextName,
      'context_type': instance.contextType,
      'user_id': instance.userId,
      'effective_context_code': instance.effectiveContextCode,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'appointment_group_id': instance.appointmentGroupId,
      'appointment_group_url': instance.appointmentGroupUrl,
      'own_reservation': instance.ownReservation,
      'reserve_url': instance.reserveUrl,
      'reserved': instance.reserved,
      'participant_type': instance.participantType,
      'url': instance.url,
      'html_url': instance.htmlUrl,
      'duplicates': instance.duplicates,
      'assignment': instance.assignment,
      'assignment_overrides': instance.assignmentOverrides,
      'important_dates': instance.importantDates,
      'parent_event_id': instance.parentEventId,
      'hidden': instance.hidden,
      'child_events_count': instance.childEventsCount,
      'child_events': instance.childEvents,
      'series_uuid': instance.seriesUuid,
      'rrule': instance.rrule,
      'series_head': instance.seriesHead,
      'series_natural_language': instance.seriesNaturalLanguage,
      'blackout_date': instance.blackoutDate,
    };
