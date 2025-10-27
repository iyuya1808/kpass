import 'package:equatable/equatable.dart';
import 'package:kpass/features/auth/domain/entities/user.dart' show Enrollment;

/// Course entity representing a Canvas course
class Course extends Equatable {
  final int id;
  final String name;
  final String? courseCode;
  final String? sisId;
  final String? uuid;
  final String? integrationId;
  final String? sisImportId;
  final String? sisSourceId;
  final String? accountId;
  final String? rootAccountId;
  final String? enrollmentTermId;
  final String? gradingStandardId;
  final String? createdAt;
  final String? startAt;
  final String? endAt;
  final String? locale;
  final List<Enrollment> enrollments;
  final int? totalStudents;
  final List<Teacher> teachers;
  final String? syllabusBody;
  final int? publicSyllabusToAuth;
  final String? publicSyllabus;
  final int? publicDescription;
  final int? storageQuotaMb;
  final int? storageQuotaUsedMb;
  final bool? hideFinalGrades;
  final String? license;
  final bool? allowStudentAssignmentEdits;
  final bool? allowWikiComments;
  final bool? allowStudentForumAttachments;
  final bool? openEnrollment;
  final bool? selfEnrollment;
  final bool? restrictEnrollmentsToCourseDates;
  final String? courseFormat;
  final bool? accessRestrictedByDate;
  final String? timeZone;
  final bool? blueprint;
  final String? blueprintRestrictions;
  final bool? blueprintRestrictionsLocked;
  final Term? term;
  final String? courseImage;
  final bool? isFavorite;
  final String? workflowState;
  final bool? applyAssignmentGroupWeights;
  final Map<String, dynamic>? calendar;
  final String? defaultView;
  final String? syllabusCourseSummary;
  final int? gradingPeriods;
  final bool? passFailGradingType;

  const Course({
    required this.id,
    required this.name,
    this.courseCode,
    this.sisId,
    this.uuid,
    this.integrationId,
    this.sisImportId,
    this.sisSourceId,
    this.accountId,
    this.rootAccountId,
    this.enrollmentTermId,
    this.gradingStandardId,
    this.createdAt,
    this.startAt,
    this.endAt,
    this.locale,
    this.enrollments = const [],
    this.totalStudents,
    this.teachers = const [],
    this.syllabusBody,
    this.publicSyllabusToAuth,
    this.publicSyllabus,
    this.publicDescription,
    this.storageQuotaMb,
    this.storageQuotaUsedMb,
    this.hideFinalGrades,
    this.license,
    this.allowStudentAssignmentEdits,
    this.allowWikiComments,
    this.allowStudentForumAttachments,
    this.openEnrollment,
    this.selfEnrollment,
    this.restrictEnrollmentsToCourseDates,
    this.courseFormat,
    this.accessRestrictedByDate,
    this.timeZone,
    this.blueprint,
    this.blueprintRestrictions,
    this.blueprintRestrictionsLocked,
    this.term,
    this.courseImage,
    this.isFavorite,
    this.workflowState,
    this.applyAssignmentGroupWeights,
    this.calendar,
    this.defaultView,
    this.syllabusCourseSummary,
    this.gradingPeriods,
    this.passFailGradingType,
  });

  /// Get display name (course code + name if available, otherwise just name)
  String get displayName {
    if (courseCode?.isNotEmpty == true) {
      return '$courseCode: $name';
    }
    return name;
  }

  /// Get short display name (course code if available, otherwise name)
  String get shortName => courseCode?.isNotEmpty == true ? courseCode! : name;

  /// Check if course is active
  bool get isActive => workflowState == 'available' || workflowState == 'active';

  /// Check if course has started
  bool get hasStarted {
    if (startAt == null) return true;
    final startDate = DateTime.tryParse(startAt!);
    return startDate == null || DateTime.now().isAfter(startDate);
  }

  /// Check if course has ended
  bool get hasEnded {
    if (endAt == null) return false;
    final endDate = DateTime.tryParse(endAt!);
    return endDate != null && DateTime.now().isAfter(endDate);
  }

  /// Check if course is currently running
  bool get isCurrentlyRunning => hasStarted && !hasEnded && isActive;

  /// Get course start date
  DateTime? get startDate => startAt != null ? DateTime.tryParse(startAt!) : null;

  /// Get course end date
  DateTime? get endDate => endAt != null ? DateTime.tryParse(endAt!) : null;

