import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/luxury_theme.dart';
import 'screens/splash_screen.dart';

class VelouraApp extends StatelessWidget {
  const VelouraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: LuxuryColors.black,
      primaryColor: LuxuryColors.gold,
      colorScheme: const ColorScheme.dark(
        primary: LuxuryColors.gold,
        secondary: LuxuryColors.gold2,
        surface: LuxuryColors.card,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: LuxuryColors.text,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: LuxuryColors.gold,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Veloura',
      theme: theme,
      home: VelouraSplashScreen(
        nextScreen: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: theme,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
