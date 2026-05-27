import 'package:flutter/material.dart';
import '../../features/profile/presentation/profile_setup_screen.dart';
import 'core/router/app_router.dart';

class VelouraApp extends StatelessWidget {
  const VelouraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Veloura',
      theme: ThemeData.dark(),
      routerConfig: appRouter,
    );
  }
}