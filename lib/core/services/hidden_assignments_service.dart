import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 非表示にした課題を管理するサービス
/// ユーザーが削除した課題のIDを永続化して管理します
class HiddenAssignmentsService {
  static const String _hiddenAssignmentsKey = 'hidden_assignments';

  /// 課題を非表示リストに追加
  Future<void> hideAssignment(int assignmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hiddenIds = await getHiddenAssignmentIds();

      if (!hiddenIds.contains(assignmentId)) {
        hiddenIds.add(assignmentId);
        await prefs.setStringList(
          _hiddenAssignmentsKey,
          hiddenIds.map((id) => id.toString()).toList(),
        );

        if (kDebugMode) {
          debugPrint(
            'HiddenAssignmentsService: Hidden assignment $assignmentId',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HiddenAssignmentsService: Failed to hide assignment: $e');
      }
    }
  }

  /// 課題を非表示リストから削除（復元）
  Future<void> unhideAssignment(int assignmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hiddenIds = await getHiddenAssignmentIds();

      if (hiddenIds.contains(assignmentId)) {
        hiddenIds.remove(assignmentId);
        await prefs.setStringList(
          _hiddenAssignmentsKey,
          hiddenIds.map((id) => id.toString()).toList(),
        );

        if (kDebugMode) {
          debugPrint(
            'HiddenAssignmentsService: Unhidden assignment $assignmentId',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HiddenAssignmentsService: Failed to unhide assignment: $e');
      }
    }
  }

  /// 非表示リストをクリア
  Future<void> clearHiddenAssignments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hiddenAssignmentsKey);

      if (kDebugMode) {
        debugPrint('HiddenAssignmentsService: Cleared all hidden assignments');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'HiddenAssignmentsService: Failed to clear hidden assignments: $e',
        );
      }
    }
  }

  /// 非表示になっている課題IDのリストを取得
  Future<List<int>> getHiddenAssignmentIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hiddenIdsString = prefs.getStringList(_hiddenAssignmentsKey) ?? [];
      return hiddenIdsString.map((id) => int.parse(id)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'HiddenAssignmentsService: Failed to get hidden assignments: $e',
        );
      }
      return [];
    }
  }

  /// 指定した課題が非表示かどうかを確認
  Future<bool> isHidden(int assignmentId) async {
    final hiddenIds = await getHiddenAssignmentIds();
    return hiddenIds.contains(assignmentId);
  }

  /// 非表示になっている課題の数を取得
  Future<int> getHiddenCount() async {
    final hiddenIds = await getHiddenAssignmentIds();
    return hiddenIds.length;
  }
}
