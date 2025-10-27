import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:kpass/features/calendar/domain/repositories/calendar_repository.dart' show CalendarPermissionStatus;
import 'package:kpass/core/errors/exceptions.dart';

/// Utility class for handling calendar permissions across platforms
class CalendarPermissionHandler {
  /// Check if calendar permissions are required on this platform
  static bool get isPermissionRequired {
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Get the current permission status
  static Future<CalendarPermissionStatus> getPermissionStatus() async {
    if (!isPermissionRequired) {
      return CalendarPermissionStatus.granted;
    }

    try {
      final status = await Permission.calendarFullAccess.status;
      return _mapPermissionStatus(status);
    } catch (e) {
      throw CalendarException(
        message: 'Failed to check calendar permission status: ${e.toString()}',
        code: 'PERMISSION_STATUS_CHECK_FAILED',
      );
    }
  }

  /// Request calendar permissions
  static Future<CalendarPermissionStatus> requestPermission() async {
    if (!isPermissionRequired) {
      return CalendarPermissionStatus.granted;
    }

    try {
      final status = await Permission.calendarFullAccess.request();
      return _mapPermissionStatus(status);
    } catch (e) {
      throw CalendarException(
        message: 'Failed to request calendar permission: ${e.toString()}',
        code: 'PERMISSION_REQUEST_FAILED',
      );
    }
  }

  /// Check if we should show permission rationale
  static Future<bool> shouldShowRequestPermissionRationale() async {
    if (!isPermissionRequired) {
      return false;
    }

    try {
      return await Permission.calendarFullAccess.shouldShowRequestRationale;
    } catch (e) {
      return false;
    }
  }

  /// Open app settings for manual permission grant
  static Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      throw CalendarException(
        message: 'Failed to open app settings: ${e.toString()}',
        code: 'OPEN_SETTINGS_FAILED',
      );
    }
  }

  /// Get platform-specific permission guidance
  static String getPermissionGuidance(CalendarPermissionStatus status) {
    switch (status) {
      case CalendarPermissionStatus.granted:
        return 'Calendar access is granted. You can sync assignments to your calendar.';
      
      case CalendarPermissionStatus.denied:
        if (Platform.isIOS) {
          return 'Calendar access was denied. Please tap "Request Permission" to allow calendar access.';
        } else {
          return 'Calendar access was denied. Please grant permission to sync assignments to your calendar.';
        }
      
      case CalendarPermissionStatus.restricted:
        if (Platform.isIOS) {
          return 'Calendar access is restricted by Screen Time or parental controls. Please check your device restrictions.';
        } else {
          return 'Calendar access is restricted by system settings. Please check your device settings.';
        }
      
      case CalendarPermissionStatus.permanentlyDenied:
        if (Platform.isIOS) {
          return 'Calendar access was permanently denied. Please go to Settings > Privacy & Security > Calendars to enable access for this app.';
        } else {
          return 'Calendar access was permanently denied. Please go to Settings > Apps > KPass > Permissions to enable calendar access.';
        }
      
      case CalendarPermissionStatus.unknown:
        return 'Calendar permission status is unknown. Please try requesting permission again.';
    }
  }

  /// Get detailed permission instructions for the current platform
  static String getDetailedInstructions() {
    if (Platform.isIOS) {
      return '''
To enable calendar access on iOS:
1. Open Settings app
2. Scroll down and tap "Privacy & Security"
3. Tap "Calendars"
4. Find "KPass" in the list
5. Toggle the switch to enable access
''';
    } else if (Platform.isAndroid) {
      return '''
To enable calendar access on Android:
1. Open Settings app
2. Tap "Apps" or "Application Manager"
3. Find and tap "KPass"
4. Tap "Permissions"
5. Find "Calendar" and toggle it on
''';
    } else {
      return 'Calendar permissions are not required on this platform.';
    }
  }

  /// Check if the user has previously denied permission
  static Future<bool> hasUserDeniedPermission() async {
    if (!isPermissionRequired) {
      return false;
    }

    final status = await getPermissionStatus();
    return status == CalendarPermissionStatus.denied || 
           status == CalendarPermissionStatus.permanentlyDenied;
  }

  /// Check if permission can be requested
  static Future<bool> canRequestPermission() async {
    if (!isPermissionRequired) {
      return false;
    }

    final status = await getPermissionStatus();
    return status != CalendarPermissionStatus.granted && 
           status != CalendarPermissionStatus.permanentlyDenied;
  }

  /// Get user-friendly permission status description
  static String getStatusDescription(CalendarPermissionStatus status) {
    switch (status) {
      case CalendarPermissionStatus.granted:
        return 'Granted';
      case CalendarPermissionStatus.denied:
        return 'Denied';
      case CalendarPermissionStatus.restricted:
        return 'Restricted';
      case CalendarPermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      case CalendarPermissionStatus.unknown:
        return 'Unknown';
    }
  }

  /// Map system permission status to our enum
  static CalendarPermissionStatus _mapPermissionStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return CalendarPermissionStatus.granted;
      case PermissionStatus.denied:
        return CalendarPermissionStatus.denied;
      case PermissionStatus.restricted:
        return CalendarPermissionStatus.restricted;
      case PermissionStatus.permanentlyDenied:
        return CalendarPermissionStatus.permanentlyDenied;
      case PermissionStatus.provisional:
        return CalendarPermissionStatus.granted; // iOS provisional access
      case PermissionStatus.limited:
        return CalendarPermissionStatus.granted; // iOS limited access
    }
  }

  /// Validate calendar permission for operations
  static Future<void> validatePermissionForOperation(String operation) async {
    final status = await getPermissionStatus();
    
    if (status != CalendarPermissionStatus.granted) {
      throw CalendarException(
        message: 'Calendar permission required for $operation. Current status: ${getStatusDescription(status)}',
        code: 'PERMISSION_REQUIRED',
      );
    }
  }

  /// Get permission request strategy based on current status
  static Future<PermissionRequestStrategy> getRequestStrategy() async {
    final status = await getPermissionStatus();
    final shouldShowRationale = await shouldShowRequestPermissionRationale();
    
    switch (status) {
      case CalendarPermissionStatus.granted:
        return PermissionRequestStrategy.alreadyGranted;
      
      case CalendarPermissionStatus.denied:
        if (shouldShowRationale) {
          return PermissionRequestStrategy.showRationaleFirst;
        } else {
          return PermissionRequestStrategy.directRequest;
        }
      
      case CalendarPermissionStatus.permanentlyDenied:
        return PermissionRequestStrategy.openSettings;
      
      case CalendarPermissionStatus.restricted:
        return PermissionRequestStrategy.showRestrictionInfo;
      
      case CalendarPermissionStatus.unknown:
        return PermissionRequestStrategy.directRequest;
    }
  }
}

/// Strategy for requesting calendar permissions
enum PermissionRequestStrategy {
  alreadyGranted,
  directRequest,
  showRationaleFirst,
  openSettings,
  showRestrictionInfo,
}