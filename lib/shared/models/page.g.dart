// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Page _$PageFromJson(Map<String, dynamic> json) => Page(
  id: (json['page_id'] as num).toInt(),
  url: json['url'] as String,
  title: json['title'] as String,
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
  hideFromStudents: json['hide_from_students'] as bool?,
  editingRoles: json['editing_roles'] as String?,
  lastEditedBy: json['last_edited_by'] as Map<String, dynamic>?,
  body: json['body'] as String?,
  published: json['published'] as bool?,
  frontPage: json['front_page'] as bool?,
  lockedForUser: json['locked_for_user'] as bool?,
  lockInfo: json['lock_info'] as Map<String, dynamic>?,
  lockExplanation: json['lock_explanation'] as String?,
);

Map<String, dynamic> _$PageToJson(Page instance) => <String, dynamic>{
  'page_id': instance.id,
  'url': instance.url,
  'title': instance.title,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'hide_from_students': instance.hideFromStudents,
  'editing_roles': instance.editingRoles,
  'last_edited_by': instance.lastEditedBy,
  'body': instance.body,
  'published': instance.published,
  'front_page': instance.frontPage,
  'locked_for_user': instance.lockedForUser,
  'lock_info': instance.lockInfo,
  'lock_explanation': instance.lockExplanation,
};
