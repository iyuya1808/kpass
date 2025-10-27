// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'module.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Module _$ModuleFromJson(Map<String, dynamic> json) => Module(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  position: (json['position'] as num).toInt(),
  unlockAt:
      json['unlock_at'] == null
          ? null
          : DateTime.parse(json['unlock_at'] as String),
  requireSequentialProgress: json['require_sequential_progress'] as bool,
  publishFinalGrade: json['publish_final_grade'] as bool?,
  prerequisiteModuleIds:
      (json['prerequisite_module_ids'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
  state: json['state'] as String?,
  completedAt:
      json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
  itemsCount: (json['items_count'] as num).toInt(),
  itemsUrl: json['items_url'] as String?,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => ModuleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$ModuleToJson(Module instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'position': instance.position,
  'unlock_at': instance.unlockAt?.toIso8601String(),
  'require_sequential_progress': instance.requireSequentialProgress,
  'publish_final_grade': instance.publishFinalGrade,
  'prerequisite_module_ids': instance.prerequisiteModuleIds,
  'state': instance.state,
  'completed_at': instance.completedAt?.toIso8601String(),
  'items_count': instance.itemsCount,
  'items_url': instance.itemsUrl,
  'items': instance.items,
};

ModuleItem _$ModuleItemFromJson(Map<String, dynamic> json) => ModuleItem(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String?,
  position: (json['position'] as num).toInt(),
  indent: (json['indent'] as num).toInt(),
  type: json['type'] as String,
  moduleId: (json['module_id'] as num).toInt(),
  htmlUrl: json['html_url'] as String?,
  contentId: (json['content_id'] as num?)?.toInt(),
  pageUrl: json['page_url'] as String?,
  externalUrl: json['external_url'] as String?,
  completionRequirement:
      json['completion_requirement'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ModuleItemToJson(ModuleItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'position': instance.position,
      'indent': instance.indent,
      'type': instance.type,
      'module_id': instance.moduleId,
      'html_url': instance.htmlUrl,
      'content_id': instance.contentId,
      'page_url': instance.pageUrl,
      'external_url': instance.externalUrl,
      'completion_requirement': instance.completionRequirement,
    };
