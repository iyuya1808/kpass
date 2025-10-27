// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Course _$CourseFromJson(Map<String, dynamic> json) => Course(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  courseCode: json['course_code'] as String,
  description: json['description'] as String?,
  startAt:
      json['start_at'] == null
          ? null
          : DateTime.parse(json['start_at'] as String),
  endAt:
      json['end_at'] == null ? null : DateTime.parse(json['end_at'] as String),
  enrollmentCount: (json['total_students'] as num?)?.toInt(),
  isFavorite: json['is_favorite'] as bool?,
  workflowState: json['workflow_state'] as String?,
  defaultView: json['default_view'] as String?,
  syllabusBody: json['syllabus_body'] as String?,
  term: json['term'] as Map<String, dynamic>?,
  enrollments:
      (json['enrollments'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'course_code': instance.courseCode,
  'description': instance.description,
  'start_at': instance.startAt?.toIso8601String(),
  'end_at': instance.endAt?.toIso8601String(),
  'total_students': instance.enrollmentCount,
  'is_favorite': instance.isFavorite,
  'workflow_state': instance.workflowState,
  'default_view': instance.defaultView,
  'syllabus_body': instance.syllabusBody,
  'term': instance.term,
  'enrollments': instance.enrollments,
  'updated_at': instance.updatedAt?.toIso8601String(),
};
