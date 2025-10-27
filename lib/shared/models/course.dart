import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'course.g.dart';

@JsonSerializable()
class Course extends Equatable {
  final int id;
  final String name;
  @JsonKey(name: 'course_code')
  final String courseCode;
  final String? description;
  @JsonKey(name: 'start_at')
  final DateTime? startAt;
  @JsonKey(name: 'end_at')
  final DateTime? endAt;
  @JsonKey(name: 'total_students')
  final int? enrollmentCount;
  @JsonKey(name: 'is_favorite')
  final bool? isFavorite;
  @JsonKey(name: 'workflow_state')
  final String? workflowState;
  @JsonKey(name: 'default_view')
  final String? defaultView;
  @JsonKey(name: 'syllabus_body')
  final String? syllabusBody;
  @JsonKey(name: 'term')
  final Map<String, dynamic>? term;
  @JsonKey(name: 'enrollments')
  final List<Map<String, dynamic>>? enrollments;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const Course({
    required this.id,
    required this.name,
    required this.courseCode,
    this.description,
    this.startAt,
    this.endAt,
    this.enrollmentCount,
    this.isFavorite,
    this.workflowState,
    this.defaultView,
    this.syllabusBody,
    this.term,
    this.enrollments,
    this.updatedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);

  Map<String, dynamic> toJson() => _$CourseToJson(this);

  /// Validation method to check if the course data is valid
  bool isValid() {
    return id > 0 && name.isNotEmpty && courseCode.isNotEmpty;
  }

  /// Check if the course is currently active
  bool get isActive {
    final now = DateTime.now();
    if (startAt != null && startAt!.isAfter(now)) return false;
    if (endAt != null && endAt!.isBefore(now)) return false;
    return workflowState != 'deleted' && workflowState != 'completed';
  }

  /// Get a display-friendly course name
  String get displayName {
    if (courseCode.isNotEmpty && name != courseCode) {
      return '$courseCode - $name';
    }
    return name;
  }

  /// Create a copy of the course with updated fields
  Course copyWith({
    int? id,
    String? name,
    String? courseCode,
    String? description,
    DateTime? startAt,
    DateTime? endAt,
    int? enrollmentCount,
    bool? isFavorite,
    String? workflowState,
    String? defaultView,
    String? syllabusBody,
    Map<String, dynamic>? term,
    List<Map<String, dynamic>>? enrollments,
    DateTime? updatedAt,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      courseCode: courseCode ?? this.courseCode,
      description: description ?? this.description,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      enrollmentCount: enrollmentCount ?? this.enrollmentCount,
      isFavorite: isFavorite ?? this.isFavorite,
      workflowState: workflowState ?? this.workflowState,
      defaultView: defaultView ?? this.defaultView,
      syllabusBody: syllabusBody ?? this.syllabusBody,
      term: term ?? this.term,
      enrollments: enrollments ?? this.enrollments,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        courseCode,
        description,
        startAt,
        endAt,
        enrollmentCount,
        isFavorite,
        workflowState,
        defaultView,
        syllabusBody,
        term,
        enrollments,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Course(id: $id, name: $name, courseCode: $courseCode, '
        'workflowState: $workflowState, isActive: $isActive)';
  }
}