import 'package:kpass/shared/models/course.dart';
import 'package:kpass/shared/models/assignment.dart';

/// Courseモデルの拡張
extension CourseExtensions on Course {
  /// コースに関連する課題の総数を計算
  int getAssignmentsCount(List<Assignment> allAssignments) {
    return allAssignments.where((a) => a.courseId == id).length;
  }

  /// 期限が近い課題の数を計算（7日以内）
  int getUpcomingAssignmentsCount(List<Assignment> allAssignments) {
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));

    return allAssignments.where((a) {
      if (a.courseId != id) return false;
      if (a.dueAt == null) return false;
      if (a.isSubmitted) return false; // 提出済みは除外

      return a.dueAt!.isAfter(now) && a.dueAt!.isBefore(sevenDaysLater);
    }).length;
  }

  /// 未提出の課題数を取得
  int getUnsubmittedAssignmentsCount(List<Assignment> allAssignments) {
    return allAssignments.where((a) {
      return a.courseId == id &&
          !a.isSubmitted && // 正確な提出状況で判定
          a.dueAt != null &&
          a.dueAt!.isAfter(DateTime.now());
    }).length;
  }

  /// 期限超過の課題数を取得
  int getOverdueAssignmentsCount(List<Assignment> allAssignments) {
    return allAssignments.where((a) {
      return a.courseId == id &&
          !a.isSubmitted && // 正確な提出状況で判定
          a.isOverdue;
    }).length;
  }
}

/// CourseにassignmentsCountとupcomingAssignmentsCountを持たせる拡張版
class CourseWithStats {
  final Course course;
  final int assignmentsCount;
  final int upcomingAssignmentsCount;
  final int unsubmittedCount;
  final int overdueCount;

  const CourseWithStats({
    required this.course,
    required this.assignmentsCount,
    required this.upcomingAssignmentsCount,
    required this.unsubmittedCount,
    required this.overdueCount,
  });

  factory CourseWithStats.fromCourse(
    Course course,
    List<Assignment> allAssignments,
  ) {
    return CourseWithStats(
      course: course,
      assignmentsCount: course.getAssignmentsCount(allAssignments),
      upcomingAssignmentsCount: course.getUpcomingAssignmentsCount(
        allAssignments,
      ),
      unsubmittedCount: course.getUnsubmittedAssignmentsCount(allAssignments),
      overdueCount: course.getOverdueAssignmentsCount(allAssignments),
    );
  }

  int get id => course.id;
  String get name => course.name;
  String get courseCode => course.courseCode;
  String? get description => course.description;
  bool get isActive => course.isActive;
  String get displayName => course.displayName;
}
