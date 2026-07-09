
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/local/hive_service.dart';
import 'presentation/providers/profile_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'core/services/notification_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Firebase (non-blocking safe init)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Keep app alive even if firebase fails in debug/dev
  }

  // Hive init must complete before runApp
  await HiveService.init();

  // Notifications should not block startup
  NotificationService.instance.initialize().catchError((_) {});

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // ─── Sentry: Error tracking & performance monitoring ───
  final sentryDsn = dotenv.env['SENTRY_DSN'] ?? '';

  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
      // Production: 30% traces, 10% profiles (100% is too expensive at scale)
      options.tracesSampleRate = 0.3;
      options.profilesSampleRate = 0.1;
      options.environment = const String.fromEnvironment(
        'ENVIRONMENT',
        defaultValue: 'development',
      );
      options.release = 'yogya@1.0.0';
      options.attachScreenshot = true;
      options.sendDefaultPii = false; // Don't send personal data to Sentry
      // Capture all uncaught Flutter framework errors
      options.reportSilentFlutterErrors = true;
    },
    appRunner: () => runApp(
      SentryWidget(
        child: const ProviderScope(
          child: YogyaApp(),
        ),
      ),
    ),
  );
}

class YogyaApp extends ConsumerWidget {
  const YogyaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(appLocaleProvider);

    // Load profile on app start
    ref.watch(profileLoaderProvider);

    return MaterialApp.router(
      title: 'Yogya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}