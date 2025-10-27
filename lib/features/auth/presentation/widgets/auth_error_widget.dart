import 'package:flutter/material.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/core/constants/app_colors.dart';
import 'package:kpass/features/auth/domain/entities/auth_result.dart';
import 'package:kpass/l10n/app_localizations.dart';

/// A reusable error widget for authentication screens
class AuthErrorWidget extends StatelessWidget {
  final String message;
  final AuthResultType? errorType;
  final VoidCallback? onRetry;
  final VoidCallback? onAlternativeAction;
  final String? alternativeActionLabel;
  final bool showDetails;

  const AuthErrorWidget({
    super.key,
    required this.message,
    this.errorType,
    this.onRetry,
    this.onAlternativeAction,
    this.alternativeActionLabel,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildErrorIcon(),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                _getErrorTitle(l10n),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (showDetails) ...[
                const SizedBox(height: AppConstants.smallPadding),
                _buildErrorDetails(theme, l10n),
              ],
              const SizedBox(height: AppConstants.largePadding),
              _buildActionButtons(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    IconData iconData;
    Color iconColor = AppColors.errorRed;

    switch (errorType) {
      case AuthResultType.networkError:
        iconData = Icons.wifi_off;
        break;
      case AuthResultType.invalidCredentials:
        iconData = Icons.person_off;
        break;
      case AuthResultType.tokenValidationFailed:
        iconData = Icons.vpn_key_off;
        break;
      case AuthResultType.webViewError:
        iconData = Icons.web_asset_off;
        break;
      case AuthResultType.shibbolethError:
        iconData = Icons.school_outlined;
        break;
      case AuthResultType.externalBrowserLaunched:
        iconData = Icons.open_in_browser;
        break;
      default:
        iconData = Icons.error_outline;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(iconData, color: iconColor, size: 40),
    );
  }

  String _getErrorTitle(AppLocalizations? l10n) {
    switch (errorType) {
      case AuthResultType.networkError:
        return l10n?.connectionError ?? 'Connection Error';
      case AuthResultType.invalidCredentials:
        return l10n?.authenticationFailed ?? 'Authentication Failed';
      case AuthResultType.tokenValidationFailed:
        return l10n?.tokenInvalid ?? 'Invalid Token';
      case AuthResultType.webViewError:
        return l10n?.webViewError ?? 'Login Error';
      case AuthResultType.shibbolethError:
        return l10n?.shibbolethError ?? 'University Authentication Error';
      case AuthResultType.externalBrowserLaunched:
        return 'Browser Launched';
      default:
        return l10n?.errorOccurred ?? 'Error Occurred';
    }
  }

  Widget _buildErrorDetails(ThemeData theme, AppLocalizations? l10n) {
    String? detailText;
    List<String>? suggestions;

    switch (errorType) {
      case AuthResultType.networkError:
        detailText =
            l10n?.checkConnection ?? 'Please check your internet connection';
        suggestions = [
          'Check your WiFi or mobile data connection',
          'Try again in a few moments',
          'Contact IT support if the problem persists',
        ];
        break;
      case AuthResultType.manualLoginRequired:
        detailText = 'Manual login is required';
        suggestions = [
          'Please use the manual login flow',
          'Follow the instructions in the opened browser',
        ];
        break;
      case AuthResultType.manualLoginStarted:
        detailText = 'Manual login has been started';
        suggestions = [
          'Please log in to K-LMS in the opened browser',
          'Click the completion button when done',
        ];
        break;
      case AuthResultType.invalidCredentials:
        detailText = 'Please verify your login credentials';
        suggestions = [
          'Check your Keio University username and password',
          'Ensure your account is active',
          'Try using manual token input instead',
        ];
        break;
      case AuthResultType.tokenValidationFailed:
        detailText = 'The provided access token is not valid';
        suggestions = [
          'Generate a new access token from Canvas',
          'Ensure you copied the entire token',
          'Check that the token hasn\'t expired',
        ];
        break;
      case AuthResultType.webViewError:
        detailText = 'Unable to complete web-based authentication';
        suggestions = [
          'Try refreshing the login page',
          'Clear your browser cache',
          'Use manual token input as an alternative',
        ];
        break;
      case AuthResultType.shibbolethError:
        detailText = 'University authentication system error';
        suggestions = [
          'Verify your Keio University credentials',
          'Check if the authentication system is available',
          'Contact university IT support',
        ];
        break;
      case AuthResultType.externalBrowserLaunched:
        detailText = 'External browser has been launched for authentication';
        suggestions = [
          'Complete the login process in the opened browser',
          'Return to the app when authentication is complete',
          'Check if the browser opened successfully',
        ];
        break;
      case null:
      case AuthResultType.success:
      case AuthResultType.serverError:
      case AuthResultType.cancelled:
      case AuthResultType.unknown:
        // No detailed suggestions for these cases
        break;
    }

    if (detailText == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detailText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (suggestions != null && suggestions.isNotEmpty)
            const SizedBox(height: AppConstants.smallPadding),
          if (suggestions != null && suggestions.isNotEmpty) ...[
            Text(
              'Suggestions:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding / 2),
            ...suggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onRetry != null)
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(l10n?.retry ?? 'Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: AppColors.primaryWhite,
            ),
          ),
        if (onAlternativeAction != null) ...[
          if (onRetry != null)
            const SizedBox(height: AppConstants.smallPadding),
          OutlinedButton.icon(
            onPressed: onAlternativeAction,
            icon: const Icon(Icons.alt_route),
            label: Text(alternativeActionLabel ?? 'Try Alternative'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.errorRed,
              side: const BorderSide(color: AppColors.errorRed),
            ),
          ),
        ],
      ],
    );
  }
}

/// A compact error widget for inline display
class CompactAuthErrorWidget extends StatelessWidget {
  final String message;
  final AuthResultType? errorType;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const CompactAuthErrorWidget({
    super.key,
    required this.message,
    this.errorType,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getErrorIcon(), color: AppColors.errorRed, size: 20),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  color: AppColors.errorRed,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                  ),
                  child: Text(l10n?.retry ?? 'Retry'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (errorType) {
      case AuthResultType.networkError:
        return Icons.wifi_off;
      case AuthResultType.invalidCredentials:
        return Icons.person_off;
      case AuthResultType.tokenValidationFailed:
        return Icons.vpn_key_off;
      case AuthResultType.webViewError:
        return Icons.web_asset_off;
      case AuthResultType.shibbolethError:
        return Icons.school_outlined;
      case AuthResultType.externalBrowserLaunched:
        return Icons.open_in_browser;
      default:
        return Icons.error_outline;
    }
  }
}

/// An error snackbar for quick error notifications
class AuthErrorSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    AuthResultType? errorType,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 5),
  }) {
    final l10n = AppLocalizations.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(errorType),
              color: AppColors.primaryWhite,
              size: 20,
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.primaryWhite),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action:
            onRetry != null
                ? SnackBarAction(
                  label: l10n?.retry ?? 'Retry',
                  textColor: AppColors.primaryWhite,
                  onPressed: onRetry,
                )
                : null,
      ),
    );
  }

  static IconData _getErrorIcon(AuthResultType? errorType) {
    switch (errorType) {
      case AuthResultType.networkError:
        return Icons.wifi_off;
      case AuthResultType.invalidCredentials:
        return Icons.person_off;
      case AuthResultType.tokenValidationFailed:
        return Icons.vpn_key_off;
      case AuthResultType.webViewError:
        return Icons.web_asset_off;
      case AuthResultType.shibbolethError:
        return Icons.school_outlined;
      case AuthResultType.externalBrowserLaunched:
        return Icons.open_in_browser;
      default:
        return Icons.error_outline;
    }
  }
}
