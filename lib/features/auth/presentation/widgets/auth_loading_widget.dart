import 'package:flutter/material.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/core/constants/app_colors.dart';
import 'package:kpass/l10n/app_localizations.dart';

/// A reusable loading widget for authentication screens
class AuthLoadingWidget extends StatelessWidget {
  final String? message;
  final bool showProgress;
  final VoidCallback? onCancel;

  const AuthLoadingWidget({
    super.key,
    this.message,
    this.showProgress = true,
    this.onCancel,
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
              if (showProgress) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: AppConstants.defaultPadding),
              ],
              Text(
                message ?? l10n?.loading ?? 'Loading...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (onCancel != null) ...[
                const SizedBox(height: AppConstants.defaultPadding),
                TextButton(
                  onPressed: onCancel,
                  child: Text(l10n?.cancel ?? 'Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A loading overlay that can be shown over other content
class AuthLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;
  final VoidCallback? onCancel;

  const AuthLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: AuthLoadingWidget(
              message: loadingMessage,
              onCancel: onCancel,
            ),
          ),
      ],
    );
  }
}

/// A specialized loading widget for WebView authentication
class WebViewLoadingWidget extends StatelessWidget {
  final String? currentUrl;
  final VoidCallback? onCancel;

  const WebViewLoadingWidget({
    super.key,
    this.currentUrl,
    this.onCancel,
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
              const CircularProgressIndicator(),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Connecting to K-LMS...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (currentUrl != null) ...[
                const SizedBox(height: AppConstants.smallPadding),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.smallPadding,
                    vertical: AppConstants.smallPadding / 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.public,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppConstants.smallPadding / 2),
                      Flexible(
                        child: Text(
                          currentUrl!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (onCancel != null) ...[
                const SizedBox(height: AppConstants.defaultPadding),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: onCancel,
                      child: Text(l10n?.cancel ?? 'Cancel'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A loading widget specifically for token validation
class TokenValidationLoadingWidget extends StatelessWidget {
  final VoidCallback? onCancel;

  const TokenValidationLoadingWidget({
    super.key,
    this.onCancel,
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
              const CircularProgressIndicator(),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                l10n?.validating ?? 'Validating token...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'Please wait while we verify your access token with Canvas.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (onCancel != null) ...[
                const SizedBox(height: AppConstants.defaultPadding),
                TextButton(
                  onPressed: onCancel,
                  child: Text(l10n?.cancel ?? 'Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A success animation widget for authentication
class AuthSuccessWidget extends StatefulWidget {
  final String message;
  final String? userName;
  final VoidCallback? onContinue;

  const AuthSuccessWidget({
    super.key,
    required this.message,
    this.userName,
    this.onContinue,
  });

  @override
  State<AuthSuccessWidget> createState() => _AuthSuccessWidgetState();
}

class _AuthSuccessWidgetState extends State<AuthSuccessWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.successGreen,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.primaryWhite,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  widget.message,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.userName != null) ...[
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    l10n?.welcomeUser(widget.userName!) ?? 'Welcome, ${widget.userName}!',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (widget.onContinue != null) ...[
                  const SizedBox(height: AppConstants.defaultPadding),
                  ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: AppColors.primaryWhite,
                    ),
                    child: Text(l10n?.action ?? 'Continue'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}