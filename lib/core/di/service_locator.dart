import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kpass/core/services/canvas_api_client.dart';
import 'package:kpass/features/courses/data/datasources/courses_remote_data_source.dart';
import 'package:kpass/features/courses/data/datasources/courses_remote_data_source_impl.dart';
import 'package:kpass/features/courses/data/datasources/courses_local_data_source_impl.dart';
import 'package:kpass/features/courses/data/repositories/courses_repository_impl.dart';
import 'package:kpass/features/courses/domain/repositories/courses_repository.dart';
import 'package:kpass/features/assignments/data/datasources/assignments_remote_data_source.dart';
import 'package:kpass/features/assignments/data/datasources/assignments_remote_data_source_impl.dart';
import 'package:kpass/features/assignments/data/datasources/assignments_local_data_source_impl.dart';
import 'package:kpass/features/assignments/data/repositories/assignments_repository_impl.dart';
import 'package:kpass/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:kpass/features/calendar/data/datasources/calendar_remote_data_source.dart';
import 'package:kpass/features/calendar/data/datasources/calendar_remote_data_source_impl.dart';
import 'package:kpass/features/calendar/data/datasources/calendar_local_data_source_impl.dart';
import 'package:kpass/features/calendar/data/services/calendar_service.dart';
import 'package:kpass/features/calendar/data/services/calendar_event_manager.dart';
import 'package:kpass/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:kpass/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:kpass/features/notifications/data/services/local_notification_service.dart';
import 'package:kpass/features/notifications/data/services/fcm_service.dart';
import 'package:kpass/features/notifications/data/services/hybrid_notification_service.dart';
import 'package:kpass/features/notifications/data/services/assignment_reminder_service.dart';
import 'package:kpass/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:kpass/features/notifications/domain/repositories/notification_repository.dart';

final GetIt sl = GetIt.instance;

/// Initialize dependency injection
Future<void> initializeDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Core services
  sl.registerLazySingleton<CanvasApiClient>(() => CanvasApiClient());

  // Courses
  sl.registerLazySingleton<CoursesRemoteDataSource>(
    () => CoursesRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<CoursesLocalDataSource>(
    () => CoursesLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<CoursesRepository>(
    () => CoursesRepositoryImpl(sl(), sl()),
  );

  // Assignments
  sl.registerLazySingleton<AssignmentsRemoteDataSource>(
    () => AssignmentsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AssignmentsLocalDataSource>(
    () => AssignmentsLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<AssignmentsRepository>(
    () => AssignmentsRepositoryImpl(sl(), sl()),
  );

  // Calendar
  sl.registerLazySingleton<CalendarRemoteDataSource>(
    () => CalendarRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<CalendarLocalDataSource>(
    () => CalendarLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<CalendarService>(
    () => CalendarService(),
  );
  sl.registerLazySingleton<CalendarEventManager>(
    () => CalendarEventManager(sl()),
  );
  sl.registerLazySingleton<CalendarRepository>(
    () => CalendarRepositoryImpl(sl(), sl(), sl(), sl()),
  );

  // Notifications
  sl.registerLazySingleton<LocalNotificationService>(
    () => LocalNotificationService(),
  );
  sl.registerLazySingleton<FCMService>(
    () => FCMService(),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<HybridNotificationService>(
    () => HybridNotificationService(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<AssignmentReminderService>(
    () => AssignmentReminderService(sl(), sl()),
  );
}

/// Reset dependencies (useful for testing)
Future<void> resetDependencies() async {
  await sl.reset();
}

/// Check if dependencies are registered
bool get isDependenciesInitialized => sl.isRegistered<CanvasApiClient>();