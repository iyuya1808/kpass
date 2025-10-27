import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'assignment.g.dart';

@JsonSerializable()
class Assignment extends Equatable {
  final int id;
  final String name;
  final String? description;
  @JsonKey(name: 'due_at')
  final DateTime? dueAt;
  @JsonKey(name: 'unlock_at')
  final DateTime? unlockAt;
  @JsonKey(name: 'lock_at')
  final DateTime? lockAt;
  @JsonKey(name: 'points_possible')
  final double? pointsPossible;
  @JsonKey(name: 'submission_types')
  final List<String>? submissionTypes;
  @JsonKey(name: 'has_submitted_submissions')
  final bool? hasSubmittedSubmissions;
  @JsonKey(name: 'workflow_state')
  final String workflowState;
  @JsonKey(name: 'course_id')
  final int courseId;
  @JsonKey(name: 'course_name', includeIfNull: false)
  final String? courseName;
  @JsonKey(name: 'html_url')
  final String? htmlUrl;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'position')
  final int? position;
  @JsonKey(name: 'assignment_group_id')
  final int? assignmentGroupId;
  @JsonKey(name: 'published')
  final bool? published;
  @JsonKey(name: 'locked_for_user')
  final bool? lockedForUser;
  @JsonKey(name: 'lock_info')
  final Map<String, dynamic>? lockInfo;
  @JsonKey(name: 'lock_explanation')
  final String? lockExplanation;
  @JsonKey(name: 'quiz_id')
  final int? quizId;
  @JsonKey(name: 'discussion_topic')
  final Map<String, dynamic>? discussionTopic;
  @JsonKey(name: 'submission')
  final Map<String, dynamic>? submission;
  @JsonKey(name: 'grading_type')
  final String? gradingType;
  @JsonKey(name: 'grading_standard_id')
  final int? gradingStandardId;
  @JsonKey(name: 'omit_from_final_grade')
  final bool? omitFromFinalGrade;
  @JsonKey(name: 'moderated_grading')
  final bool? moderatedGrading;
  @JsonKey(name: 'anonymous_grading')
  final bool? anonymousGrading;
  @JsonKey(name: 'allowed_attempts')
  final int? allowedAttempts;
  @JsonKey(name: 'post_to_sis')
  final bool? postToSis;
  @JsonKey(name: 'integration_id')
  final String? integrationId;
  @JsonKey(name: 'integration_data')
  final Map<String, dynamic>? integrationData;
  @JsonKey(name: 'allowed_extensions')
  final List<String>? allowedExtensions;

  const Assignment({
    required this.id,
    required this.name,
    required this.workflowState,
    required this.courseId,
    this.courseName,
    this.description,
    this.dueAt,
    this.unlockAt,
    this.lockAt,
    this.pointsPossible,
    this.submissionTypes,
    this.hasSubmittedSubmissions,
    this.htmlUrl,
    this.createdAt,
    this.updatedAt,
    this.position,
    this.assignmentGroupId,
    this.published,
    this.lockedForUser,
    this.lockInfo,
    this.lockExplanation,
    this.quizId,
    this.discussionTopic,
    this.submission,
    this.gradingType,
    this.gradingStandardId,
    this.omitFromFinalGrade,
    this.moderatedGrading,
    this.anonymousGrading,
    this.allowedAttempts,
    this.postToSis,
    this.integrationId,
    this.integrationData,
    this.allowedExtensions,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) =>
      _$AssignmentFromJson(json);

  Map<String, dynamic> toJson() => _$AssignmentToJson(this);

  /// Validation method to check if the assignment data is valid
  bool isValid() {
    return id > 0 && name.isNotEmpty && courseId > 0;
  }

  /// Check if the assignment is currently available for submission
  bool get isAvailable {
    final now = DateTime.now();
    if (unlockAt != null && unlockAt!.isAfter(now)) return false;
    if (lockAt != null && lockAt!.isBefore(now)) return false;
    return workflowState == 'published' && (published ?? false);
  }

  /// Check if the assignment is overdue (past due date)
  bool get isOverdue {
    if (dueAt == null) return false;
    return DateTime.now().isAfter(dueAt!);
  }

  /// Check if the assignment is upcoming (not yet due)
  bool get isUpcoming {
    if (dueAt == null) return false;
    return DateTime.now().isBefore(dueAt!);
  }

  /// Check if the assignment is due soon (within 24 hours and not overdue)
  bool get isDueSoon {
    if (dueAt == null) return false;
    final now = DateTime.now();
    final timeDiff = dueAt!.difference(now);
    return timeDiff.inHours <= 24 && timeDiff.inHours > 0;
  }

  /// Get the submission types as a formatted string
  String get submissionTypesDisplay {
    if (submissionTypes == null || submissionTypes!.isEmpty) {
      return 'No submission required';
    }
    return submissionTypes!.join(', ');
  }

  /// Check if the assignment has been submitted
  bool get isSubmitted {
    // submissionオブジェクトから提出状況を判定（最優先）
    if (submission != null) {
      final workflowState = submission!['workflow_state'] as String?;
      // workflow_stateが'submitted'または'graded'の場合は提出済みと判定
      return workflowState == 'submitted' || workflowState == 'graded';
    }

    // submissionオブジェクトが存在しない場合、hasSubmittedSubmissionsを参考にする
    // ただし、これだけでは不正確な場合があるため、より慎重に判定
    if (hasSubmittedSubmissions != null) {
      // hasSubmittedSubmissionsがtrueでも、submissionオブジェクトがない場合は
      // 実際の提出状況が不明なため、falseを返す
      return false;
    }

    return false;
  }

  /// Get detailed submission status information
  Map<String, dynamic> get submissionStatus {
    final status = <String, dynamic>{
      'isSubmitted': isSubmitted,
      'hasSubmissionObject': submission != null,
      'hasSubmittedSubmissions': hasSubmittedSubmissions,
      'workflowState': submission?['workflow_state'],
      'submissionId': submission?['id'],
      'submittedAt': submission?['submitted_at'],
    };

    // 提出状況の詳細説明を追加
    if (submission != null) {
      final workflowState = submission!['workflow_state'] as String?;
      switch (workflowState) {
        case 'submitted':
          status['statusDescription'] = '提出済み';
          break;
        case 'unsubmitted':
          status['statusDescription'] = '未提出';
          break;
        case 'draft':
          status['statusDescription'] = '下書き保存';
          break;
        case 'graded':
          status['statusDescription'] = '採点済み';
          break;
        default:
          status['statusDescription'] = '不明 ($workflowState)';
      }
    } else if (hasSubmittedSubmissions == true) {
      status['statusDescription'] = '提出物あり（詳細不明）';
    } else {
      status['statusDescription'] = '未提出';
    }

    return status;
  }

  /// Get a unique identifier for calendar integration
  String get calendarEventId {
    return 'canvas_assignment_$id';
  }

  /// Create a copy of the assignment with updated fields
  Assignment copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? dueAt,
    DateTime? unlockAt,
    DateTime? lockAt,
    double? pointsPossible,
    List<String>? submissionTypes,
    bool? hasSubmittedSubmissions,
    String? workflowState,
    int? courseId,
    String? courseName,
    String? htmlUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? position,
    int? assignmentGroupId,
    bool? published,
    bool? lockedForUser,
    Map<String, dynamic>? lockInfo,
    String? lockExplanation,
    int? quizId,
    Map<String, dynamic>? discussionTopic,
    Map<String, dynamic>? submission,
    String? gradingType,
    int? gradingStandardId,
    bool? omitFromFinalGrade,
    bool? moderatedGrading,
    bool? anonymousGrading,
    int? allowedAttempts,
    bool? postToSis,
    String? integrationId,
    Map<String, dynamic>? integrationData,
    List<String>? allowedExtensions,
  }) {
    return Assignment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      dueAt: dueAt ?? this.dueAt,
      unlockAt: unlockAt ?? this.unlockAt,
      lockAt: lockAt ?? this.lockAt,
      pointsPossible: pointsPossible ?? this.pointsPossible,
      submissionTypes: submissionTypes ?? this.submissionTypes,
      hasSubmittedSubmissions:
          hasSubmittedSubmissions ?? this.hasSubmittedSubmissions,
      workflowState: workflowState ?? this.workflowState,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      htmlUrl: htmlUrl ?? this.htmlUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      position: position ?? this.position,
      assignmentGroupId: assignmentGroupId ?? this.assignmentGroupId,
      published: published ?? this.published,
      lockedForUser: lockedForUser ?? this.lockedForUser,
      lockInfo: lockInfo ?? this.lockInfo,
      lockExplanation: lockExplanation ?? this.lockExplanation,
      quizId: quizId ?? this.quizId,
      discussionTopic: discussionTopic ?? this.discussionTopic,
      submission: submission ?? this.submission,
      gradingType: gradingType ?? this.gradingType,
      gradingStandardId: gradingStandardId ?? this.gradingStandardId,
      omitFromFinalGrade: omitFromFinalGrade ?? this.omitFromFinalGrade,
      moderatedGrading: moderatedGrading ?? this.moderatedGrading,
      anonymousGrading: anonymousGrading ?? this.anonymousGrading,
      allowedAttempts: allowedAttempts ?? this.allowedAttempts,
      postToSis: postToSis ?? this.postToSis,
      integrationId: integrationId ?? this.integrationId,
      integrationData: integrationData ?? this.integrationData,
      allowedExtensions: allowedExtensions ?? this.allowedExtensions,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    dueAt,
    unlockAt,
    lockAt,
    pointsPossible,
    submissionTypes,
    hasSubmittedSubmissions,
    workflowState,
    courseId,
    courseName,
    htmlUrl,
    createdAt,
    updatedAt,
    position,
    assignmentGroupId,
    published,
    lockedForUser,
    lockInfo,
    lockExplanation,
    quizId,
    discussionTopic,
    submission,
    gradingType,
    gradingStandardId,
    omitFromFinalGrade,
    moderatedGrading,
    anonymousGrading,
    allowedAttempts,
    postToSis,
    integrationId,
    integrationData,
    allowedExtensions,
  ];

  @override
  String toString() {
    return 'Assignment(id: $id, name: $name, courseId: $courseId, '
        'dueAt: $dueAt, workflowState: $workflowState, isAvailable: $isAvailable)';
  }
}
