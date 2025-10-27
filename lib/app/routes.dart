import 'package:flutter/material.dart';
import 'package:kpass/features/splash/presentation/pages/splash_screen.dart';
import 'package:kpass/features/auth/presentation/screens/login_screen.dart';
import 'package:kpass/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:kpass/features/courses/presentation/screens/course_detail_screen.dart';
import 'package:kpass/features/courses/presentation/screens/module_detail_screen.dart';
import 'package:kpass/features/courses/presentation/screens/page_viewer_screen.dart';
import 'package:kpass/features/courses/presentation/screens/file_viewer_screen.dart';
import 'package:kpass/features/assignments/presentation/screens/assignment_detail_screen.dart';
import 'package:kpass/features/assignments/presentation/screens/overdue_assignments_screen.dart';
import 'package:kpass/features/assignments/presentation/screens/hidden_assignments_screen.dart';
import 'package:kpass/features/assignments/presentation/screens/upcoming_assignments_screen.dart';
import 'package:kpass/shared/models/module.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String manualToken = '/manual-token';
  static const String dashboard = '/dashboard';
  static const String courseDetail = '/course-detail';
  static const String moduleDetail = '/module-detail';
  static const String pageViewer = '/page-viewer';
  static const String fileViewer = '/file-viewer';
  static const String assignmentDetail = '/assignment-detail';
  static const String overdueAssignments = '/overdue-assignments';
  static const String hiddenAssignments = '/hidden-assignments';
  static const String upcomingAssignments = '/upcoming-assignments';
  static const String settings = '/settings';
  static const String notificationSettings = '/notification-settings';
  static const String calendarSettings = '/calendar-settings';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      dashboard: (context) => const DashboardScreen(),
      // TODO: Add other routes as they are implemented
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Handle dynamic routes with parameters
    switch (settings.name) {
      case courseDetail:
        final courseId = settings.arguments as int?;
        if (courseId == null) {
          return MaterialPageRoute(
            builder: (context) => const NotFoundScreen(),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (context) => CourseDetailScreen(courseId: courseId),
          settings: settings,
        );

      case moduleDetail:
        final module = settings.arguments as Module?;
        if (module == null) {
          return MaterialPageRoute(
            builder: (context) => const NotFoundScreen(),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (context) => ModuleDetailScreen(module: module),
          settings: settings,
        );

      case pageViewer:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null ||
            args['courseId'] == null ||
            args['pageUrl'] == null ||
            args['pageTitle'] == null) {
          return MaterialPageRoute(
            builder: (context) => const NotFoundScreen(),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder:
              (context) => PageViewerScreen(
                courseId: args['courseId'] as int,
                pageUrl: args['pageUrl'] as String,
                pageTitle: args['pageTitle'] as String,
              ),
          settings: settings,
        );

      case fileViewer:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null ||
            args['courseId'] == null ||
            args['fileId'] == null ||
            args['fileTitle'] == null) {
          return MaterialPageRoute(
            builder: (context) => const NotFoundScreen(),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder:
              (context) => FileViewerScreen(
                courseId: args['courseId'] as int,
                fileId: args['fileId'] as int,
                fileTitle: args['fileTitle'] as String,
              ),
          settings: settings,
        );

      case assignmentDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null ||
            args['courseId'] == null ||
            args['assignmentId'] == null ||
            args['assignmentTitle'] == null) {
          return MaterialPageRoute(
            builder: (context) => const NotFoundScreen(),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder:
              (context) => AssignmentDetailScreen(
                courseId: args['courseId'] as int,
                assignmentId: args['assignmentId'] as int,
                assignmentTitle: args['assignmentTitle'] as String,
              ),
          settings: settings,
        );

      case overdueAssignments:
        return MaterialPageRoute(
          builder: (context) => const OverdueAssignmentsScreen(),
          settings: settings,
        );

      case hiddenAssignments:
        return MaterialPageRoute(
          builder: (context) => const HiddenAssignmentsScreen(),
          settings: settings,
        );

      case upcomingAssignments:
        return MaterialPageRoute(
          builder: (context) => const UpcomingAssignmentsScreen(),
          settings: settings,
        );

      // TODO: Add other dynamic routes as needed

      default:
        // Return 404 page for unknown routes
        return MaterialPageRoute(
          builder: (context) => const NotFoundScreen(),
          settings: settings,
        );
    }
  }
}

// 404 Not Found Screen
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '404 - Page Not Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'The requested page could not be found.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.dashboard,
                  (route) => false,
                );
              },
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
