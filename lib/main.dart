// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'core/router/app_router.dart';
// import 'core/theme/app_theme.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   SystemChrome.setSystemUIOverlayStyle(
//     const SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: Brightness.light,
//     ),
//   );

//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//   ]);

//   runApp(
//     const ProviderScope(
//       child: YogyaApp(),
//     ),
//   );
// }

// class YogyaApp extends ConsumerWidget {
//   const YogyaApp({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final router = ref.watch(routerProvider);
//     return MaterialApp.router(
//       title: 'Yogya',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.lightTheme,
//       darkTheme: AppTheme.darkTheme,
//       themeMode: ThemeMode.dark,
//       routerConfig: router,
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_core/firebase_core.dart';
// // import 'package:hive_flutter/hive_flutter.dart';
// import 'firebase_options.dart';
// import 'core/router/app_router.dart';
// import 'core/theme/app_theme.dart';
// import 'data/local/hive_service.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // ── Firebase init ─────────────────────────────────────
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   // ── Hive init (Sprint 2 mein boxes register karenge) ──
//   // await Hive.initFlutter();

//   // Naya (adapters bhi register hote hain):
//   await HiveService.init();

//   // ── System UI ─────────────────────────────────────────
//   SystemChrome.setSystemUIOverlayStyle(
//     const SystemUiOverlayStyle(
//       statusBarColor:           Colors.transparent,
//       statusBarIconBrightness:  Brightness.light,
//     ),
//   );

//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//   ]);

//   runApp(
//     const ProviderScope(
//       child: YogyaApp(),
//     ),
//   );
// }

// class YogyaApp extends ConsumerWidget {
//   const YogyaApp({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final router = ref.watch(routerProvider);

//     return MaterialApp.router(
//       title:                    'Yogya',
//       debugShowCheckedModeBanner: false,
//       theme:                    AppTheme.lightTheme,
//       darkTheme:                AppTheme.darkTheme,
//       themeMode:                ThemeMode.dark,
//       routerConfig:             router,
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/local/hive_service.dart';
import 'presentation/providers/profile_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'core/services/notification_service.dart';

void main() async {
  print('🚀 UNBLOCKING STARTUP...');
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('📦 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    print('✅ Firebase Ready');
  } catch (e) {
    print('❌ Firebase Init Failed/Timed out: $e');
  }

  // Notification service handles its own errors and shouldn't block main
  print('🔔 Initializing Notifications...');
  NotificationService.instance.initialize().catchError((e) => print('❌ Notification Error: $e'));

  try {
    print('🗄️ Initializing Hive...');
    await HiveService.init().timeout(const Duration(seconds: 8));
    print('✅ Hive Ready');
  } catch (e) {
    print('❌ Hive Init Failed/Timed out: $e');
    // We already have a try/catch inside HiveService.init, 
    // but this catch ensures main() doesn't hang.
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  print('📱 Launching App...');
  runApp(
    const ProviderScope(
      child: YogyaApp(),
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

    // Profile load karo on app start
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
