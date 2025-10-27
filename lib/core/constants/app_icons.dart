import 'package:flutter/material.dart';

/// Icon constants used throughout the app
class AppIcons {
  // Navigation Icons
  static const IconData dashboard = Icons.dashboard_outlined;
  static const IconData dashboardFilled = Icons.dashboard;
  static const IconData courses = Icons.school_outlined;
  static const IconData coursesFilled = Icons.school;
  static const IconData assignments = Icons.assignment_outlined;
  static const IconData assignmentsFilled = Icons.assignment;
  static const IconData calendar = Icons.calendar_today_outlined;
  static const IconData calendarFilled = Icons.calendar_today;
  static const IconData settings = Icons.settings_outlined;
  static const IconData settingsFilled = Icons.settings;
  
  // Authentication Icons
  static const IconData login = Icons.login;
  static const IconData logout = Icons.logout;
  static const IconData person = Icons.person_outline;
  static const IconData personFilled = Icons.person;
  static const IconData key = Icons.key;
  static const IconData security = Icons.security;
  static const IconData visibility = Icons.visibility;
  static const IconData visibilityOff = Icons.visibility_off;
  
  // Action Icons
  static const IconData add = Icons.add;
  static const IconData edit = Icons.edit;
  static const IconData delete = Icons.delete;
  static const IconData save = Icons.save;
  static const IconData cancel = Icons.cancel;
  static const IconData check = Icons.check;
  static const IconData close = Icons.close;
  static const IconData refresh = Icons.refresh;
  static const IconData sync = Icons.sync;
  static const IconData download = Icons.download;
  static const IconData upload = Icons.upload;
  
  // Navigation Actions
  static const IconData back = Icons.arrow_back;
  static const IconData forward = Icons.arrow_forward;
  static const IconData up = Icons.keyboard_arrow_up;
  static const IconData down = Icons.keyboard_arrow_down;
  static const IconData left = Icons.keyboard_arrow_left;
  static const IconData right = Icons.keyboard_arrow_right;
  static const IconData menu = Icons.menu;
  static const IconData more = Icons.more_vert;
  static const IconData moreHoriz = Icons.more_horiz;
  
  // Status Icons
  static const IconData success = Icons.check_circle;
  static const IconData error = Icons.error;
  static const IconData warning = Icons.warning;
  static const IconData info = Icons.info;
  static const IconData pending = Icons.schedule;
  static const IconData completed = Icons.task_alt;
  static const IconData overdue = Icons.warning_amber;
  
  // Content Icons
  static const IconData document = Icons.description;
  static const IconData link = Icons.link;
  static const IconData attachment = Icons.attach_file;
  static const IconData image = Icons.image;
  static const IconData video = Icons.video_library;
  static const IconData audio = Icons.audio_file;
  static const IconData pdf = Icons.picture_as_pdf;
  
  // Communication Icons
  static const IconData notification = Icons.notifications_outlined;
  static const IconData notificationFilled = Icons.notifications;
  static const IconData notificationOff = Icons.notifications_off;
  static const IconData email = Icons.email;
  static const IconData message = Icons.message;
  static const IconData chat = Icons.chat;
  static const IconData phone = Icons.phone;
  
  // Time and Date Icons
  static const IconData time = Icons.access_time;
  static const IconData date = Icons.date_range;
  static const IconData today = Icons.today;
  static const IconData schedule = Icons.schedule;
  static const IconData timer = Icons.timer;
  static const IconData alarm = Icons.alarm;
  
  // Search and Filter Icons
  static const IconData search = Icons.search;
  static const IconData filter = Icons.filter_list;
  static const IconData sort = Icons.sort;
  static const IconData clear = Icons.clear;
  
  // Theme and Display Icons
  static const IconData lightMode = Icons.light_mode;
  static const IconData darkMode = Icons.dark_mode;
  static const IconData autoMode = Icons.brightness_auto;
  static const IconData language = Icons.language;
  static const IconData palette = Icons.palette;
  
  // Permission Icons
  static const IconData calendarPermission = Icons.event_available;
  static const IconData notificationPermission = Icons.notifications_active;
  static const IconData storagePermission = Icons.storage;
  static const IconData cameraPermission = Icons.camera_alt;
  
