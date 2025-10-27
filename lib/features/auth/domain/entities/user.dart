import 'package:equatable/equatable.dart';

/// User entity representing a Canvas user
class User extends Equatable {
  final int id;
  final String name;
  final String? sortableName;
  final String? shortName;
  final String? sisUserId;
  final String? sisImportId;
  final String? loginId;
  final String? avatarUrl;
  final List<Enrollment> enrollments;
  final String? email;
  final String? locale;
  final String? effectiveLocale;
  final DateTime? lastLogin;
  final String? timeZone;
  final String? bio;

  const User({
    required this.id,
    required this.name,
    this.sortableName,
    this.shortName,
    this.sisUserId,
    this.sisImportId,
    this.loginId,
    this.avatarUrl,
    this.enrollments = const [],
    this.email,
    this.locale,
    this.effectiveLocale,
    this.lastLogin,
    this.timeZone,
    this.bio,
  });

  /// Get display name (Japanese name only)
  String get displayName {
    if (shortName?.isNotEmpty == true) {
      // Extract Japanese name from short_name (remove English name)
      final shortNameText = shortName!;
      // If short_name contains both Japanese and English names, extract Japanese part
      if (shortNameText.contains('　') && shortNameText.contains(' ')) {
        // Split by space to separate Japanese and English parts
        final spaceIndex = shortNameText.indexOf(' ');
        if (spaceIndex > 0) {
          // Take the part before the first space (Japanese name)
          return shortNameText.substring(0, spaceIndex).trim();
        }
      }
      return shortNameText;
    }
    return name;
  }

  /// Check if user has avatar
  bool get hasAvatar => avatarUrl?.isNotEmpty == true;

  /// Get user's primary email
  String? get primaryEmail => email;

  /// Check if user is active (has recent login)
  bool get isActive {
    if (lastLogin == null) return false;
    final now = DateTime.now();
    final daysSinceLogin = now.difference(lastLogin!).inDays;
    return daysSinceLogin <= 30; // Consider active if logged in within 30 days
  }

  @override
  List<Object?> get props => [
    id,
    name,
    sortableName,
    shortName,
    sisUserId,
    sisImportId,
    loginId,
    avatarUrl,
    enrollments,
    email,
    locale,
    effectiveLocale,
    lastLogin,
    timeZone,
    bio,
  ];

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}

/// User enrollment information
class Enrollment extends Equatable {
  final String type;
  final String role;
  final int? roleId;
  final int userId;
  final String enrollmentState;
  final bool? limitPrivilegesToCourseSection;

  const Enrollment({
    required this.type,
    required this.role,
    this.roleId,
    required this.userId,
    required this.enrollmentState,
    this.limitPrivilegesToCourseSection,
  });

  /// Check if enrollment is active
  bool get isActive => enrollmentState == 'active';

  /// Check if user is a student
  bool get isStudent =>
      role.toLowerCase() == 'student' ||
      type.toLowerCase() == 'studentenrollment';

  /// Check if user is a teacher
  bool get isTeacher =>
      role.toLowerCase() == 'teacher' ||
      type.toLowerCase() == 'teacherenrollment';

  /// Check if user is a TA
  bool get isTA =>
      role.toLowerCase() == 'ta' || type.toLowerCase() == 'taenrollment';

  @override
  List<Object?> get props => [
    type,
    role,
    roleId,
    userId,
    enrollmentState,
    limitPrivilegesToCourseSection,
  ];

  @override
  String toString() =>
      'Enrollment(type: $type, role: $role, state: $enrollmentState)';
}
