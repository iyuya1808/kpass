import 'package:flutter/foundation.dart';
import 'package:kpass/core/services/canvas_api_client.dart';
import 'package:kpass/core/services/hidden_assignments_service.dart';
import 'package:kpass/shared/models/assignment.dart';
import 'package:kpass/shared/models/course.dart';

class AssignmentsProvider extends ChangeNotifier {
  final CanvasApiClient _apiClient;
  final HiddenAssignmentsService _hiddenAssignmentsService;

  List<Assignment> _assignments = [];
  List<int> _hiddenAssignmentIds = [];
  bool _isLoading = false;
  bool _hiddenListInitialized = false;
  String? _error;
  DateTime? _lastSync;
  int _totalCourses = 0;
  int _successfulCourses = 0;
  bool _isPartialData = false;

  List<Assignment> get assignments =>
      _assignments.where((a) => !_hiddenAssignmentIds.contains(a.id)).toList();

  /// Get all assignments without hidden filter (for use when hidden list is not initialized)
  List<Assignment> get allAssignments => _assignments;

  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastSync => _lastSync;
  bool get hasAssignments => assignments.isNotEmpty;
  bool get isHiddenListInitialized => _hiddenListInitialized;
  int get totalCourses => _totalCourses;
  int get successfulCourses => _successfulCourses;
  bool get isPartialData => _isPartialData;
  double get dataCompleteness =>
      _totalCourses > 0 ? _successfulCourses / _totalCourses : 1.0;

  AssignmentsProvider({
    CanvasApiClient? apiClient,
    HiddenAssignmentsService? hiddenAssignmentsService,
  }) : _apiClient = apiClient ?? CanvasApiClient(),
       _hiddenAssignmentsService =
           hiddenAssignmentsService ?? HiddenAssignmentsService() {
    _loadHiddenAssignments();
  }

  /// 非表示リストを読み込み
  Future<void> _loadHiddenAssignments() async {
    _hiddenAssignmentIds =
        await _hiddenAssignmentsService.getHiddenAssignmentIds();
    _hiddenListInitialized = true;
    notifyListeners();
  }

  /// 非表示リストを読み込み（公開メソッド）
  Future<void> loadHiddenAssignments() async {
    await _loadHiddenAssignments();
  }

