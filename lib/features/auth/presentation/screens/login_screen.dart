import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/features/auth/presentation/providers/auth_provider.dart';
import 'package:kpass/features/auth/presentation/screens/credential_login_screen.dart';
import 'package:kpass/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAuthentication();
  }

  Future<void> _initializeAuthentication() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if already authenticated
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
      return;
    }

    // Check if there's an error state (e.g., proxy connection failed)
    if (authProvider.hasError) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Show initial UI
    setState(() {
      _isLoading = false;
    });
  }

  void _navigateToCredentialLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CredentialLoginScreen()),
    );
  }

  Future<void> _startBrowserLogin() async {
    // 手動ログイン画面に遷移
    _navigateToCredentialLogin();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(child: _buildWelcomeContent(theme, l10n)),
    );
  }

  Widget _buildWelcomeContent(ThemeData theme, AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWelcomeHeader(theme, l10n),
                const SizedBox(height: AppConstants.largePadding * 2),
                _buildAuthenticationOptions(theme, l10n),
              ],
            ),
          ),
          _buildFooter(theme, l10n),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(ThemeData theme, AppLocalizations? l10n) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Icon(Icons.school, size: 60, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Text(
          AppConstants.appFullName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          l10n?.tokenDescription ?? 'Access your K-LMS courses and assignments',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthenticationOptions(ThemeData theme, AppLocalizations? l10n) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.hasError) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'プロキシサーバーに接続できません',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authProvider.errorMessage ??
                          'プロキシサーバーが起動していることを確認してください。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/');
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('再試行'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppConstants.buttonHeight,
                        ),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _navigateToCredentialLogin,
                      icon:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.login),
                      label: Text(l10n?.login ?? '手動ログインを試す'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppConstants.buttonHeight,
                        ),
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        // Show welcome message for first-time users
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'K-LMSにログインしてください',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '慶應義塾大学のアカウントでK-LMSにアクセスできます。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _startBrowserLogin,
              icon:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.login),
              label: Text(l10n?.login ?? 'K-LMSでログイン'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFooter(ThemeData theme, AppLocalizations? l10n) {
    return Column(
      children: [
        TextButton.icon(
          onPressed: _showHelpDialog,
          icon: const Icon(Icons.help_outline),
          label: Text(l10n?.action ?? 'Need Help?'),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          'Version ${AppConstants.appVersion}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
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
                Text(l10n?.action ?? 'Help'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Login Methods:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                const Text('• 慶應義塾大学のアカウントでログイン'),
                const Text('• K-LMSと同じ認証情報を使用'),
                const Text('• Proxy API経由で安全に認証'),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  'システム要件:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                const Text('• インターネット接続が必要です'),
                const Text('• Proxyサーバーが起動している必要があります'),
                const Text('  (開発環境: http://localhost:3000)'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n?.close ?? 'Close'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}
