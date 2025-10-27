// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  sortableName: json['sortableName'] as String?,
  shortName: json['shortName'] as String?,
  sisUserId: json['sisUserId'] as String?,
  sisImportId: json['sisImportId'] as String?,
  loginId: json['loginId'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  enrollmentModels:
      (json['enrollments'] as List<dynamic>?)
          ?.map((e) => EnrollmentModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  email: json['email'] as String?,
  locale: json['locale'] as String?,
  effectiveLocale: json['effectiveLocale'] as String?,
  lastLogin:
      json['lastLogin'] == null
          ? null
          : DateTime.parse(json['lastLogin'] as String),
  timeZone: json['timeZone'] as String?,
  bio: json['bio'] as String?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'sortableName': instance.sortableName,
  'shortName': instance.shortName,
  'sisUserId': instance.sisUserId,
  'sisImportId': instance.sisImportId,
  'loginId': instance.loginId,
  'avatarUrl': instance.avatarUrl,
  'email': instance.email,
  'locale': instance.locale,
  'effectiveLocale': instance.effectiveLocale,
  'lastLogin': instance.lastLogin?.toIso8601String(),
  'timeZone': instance.timeZone,
  'bio': instance.bio,
  'enrollments': instance.enrollmentModels,
};

EnrollmentModel _$EnrollmentModelFromJson(Map<String, dynamic> json) =>
    EnrollmentModel(
      type: json['type'] as String,
      role: json['role'] as String,
      roleId: (json['roleId'] as num?)?.toInt(),
      userId: (json['userId'] as num).toInt(),
      enrollmentState: json['enrollmentState'] as String,
      limitPrivilegesToCourseSection:
          json['limitPrivilegesToCourseSection'] as bool?,
    );

Map<String, dynamic> _$EnrollmentModelToJson(EnrollmentModel instance) =>
    <String, dynamic>{
      'type': instance.type,
      'role': instance.role,
      'roleId': instance.roleId,
      'userId': instance.userId,
      'enrollmentState': instance.enrollmentState,
      'limitPrivilegesToCourseSection': instance.limitPrivilegesToCourseSection,
    };
