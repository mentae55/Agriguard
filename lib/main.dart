import 'package:agriguard_project/features/splash/view/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/authentication/view_model/user_view_model.dart';
import 'features/connection_to_device/services/device_provider.dart';
import 'features/connection_to_device/view_model/connection_view_model.dart';
import 'core/widgets/global_connection_monitor.dart'; // [Added] global monitor
import 'features/chatbot/view_model/chatbot_view_model.dart';
import 'features/home/presentation/view/home_screen.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/localization/language_provider.dart';
import 'features/profile/controllers/profile_provider.dart';
import 'features/alerts/viewmodels/alerts_view_model.dart';
import 'features/home/data/repositories/soil_repository.dart';
import 'features/home/domain/usecases/fetch_soil_data.dart';
import 'features/device_settings/viewmodels/device_settings_view_model.dart';
import 'features/spectral/viewmodels/spectral_view_model.dart';
import 'features/spectral/viewmodels/spectral_history_view_model.dart';

import 'features/spectral/data/services/spectral_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SpectralNotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionViewModel()),
        ChangeNotifierProvider(create: (_) => ChatbotViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => AlertsViewModel()),
        ChangeNotifierProvider(
          create: (_) => DeviceSettingsViewModel(serial: '')..loadSettings(),
        ),
        ChangeNotifierProvider(create: (_) => SpectralViewModel()),
        ChangeNotifierProvider(create: (_) => SpectralHistoryViewModel()),
        Provider<SoilRepository>(
          create: (_) => SoilRepositoryImpl()..initialize(),
          dispose: (_, rep) => rep.dispose(),
        ),
        Provider<FetchSoilDataUseCase>(
          create: (ctx) => FetchSoilDataUseCase(repository: ctx.read<SoilRepository>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Consumer2<LanguageProvider, ThemeProvider>(
          builder: (context, languageProvider, themeProvider, _) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              builder: (context, child) {
             return GlobalConnectionMonitor(
               navigatorKey: navigatorKey,
               child: child!,
             );
          },
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              locale: languageProvider.currentLocale,
              supportedLocales: const [
                Locale('en'),
                Locale('ar'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              debugShowCheckedModeBanner: false,
              title: 'AgriGuard',
              home: const SplashScreen(),
            );
          }
        );
      },
    );
  }
}