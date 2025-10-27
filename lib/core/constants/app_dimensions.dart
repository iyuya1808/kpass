import 'package:flutter/material.dart';

/// Application-wide dimension constants
class AppDimensions {
  // Padding and Margins
  static const double smallPadding = 8.0;
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;
  
  // Padding Getters (for consistency with theme usage)
  static EdgeInsets get paddingSM => EdgeInsets.all(smallPadding);
  static EdgeInsets get paddingMD => EdgeInsets.all(defaultPadding);
  static EdgeInsets get paddingLG => EdgeInsets.all(largePadding);
  static EdgeInsets get paddingHorizontalMD => EdgeInsets.symmetric(horizontal: defaultPadding);
  
  // Component Heights
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 60.0;
  
  // Card and Container Properties
  static const double cardElevation = 2.0;
  static const double cardRadius = 8.0;
  static const double containerRadius = 12.0;
  
  // Radius Getters (for consistency with theme usage)
  static BorderRadius get radiusSM => BorderRadius.circular(cardRadius);
  static BorderRadius get radiusMD => BorderRadius.circular(containerRadius);
  static BorderRadius get radiusLG => BorderRadius.circular(16.0);
  static BorderRadius get radiusXL => BorderRadius.circular(24.0);
  static BorderRadius get radiusCircular => BorderRadius.circular(9999.0);
  
  // Icon Sizes
  static const double smallIconSize = 16.0;
  static const double defaultIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double extraLargeIconSize = 48.0;
  
  // Touch Targets
  static const double minTouchTargetSize = 44.0;
  static const double touchTargetPadding = 12.0;
  
  // List Items
  static const double listItemHeight = 72.0;
  static const double listItemPadding = 16.0;
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  
  // Border Widths
  static const double thinBorder = 1.0;
  static const double mediumBorder = 2.0;
  static const double thickBorder = 4.0;
  
  // Animation Durations (in milliseconds)
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;
}