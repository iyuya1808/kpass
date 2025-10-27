// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TodayCourse _$TodayCourseFromJson(Map<String, dynamic> json) => TodayCourse(
  period: (json['period'] as num).toInt(),
  periodLabel: json['periodLabel'] as String,
  timeRange: json['timeRange'] as String,
  courseName: json['courseName'] as String,
  courseId: (json['courseId'] as num).toInt(),
  location: json['location'] as String?,
  nextAssignment:
      json['nextAssignment'] == null
          ? null
          : Assignment.fromJson(json['nextAssignment'] as Map<String, dynamic>),
  startTime: DateTime.parse(json['startTime'] as String),
  endTime:
      json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
  description: json['description'] as String?,
);

Map<String, dynamic> _$TodayCourseToJson(TodayCourse instance) =>
    <String, dynamic>{
      'period': instance.period,
      'periodLabel': instance.periodLabel,
      'timeRange': instance.timeRange,
      'courseName': instance.courseName,
      'courseId': instance.courseId,
      'location': instance.location,
      'nextAssignment': instance.nextAssignment,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'description': instance.description,
    };
