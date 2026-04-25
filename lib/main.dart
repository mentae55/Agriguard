import 'package:agriguard_project/core/core.dart';
import 'package:agriguard_project/features/splash/view/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/authentication/view_model/user_view_model.dart';
import 'features/connection_to_device/services/device_provider.dart';
import 'features/connection_to_device/view_model/connection_view_model.dart';
import 'core/widgets/global_connection_monitor.dart'; // [Added] global monitor
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionViewModel()),
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
        return MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) {
             return GlobalConnectionMonitor(
               navigatorKey: navigatorKey,
               child: child!,
             );
          },
          theme: ThemeData(primaryColor: primaryColor),
          debugShowCheckedModeBanner: false,
          title: 'AgriGuard',
          home: const SplashScreen(),
        );
      },
    );
  }
}