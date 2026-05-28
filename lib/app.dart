import 'package:flutter/material.dart';
import '../../features/profile/presentation/profile_setup_screen.dart';
import 'core/router/app_router.dart';
import 'screens/splash_screen.dart';

class VelouraApp extends StatelessWidget {
  const VelouraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Veloura',
      theme: ThemeData.dark(),
      home: VelouraSplashScreen(
        nextScreen: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}