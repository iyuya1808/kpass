import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:kpass/core/utils/period_calculator.dart';
import 'package:kpass/shared/models/calendar_event.dart';
import 'package:kpass/shared/models/assignment.dart';

part 'today_course.g.dart';

/// Represents a course scheduled for today
@JsonSerializable()
class TodayCourse extends Equatable {
  final int period;
  final String periodLabel;
  final String timeRange;
  final String courseName;
  final int courseId;
  final String? location;
  final Assignment? nextAssignment;
  final DateTime startTime;
  final DateTime? endTime;
  final String? description;

  const TodayCourse({
    required this.period,
    required this.periodLabel,
    required this.timeRange,
    required this.courseName,
    required this.courseId,
    this.location,
    this.nextAssignment,
    required this.startTime,
    this.endTime,
    this.description,
  });

  factory TodayCourse.fromJson(Map<String, dynamic> json) =>
      _$TodayCourseFromJson(json);

  Map<String, dynamic> toJson() => _$TodayCourseToJson(this);

  /// Create TodayCourse from CalendarEvent
  factory TodayCourse.fromCalendarEvent(
    CalendarEvent event, {
    Assignment? nextAssignment,
  }) {
    // Calculate period from start time
    final period = PeriodCalculator.getPeriodFromTime(event.startTime);
    if (period == null) {
      throw ArgumentError('Cannot determine period for event: ${event.title}');
    }

    return TodayCourse(
      period: period,
      periodLabel: PeriodCalculator.getPeriodLabel(period),
      timeRange: PeriodCalculator.getPeriodTimeRange(period),
      courseName: event.title,
      courseId: _extractCourseId(event.contextCode),
      location: event.location,
      nextAssignment: nextAssignment,
      startTime: event.startTime,
      endTime: event.endTime,
      description: event.description,
    );
  }

  /// Extract course ID from context code (e.g., "course_12345" -> 12345)
  static int _extractCourseId(String? contextCode) {
    if (contextCode == null) return 0;

    // Context code format: "course_12345"
    if (contextCode.startsWith('course_')) {
      final idString = contextCode.substring(7);
      return int.tryParse(idString) ?? 0;
    }

    return 0;
  }

  /// Get full period display string (e.g., "1限 (09:00-10:30)")
  String get periodDisplay => PeriodCalculator.getPeriodDisplay(period);

  /// Check if this course has a location
  bool get hasLocation => location != null && location!.isNotEmpty;

  /// Check if this course has a next assignment
  bool get hasNextAssignment => nextAssignment != null;

  /// Get display name for the course
  String get displayName {
    // If course name contains course code, use it as is
    if (courseName.contains('-') || courseName.contains(' ')) {
      return courseName;
    }
    return courseName;
  }

  /// Get next assignment due date as string
  String? get nextAssignmentDueDate {
    if (nextAssignment?.dueAt == null) return null;

    final dueDate = nextAssignment!.dueAt!;
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference == 0) {
      return '今日';
    } else if (difference == 1) {
      return '明日';
    } else if (difference > 0) {
      return '$difference日後';
    } else {
      return '期限超過';
    }
  }

  /// Check if the course is currently in session
  bool get isCurrentlyInSession {
    final now = DateTime.now();
    if (endTime == null) return false;

    return now.isAfter(startTime) && now.isBefore(endTime!);
  }

  /// Check if the course has already ended today
  bool get hasEnded {
    final now = DateTime.now();
    if (endTime == null) return now.isAfter(startTime);

    return now.isAfter(endTime!);
  }

  /// Check if the course is upcoming today
  bool get isUpcoming {
    final now = DateTime.now();
    return now.isBefore(startTime);
  }

  /// Create a copy with updated fields
  TodayCourse copyWith({
    int? period,
    String? periodLabel,
    String? timeRange,
    String? courseName,
    int? courseId,
    String? location,
    Assignment? nextAssignment,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
  }) {
    return TodayCourse(
      period: period ?? this.period,
      periodLabel: periodLabel ?? this.periodLabel,
      timeRange: timeRange ?? this.timeRange,
      courseName: courseName ?? this.courseName,
      courseId: courseId ?? this.courseId,
      location: location ?? this.location,
      nextAssignment: nextAssignment ?? this.nextAssignment,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
    period,
    periodLabel,
    timeRange,
    courseName,
    courseId,
    location,
    nextAssignment,
    startTime,
    endTime,
    description,
  ];

  @override
  String toString() {
    return 'TodayCourse(period: $period, courseName: $courseName, '
        'startTime: $startTime, location: $location)';
  }
}
