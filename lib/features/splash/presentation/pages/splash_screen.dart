import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kpass/app/theme.dart';
import 'package:kpass/app/routes.dart';
import 'package:kpass/features/auth/presentation/providers/auth_provider.dart';
import 'package:kpass/features/auth/presentation/screens/login_screen.dart';
import 'package:kpass/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:kpass/shared/widgets/proxy_connection_error_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();

    // Listen to auth state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  void _checkAuthState() {
    final authProvider = context.read<AuthProvider>();

    // If already initialized, navigate immediately
    if (!authProvider.isInitializing) {
      _navigateToNextScreen();
      return;
    }

    // Set a timeout to prevent infinite loading
    Timer(const Duration(seconds: 15), () {
      if (mounted && authProvider.isInitializing) {
        if (kDebugMode) {
          debugPrint('SplashScreen: Initialization timeout reached');
        }
        _navigateToNextScreen();
      }
    });

    // Otherwise, listen for initialization completion
    void listener() {
      if (!authProvider.isInitializing && mounted) {
        authProvider.removeListener(listener);
        _navigateToNextScreen();
      }
    }

    authProvider.addListener(listener);
  }

  void _navigateToNextScreen() {
    if (_hasNavigated) return;
    _hasNavigated = true;

    final authProvider = context.read<AuthProvider>();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        if (authProvider.hasError) {
          // Show proxy connection error screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) => ProxyConnectionErrorWidget(
                    errorMessage: authProvider.errorMessage,
                    onRetry: () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(AppRoutes.splash);
                    },
                    onManualLogin: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                  ),
            ),
          );
        } else if (authProvider.isAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else {
          // No valid stored session found - this is normal for first-time users
          if (kDebugMode) {
            debugPrint(
              'SplashScreen: No valid stored session found, navigating to login',
            );
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo with Animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school,
                            size: 60,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // App Name
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        'KPass',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // App Subtitle
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        'Keio University K-LMS Client',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          letterSpacing: 1,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 64),

                // Loading Indicator
                if (authProvider.isInitializing)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
