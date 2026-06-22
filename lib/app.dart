import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart'; // сгенерируется flutter gen-l10n
import 'core/i18n/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/luxury_theme.dart';
import 'screens/splash_screen.dart';

class VelouraApp extends ConsumerWidget {
  const VelouraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // null → следуем за языком телефона; иначе ручной выбор пользователя.
    final locale = ref.watch(localeControllerProvider);

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

    // Делегаты и список языков — общие для обоих MaterialApp.
    const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Veloura',
      theme: theme,
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      home: VeloSplashScreen(
        nextScreen: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: locale,
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}