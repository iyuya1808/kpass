import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'module.g.dart';

@JsonSerializable()
class Module extends Equatable {
  final int id;
  final String name;
  final int position;
  @JsonKey(name: 'unlock_at')
  final DateTime? unlockAt;
  @JsonKey(name: 'require_sequential_progress')
  final bool requireSequentialProgress;
  @JsonKey(name: 'publish_final_grade')
  final bool? publishFinalGrade;
  @JsonKey(name: 'prerequisite_module_ids')
  final List<int>? prerequisiteModuleIds;
  final String? state;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  @JsonKey(name: 'items_count')
  final int itemsCount;
  @JsonKey(name: 'items_url')
  final String? itemsUrl;
  @JsonKey(name: 'items')
  final List<ModuleItem>? items;

  const Module({
    required this.id,
    required this.name,
    required this.position,
    this.unlockAt,
    required this.requireSequentialProgress,
    this.publishFinalGrade,
    this.prerequisiteModuleIds,
    this.state,
    this.completedAt,
    required this.itemsCount,
    this.itemsUrl,
    this.items,
  });

  factory Module.fromJson(Map<String, dynamic> json) => _$ModuleFromJson(json);

  Map<String, dynamic> toJson() => _$ModuleToJson(this);

  /// Check if the module is published (available to students)
  bool get isCompleted => state == 'completed';

  /// Check if the module is locked
  bool get isLocked => state == 'locked';

  /// Check if the module is unlocked and available
  bool get isUnlocked =>
      state == 'unlocked' || state == 'started' || state == 'completed';

  @override
  List<Object?> get props => [
    id,
    name,
    position,
    unlockAt,
    requireSequentialProgress,
    publishFinalGrade,
    prerequisiteModuleIds,
    state,
    completedAt,
    itemsCount,
    itemsUrl,
    items,
  ];

  @override
  String toString() {
    return 'Module(id: $id, name: $name, position: $position, state: $state, itemsCount: $itemsCount)';
  }
}

@JsonSerializable()
class ModuleItem extends Equatable {
  final int id;
  final String? title;
  final int position;
  final int indent;
  final String type;
  @JsonKey(name: 'module_id')
  final int moduleId;
  @JsonKey(name: 'html_url')
  final String? htmlUrl;
  @JsonKey(name: 'content_id')
  final int? contentId;
  @JsonKey(name: 'page_url')
  final String? pageUrl;
  @JsonKey(name: 'external_url')
  final String? externalUrl;
  @JsonKey(name: 'completion_requirement')
  final Map<String, dynamic>? completionRequirement;

  const ModuleItem({
    required this.id,
    this.title,
    required this.position,
    required this.indent,
    required this.type,
    required this.moduleId,
    this.htmlUrl,
    this.contentId,
    this.pageUrl,
    this.externalUrl,
    this.completionRequirement,
  });

  factory ModuleItem.fromJson(Map<String, dynamic> json) =>
      _$ModuleItemFromJson(json);

  Map<String, dynamic> toJson() => _$ModuleItemToJson(this);

  @override
  List<Object?> get props => [
    id,
    title,
    position,
    indent,
    type,
    moduleId,
    htmlUrl,
    contentId,
    pageUrl,
    externalUrl,
    completionRequirement,
  ];

  @override
  String toString() {
    return 'ModuleItem(id: $id, title: $title, type: $type, position: $position)';
  }
}
