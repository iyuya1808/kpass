// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Assignment _$AssignmentFromJson(Map<String, dynamic> json) => Assignment(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  workflowState: json['workflow_state'] as String,
  courseId: (json['course_id'] as num).toInt(),
  courseName: json['course_name'] as String?,
  description: json['description'] as String?,
  dueAt:
      json['due_at'] == null ? null : DateTime.parse(json['due_at'] as String),
  unlockAt:
      json['unlock_at'] == null
          ? null
          : DateTime.parse(json['unlock_at'] as String),
  lockAt:
      json['lock_at'] == null
          ? null
          : DateTime.parse(json['lock_at'] as String),
  pointsPossible: (json['points_possible'] as num?)?.toDouble(),
  submissionTypes:
      (json['submission_types'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
  hasSubmittedSubmissions: json['has_submitted_submissions'] as bool?,
  htmlUrl: json['html_url'] as String?,
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
  position: (json['position'] as num?)?.toInt(),
  assignmentGroupId: (json['assignment_group_id'] as num?)?.toInt(),
  published: json['published'] as bool?,
  lockedForUser: json['locked_for_user'] as bool?,
  lockInfo: json['lock_info'] as Map<String, dynamic>?,
  lockExplanation: json['lock_explanation'] as String?,
  quizId: (json['quiz_id'] as num?)?.toInt(),
  discussionTopic: json['discussion_topic'] as Map<String, dynamic>?,
  submission: json['submission'] as Map<String, dynamic>?,
  gradingType: json['grading_type'] as String?,
  gradingStandardId: (json['grading_standard_id'] as num?)?.toInt(),
  omitFromFinalGrade: json['omit_from_final_grade'] as bool?,
  moderatedGrading: json['moderated_grading'] as bool?,
  anonymousGrading: json['anonymous_grading'] as bool?,
  allowedAttempts: (json['allowed_attempts'] as num?)?.toInt(),
  postToSis: json['post_to_sis'] as bool?,
  integrationId: json['integration_id'] as String?,
  integrationData: json['integration_data'] as Map<String, dynamic>?,
  allowedExtensions:
      (json['allowed_extensions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
);

Map<String, dynamic> _$AssignmentToJson(Assignment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'due_at': instance.dueAt?.toIso8601String(),
      'unlock_at': instance.unlockAt?.toIso8601String(),
      'lock_at': instance.lockAt?.toIso8601String(),
      'points_possible': instance.pointsPossible,
      'submission_types': instance.submissionTypes,
      'has_submitted_submissions': instance.hasSubmittedSubmissions,
      'workflow_state': instance.workflowState,
      'course_id': instance.courseId,
      if (instance.courseName case final value?) 'course_name': value,
      'html_url': instance.htmlUrl,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'position': instance.position,
      'assignment_group_id': instance.assignmentGroupId,
      'published': instance.published,
      'locked_for_user': instance.lockedForUser,
      'lock_info': instance.lockInfo,
      'lock_explanation': instance.lockExplanation,
      'quiz_id': instance.quizId,
      'discussion_topic': instance.discussionTopic,
      'submission': instance.submission,
      'grading_type': instance.gradingType,
      'grading_standard_id': instance.gradingStandardId,
      'omit_from_final_grade': instance.omitFromFinalGrade,
      'moderated_grading': instance.moderatedGrading,
      'anonymous_grading': instance.anonymousGrading,
      'allowed_attempts': instance.allowedAttempts,
      'post_to_sis': instance.postToSis,
      'integration_id': instance.integrationId,
      'integration_data': instance.integrationData,
      'allowed_extensions': instance.allowedExtensions,
    };
