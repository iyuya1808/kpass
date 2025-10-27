import 'assignment.dart';
import 'calendar_event.dart';
import 'course.dart';

/// Utility class for model conversions and validations
class ModelUtils {
  ModelUtils._();

  /// Convert a list of assignments to calendar events
  static List<CalendarEvent> assignmentsToCalendarEvents(
    List<Assignment> assignments, {
    Map<int, Course>? coursesMap,
  }) {
    return assignments
        .where((assignment) => assignment.dueAt != null)
        .map((assignment) {
      final course = coursesMap?[assignment.courseId];
      return CalendarEvent.fromAssignment(
        assignmentId: assignment.id,
        assignmentName: assignment.name,
        dueDate: assignment.dueAt!,
        description: assignment.description,
        courseCode: course?.courseCode,
        courseName: course?.name,
      );
    }).toList();
  }

  /// Validate a list of courses and return only valid ones
  static List<Course> validateCourses(List<Course> courses) {
    return courses.where((course) => course.isValid()).toList();
  }

  /// Validate a list of assignments and return only valid ones
  static List<Assignment> validateAssignments(List<Assignment> assignments) {
    return assignments.where((assignment) => assignment.isValid()).toList();
  }

  /// Validate a list of calendar events and return only valid ones
  static List<CalendarEvent> validateCalendarEvents(List<CalendarEvent> events) {
    return events.where((event) => event.isValid()).toList();
  }

  /// Filter assignments by course ID
  static List<Assignment> filterAssignmentsByCourse(
    List<Assignment> assignments,
    int courseId,
  ) {
    return assignments
        .where((assignment) => assignment.courseId == courseId)
        .toList();
  }

  /// Filter assignments that are due soon (within specified duration)
  static List<Assignment> filterAssignmentsDueSoon(
    List<Assignment> assignments, {
    Duration threshold = const Duration(days: 7),
  }) {
    final now = DateTime.now();
    final cutoffTime = now.add(threshold);

    return assignments.where((assignment) {
      if (assignment.dueAt == null) return false;
      return assignment.dueAt!.isAfter(now) && 
             assignment.dueAt!.isBefore(cutoffTime);
    }).toList();
  }

  /// Filter assignments that are overdue
  static List<Assignment> filterOverdueAssignments(List<Assignment> assignments) {
    return assignments.where((assignment) => assignment.isOverdue).toList();
  }

  /// Filter assignments that are available for submission
  static List<Assignment> filterAvailableAssignments(List<Assignment> assignments) {
    return assignments.where((assignment) => assignment.isAvailable).toList();
  }

  /// Filter courses that are currently active
  static List<Course> filterActiveCourses(List<Course> courses) {
    return courses.where((course) => course.isActive).toList();
  }

  /// Filter calendar events for today
  static List<CalendarEvent> filterTodayEvents(List<CalendarEvent> events) {
    return events.where((event) => event.isToday).toList();
  }

  /// Filter calendar events that are upcoming (within specified duration)
  static List<CalendarEvent> filterUpcomingEvents(
    List<CalendarEvent> events, {
    Duration threshold = const Duration(days: 7),
  }) {
    final now = DateTime.now();
    final cutoffTime = now.add(threshold);

    return events.where((event) {
      return event.startTime.isAfter(now) && 
             event.startTime.isBefore(cutoffTime);
    }).toList();
  }

  /// Sort assignments by due date (earliest first)
  static List<Assignment> sortAssignmentsByDueDate(List<Assignment> assignments) {
    final assignmentsCopy = List<Assignment>.from(assignments);
    assignmentsCopy.sort((a, b) {
      if (a.dueAt == null && b.dueAt == null) return 0;
      if (a.dueAt == null) return 1;
      if (b.dueAt == null) return -1;
      return a.dueAt!.compareTo(b.dueAt!);
    });
    return assignmentsCopy;
  }

  /// Sort courses by name alphabetically
  static List<Course> sortCoursesByName(List<Course> courses) {
    final coursesCopy = List<Course>.from(courses);
    coursesCopy.sort((a, b) => a.name.compareTo(b.name));
    return coursesCopy;
  }

