import 'package:json_annotation/json_annotation.dart';
import 'package:kpass/features/auth/domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends User {
  @JsonKey(name: 'enrollments')
  final List<EnrollmentModel> enrollmentModels;

  const UserModel({
    required super.id,
    required super.name,
    super.sortableName,
    super.shortName,
    super.sisUserId,
    super.sisImportId,
    super.loginId,
    super.avatarUrl,
    this.enrollmentModels = const [],
    super.email,
    super.locale,
    super.effectiveLocale,
    super.lastLogin,
    super.timeZone,
    super.bio,
  }) : super(enrollments: enrollmentModels);

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Convert from domain entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      sortableName: user.sortableName,
      shortName: user.shortName,
      sisUserId: user.sisUserId,
      sisImportId: user.sisImportId,
      loginId: user.loginId,
      avatarUrl: user.avatarUrl,
      enrollmentModels: user.enrollments.map((e) => EnrollmentModel.fromEntity(e)).toList(),
      email: user.email,
      locale: user.locale,
      effectiveLocale: user.effectiveLocale,
      lastLogin: user.lastLogin,
      timeZone: user.timeZone,
      bio: user.bio,
    );
  }

  /// Convert to domain entity
  User toEntity() {
    return User(
      id: id,
      name: name,
      sortableName: sortableName,
      shortName: shortName,
      sisUserId: sisUserId,
      sisImportId: sisImportId,
      loginId: loginId,
      avatarUrl: avatarUrl,
      enrollments: enrollmentModels.map((e) => e.toEntity()).toList(),
      email: email,
      locale: locale,
      effectiveLocale: effectiveLocale,
      lastLogin: lastLogin,
      timeZone: timeZone,
      bio: bio,
    );
  }

  /// Create from Canvas API response
  factory UserModel.fromCanvasJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      sortableName: json['sortable_name'] as String?,
      shortName: json['short_name'] as String?,
      sisUserId: json['sis_user_id'] as String?,
      sisImportId: json['sis_import_id'] as String?,
      loginId: json['login_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      enrollmentModels: (json['enrollments'] as List<dynamic>?)
              ?.map((e) => EnrollmentModel.fromCanvasJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      email: json['email'] as String?,
      locale: json['locale'] as String?,
      effectiveLocale: json['effective_locale'] as String?,
      lastLogin: json['last_login'] != null 
          ? DateTime.tryParse(json['last_login'] as String)
          : null,
      timeZone: json['time_zone'] as String?,
      bio: json['bio'] as String?,
    );
  }

  /// Convert to Canvas API format
  Map<String, dynamic> toCanvasJson() {
    return {
      'id': id,
      'name': name,
      if (sortableName != null) 'sortable_name': sortableName,
      if (shortName != null) 'short_name': shortName,
      if (sisUserId != null) 'sis_user_id': sisUserId,
      if (sisImportId != null) 'sis_import_id': sisImportId,
      if (loginId != null) 'login_id': loginId,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'enrollments': enrollmentModels.map((e) => e.toCanvasJson()).toList(),
      if (email != null) 'email': email,
      if (locale != null) 'locale': locale,
      if (effectiveLocale != null) 'effective_locale': effectiveLocale,
      if (lastLogin != null) 'last_login': lastLogin!.toIso8601String(),
      if (timeZone != null) 'time_zone': timeZone,
      if (bio != null) 'bio': bio,
    };
  }
}

@JsonSerializable()
class EnrollmentModel extends Enrollment {
  const EnrollmentModel({
    required super.type,
    required super.role,
    super.roleId,
    required super.userId,
    required super.enrollmentState,
    super.limitPrivilegesToCourseSection,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) => _$EnrollmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentModelToJson(this);

  /// Convert from domain entity
  factory EnrollmentModel.fromEntity(Enrollment enrollment) {
    return EnrollmentModel(
      type: enrollment.type,
      role: enrollment.role,
      roleId: enrollment.roleId,
      userId: enrollment.userId,
      enrollmentState: enrollment.enrollmentState,
      limitPrivilegesToCourseSection: enrollment.limitPrivilegesToCourseSection,
    );
  }

  /// Convert to domain entity
  Enrollment toEntity() {
    return Enrollment(
      type: type,
      role: role,
      roleId: roleId,
      userId: userId,
      enrollmentState: enrollmentState,
      limitPrivilegesToCourseSection: limitPrivilegesToCourseSection,
    );
  }

  /// Create from Canvas API response
  factory EnrollmentModel.fromCanvasJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      type: json['type'] as String,
      role: json['role'] as String,
      roleId: json['role_id'] as int?,
      userId: json['user_id'] as int,
      enrollmentState: json['enrollment_state'] as String,
      limitPrivilegesToCourseSection: json['limit_privileges_to_course_section'] as bool?,
    );
  }

  /// Convert to Canvas API format
  Map<String, dynamic> toCanvasJson() {
    return {
      'type': type,
      'role': role,
      if (roleId != null) 'role_id': roleId,
      'user_id': userId,
      'enrollment_state': enrollmentState,
      if (limitPrivilegesToCourseSection != null) 
        'limit_privileges_to_course_section': limitPrivilegesToCourseSection,
    };
  }
}