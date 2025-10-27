import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'page.g.dart';

@JsonSerializable()
class Page extends Equatable {
  @JsonKey(name: 'page_id')
  final int id;
  final String url;
  final String title;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'hide_from_students')
  final bool? hideFromStudents;
  @JsonKey(name: 'editing_roles')
  final String? editingRoles;
  @JsonKey(name: 'last_edited_by')
  final Map<String, dynamic>? lastEditedBy;
  final String? body;
  final bool? published;
  @JsonKey(name: 'front_page')
  final bool? frontPage;
  @JsonKey(name: 'locked_for_user')
  final bool? lockedForUser;
  @JsonKey(name: 'lock_info')
  final Map<String, dynamic>? lockInfo;
  @JsonKey(name: 'lock_explanation')
  final String? lockExplanation;

  const Page({
    required this.id,
    required this.url,
    required this.title,
    this.createdAt,
    this.updatedAt,
    this.hideFromStudents,
    this.editingRoles,
    this.lastEditedBy,
    this.body,
    this.published,
    this.frontPage,
    this.lockedForUser,
    this.lockInfo,
    this.lockExplanation,
  });

  factory Page.fromJson(Map<String, dynamic> json) => _$PageFromJson(json);

  Map<String, dynamic> toJson() => _$PageToJson(this);

  @override
  List<Object?> get props => [
    id,
    url,
    title,
    createdAt,
    updatedAt,
    hideFromStudents,
    editingRoles,
    lastEditedBy,
    body,
    published,
    frontPage,
    lockedForUser,
    lockInfo,
    lockExplanation,
  ];

  @override
  String toString() {
    return 'Page(id: $id, title: $title, url: $url)';
  }
}