  /// Sort calendar events by start time (earliest first)
  static List<CalendarEvent> sortEventsByStartTime(List<CalendarEvent> events) {
    final eventsCopy = List<CalendarEvent>.from(events);
    eventsCopy.sort((a, b) => a.startTime.compareTo(b.startTime));
    return eventsCopy;
  }

  /// Group assignments by course ID
  static Map<int, List<Assignment>> groupAssignmentsByCourse(
    List<Assignment> assignments,
  ) {
    final Map<int, List<Assignment>> grouped = {};
    for (final assignment in assignments) {
      grouped.putIfAbsent(assignment.courseId, () => []).add(assignment);
    }
    return grouped;
  }

  /// Group calendar events by date
  static Map<DateTime, List<CalendarEvent>> groupEventsByDate(
    List<CalendarEvent> events,
  ) {
    final Map<DateTime, List<CalendarEvent>> grouped = {};
    for (final event in events) {
      final date = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      grouped.putIfAbsent(date, () => []).add(event);
    }
    return grouped;
  }

  /// Create a map of course ID to course for quick lookups
  static Map<int, Course> createCourseMap(List<Course> courses) {
    return {for (final course in courses) course.id: course};
  }

  /// Create a map of assignment ID to assignment for quick lookups
  static Map<int, Assignment> createAssignmentMap(List<Assignment> assignments) {
    return {for (final assignment in assignments) assignment.id: assignment};
  }

  /// Create a map of calendar event ID to event for quick lookups
  static Map<String, CalendarEvent> createCalendarEventMap(
    List<CalendarEvent> events,
  ) {
    return {for (final event in events) event.id: event};
  }

  /// Find assignments that need calendar sync (have due dates but no calendar events)
  static List<Assignment> findAssignmentsNeedingCalendarSync(
    List<Assignment> assignments,
    List<CalendarEvent> calendarEvents,
  ) {
    final eventAssignmentIds = calendarEvents
        .where((event) => event.canvasAssignmentId != null)
        .map((event) => int.tryParse(event.canvasAssignmentId!))
        .where((id) => id != null)
        .cast<int>()
        .toSet();

    return assignments
        .where((assignment) => 
            assignment.dueAt != null && 
            !eventAssignmentIds.contains(assignment.id))
        .toList();
  }

  /// Find calendar events that are orphaned (assignment no longer exists)
  static List<CalendarEvent> findOrphanedCalendarEvents(
    List<CalendarEvent> calendarEvents,
    List<Assignment> assignments,
  ) {
    final assignmentIds = assignments.map((a) => a.id).toSet();

    return calendarEvents
        .where((event) => 
            event.canvasAssignmentId != null &&
            !assignmentIds.contains(int.tryParse(event.canvasAssignmentId!)))
        .toList();
  }

  /// Calculate statistics for a list of assignments
  static AssignmentStatistics calculateAssignmentStatistics(
    List<Assignment> assignments,
  ) {
    final total = assignments.length;
    final submitted = assignments.where((a) => a.isSubmitted).length;
    final overdue = assignments.where((a) => a.isOverdue).length;
    final dueSoon = assignments.where((a) => a.isDueSoon).length;
    final available = assignments.where((a) => a.isAvailable).length;

    return AssignmentStatistics(
      total: total,
      submitted: submitted,
      overdue: overdue,
      dueSoon: dueSoon,
      available: available,
    );
  }
}

/// Statistics for a collection of assignments
class AssignmentStatistics {
  final int total;
  final int submitted;
  final int overdue;
  final int dueSoon;
  final int available;

  const AssignmentStatistics({
    required this.total,
    required this.submitted,
    required this.overdue,
    required this.dueSoon,
    required this.available,
  });

  /// Get the percentage of submitted assignments
  double get submittedPercentage {
    if (total == 0) return 0.0;
    return (submitted / total) * 100;
  }

  /// Get the percentage of overdue assignments
  double get overduePercentage {
    if (total == 0) return 0.0;
    return (overdue / total) * 100;
  }

  /// Get the number of pending assignments (not submitted and not overdue)
  int get pending {
    return total - submitted - overdue;
  }

  @override
  String toString() {
    return 'AssignmentStatistics(total: $total, submitted: $submitted, '
        'overdue: $overdue, dueSoon: $dueSoon, available: $available)';
  }
}