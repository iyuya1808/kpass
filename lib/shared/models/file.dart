import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'file.g.dart';

@JsonSerializable()
class CanvasFile extends Equatable {
  final int id;
  final String uuid;
  @JsonKey(name: 'folder_id')
  final int? folderId;
  @JsonKey(name: 'display_name')
  final String displayName;
  final String filename;
  @JsonKey(name: 'upload_status')
  final String? uploadStatus;
  @JsonKey(name: 'content-type')
  final String? contentType;
  final String url;
  final int size;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'unlock_at')
  final DateTime? unlockAt;
  final bool? locked;
  final bool? hidden;
  @JsonKey(name: 'lock_at')
  final DateTime? lockAt;
  @JsonKey(name: 'hidden_for_user')
  final bool? hiddenForUser;
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @JsonKey(name: 'modified_at')
  final DateTime? modifiedAt;
  @JsonKey(name: 'mime_class')
  final String? mimeClass;
  @JsonKey(name: 'media_entry_id')
  final String? mediaEntryId;
  final String? category;
  @JsonKey(name: 'locked_for_user')
  final bool? lockedForUser;

  const CanvasFile({
    required this.id,
    required this.uuid,
    this.folderId,
    required this.displayName,
    required this.filename,
    this.uploadStatus,
    this.contentType,
    required this.url,
    required this.size,
    this.createdAt,
    this.updatedAt,
    this.unlockAt,
    this.locked,
    this.hidden,
    this.lockAt,
    this.hiddenForUser,
    this.thumbnailUrl,
    this.modifiedAt,
    this.mimeClass,
    this.mediaEntryId,
    this.category,
    this.lockedForUser,
  });

  factory CanvasFile.fromJson(Map<String, dynamic> json) =>
      _$CanvasFileFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasFileToJson(this);

  /// Check if the file is a PDF
  bool get isPdf =>
      mimeClass == 'pdf' ||
      contentType == 'application/pdf' ||
      displayName.toLowerCase().endsWith('.pdf');

  /// Check if the file is an image
  bool get isImage =>
      mimeClass == 'image' ||
      contentType?.startsWith('image/') == true ||
      displayName.toLowerCase().endsWith('.jpg') ||
      displayName.toLowerCase().endsWith('.jpeg') ||
      displayName.toLowerCase().endsWith('.png') ||
      displayName.toLowerCase().endsWith('.gif');

  /// Get human readable file size
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  @override
  List<Object?> get props => [
    id,
    uuid,
    folderId,
    displayName,
    filename,
    uploadStatus,
    contentType,
    url,
    size,
    createdAt,
    updatedAt,
    unlockAt,
    locked,
    hidden,
    lockAt,
    hiddenForUser,
    thumbnailUrl,
    modifiedAt,
    mimeClass,
    mediaEntryId,
    category,
    lockedForUser,
  ];

  @override
  String toString() {
    return 'CanvasFile(id: $id, displayName: $displayName, mimeClass: $mimeClass)';
  }
}
