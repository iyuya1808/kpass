import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:kpass/app/theme.dart';
import 'package:kpass/app/routes.dart';
import 'package:kpass/features/auth/presentation/providers/auth_provider.dart';
import 'package:kpass/features/courses/presentation/providers/courses_provider.dart';
import 'package:kpass/features/assignments/presentation/providers/assignments_provider.dart';
import 'package:kpass/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:kpass/features/notifications/presentation/providers/notification_provider.dart';
import 'package:kpass/features/settings/presentation/providers/settings_provider.dart';
import 'package:kpass/features/splash/presentation/pages/splash_screen.dart';
import 'package:kpass/l10n/app_localizations.dart';
import 'package:kpass/core/di/service_locator.dart';
import 'package:kpass/core/services/canvas_api_client.dart';
import 'package:kpass/core/services/proxy_api_client.dart';

class KPassApp extends StatelessWidget {
  const KPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create shared API client instances
    final canvasApiClient = CanvasApiClient();
    final proxyApiClient = ProxyApiClient();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => CoursesProvider(apiClient: canvasApiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => AssignmentsProvider(apiClient: canvasApiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => CalendarProvider(apiClient: proxyApiClient),
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider(sl(), sl())),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'KPass',
            debugShowCheckedModeBanner: false,

            // Theme Configuration
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProvider.themeMode,

            // Localization Configuration
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ja', ''), // Japanese (Default)
              Locale('en', ''), // English
            ],
            locale: settingsProvider.locale,

            // Routing Configuration
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,

            // Global Navigation Key for programmatic navigation
            navigatorKey: NavigationService.navigatorKey,

            // Builder for global error handling and loading states
            builder: (context, child) {
              return Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  // Show loading screen during app initialization
                  if (authProvider.isInitializing) {
                    return const MaterialApp(
                      home: SplashScreen(),
                      debugShowCheckedModeBanner: false,
                    );
                  }

                  return child ?? const SizedBox.shrink();
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Navigation Service for programmatic navigation
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  static Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return navigator!.pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return navigator!.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String newRouteName,
    bool Function(Route<dynamic>) predicate, {
    Object? arguments,
  }) {
    return navigator!.pushNamedAndRemoveUntil<T>(
      newRouteName,
      predicate,
      arguments: arguments,
    );
  }

  static void pop<T extends Object?>([T? result]) {
    navigator!.pop<T>(result);
  }

  static bool canPop() {
    return navigator!.canPop();
  }

  static void popUntil(bool Function(Route<dynamic>) predicate) {
    navigator!.popUntil(predicate);
  }
}
