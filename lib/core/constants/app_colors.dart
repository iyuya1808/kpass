import 'package:flutter/material.dart';

/// Extended color palette for the KPASS application
class AppColors {
  // Primary App Colors
  static const Color primaryBlue = Color(0xFF001D5E);
  static const Color primaryBlueDark = Color(0xFF001447);
  static const Color primaryBlueLight = Color(0xFF1A3D7C);
  static const Color primaryBlueAccent = Color(0xFF2E5090);

  // Keio Colors (kept for reference/legacy)
  static const Color keioRed = Color(0xFFDC143C);
  static const Color keioRedDark = Color(0xFFB71C1C);
  static const Color keioRedLight = Color(0xFFFF5252);
  static const Color keioRedAccent = Color(0xFFFF1744);

  // Primary Blue Variations
  static const Color primaryBlue50 = Color(0xFFE3E7F1);
  static const Color primaryBlue100 = Color(0xFFB8C3DC);
  static const Color primaryBlue200 = Color(0xFF899BC5);
  static const Color primaryBlue300 = Color(0xFF5973AD);
  static const Color primaryBlue400 = Color(0xFF36569C);
  static const Color primaryBlue500 = Color(0xFF001D5E); // Primary
  static const Color primaryBlue600 = Color(0xFF001A56);
  static const Color primaryBlue700 = Color(0xFF00154C);
  static const Color primaryBlue800 = Color(0xFF001147);
  static const Color primaryBlue900 = Color(0xFF000A3D);

  // Keio Red Variations
  static const Color keioRed50 = Color(0xFFFFF5F5);
  static const Color keioRed100 = Color(0xFFFFEBEE);
  static const Color keioRed200 = Color(0xFFFFCDD2);
  static const Color keioRed300 = Color(0xFFEF9A9A);
  static const Color keioRed400 = Color(0xFFE57373);
  static const Color keioRed500 = Color(0xFFDC143C); // Primary
  static const Color keioRed600 = Color(0xFFE53935);
  static const Color keioRed700 = Color(0xFFD32F2F);
  static const Color keioRed800 = Color(0xFFC62828);
  static const Color keioRed900 = Color(0xFFB71C1C);

