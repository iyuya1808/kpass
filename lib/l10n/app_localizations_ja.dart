// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'KPass';

  @override
  String get login => 'ログイン';

  @override
  String get logout => 'ログアウト';

  @override
  String get courses => 'コース';

  @override
  String get assignments => '課題';

  @override
  String get calendar => 'カレンダー';

  @override
  String get settings => '設定';

  @override
  String get notifications => '通知';

  @override
  String get dashboard => 'ダッシュボード';

  @override
  String get todayCourses => '本日の授業';

  @override
  String get loading => '読み込み中...';

  @override
  String get error => 'エラー';

  @override
  String get retry => '再試行';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get edit => '編集';

  @override
  String get add => '追加';

  @override
  String get dueDate => '締切日';

  @override
  String get noDueDate => '締切なし';

  @override
  String get submitted => '提出済み';

  @override
  String get notSubmitted => '未提出';

  @override
  String get syncCalendar => 'カレンダーに同期';

  @override
  String get calendarSynced => 'カレンダーに同期済み';

  @override
  String get reminderSet => 'リマインダー設定済み';

  @override
  String get noAssignments => '課題が見つかりません';

  @override
  String get noCourses => 'コースが見つかりません';

  @override
  String get networkError => 'ネットワークエラーが発生しました';

  @override
  String get authenticationError => '認証に失敗しました';

  @override
  String get tokenExpired => 'セッションが期限切れです。再度ログインしてください。';

  @override
  String get enterToken => 'アクセストークンを入力';

  @override
  String get tokenHint => 'Canvasのアクセストークンをここに貼り付けてください';

  @override
  String get validateToken => 'トークンを検証';

  @override
  String get tokenValid => 'トークンは有効です';

  @override
  String get tokenInvalid => '無効なトークンです';

  @override
  String get calendarPermission => 'カレンダーの許可';

  @override
  String get calendarPermissionMessage => 'KPassは課題の締切をカレンダーに同期するためにカレンダーへのアクセスが必要です';

  @override
  String get notificationPermission => '通知の許可';

  @override
  String get notificationPermissionMessage => 'KPassは締切のリマインダーを送信するために通知へのアクセスが必要です';

  @override
  String get grant => '許可';

  @override
  String get deny => '拒否';

  @override
  String get syncSettings => '同期設定';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get accountSettings => 'アカウント設定';

  @override
  String get syncFrequency => '同期頻度';

  @override
  String get reminderTime => 'リマインダー時間';

  @override
  String get oneHour => '1時間前';

  @override
  String get sixHours => '6時間前';

  @override
  String get twentyFourHours => '24時間前';

  @override
  String get enableNotifications => '通知を有効にする';

  @override
  String get enableCalendarSync => 'カレンダー同期を有効にする';

  @override
  String get close => '閉じる';

  @override
  String get action => 'アクション';

  @override
  String get connectionError => '接続エラー';

  @override
  String get authenticationFailed => '認証に失敗しました';

  @override
  String get permissionRequired => '許可が必要です';

  @override
  String get errorOccurred => 'エラーが発生しました';

  @override
  String get unknownError => '不明なエラーが発生しました';

  @override
  String get tryAgain => 'もう一度お試しください';

  @override
  String get checkConnection => 'インターネット接続を確認してください';

  @override
  String get sessionExpiredMessage => 'セッションが期限切れです。再度ログインしてください。';

  @override
  String get permissionDeniedMessage => '許可が拒否されました。設定で必要な許可を与えてください。';

  @override
  String get serverError => 'サーバーエラーが発生しました。しばらくしてからもう一度お試しください。';

  @override
  String get requestTimeout => 'リクエストがタイムアウトしました。もう一度お試しください。';

  @override
  String get tooManyRequests => 'リクエストが多すぎます。しばらく待ってからもう一度お試しください。';

  @override
  String get resourceNotFound => '要求されたリソースが見つかりませんでした。';

  @override
  String get accessDenied => 'アクセスが拒否されました。このリソースにアクセスする権限がありません。';

  @override
  String get invalidData => 'サーバーから無効なデータを受信しました。';

  @override
  String get storageError => 'ストレージエラーが発生しました。利用可能な容量を確認してください。';

  @override
  String get calendarError => 'カレンダーエラーが発生しました。カレンダーの許可を確認してください。';

  @override
  String get notificationError => '通知エラーが発生しました。通知の許可を確認してください。';

  @override
  String get syncError => '同期に失敗しました。もう一度お試しください。';

  @override
  String get validationError => '検証エラーが発生しました。入力内容を確認してください。';

  @override
  String get configurationError => '設定エラーです。サポートにお問い合わせください。';

  @override
  String get featureNotImplemented => 'この機能はまだ実装されていません。';

  @override
  String get backgroundSyncError => 'バックグラウンド同期に失敗しました。設定を確認してください。';

  @override
  String get batteryOptimizationWarning => 'バッテリー最適化がバックグラウンド同期を妨げる可能性があります。';

  @override
  String get fcmError => 'プッシュ通知エラーです。代わりにローカル通知を使用します。';

  @override
  String get cacheError => 'キャッシュエラーが発生しました。データが古い可能性があります。';

  @override
  String get encryptionError => 'セキュリティエラーが発生しました。アプリを再起動してください。';

  @override
  String get tokenFormatError => '無効なトークン形式です。トークンを確認してください。';

  @override
  String get courseNotFound => 'コースが見つかりません。削除されたか、アクセス権限がない可能性があります。';

  @override
  String get assignmentNotFound => '課題が見つかりません。削除または変更された可能性があります。';

  @override
  String get calendarEventError => 'カレンダーイベントの管理に失敗しました。カレンダーの許可を確認してください。';

  @override
  String get reminderError => 'リマインダーのスケジュール設定に失敗しました。通知の許可を確認してください。';

  @override
  String get webViewError => 'ログインに失敗しました。もう一度お試しいただくか、手動でトークンを入力してください。';

  @override
  String get shibbolethError => '大学認証に失敗しました。認証情報を確認してください。';

  @override
  String get manualTokenTitle => 'アクセストークン手動入力';

  @override
  String get enterCanvasToken => 'Canvasアクセストークンを入力';

  @override
  String get tokenDescription => 'Canvasのアカウント設定からアクセストークンを生成できます。トークンは安全にデバイスに保存されます。';

  @override
  String get accessToken => 'アクセストークン';

  @override
  String get tokenPlaceholder => 'Canvasアクセストークンをここに貼り付けてください...';

  @override
  String get showToken => 'トークンを表示';

  @override
  String get hideToken => 'トークンを隠す';

  @override
  String get pasteFromClipboard => 'クリップボードから貼り付け';

  @override
  String get validateAndSaveToken => '検証して保存';

  @override
  String get validating => '検証中...';

  @override
  String get clear => 'クリア';

  @override
  String get howToGetToken => 'アクセストークンの取得方法';

  @override
  String get openCanvasSettings => 'Canvas設定を開く';

  @override
  String get tokenFormatValid => 'トークン形式は有効です';

  @override
  String get tokenCannotBeEmpty => 'アクセストークンを入力してください';

  @override
  String get tokenTooShort => 'トークンが短すぎます。確認してもう一度お試しください';

  @override
  String get tokenTooLong => 'トークンが長すぎます。確認してもう一度お試しください';

  @override
  String get tokenInvalidCharacters => 'トークンに無効な文字が含まれています。英数字と~のみ使用できます';

  @override
  String welcomeUser(String userName) {
    return 'ようこそ、$userNameさん！';
  }

  @override
  String get failedToPasteClipboard => 'クリップボードからの貼り付けに失敗しました';

  @override
  String get unexpectedError => '予期しないエラーが発生しました。もう一度お試しください。';

  @override
  String get canvasSettingsTitle => 'Canvas設定';

  @override
  String get tokenGenerationSteps => 'アクセストークンを生成するには：';

  @override
  String get tokenStep1 => '1. Canvasの設定に移動';

  @override
  String get tokenStep2 => '2. 「承認済み統合」をクリック';

  @override
  String get tokenStep3 => '3. 「+ 新しいアクセストークン」をクリック';

  @override
  String get tokenStep4 => '4. 目的を入力して生成';

  @override
  String get tokenStep5 => '5. トークンをコピーしてここに貼り付け';

  @override
  String get tokenHint1 => 'トークンは64〜128文字である必要があります';

  @override
  String get tokenHint2 => '英数字と~記号のみが許可されています';

  @override
  String get tokenHint3 => 'Canvas設定 > 承認済み統合からトークンを取得できます';

  @override
  String get tokenHint4 => 'スペースなしでトークン全体をコピーしてください';

  @override
  String get notificationSettingsTitle => 'Notification Settings';

  @override
  String get permissions => 'Permissions';

  @override
  String get notificationsEnabled => 'Notifications Enabled';

  @override
  String get notificationsDisabled => 'Notifications Disabled';

  @override
  String get notificationPermissionGranted => 'You will receive assignment reminders';

  @override
  String get notificationPermissionDenied => 'Grant permission to receive notifications';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get connectedToFirebase => 'Connected to Firebase';

  @override
  String get localNotificationsOnly => 'Using local notifications only';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get enableNotificationsSubtitle => 'Turn on/off all notifications';

  @override
  String get assignmentReminders => 'Assignment Reminders';

  @override
  String get assignmentRemindersSubtitle => 'Get reminded before assignment deadlines';

  @override
  String get newAssignmentNotifications => 'New Assignment Notifications';

  @override
  String get newAssignmentNotificationsSubtitle => 'Get notified when new assignments are posted';

  @override
  String get assignmentUpdateNotifications => 'Assignment Update Notifications';

  @override
  String get assignmentUpdateNotificationsSubtitle => 'Get notified when assignments are modified';

  @override
  String get sound => 'Sound';

  @override
  String get soundSubtitle => 'Play sound for notifications';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrationSubtitle => 'Vibrate for notifications';

  @override
  String get reminderTiming => 'Reminder Timing';

  @override
  String get reminderTimingSubtitle => 'Choose when to receive assignment reminders before the due date';

  @override
  String get fifteenMinutes => '15 minutes';

  @override
  String get thirtyMinutes => '30 minutes';

  @override
  String get twoHours => '2 hours';

  @override
  String get fortyEightHours => '48 hours';

  @override
  String get oneWeek => '1 week';

  @override
  String get quietHours => 'Quiet Hours';

  @override
  String get quietHoursSubtitle => 'Set hours when you don\'t want to receive notifications';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get notSet => 'Not set';

  @override
  String get currentlyInQuietHours => 'Currently in quiet hours';

  @override
  String get notInQuietHours => 'Not in quiet hours';

  @override
  String get courseNotifications => 'Course Notifications';

  @override
  String get courseNotificationsSubtitle => 'Choose which courses to receive notifications for';

  @override
  String get noCoursesFound => 'No courses found';

  @override
  String get syncCoursesToManage => 'Sync your courses to manage notifications';

  @override
  String get notificationHistory => 'Notification History';

  @override
  String get viewAll => 'View All';

  @override
  String get totalNotifications => 'Total Notifications';

  @override
  String get unreadNotifications => 'Unread Notifications';

  @override
  String get recentActivity => 'Recent Activity (7 days)';

  @override
  String get markAllRead => 'Mark All Read';

  @override
  String get clearAll => 'Clear All';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get serviceStatus => 'Service Status';

  @override
  String get notificationServiceAvailable => 'Notification service is available';

  @override
  String get notificationServiceUnavailable => 'Notification service is not available';

  @override
  String get refreshPushToken => 'Refresh Push Token';

  @override
  String get refreshPushTokenSubtitle => 'Refresh Firebase messaging token';

  @override
  String get viewStatistics => 'View Statistics';

  @override
  String get viewStatisticsSubtitle => 'Detailed notification statistics';

  @override
  String get notificationStatistics => 'Notification Statistics';

  @override
  String get total => 'Total';

  @override
  String get unread => 'Unread';

  @override
  String get recent => 'Recent (7 days)';

  @override
  String get enabled => 'Enabled';

  @override
  String get reminders => 'Reminders';

  @override
  String get defaultReminder => 'Default reminder';

  @override
  String get enabledCourses => 'Enabled courses';

  @override
  String get clearAllNotifications => 'Clear All Notifications';

  @override
  String get clearAllNotificationsMessage => 'This will permanently delete all notification history. This action cannot be undone.';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get justNow => 'Just now';

  @override
  String get minuteAgo => 'minute ago';

  @override
  String get minutesAgo => 'minutes ago';

  @override
  String get hourAgo => 'hour ago';

  @override
  String get hoursAgo => 'hours ago';

  @override
  String get dayAgo => 'day ago';

  @override
  String get daysAgo => 'days ago';

  @override
  String get timetable => '時間割';

  @override
  String get weeklyTimetable => '週間時間割';

  @override
  String get noCoursesThisWeek => '今週は授業がありません';

  @override
  String get monday => '月';

  @override
  String get tuesday => '火';

  @override
  String get wednesday => '水';

  @override
  String get thursday => '木';

  @override
  String get friday => '金';

  @override
  String get saturday => '土';

  @override
  String get sunday => '日';
}
