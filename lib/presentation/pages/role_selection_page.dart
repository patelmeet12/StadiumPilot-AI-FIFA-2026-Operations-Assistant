import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/local_dictionary.dart';
import '../../domain/entities/user_role.dart';
import '../providers/app_state_providers.dart';

class RoleSelectionPage extends ConsumerWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLanguage = ref.watch(localeProvider);
    final activeTheme = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    // Grid details for the roles
    final roles = [
      _RoleCardData(
        role: UserRole.fan,
        titleKey: 'role_fan',
        icon: Icons.sports_soccer,
        description:
            'Access ticket itineraries, smart navigation, food courts, and public transport guides.',
        color: const Color(0xFF00875A),
      ),
      _RoleCardData(
        role: UserRole.volunteer,
        titleKey: 'role_volunteer',
        icon: Icons.volunteer_activism,
        description:
            'Complete operational checklists, respond to nearby incidents, and assist organizers.',
        color: const Color(0xFF6366F1),
      ),
      _RoleCardData(
        role: UserRole.organizer,
        titleKey: 'role_organizer',
        icon: Icons.analytics,
        description:
            'Monitor heatmaps, gate capacity meters, incident consoles, and dispatch volunteers.',
        color: const Color(0xFFFFC72C),
      ),
      _RoleCardData(
        role: UserRole.staff,
        titleKey: 'role_staff',
        icon: Icons.shield,
        description:
            'Access venue control, trigger announcements, resolve facility emergencies, and manage security.',
        color: const Color(0xFFEF4444),
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.brightness == Brightness.dark
                  ? const Color(0xFF070D0A)
                  : const Color(0xFFE8F0EB),
              theme.brightness == Brightness.dark
                  ? const Color(0xFF0F261B)
                  : const Color(0xFFCBE2D4),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App branding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assistant_navigation,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        LocalDictionary.translate('app_title', activeLanguage),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 38,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.primary == Colors.yellow
                              ? Colors.yellow
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'FIFA World Cup 2026™ Operations Center',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 50),
                  Text(
                    LocalDictionary.translate('role_selection', activeLanguage),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please select your portal to proceed. You can switch roles at any time.',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Role cards grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: constraints.maxWidth > 700
                              ? 1.6
                              : 1.4,
                        ),
                        itemCount: roles.length,
                        itemBuilder: (context, index) {
                          final data = roles[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            elevation: 4,
                            child: InkWell(
                              onTap: () async {
                                await ref
                                    .read(userRoleProvider.notifier)
                                    .setRole(data.role);
                                if (!context.mounted) return;
                                context.go('/dashboard');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: data.color
                                              .withValues(alpha: 0.15),
                                          radius: 28,
                                          child: Icon(
                                            data.icon,
                                            size: 28,
                                            color: data.color,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.arrow_forward,
                                          color: theme.hintColor,
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      LocalDictionary.translate(
                                        data.titleKey,
                                        activeLanguage,
                                      ),
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontSize: 20,
                                            color:
                                                activeTheme ==
                                                    AppThemeMode.highContrast
                                                ? Colors.yellow
                                                : null,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      data.description,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(fontSize: 13, height: 1.4),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 50),

                  // Language selection bar at bottom of role select
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _langButton(ref, activeLanguage, 'en', 'English 🇬🇧'),
                      _langButton(ref, activeLanguage, 'es', 'Español 🇪🇸'),
                      _langButton(ref, activeLanguage, 'fr', 'Français 🇫🇷'),
                      _langButton(ref, activeLanguage, 'hi', 'हिन्दी 🇮🇳'),
                      _langButton(ref, activeLanguage, 'ar', 'العربية 🇸🇦'),
                      _langButton(ref, activeLanguage, 'pt', 'Português 🇧🇷'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _langButton(
    WidgetRef ref,
    String activeLang,
    String code,
    String label,
  ) {
    final isSelected = activeLang == code;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(localeProvider.notifier).setLocale(code);
        }
      },
    );
  }
}

class _RoleCardData {
  final UserRole role;
  final String titleKey;
  final IconData icon;
  final String description;
  final Color color;

  _RoleCardData({
    required this.role,
    required this.titleKey,
    required this.icon,
    required this.description,
    required this.color,
  });
}
