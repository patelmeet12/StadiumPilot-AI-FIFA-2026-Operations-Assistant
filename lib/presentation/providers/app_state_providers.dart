import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/secure_storage_service.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/stadium_repository.dart';
import '../../data/repositories/stadium_repository_impl.dart';

// Provider for SharedPreferences - initialized at startup
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    "Initialize SharedPreferences in main and override this provider",
  );
});

// Provider for SecureStorageService
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SecureStorageService(prefs);
});

// Provider for StadiumRepository
final stadiumRepositoryProvider = Provider<StadiumRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StadiumRepositoryImpl(prefs);
});

// User role management provider
class UserRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() {
    final secureStorage = ref.watch(secureStorageProvider);
    final saved = secureStorage.read('sp_user_role');
    if (saved != null) {
      return UserRole.values.firstWhere(
        (r) => r.name == saved,
        orElse: () => UserRole.fan,
      );
    }
    return UserRole.fan;
  }

  Future<void> setRole(UserRole role) async {
    if (state == role) return;
    state = role;
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.write('sp_user_role', role.name);
  }
}

final userRoleProvider = NotifierProvider<UserRoleNotifier, UserRole>(() {
  return UserRoleNotifier();
});

// Locale translation management provider
class LocaleNotifier extends Notifier<String> {
  @override
  String build() {
    final secureStorage = ref.watch(secureStorageProvider);
    return secureStorage.read('sp_locale') ?? 'en';
  }

  Future<void> setLocale(String langCode) async {
    if (state == langCode) return;
    state = langCode;
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.write('sp_locale', langCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, String>(() {
  return LocaleNotifier();
});

// Theme management supporting Light, Dark, and High Contrast
enum AppThemeMode { light, dark, highContrast }

class ThemeModeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    final secureStorage = ref.watch(secureStorageProvider);
    final saved = secureStorage.read('sp_theme_mode');
    if (saved != null) {
      return AppThemeMode.values.firstWhere(
        (t) => t.name == saved,
        orElse: () => AppThemeMode.dark,
      );
    }
    return AppThemeMode.dark;
  }

  Future<void> setTheme(AppThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.write('sp_theme_mode', mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, AppThemeMode>(() {
  return ThemeModeNotifier();
});

// Global Emergency Broadcast Provider
class EmergencyAlertNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle(bool val) {
    state = val;
  }
}

final emergencyAlertProvider = NotifierProvider<EmergencyAlertNotifier, bool>(
  () {
    return EmergencyAlertNotifier();
  },
);
