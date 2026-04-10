import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/config/theme.dart';
import 'core/config/router.dart';
import 'core/services/analytics_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/worker/presentation/bloc/worker_onboarding_bloc.dart';
import 'injection_container.dart';

/// Main application widget
class HelaServiceApp extends StatefulWidget {
  const HelaServiceApp({super.key});

  @override
  State<HelaServiceApp> createState() => _HelaServiceAppState();
}

class _HelaServiceAppState extends State<HelaServiceApp> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize all async services
    await initServices();
  }

  @override
  Widget build(BuildContext context) {
    // Lock to portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<WorkerOnboardingBloc>()),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel(sl())),
        ],
        child: MaterialApp.router(
          title: 'HelaService',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light, // Force light mode for v1
          routerConfig: appRouter,
          builder: (context, child) {
            // Add error boundary
            ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
              return Material(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Something went wrong',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorDetails.exception.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            };
            return child!;
          },
        ),
      ),
    );
  }
}

/// Route observer for analytics
class AnalyticsRouteObserver extends NavigatorObserver {
  final AnalyticsService _analytics;

  AnalyticsRouteObserver(this._analytics);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      _analytics.logScreenView(screenName: route.settings.name!);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      _analytics.logScreenView(screenName: newRoute!.settings.name!);
    }
  }
}