  // Sync and Network Icons
  static const IconData syncSuccess = Icons.sync_alt;
  static const IconData syncError = Icons.sync_problem;
  static const IconData offline = Icons.wifi_off;
  static const IconData online = Icons.wifi;
  static const IconData cloud = Icons.cloud;
  static const IconData cloudSync = Icons.cloud_sync;
  
  // Grade and Progress Icons
  static const IconData grade = Icons.grade;
  static const IconData star = Icons.star;
  static const IconData starOutline = Icons.star_outline;
  static const IconData progress = Icons.trending_up;
  static const IconData analytics = Icons.analytics;
  
  // File Type Icons
  static const IconData folder = Icons.folder;
  static const IconData folderOpen = Icons.folder_open;
  static const IconData file = Icons.insert_drive_file;
  static const IconData textFile = Icons.text_snippet;
  static const IconData spreadsheet = Icons.table_chart;
  static const IconData presentation = Icons.slideshow;
  
  // Priority Icons
  static const IconData priorityHigh = Icons.priority_high;
  static const IconData flag = Icons.flag;
  static const IconData bookmark = Icons.bookmark;
  static const IconData bookmarkOutline = Icons.bookmark_outline;
  
  // Help and Support Icons
  static const IconData help = Icons.help_outline;
  static const IconData helpFilled = Icons.help;
  static const IconData support = Icons.support_agent;
  static const IconData feedback = Icons.feedback;
  static const IconData bug = Icons.bug_report;
  
  // Accessibility Icons
  static const IconData accessibility = Icons.accessibility;
  static const IconData fontSize = Icons.format_size;
  static const IconData contrast = Icons.contrast;
  static const IconData voiceOver = Icons.record_voice_over;
}

/// Icon size constants
class AppIconSizes {
  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
  static const double xxl = 64.0;
  
  // Specific use cases
  static const double navigationIcon = 24.0;
  static const double actionIcon = 20.0;
  static const double statusIcon = 16.0;
  static const double avatarIcon = 32.0;
  static const double fabIcon = 24.0;
  static const double appBarIcon = 24.0;
  static const double listIcon = 20.0;
  static const double cardIcon = 18.0;
}

/// Utility class for creating themed icons
class ThemedIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  
  const ThemedIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Icon(
      icon,
      size: size ?? AppIconSizes.md,
      color: color ?? theme.iconTheme.color,
      semanticLabel: semanticLabel,
    );
  }
}

/// Status icon with color coding
class StatusIcon extends StatelessWidget {
  final String status;
  final double? size;
  
  const StatusIcon({
    super.key,
    required this.status,
    this.size,
  });
  
  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;
    
    switch (status.toLowerCase()) {
      case 'completed':
      case 'submitted':
        iconData = AppIcons.success;
        iconColor = Colors.green;
        break;
      case 'overdue':
        iconData = AppIcons.overdue;
        iconColor = Colors.red;
        break;
      case 'pending':
      case 'not_submitted':
        iconData = AppIcons.pending;
        iconColor = Colors.orange;
        break;
      case 'graded':
        iconData = AppIcons.grade;
        iconColor = Colors.blue;
        break;
      default:
        iconData = AppIcons.info;
        iconColor = Colors.grey;
    }
    
    return Icon(
      iconData,
      size: size ?? AppIconSizes.sm,
      color: iconColor,
    );
  }
}

/// Priority icon with color coding
class PriorityIcon extends StatelessWidget {
  final String priority;
  final double? size;
  
  const PriorityIcon({
    super.key,
    required this.priority,
    this.size,
  });
  
  @override
  Widget build(BuildContext context) {
    Color iconColor;
    
    switch (priority.toLowerCase()) {
      case 'high':
        iconColor = Colors.red;
        break;
      case 'medium':
        iconColor = Colors.orange;
        break;
      case 'low':
        iconColor = Colors.green;
        break;
      default:
        iconColor = Colors.grey;
    }
    
    return Icon(
      AppIcons.priorityHigh,
      size: size ?? AppIconSizes.sm,
      color: iconColor,
    );
  }
}