  // Base Colors
  static const Color primaryBlack = Color(0xFF212121);
  static const Color secondaryBlack = Color(0xFF424242);
  static const Color tertiaryBlack = Color(0xFF616161);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAFAFA);
  static const Color backgroundGrey = Color(0xFFF5F5F5);
  static const Color surfaceGrey = Color(0xFFFAFAFA);
  static const Color borderGrey = Color(0xFFE0E0E0);

  // Grey Scale
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color successGreenLight = Color(0xFF81C784);
  static const Color successGreenDark = Color(0xFF388E3C);

  static const Color warningOrange = Color(0xFFFF9800);
  static const Color warningOrangeLight = Color(0xFFFFB74D);
  static const Color warningOrangeDark = Color(0xFFF57C00);

  static const Color errorRed = Color(0xFFF44336);
  static const Color errorRedLight = Color(0xFFEF5350);
  static const Color errorRedDark = Color(0xFFD32F2F);

  static const Color infoBlue = Color(0xFF2196F3);
  static const Color infoBlueLight = Color(0xFF64B5F6);
  static const Color infoBlueDark = Color(0xFF1976D2);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF000000);

  // Assignment Status Colors
  static const Color assignmentSubmitted = Color(0xFF4CAF50);
  static const Color assignmentPending = Color(0xFFFF9800);
  static const Color assignmentOverdue = Color(0xFFF44336);
  static const Color assignmentGraded = Color(0xFF2196F3);
  static const Color assignmentDraft = Color(0xFF9E9E9E);

  // Priority Colors
  static const Color priorityHigh = Color(0xFFF44336);
  static const Color priorityMedium = Color(0xFFFF9800);
  static const Color priorityLow = Color(0xFF4CAF50);
  static const Color priorityNone = Color(0xFF9E9E9E);

  // Course Category Colors
  static const List<Color> courseCategoryColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFE91E63), // Pink
    Color(0xFF3F51B5), // Indigo
  ];

  // Grade Colors
  static const Color gradeA = Color(0xFF4CAF50);
  static const Color gradeB = Color(0xFF8BC34A);
  static const Color gradeC = Color(0xFFFFEB3B);
  static const Color gradeD = Color(0xFFFF9800);
  static const Color gradeF = Color(0xFFF44336);
  static const Color gradeIncomplete = Color(0xFF9E9E9E);

  // Calendar Colors
  static const Color calendarToday = Color(0xFF001D5E);
  static const Color calendarSelected = Color(0xFF1A3D7C);
  static const Color calendarEvent = Color(0xFF2196F3);
  static const Color calendarDeadline = Color(0xFFFF9800);
  static const Color calendarOverdue = Color(0xFFF44336);

  // Notification Colors
  static const Color notificationBackground = Color(0xFF323232);
  static const Color notificationText = Color(0xFFFFFFFF);
  static const Color notificationAction = Color(0xFF1A3D7C);

  // Overlay Colors
  static const Color overlayLight = Color(0x80FFFFFF);
  static const Color overlayDark = Color(0x80000000);
  static const Color scrimLight = Color(0x52000000);
  static const Color scrimDark = Color(0x52FFFFFF);

  // Shimmer Colors (for loading states)
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF424242);
  static const Color shimmerHighlightDark = Color(0xFF616161);

  // Social Media Colors (if needed for sharing)
  static const Color facebook = Color(0xFF1877F2);
  static const Color twitter = Color(0xFF1DA1F2);
  static const Color linkedin = Color(0xFF0A66C2);
  static const Color instagram = Color(0xFFE4405F);

  // Accessibility Colors
  static const Color focusIndicator = Color(0xFF2196F3);
  static const Color highContrastBorder = Color(0xFF000000);
  static const Color highContrastText = Color(0xFF000000);
  static const Color highContrastBackground = Color(0xFFFFFFFF);
}

/// Color utility functions
class ColorUtils {
  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Get contrasting text color for a given background color
  static Color getContrastingTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? AppColors.textPrimary : AppColors.textOnPrimary;
  }

  /// Get assignment status color
  static Color getAssignmentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return AppColors.assignmentSubmitted;
      case 'pending':
      case 'not_submitted':
        return AppColors.assignmentPending;
      case 'overdue':
        return AppColors.assignmentOverdue;
      case 'graded':
        return AppColors.assignmentGraded;
      case 'draft':
        return AppColors.assignmentDraft;
      default:
        return AppColors.grey500;
    }
  }

  /// Get priority color
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.priorityHigh;
      case 'medium':
        return AppColors.priorityMedium;
      case 'low':
        return AppColors.priorityLow;
      default:
        return AppColors.priorityNone;
    }
  }

  /// Get grade color
  static Color getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
      case 'A+':
      case 'A-':
        return AppColors.gradeA;
      case 'B':
      case 'B+':
      case 'B-':
        return AppColors.gradeB;
      case 'C':
      case 'C+':
      case 'C-':
        return AppColors.gradeC;
      case 'D':
      case 'D+':
      case 'D-':
        return AppColors.gradeD;
      case 'F':
        return AppColors.gradeF;
      default:
        return AppColors.gradeIncomplete;
    }
  }

  /// Get course category color by index
  static Color getCourseColor(int index) {
    return AppColors.courseCategoryColors[index %
        AppColors.courseCategoryColors.length];
  }

  /// Lighten a color by a percentage
  static Color lighten(Color color, double percentage) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + percentage).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Darken a color by a percentage
  static Color darken(Color color, double percentage) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - percentage).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Check if a color is considered dark
  static bool isDark(Color color) {
    return color.computeLuminance() < 0.5;
  }

  /// Check if a color is considered light
  static bool isLight(Color color) {
    return color.computeLuminance() >= 0.5;
  }
}
