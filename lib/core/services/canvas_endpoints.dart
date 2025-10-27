/// Canvas API endpoint constants and utilities
class CanvasEndpoints {
  // User endpoints
  static const String userSelf = '/users/self';
  static const String userProfile = '/users/self/profile';
  
  // Course endpoints
  static const String courses = '/courses';
  static String courseById(int courseId) => '$courses/$courseId';
  static String courseAssignments(int courseId) => '$courses/$courseId/assignments';
  static String courseModules(int courseId) => '$courses/$courseId/modules';
  static String courseAnnouncements(int courseId) => '$courses/$courseId/discussion_topics';
  static String courseGrades(int courseId) => '$courses/$courseId/enrollments';
  
  // Assignment endpoints
  static const String assignments = '/assignments';
  static String assignmentById(int assignmentId) => '$assignments/$assignmentId';
  static String assignmentSubmissions(int courseId, int assignmentId) => 
      '$courses/$courseId/assignments/$assignmentId/submissions';
  
  // Calendar endpoints
  static const String calendarEvents = '/calendar_events';
  static const String userCalendarEvents = '/users/self/calendar_events';
  
  // Planner endpoints
  static const String plannerItems = '/planner/items';
  
  // Submission endpoints
  static String courseSubmissions(int courseId) => '$courses/$courseId/students/submissions';
  
  // File endpoints
  static const String files = '/files';
  static String fileById(int fileId) => '$files/$fileId';
  
  // Conversation endpoints
  static const String conversations = '/conversations';
  
  // Notification endpoints
  static const String accountNotifications = '/accounts/self/account_notifications';
  
  // Common query parameters
  static const Map<String, String> defaultCourseParams = {
    'enrollment_state': 'active',
    'include[]': 'term,course_image,favorites,sections,total_students,teachers',
  };
  
  static const Map<String, String> defaultAssignmentParams = {
    'include[]': 'submission,rubric_assessment,assignment_visibility,overrides,observed_users',
    'order_by': 'due_at',
  };
  
  static const Map<String, String> defaultCalendarParams = {
    'type': 'assignment',
    'include[]': 'description,child_events,assignment,course',
  };
  
  /// Build query parameters for courses endpoint
  static Map<String, dynamic> buildCoursesParams({
    String? enrollmentState,
    List<String>? include,
    String? state,
    int? perPage,
  }) {
    final params = <String, dynamic>{};
    
    if (enrollmentState != null) {
      params['enrollment_state'] = enrollmentState;
    }
    
    if (include != null && include.isNotEmpty) {
      params['include[]'] = include;
    }
    
    if (state != null) {
      params['state'] = state;
    }
    
    if (perPage != null) {
      params['per_page'] = perPage;
    }
    
    return params;
  }
  
  /// Build query parameters for assignments endpoint
  static Map<String, dynamic> buildAssignmentsParams({
    List<String>? include,
    String? orderBy,
    String? searchTerm,
    DateTime? dueBefore,
    DateTime? dueAfter,
    int? perPage,
  }) {
    final params = <String, dynamic>{};
    
    if (include != null && include.isNotEmpty) {
      params['include[]'] = include;
    }
    
    if (orderBy != null) {
      params['order_by'] = orderBy;
    }
    
    if (searchTerm != null) {
      params['search_term'] = searchTerm;
    }
    
    if (dueBefore != null) {
      params['due_before'] = dueBefore.toIso8601String();
    }
    
    if (dueAfter != null) {
      params['due_after'] = dueAfter.toIso8601String();
    }
    
    if (perPage != null) {
      params['per_page'] = perPage;
    }
    
    return params;
  }
  
  /// Build query parameters for calendar events endpoint
  static Map<String, dynamic> buildCalendarParams({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? contextCodes,
    List<String>? include,
    int? perPage,
  }) {
    final params = <String, dynamic>{};
    
    if (type != null) {
      params['type'] = type;
    }
    
    if (startDate != null) {
      params['start_date'] = startDate.toIso8601String();
    }
    
    if (endDate != null) {
      params['end_date'] = endDate.toIso8601String();
    }
    
    if (contextCodes != null && contextCodes.isNotEmpty) {
      params['context_codes[]'] = contextCodes;
    }
    
    if (include != null && include.isNotEmpty) {
      params['include[]'] = include;
    }
    
    if (perPage != null) {
      params['per_page'] = perPage;
    }
    
    return params;
  }
}