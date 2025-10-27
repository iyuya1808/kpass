import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/features/auth/presentation/providers/auth_provider.dart';
import 'package:kpass/features/settings/presentation/providers/settings_provider.dart';
import 'package:kpass/shared/widgets/custom_app_bar.dart';
import 'package:kpass/shared/widgets/upcoming_assignments_days_dialog.dart';
import 'package:kpass/app/routes.dart';
import 'package:kpass/l10n/app_localizations.dart';

/// 設定タブ
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n?.settings ?? '設定',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // 挨拶セクション
          Container(
            color: theme.colorScheme.primary,
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: _buildGreeting(context, user?.name ?? 'ユーザー'),
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // 設定項目
          _buildSectionHeader(context, '一般設定'),
          ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: const Text('課題表示範囲'),
            subtitle: Text(
              '${settingsProvider.upcomingAssignmentsDays}日以内の課題を表示',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              UpcomingAssignmentsDaysDialog.show(context, settingsProvider);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('通知設定'),
            subtitle: const Text('課題のリマインダー通知を管理'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to notification settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('カレンダー同期'),
            subtitle: const Text('デバイスカレンダーとの同期設定'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to calendar settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.sync_outlined),
            title: const Text('バックグラウンド同期'),
            subtitle: const Text('自動同期の頻度を設定'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to sync settings
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_view_week_outlined),
            title: const Text('土日表示'),
            subtitle: const Text('時間割で土曜日と日曜日を表示する'),
            value: settingsProvider.showWeekendsInTimetable,
            onChanged: (value) {
              settingsProvider.setShowWeekendsInTimetable(value);
            },
          ),

          const Divider(),

          _buildSectionHeader(context, 'アプリ情報'),
          ListTile(
            leading: const Icon(Icons.info_outlined),
            title: const Text('バージョン'),
            subtitle: Text(AppConstants.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('ヘルプ'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showHelpDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () {
              // TODO: Open privacy policy
            },
          ),

          const Divider(),

          _buildSectionHeader(context, 'アカウント'),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('ログアウト', style: TextStyle(color: Colors.red)),
            subtitle: const Text('このデバイスからログアウトします'),
            onTap: () => _showLogoutDialog(context, authProvider),
          ),

          const SizedBox(height: AppConstants.largePadding),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, String userName) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;

    // より自然で親しみやすい挨拶に改善
    if (hour >= 5 && hour < 12) {
      greeting = 'おはようございます';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'こんにちは';
    } else if (hour >= 17 && hour < 21) {
      greeting = 'こんばんは';
    } else {
      greeting = 'お疲れ様です';
    }

    // ユーザー名から表示名を抽出
    String displayName = userName;
    if (userName.contains('　')) {
      final parts = userName.split('　');
      if (parts.length > 1) {
        displayName = parts[1];
        if (displayName.contains('|')) {
          displayName = displayName.split('|').first.trim();
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$displayNameさん',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.defaultPadding,
        AppConstants.defaultPadding,
        AppConstants.defaultPadding,
        AppConstants.smallPadding,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.logout, color: Colors.red),
                SizedBox(width: AppConstants.smallPadding),
                Text('ログアウト'),
              ],
            ),
            content: const Text('ログアウトしますか？\n\n次回起動時に再度ログインが必要になります。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) => const Center(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(
                                AppConstants.largePadding,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: AppConstants.defaultPadding),
                                  Text('ログアウト中...'),
                                ],
                              ),
                            ),
                          ),
                        ),
                  );

                  // Perform logout
                  await authProvider.logout();

                  if (context.mounted) {
                    // Close loading dialog
                    Navigator.of(context).pop();

                    // Navigate to login screen
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ログアウトしました'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('ログアウト'),
              ),
            ],
          ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.help_outline),
                SizedBox(width: AppConstants.smallPadding),
                Text('ヘルプ'),
              ],
            ),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KPassについて',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppConstants.smallPadding),
                  Text(
                    'KPassは慶應義塾大学のK-LMS（Canvas）を'
                    'より便利に利用するためのアプリです。',
                  ),
                  SizedBox(height: AppConstants.defaultPadding),
                  Text('主な機能', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: AppConstants.smallPadding),
                  Text('• コースと課題の確認'),
                  Text('• カレンダーへの自動同期'),
                  Text('• 課題期限のリマインダー通知'),
                  Text('• バックグラウンド自動同期'),
                  SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    '問題が発生した場合',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppConstants.smallPadding),
                  Text('• アプリを再起動してください'),
                  Text('• インターネット接続を確認してください'),
                  Text('• 再度ログインをお試しください'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
    );
  }
}
