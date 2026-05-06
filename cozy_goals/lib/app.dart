import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/providers/app_providers.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/theme/app_theme.dart';

class CozyGoalsApp extends ConsumerWidget {
  const CozyGoalsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    return MaterialApp(
      title: 'Cozy Goals',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) {
          if (app.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (app.needsOnboarding) {
            return const OnboardingScreen();
          }
          return const HomeScreen();
        },
      ),
    );
  }
}