  /// Load all assignments from Canvas API
  /// Requires list of courses to fetch assignments from each
  Future<void> loadAssignments(List<Course> courses) async {
    // 非表示リストの読み込みが完了するまで待つ（重複読み込みを避ける）
    if (!_hiddenListInitialized) {
      await _loadHiddenAssignments();
    }

    if (courses.isEmpty) {
      _assignments = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _totalCourses = courses.length;
    _successfulCourses = 0;
    _isPartialData = false;
    notifyListeners();

    // リトライ機能付きで課題を取得
    const maxRetries = 2;
    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        final courseIds = courses.map((c) => c.id.toString()).toList();

        final result = await _apiClient.getAllAssignments(
          courseIds,
          include: ['submission'],
          perPage: 1000, // より多くの課題を取得して期限が近い課題の表示を安定化
        );

        if (result.isSuccess) {
          final rawList = result.valueOrNull!;

          // 課題データの変換と検証を強化
          final validAssignments = <Assignment>[];
          for (final json in rawList) {
            try {
              // コース情報からcourse_nameを追加
              final courseId = json['course_id'] as int?;
              if (courseId != null) {
                final course = courses.firstWhere(
                  (c) => c.id == courseId,
                  orElse: () => courses.first, // フォールバック
                );
                json['course_name'] = course.name;
              }

              final assignment = Assignment.fromJson(json);
              if (assignment.isValid()) {
                validAssignments.add(assignment);
              }
            } catch (e) {
              // 個別の課題のパースエラーは無視して続行
            }
          }

          _assignments = validAssignments;

          // Sort by due date (upcoming first)
          _assignments.sort((a, b) {
            if (a.dueAt == null && b.dueAt == null) return 0;
            if (a.dueAt == null) return 1;
            if (b.dueAt == null) return -1;
            return a.dueAt!.compareTo(b.dueAt!);
          });

          _lastSync = DateTime.now();
          _error = null;
          _isPartialData = false;

          // 成功した場合はループを抜ける
          break;
        } else {
          _error = result.failureOrNull?.message ?? '課題の取得に失敗しました';

          // リトライ可能な場合は再試行
          if (retryCount < maxRetries) {
            retryCount++;
            await Future.delayed(Duration(seconds: retryCount)); // 指数バックオフ
            continue;
          }

          // エラーが発生しても、既存の課題データは保持する
          // これにより、部分的なデータでも表示を継続できる
          if (_assignments.isEmpty) {
            _assignments = [];
          }
          _isPartialData = true;
          break;
        }
      } catch (e) {
        _error = '課題の取得中にエラーが発生しました: $e';

        // リトライ可能な場合は再試行
        if (retryCount < maxRetries) {
          retryCount++;
          await Future.delayed(Duration(seconds: retryCount)); // 指数バックオフ
          continue;
        }

        // 例外が発生しても、既存の課題データは保持する
        // これにより、部分的なデータでも表示を継続できる
        if (_assignments.isEmpty) {
          _assignments = [];
        }
        _isPartialData = true;
        break;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Get assignments for a specific course
  List<Assignment> getAssignmentsForCourse(int courseId) {
    return assignments.where((a) => a.courseId == courseId).toList();
  }

  /// Get upcoming assignments (not submitted, due in the future)
  List<Assignment> getUpcomingAssignments({int? limit}) {
    // 非表示リストが初期化されていない場合は、非表示フィルターを適用せずに返す
    // これにより、初期化完了前でも期限前課題を表示できる
    final assignmentsToFilter =
        _hiddenListInitialized ? assignments : _assignments;

    var upcoming =
        assignmentsToFilter.where((a) {
          return a.isUpcoming && !a.isSubmitted;
        }).toList();

    if (limit != null && upcoming.length > limit) {
      return upcoming.sublist(0, limit);
    }

    return upcoming;
  }

  /// Get overdue assignments (not submitted, past due date)
  List<Assignment> getOverdueAssignments() {
    // 非表示リストが初期化されていない場合は、非表示フィルターを適用せずに返す
    // これにより、初期化完了前でも期限すぎ課題を表示できる
    final assignmentsToFilter =
        _hiddenListInitialized ? assignments : _assignments;

    return assignmentsToFilter
        .where((a) => a.isOverdue && !a.isSubmitted)
        .toList();
  }

  /// Refresh assignments
  Future<void> refresh(List<Course> courses) async {
    _assignments = [];
    await loadAssignments(courses);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 課題を非表示にする（永久的に削除）
  Future<void> hideAssignment(int assignmentId) async {
    await _hiddenAssignmentsService.hideAssignment(assignmentId);
    await _loadHiddenAssignments();
    notifyListeners();
  }

  /// 課題を復元する
  Future<void> unhideAssignment(int assignmentId) async {
    await _hiddenAssignmentsService.unhideAssignment(assignmentId);
    await _loadHiddenAssignments();
    notifyListeners();
  }

  /// すべての非表示課題をクリア
  Future<void> clearHiddenAssignments() async {
    await _hiddenAssignmentsService.clearHiddenAssignments();
    await _loadHiddenAssignments();
    notifyListeners();
  }

  /// 非表示になっている課題の数を取得
  Future<int> getHiddenCount() async {
    return _hiddenAssignmentsService.getHiddenCount();
  }

  /// 非表示になっている課題のリストを取得
  List<Assignment> getHiddenAssignments() {
    // 非表示リストが初期化されていない場合は空のリストを返す
    if (!_hiddenListInitialized) {
      return [];
    }
    return _assignments
        .where((a) => _hiddenAssignmentIds.contains(a.id))
        .toList();
  }
}
