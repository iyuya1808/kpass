import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'calendar_event.g.dart';

@JsonSerializable()
class CalendarEvent extends Equatable {
  final String id;
  final String title;
  final String? description;
  @JsonKey(name: 'start_at')
  final DateTime startTime;
  @JsonKey(name: 'end_at')
  final DateTime? endTime;
  @JsonKey(name: 'location_name')
  final String? location;
  @JsonKey(name: 'all_day')
  final bool? isAllDay;
  @JsonKey(name: 'workflow_state')
  final String? workflowState;
  @JsonKey(name: 'context_code')
  final String? contextCode;
  @JsonKey(name: 'context_name')
  final String? contextName;
  @JsonKey(name: 'context_type')
  final String? contextType;
  @JsonKey(name: 'user_id')
  final int? userId;
  @JsonKey(name: 'effective_context_code')
  final String? effectiveContextCode;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'appointment_group_id')
  final int? appointmentGroupId;
  @JsonKey(name: 'appointment_group_url')
  final String? appointmentGroupUrl;
  @JsonKey(name: 'own_reservation')
  final bool? ownReservation;
  @JsonKey(name: 'reserve_url')
  final String? reserveUrl;
  @JsonKey(name: 'reserved')
  final bool? reserved;
  @JsonKey(name: 'participant_type')
  final String? participantType;
  @JsonKey(name: 'url')
  final String? url;
  @JsonKey(name: 'html_url')
  final String? htmlUrl;
  @JsonKey(name: 'duplicates')
  final List<Map<String, dynamic>>? duplicates;
  @JsonKey(name: 'assignment')
  final Map<String, dynamic>? assignment;
  @JsonKey(name: 'assignment_overrides')
  final List<Map<String, dynamic>>? assignmentOverrides;
  @JsonKey(name: 'important_dates')
  final bool? importantDates;
  @JsonKey(name: 'parent_event_id')
  final String? parentEventId;
  @JsonKey(name: 'hidden')
  final bool? hidden;
  @JsonKey(name: 'child_events_count')
  final int? childEventsCount;
  @JsonKey(name: 'child_events')
  final List<Map<String, dynamic>>? childEvents;
  @JsonKey(name: 'series_uuid')
  final String? seriesUuid;
  @JsonKey(name: 'rrule')
  final String? rrule;
  @JsonKey(name: 'series_head')
  final bool? seriesHead;
  @JsonKey(name: 'series_natural_language')
  final String? seriesNaturalLanguage;
  @JsonKey(name: 'blackout_date')
  final bool? blackoutDate;
  
  // Custom field for Canvas assignment ID (used for calendar sync)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? canvasAssignmentId;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    this.description,
    this.endTime,
    this.location,
    this.isAllDay,
    this.workflowState,
    this.contextCode,
    this.contextName,
    this.contextType,
    this.userId,
    this.effectiveContextCode,
    this.createdAt,
    this.updatedAt,
    this.appointmentGroupId,
    this.appointmentGroupUrl,
    this.ownReservation,
    this.reserveUrl,
    this.reserved,
    this.participantType,
    this.url,
    this.htmlUrl,
    this.duplicates,
    this.assignment,
    this.assignmentOverrides,
    this.importantDates,
    this.parentEventId,
    this.hidden,
    this.childEventsCount,
    this.childEvents,
    this.seriesUuid,
    this.rrule,
    this.seriesHead,
    this.seriesNaturalLanguage,
    this.blackoutDate,
    this.canvasAssignmentId,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarEventToJson(this);

  /// Factory constructor to create a CalendarEvent from an Assignment
  factory CalendarEvent.fromAssignment({
    required int assignmentId,
    required String assignmentName,
    required DateTime dueDate,
    String? description,
    String? courseCode,
    String? courseName,
  }) {
    return CalendarEvent(
      id: 'canvas_assignment_$assignmentId',
      title: assignmentName,
      description: description ?? 'Assignment due for ${courseCode ?? courseName ?? 'course'}',
      startTime: dueDate,
      endTime: dueDate,
      isAllDay: false,
      workflowState: 'active',
      contextCode: courseCode,
      contextName: courseName,
      contextType: 'Course',
      canvasAssignmentId: assignmentId.toString(),
    );
  }

  /// Validation method to check if the calendar event data is valid
  bool isValid() {
    return id.isNotEmpty && title.isNotEmpty;
  }

  /// Check if the event is currently active
  bool get isActive {
    return workflowState != 'deleted' && (hidden != true);
  }

  /// Check if the event is in the past
  bool get isPast {
    final now = DateTime.now();
    final eventEnd = endTime ?? startTime;
    return eventEnd.isBefore(now);
  }

  /// Check if the event is happening today
  bool get isToday {
    final now = DateTime.now();
    final eventDate = startTime;
    return eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day;
  }

  /// Check if the event is upcoming (within the next 7 days)
  bool get isUpcoming {
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));
    return startTime.isAfter(now) && startTime.isBefore(sevenDaysFromNow);
  }

  /// Get the duration of the event
  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  /// Check if this event is related to a Canvas assignment
  bool get isAssignmentEvent {
    return canvasAssignmentId != null || 
           (assignment != null && assignment!.isNotEmpty);
  }

  /// Get the assignment ID if this is an assignment event
  int? get assignmentId {
    if (canvasAssignmentId != null) {
      return int.tryParse(canvasAssignmentId!);
    }
    if (assignment != null && assignment!['id'] != null) {
      return assignment!['id'] as int?;
    }
    return null;
  }

  /// Get a display-friendly event title
  String get displayTitle {
    if (contextName != null && !title.contains(contextName!)) {
      return '$title ($contextName)';
    }
    return title;
  }

  /// Create a copy of the calendar event with updated fields
  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    bool? isAllDay,
    String? workflowState,
    String? contextCode,
    String? contextName,
    String? contextType,
    int? userId,
    String? effectiveContextCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? url,
    String? htmlUrl,
    Map<String, dynamic>? assignment,
    bool? importantDates,
    bool? hidden,
    String? canvasAssignmentId,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      isAllDay: isAllDay ?? this.isAllDay,
      workflowState: workflowState ?? this.workflowState,
      contextCode: contextCode ?? this.contextCode,
      contextName: contextName ?? this.contextName,
      contextType: contextType ?? this.contextType,
      userId: userId ?? this.userId,
      effectiveContextCode: effectiveContextCode ?? this.effectiveContextCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      appointmentGroupId: appointmentGroupId,
      appointmentGroupUrl: appointmentGroupUrl,
      ownReservation: ownReservation,
      reserveUrl: reserveUrl,
      reserved: reserved,
      participantType: participantType,
      url: url ?? this.url,
      htmlUrl: htmlUrl ?? this.htmlUrl,
      duplicates: duplicates,
      assignment: assignment ?? this.assignment,
      assignmentOverrides: assignmentOverrides,
      importantDates: importantDates ?? this.importantDates,
      parentEventId: parentEventId,
      hidden: hidden ?? this.hidden,
      childEventsCount: childEventsCount,
      childEvents: childEvents,
      seriesUuid: seriesUuid,
      rrule: rrule,
      seriesHead: seriesHead,
      seriesNaturalLanguage: seriesNaturalLanguage,
      blackoutDate: blackoutDate,
      canvasAssignmentId: canvasAssignmentId ?? this.canvasAssignmentId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        startTime,
        endTime,
        location,
        isAllDay,
        workflowState,
        contextCode,
        contextName,
        contextType,
        userId,
        effectiveContextCode,
        createdAt,
        updatedAt,
        appointmentGroupId,
        appointmentGroupUrl,
        ownReservation,
        reserveUrl,
        reserved,
        participantType,
        url,
        htmlUrl,
        duplicates,
        assignment,
        assignmentOverrides,
        importantDates,
        parentEventId,
        hidden,
        childEventsCount,
        childEvents,
        seriesUuid,
        rrule,
        seriesHead,
        seriesNaturalLanguage,
        blackoutDate,
        canvasAssignmentId,
      ];

  @override
  String toString() {
    return 'CalendarEvent(id: $id, title: $title, startTime: $startTime, '
        'endTime: $endTime, isAllDay: $isAllDay, contextName: $contextName)';
  }
}