  /// Get user's enrollment in this course
  Enrollment? get userEnrollment {
    return enrollments.isNotEmpty ? enrollments.first : null;
  }

  /// Check if user is enrolled as student
  bool get isStudentEnrolled {
    final enrollment = userEnrollment;
    return enrollment != null && enrollment.isStudent && enrollment.isActive;
  }

  /// Check if user is enrolled as teacher
  bool get isTeacherEnrolled {
    final enrollment = userEnrollment;
    return enrollment != null && enrollment.isTeacher && enrollment.isActive;
  }

  /// Get storage usage percentage
  double? get storageUsagePercentage {
    if (storageQuotaMb == null || storageQuotaUsedMb == null) return null;
    if (storageQuotaMb == 0) return 0.0;
    return (storageQuotaUsedMb! / storageQuotaMb!) * 100;
  }

  /// Check if course has syllabus
  bool get hasSyllabus => syllabusBody?.isNotEmpty == true;

  /// Check if course has course image
  bool get hasCourseImage => courseImage?.isNotEmpty == true;

  @override
  List<Object?> get props => [
        id,
        name,
        courseCode,
        sisId,
        uuid,
        integrationId,
        sisImportId,
        sisSourceId,
        accountId,
        rootAccountId,
        enrollmentTermId,
        gradingStandardId,
        createdAt,
        startAt,
        endAt,
        locale,
        enrollments,
        totalStudents,
        teachers,
        syllabusBody,
        publicSyllabusToAuth,
        publicSyllabus,
        publicDescription,
        storageQuotaMb,
        storageQuotaUsedMb,
        hideFinalGrades,
        license,
        allowStudentAssignmentEdits,
        allowWikiComments,
        allowStudentForumAttachments,
        openEnrollment,
        selfEnrollment,
        restrictEnrollmentsToCourseDates,
        courseFormat,
        accessRestrictedByDate,
        timeZone,
        blueprint,
        blueprintRestrictions,
        blueprintRestrictionsLocked,
        term,
        courseImage,
        isFavorite,
        workflowState,
        applyAssignmentGroupWeights,
        calendar,
        defaultView,
        syllabusCourseSummary,
        gradingPeriods,
        passFailGradingType,
      ];

  @override
  String toString() {
    return 'Course(id: $id, name: $name, code: $courseCode, active: $isActive)';
  }
}

/// Course term information
class Term extends Equatable {
  final int id;
  final String name;
  final String? startAt;
  final String? endAt;
  final String? createdAt;
  final String? workflowState;
  final int? gradingPeriodGroupId;
  final String? sisTermId;
  final String? sisImportId;

  const Term({
    required this.id,
    required this.name,
    this.startAt,
    this.endAt,
    this.createdAt,
    this.workflowState,
    this.gradingPeriodGroupId,
    this.sisTermId,
    this.sisImportId,
  });

  /// Check if term is active
  bool get isActive => workflowState == 'active';

  /// Get term start date
  DateTime? get startDate => startAt != null ? DateTime.tryParse(startAt!) : null;

  /// Get term end date
  DateTime? get endDate => endAt != null ? DateTime.tryParse(endAt!) : null;

  /// Check if term is currently active (within date range)
  bool get isCurrentlyActive {
    final now = DateTime.now();
    final start = startDate;
    final end = endDate;
    
    if (start != null && now.isBefore(start)) return false;
    if (end != null && now.isAfter(end)) return false;
    
    return isActive;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        startAt,
        endAt,
        createdAt,
        workflowState,
        gradingPeriodGroupId,
        sisTermId,
        sisImportId,
      ];

  @override
  String toString() {
    return 'Term(id: $id, name: $name, active: $isActive)';
  }
}

/// Teacher information
class Teacher extends Equatable {
  final int id;
  final String displayName;
  final String? avatarImageUrl;
  final String? htmlUrl;
  final String? pronouns;

  const Teacher({
    required this.id,
    required this.displayName,
    this.avatarImageUrl,
    this.htmlUrl,
    this.pronouns,
  });

  /// Check if teacher has avatar
  bool get hasAvatar => avatarImageUrl?.isNotEmpty == true;

  @override
  List<Object?> get props => [
        id,
        displayName,
        avatarImageUrl,
        htmlUrl,
        pronouns,
      ];

  @override
  String toString() {
    return 'Teacher(id: $id, name: $displayName)';
  }
}