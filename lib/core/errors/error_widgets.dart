import 'package:flutter/material.dart';
import 'package:kpass/core/errors/failures.dart';
import 'package:kpass/core/errors/error_handler.dart';
import 'package:kpass/core/constants/app_dimensions.dart';
import 'package:kpass/core/constants/app_icons.dart';
import 'package:kpass/core/utils/result.dart';
import 'package:kpass/app/theme.dart';

/// Generic error display widget
class ErrorDisplayWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool showDetails;

  const ErrorDisplayWidget({
    super.key,
    required this.failure,
    this.onRetry,
    this.onAction,
    this.actionLabel,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorMessage = ErrorHandler.getErrorMessage(failure);
    final isRetryable = ErrorHandler.isRetryable(failure);
    final requiresAction = ErrorHandler.requiresUserAction(failure);

    return Container(
      padding: AppDimensions.paddingLG,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Error Icon
          Icon(
            _getErrorIcon(),
            size: AppIconSizes.xxl,
            color: _getErrorColor(),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Error Title
          Text(
            _getErrorTitle(),
            style: AppTextStyles.heading3.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Error Message
          Text(
            errorMessage,
            style: AppTextStyles.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          if (showDetails && failure.code != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Error Code: ${failure.code}',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
          
          const SizedBox(height: AppSpacing.xl),
          
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRetryable && onRetry != null) ...[
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(AppIcons.refresh),
                  label: const Text('Retry'),
                ),
                if (requiresAction && onAction != null)
                  const SizedBox(width: AppSpacing.md),
              ],
              
              if (requiresAction && onAction != null)
                OutlinedButton.icon(
                  onPressed: onAction,
                  icon: Icon(_getActionIcon()),
                  label: Text(actionLabel ?? _getDefaultActionLabel()),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getErrorIcon() {
    if (failure is NetworkFailure) {
      final networkFailure = failure as NetworkFailure;
      if (networkFailure.code == 'NO_CONNECTION') {
        return AppIcons.offline;
      }
      return AppIcons.error;
    }
    
    if (failure is AuthFailure) {
      return AppIcons.security;
    }
    
    if (failure is PermissionFailure) {
      return AppIcons.warning;
    }
    
    if (failure is ValidationFailure) {
      return AppIcons.warning;
    }
    
    return AppIcons.error;
  }

  Color _getErrorColor() {
    if (failure is NetworkFailure) {
      final networkFailure = failure as NetworkFailure;
      if (networkFailure.code == 'NO_CONNECTION') {
        return AppTheme.warningOrange;
      }
    }
    
    if (failure is AuthFailure || failure is PermissionFailure) {
      return AppTheme.warningOrange;
    }
    
    if (failure is ValidationFailure) {
      return AppTheme.warningOrange;
    }
    
    return AppTheme.errorRed;
  }

  String _getErrorTitle() {
    if (failure is NetworkFailure) {
      final networkFailure = failure as NetworkFailure;
      if (networkFailure.code == 'NO_CONNECTION') {
        return 'No Internet Connection';
      }
      if (networkFailure.code == 'TIMEOUT') {
        return 'Request Timeout';
      }
      return 'Network Error';
    }
    
    if (failure is AuthFailure) {
      return 'Authentication Error';
    }
    
    if (failure is CanvasFailure) {
      return 'Canvas API Error';
    }
    
    if (failure is CalendarFailure) {
      return 'Calendar Error';
    }
    
    if (failure is NotificationFailure) {
      return 'Notification Error';
    }
    
    if (failure is PermissionFailure) {
      return 'Permission Required';
    }
    
    if (failure is ValidationFailure) {
      return 'Validation Error';
    }
    
    return 'Error Occurred';
  }

  IconData _getActionIcon() {
    if (failure is AuthFailure) {
      return AppIcons.login;
    }
    
    if (failure is PermissionFailure) {
      return AppIcons.settings;
    }
    
    return AppIcons.settings;
  }

  String _getDefaultActionLabel() {
    if (failure is AuthFailure) {
      return 'Login';
    }
    
    if (failure is PermissionFailure) {
      return 'Settings';
    }
    
    return 'Settings';
  }
}

/// Compact error widget for inline display
class CompactErrorWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;

  const CompactErrorWidget({
    super.key,
    required this.failure,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorMessage = ErrorHandler.getErrorMessage(failure);
    final isRetryable = ErrorHandler.isRetryable(failure);

    return Container(
      padding: AppDimensions.paddingMD,
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.1),
        borderRadius: AppDimensions.radiusSM,
        border: Border.all(
          color: AppTheme.errorRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            AppIcons.error,
            size: AppIconSizes.sm,
            color: AppTheme.errorRed,
          ),
          
          const SizedBox(width: AppSpacing.sm),
          
          Expanded(
            child: Text(
              errorMessage,
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          
          if (isRetryable && onRetry != null) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(AppIcons.refresh),
              iconSize: AppIconSizes.sm,
              color: AppTheme.errorRed,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error snackbar utility
class ErrorSnackBar {
  static void show(
    BuildContext context,
    Failure failure, {
    VoidCallback? onRetry,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final errorMessage = ErrorHandler.getErrorMessage(failure);
    final isRetryable = ErrorHandler.isRetryable(failure);
    final requiresAction = ErrorHandler.requiresUserAction(failure);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              AppIcons.error,
              color: Colors.white,
              size: AppIconSizes.sm,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        action: _buildSnackBarAction(
          isRetryable: isRetryable,
          requiresAction: requiresAction,
          onRetry: onRetry,
          onAction: onAction,
          actionLabel: actionLabel,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static SnackBarAction? _buildSnackBarAction({
    required bool isRetryable,
    required bool requiresAction,
    VoidCallback? onRetry,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    if (isRetryable && onRetry != null) {
      return SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: onRetry,
      );
    }
    
    if (requiresAction && onAction != null) {
      return SnackBarAction(
        label: actionLabel ?? 'Action',
        textColor: Colors.white,
        onPressed: onAction,
      );
    }
    
    return null;
  }
}

/// Loading error state widget
class LoadingErrorWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final bool isLoading;

  const LoadingErrorWidget({
    super.key,
    required this.failure,
    this.onRetry,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ErrorDisplayWidget(
      failure: failure,
      onRetry: onRetry,
    );
  }
}

/// Empty state with error fallback
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = AppIcons.info,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppDimensions.paddingLG,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: AppIconSizes.xxl,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          if (onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel ?? 'Action'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error dialog utility
class ErrorDialog {
  static Future<void> show(
    BuildContext context,
    Failure failure, {
    VoidCallback? onRetry,
    VoidCallback? onAction,
    String? actionLabel,
    bool barrierDismissible = true,
  }) async {
    final errorMessage = ErrorHandler.getErrorMessage(failure);
    final isRetryable = ErrorHandler.isRetryable(failure);
    final requiresAction = ErrorHandler.requiresUserAction(failure);

    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(
            _getDialogIcon(failure),
            color: _getDialogIconColor(failure),
            size: AppIconSizes.lg,
          ),
          title: Text(_getDialogTitle(failure)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(errorMessage),
              if (failure.code != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Error Code: ${failure.code}',
                  style: AppTextStyles.caption,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (isRetryable && onRetry != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: const Text('Retry'),
              ),
            if (requiresAction && onAction != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onAction();
                },
                child: Text(actionLabel ?? _getDefaultDialogActionLabel(failure)),
              ),
          ],
        );
      },
    );
  }

  static IconData _getDialogIcon(Failure failure) {
    if (failure is NetworkFailure) {
      final networkFailure = failure;
      if (networkFailure.code == 'NO_CONNECTION') {
        return AppIcons.offline;
      }
      return AppIcons.error;
    }
    
    if (failure is AuthFailure) {
      return AppIcons.security;
    }
    
    if (failure is PermissionFailure) {
      return AppIcons.warning;
    }
    
    return AppIcons.error;
  }

  static Color _getDialogIconColor(Failure failure) {
    if (failure is NetworkFailure) {
      final networkFailure = failure;
      if (networkFailure.code == 'NO_CONNECTION') {
        return AppTheme.warningOrange;
      }
    }
    
    if (failure is AuthFailure || failure is PermissionFailure) {
      return AppTheme.warningOrange;
    }
    
    return AppTheme.errorRed;
  }

  static String _getDialogTitle(Failure failure) {
    if (failure is NetworkFailure) {
      final networkFailure = failure;
      if (networkFailure.code == 'NO_CONNECTION') {
        return 'Connection Error';
      }
      return 'Network Error';
    }
    
    if (failure is AuthFailure) {
      return 'Authentication Error';
    }
    
    if (failure is PermissionFailure) {
      return 'Permission Required';
    }
    
    return 'Error';
  }

  static String _getDefaultDialogActionLabel(Failure failure) {
    if (failure is AuthFailure) {
      return 'Login';
    }
    
    if (failure is PermissionFailure) {
      return 'Settings';
    }
    
    return 'Action';
  }
}

/// Bottom sheet error display
class ErrorBottomSheet {
  static Future<void> show(
    BuildContext context,
    Failure failure, {
    VoidCallback? onRetry,
    VoidCallback? onAction,
    String? actionLabel,
  }) async {
    final errorMessage = ErrorHandler.getErrorMessage(failure);
    final isRetryable = ErrorHandler.isRetryable(failure);
    final requiresAction = ErrorHandler.requiresUserAction(failure);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: AppDimensions.paddingLG,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Error Icon
              Icon(
                ErrorDialog._getDialogIcon(failure),
                size: AppIconSizes.xl,
                color: ErrorDialog._getDialogIconColor(failure),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Error Title
              Text(
                ErrorDialog._getDialogTitle(failure),
                style: AppTextStyles.heading3,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              // Error Message
              Text(
                errorMessage,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              
              if (failure.code != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Error Code: ${failure.code}',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
              
              const SizedBox(height: AppSpacing.xl),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                  
                  if (isRetryable && onRetry != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onRetry();
                        },
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                  
                  if (requiresAction && onAction != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onAction();
                        },
                        child: Text(actionLabel ?? ErrorDialog._getDefaultDialogActionLabel(failure)),
                      ),
                    ),
                  ],
                ],
              ),
              
              // Add bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }
}

/// Error boundary widget for catching and displaying errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;
  final void Function(Object error, StackTrace? stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }
      
      // Default error display
      final failure = ErrorHandler.handleException(_error!, _stackTrace);
      return ErrorDisplayWidget(
        failure: failure,
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
      );
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Reset error state when dependencies change
    if (_error != null) {
      setState(() {
        _error = null;
        _stackTrace = null;
      });
    }
  }


}

/// Mixin for handling errors in widgets
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  /// Handle an error and show appropriate UI feedback
  void handleError(
    Object error, {
    StackTrace? stackTrace,
    bool showSnackBar = true,
    bool showDialog = false,
    VoidCallback? onRetry,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final failure = ErrorHandler.handleException(error, stackTrace);
    
    // Log the error
    ErrorHandler.logError(error, stackTrace);
    
    if (!mounted) return;
    
    if (showDialog) {
      ErrorDialog.show(
        context,
        failure,
        onRetry: onRetry,
        onAction: onAction,
        actionLabel: actionLabel,
      );
    } else if (showSnackBar) {
      ErrorSnackBar.show(
        context,
        failure,
        onRetry: onRetry,
        onAction: onAction,
        actionLabel: actionLabel,
      );
    }
  }

  /// Handle a result and show error if it's a failure
  void handleResult<R>(
    Result<R> result, {
    void Function(R value)? onSuccess,
    bool showSnackBar = true,
    bool showDialog = false,
    VoidCallback? onRetry,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    result.fold(
      (failure) => handleError(
        failure,
        showSnackBar: showSnackBar,
        showDialog: showDialog,
        onRetry: onRetry,
        onAction: onAction,
        actionLabel: actionLabel,
      ),
      (value) => onSuccess?.call(value),
    );
  }
}

/// Extension for BuildContext to easily show error dialogs
extension ErrorHandlingExtension on BuildContext {
  /// Show error snackbar
  void showErrorSnackBar(
    Failure failure, {
    VoidCallback? onRetry,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    ErrorSnackBar.show(
      this,
      failure,
      onRetry: onRetry,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show error dialog
  Future<void> showErrorDialog(
    Failure failure, {
    VoidCallback? onRetry,
    VoidCallback? onAction,
    String? actionLabel,
    bool barrierDismissible = true,
  }) {
    return ErrorDialog.show(
      this,
      failure,
      onRetry: onRetry,
      onAction: onAction,
      actionLabel: actionLabel,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Show error bottom sheet
  Future<void> showErrorBottomSheet(
    Failure failure, {
    VoidCallback? onRetry,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return ErrorBottomSheet.show(
      this,
      failure,
      onRetry: onRetry,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }
}