import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/routing/app_router.dart';
import 'core/theme/theme.dart';
import 'presentation/providers/app_state_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const StadiumPilotApp(),
    ),
  );
}

class StadiumPilotApp extends ConsumerWidget {
  const StadiumPilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = ref.watch(themeModeProvider);

    ThemeData selectedTheme;
    switch (activeTheme) {
      case AppThemeMode.light:
        selectedTheme = AppTheme.lightTheme;
        break;
      case AppThemeMode.dark:
        selectedTheme = AppTheme.darkTheme;
        break;
      case AppThemeMode.highContrast:
        selectedTheme = AppTheme.highContrastTheme;
        break;
    }

    return MaterialApp.router(
      title: 'StadiumPilot AI - FIFA 2026 Operations Assistant',
      debugShowCheckedModeBanner: false,
      theme: selectedTheme,
      routerConfig: appRouter,
    );
  }
}
