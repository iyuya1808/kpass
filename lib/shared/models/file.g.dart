// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasFile _$CanvasFileFromJson(Map<String, dynamic> json) => CanvasFile(
  id: (json['id'] as num).toInt(),
  uuid: json['uuid'] as String,
  folderId: (json['folder_id'] as num?)?.toInt(),
  displayName: json['display_name'] as String,
  filename: json['filename'] as String,
  uploadStatus: json['upload_status'] as String?,
  contentType: json['content-type'] as String?,
  url: json['url'] as String,
  size: (json['size'] as num).toInt(),
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
  unlockAt:
      json['unlock_at'] == null
          ? null
          : DateTime.parse(json['unlock_at'] as String),
  locked: json['locked'] as bool?,
  hidden: json['hidden'] as bool?,
  lockAt:
      json['lock_at'] == null
          ? null
          : DateTime.parse(json['lock_at'] as String),
  hiddenForUser: json['hidden_for_user'] as bool?,
  thumbnailUrl: json['thumbnail_url'] as String?,
  modifiedAt:
      json['modified_at'] == null
          ? null
          : DateTime.parse(json['modified_at'] as String),
  mimeClass: json['mime_class'] as String?,
  mediaEntryId: json['media_entry_id'] as String?,
  category: json['category'] as String?,
  lockedForUser: json['locked_for_user'] as bool?,
);

Map<String, dynamic> _$CanvasFileToJson(CanvasFile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uuid': instance.uuid,
      'folder_id': instance.folderId,
      'display_name': instance.displayName,
      'filename': instance.filename,
      'upload_status': instance.uploadStatus,
      'content-type': instance.contentType,
      'url': instance.url,
      'size': instance.size,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'unlock_at': instance.unlockAt?.toIso8601String(),
      'locked': instance.locked,
      'hidden': instance.hidden,
      'lock_at': instance.lockAt?.toIso8601String(),
      'hidden_for_user': instance.hiddenForUser,
      'thumbnail_url': instance.thumbnailUrl,
      'modified_at': instance.modifiedAt?.toIso8601String(),
      'mime_class': instance.mimeClass,
      'media_entry_id': instance.mediaEntryId,
      'category': instance.category,
      'locked_for_user': instance.lockedForUser,
    };
