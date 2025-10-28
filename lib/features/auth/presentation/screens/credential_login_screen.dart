import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/core/constants/app_colors.dart';
import 'package:kpass/features/auth/presentation/providers/auth_provider.dart';
import 'package:kpass/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:kpass/l10n/app_localizations.dart';

class CredentialLoginScreen extends StatefulWidget {
  const CredentialLoginScreen({super.key});

  @override
  State<CredentialLoginScreen> createState() => _CredentialLoginScreenState();
}

class _CredentialLoginScreenState extends State<CredentialLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Clear previous error
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (kDebugMode) {
      debugPrint('CredentialLoginScreen: Starting credentials login for user: $username');
    }

    try {
      if (kDebugMode) {
        debugPrint('CredentialLoginScreen: Getting AuthProvider');
      }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (kDebugMode) {
        debugPrint('CredentialLoginScreen: Calling authenticateWithCredentials');
      }
      final result = await authProvider.authenticateWithCredentials(username, password);

      if (kDebugMode) {
        debugPrint('CredentialLoginScreen: Credentials login result: ${result.type}');
      }

      if (!mounted) return;

      if (result.isSuccess) {
        // Credentials login completed successfully
        if (kDebugMode) {
          debugPrint('CredentialLoginScreen: Credentials login completed successfully');
        }

        // Navigate to dashboard or home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        if (kDebugMode) {
          debugPrint('CredentialLoginScreen: Credentials login failed: ${result.userFriendlyMessage}');
        }
        setState(() {
          _errorMessage = result.userFriendlyMessage;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      if (kDebugMode) {
        debugPrint('CredentialLoginScreen: Credentials login error: $error');
        debugPrint('CredentialLoginScreen: Error type: ${error.runtimeType}');
      }

      setState(() {
        _errorMessage = 'ログインに失敗しました: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n?.login ?? 'ログイン'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppConstants.largePadding),
                _buildHeader(theme, l10n),
                const SizedBox(height: AppConstants.largePadding * 2),
                _buildUsernameField(theme, l10n),
                const SizedBox(height: AppConstants.defaultPadding),
                _buildPasswordField(theme, l10n),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildErrorCard(theme),
                ],
                const SizedBox(height: AppConstants.largePadding),
                _buildLoginButton(theme, l10n),
                const SizedBox(height: AppConstants.defaultPadding),
                _buildHelpButton(theme, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations? l10n) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(Icons.school, size: 50, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Text(
          'K-LMS ログイン',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          'サーバ側で認証を実行します（ID/パスワード入力）',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUsernameField(ThemeData theme, AppLocalizations? l10n) {
    return TextFormField(
      controller: _usernameController,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: 'ユーザー名（慶應ID）',
        hintText: '例: ist***@keio.jp',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'ユーザー名を入力してください';
        }
        if (value.trim().length < 3) {
          return 'ユーザー名は3文字以上で入力してください';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(ThemeData theme, AppLocalizations? l10n) {
    return TextFormField(
      controller: _passwordController,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: 'パスワード',
        hintText: 'K-LMSのパスワード',
        prefixIcon: const Icon(Icons.lock_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
      ),
      obscureText: true,
      textInputAction: TextInputAction.done,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'パスワードを入力してください';
        }
        if (value.length < 3) {
          return 'パスワードが短すぎます';
        }
        return null;
      },
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Card(
      color: AppColors.errorRed.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.errorRed, size: 24),
            const SizedBox(width: AppConstants.smallPadding),
            Expanded(
              child: Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(ThemeData theme, AppLocalizations? l10n) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child:
          _isLoading
              ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : Text(
                'ログイン（ID/パスワード）',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
    );
  }

  Widget _buildHelpButton(ThemeData theme, AppLocalizations? l10n) {
    return TextButton.icon(
      onPressed: _showHelpDialog,
      icon: const Icon(Icons.help_outline),
      label: const Text('ログインできない場合'),
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  void _showHelpDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.help_outline),
                const SizedBox(width: AppConstants.smallPadding),
                Text(l10n?.action ?? 'ヘルプ'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ログインについて:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  const Text('• 慶應義塾大学のアカウント（慶應ID）を使用します'),
                  const Text('• K-LMSと同じ認証情報でログインできます'),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'トラブルシューティング:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  const Text('• インターネット接続を確認してください'),
                  const Text('• ユーザー名とパスワードが正しいか確認してください'),
                  const Text('• Proxyサーバーが起動しているか確認してください'),
                  const Text('  (開発環境: http://localhost:3000)'),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    '注意:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  const Text('• 初回ログイン時は時間がかかる場合があります'),
                  const Text('• セキュリティのため、パスワードは安全に保管されます'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n?.close ?? '閉じる'),
              ),
            ],
          ),
    );
  }
}
