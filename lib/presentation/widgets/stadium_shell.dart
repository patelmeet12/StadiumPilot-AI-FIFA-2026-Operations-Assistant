import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/local_dictionary.dart';
import '../../domain/entities/user_role.dart';
import '../providers/app_state_providers.dart';

class StadiumShell extends ConsumerWidget {
  final Widget child;
  final String currentPath;

  const StadiumShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRole = ref.watch(userRoleProvider);
    final activeLanguage = ref.watch(localeProvider);
    final activeTheme = ref.watch(themeModeProvider);
    final isEmergency = ref.watch(emergencyAlertProvider);
    final theme = Theme.of(context);

    // Filter menu items by role permissions
    final menuItems = [
      _NavData(
        path: '/dashboard',
        labelKey: 'dashboard',
        icon: Icons.dashboard,
        roles: UserRole.values,
      ),
      _NavData(
        path: '/navigation',
        labelKey: 'navigation',
        icon: Icons.navigation,
        roles: UserRole.values,
      ),
      _NavData(
        path: '/transport',
        labelKey: 'transport',
        icon: Icons.directions_transit,
        roles: UserRole.values,
      ),
      _NavData(
        path: '/accessibility',
        labelKey: 'accessibility',
        icon: Icons.accessibility_new,
        roles: UserRole.values,
      ),
      _NavData(
        path: '/volunteer',
        labelKey: 'role_volunteer',
        icon: Icons.assignment_turned_in,
        roles: [UserRole.volunteer, UserRole.organizer, UserRole.staff],
      ),
      _NavData(
        path: '/organizer',
        labelKey: 'role_organizer',
        icon: Icons.admin_panel_settings,
        roles: [UserRole.organizer, UserRole.staff],
      ),
    ];

    final filteredItems = menuItems.where((item) => item.roles.contains(activeRole)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.sports_soccer, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Text(
              LocalDictionary.translate('app_title', activeLanguage),
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
            ),
          ],
        ),
        actions: [
          // Language selector
          DropdownButton<String>(
            value: activeLanguage,
            dropdownColor: theme.cardColor,
            underline: const SizedBox(),
            icon: const Icon(Icons.language, color: Colors.white),
            onChanged: (lang) {
              if (lang != null) {
                ref.read(localeProvider.notifier).setLocale(lang);
              }
            },
            items: const [
              DropdownMenuItem(value: 'en', child: Text('EN ', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'es', child: Text('ES ', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'fr', child: Text('FR ', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'hi', child: Text('HI ', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'ar', child: Text('AR ', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'pt', child: Text('PT ', style: TextStyle(color: Colors.white))),
            ],
          ),
          const SizedBox(width: 8),
          
          // Role switcher dropdown directly in header
          DropdownButton<UserRole>(
            value: activeRole,
            dropdownColor: theme.brightness == Brightness.dark 
                ? const Color(0xFF0F261B) 
                : Colors.white,
            underline: const SizedBox(),
            icon: Icon(Icons.person, color: theme.colorScheme.secondary),
            onChanged: (role) {
              if (role != null) {
                ref.read(userRoleProvider.notifier).setRole(role);
              }
            },
            items: UserRole.values.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(
                  LocalDictionary.translate(
                    role == UserRole.fan 
                        ? 'role_fan' 
                        : role == UserRole.volunteer 
                            ? 'role_volunteer' 
                            : role == UserRole.organizer 
                                ? 'role_organizer' 
                                : 'role_staff',
                    activeLanguage,
                  ),
                  style: TextStyle(
                    color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),

          // High Contrast accessibility toggle
          IconButton(
            tooltip: 'Contrast Toggle',
            icon: Icon(
              activeTheme == AppThemeMode.highContrast 
                  ? Icons.visibility_off 
                  : Icons.accessibility_new,
              color: Colors.white,
            ),
            onPressed: () {
              if (activeTheme == AppThemeMode.highContrast) {
                ref.read(themeModeProvider.notifier).setTheme(AppThemeMode.dark);
              } else {
                ref.read(themeModeProvider.notifier).setTheme(AppThemeMode.highContrast);
              }
            },
          ),

          // Theme toggle (Dark / Light)
          if (activeTheme != AppThemeMode.highContrast)
            IconButton(
              icon: Icon(
                activeTheme == AppThemeMode.dark 
                    ? Icons.wb_sunny 
                    : Icons.brightness_3,
                color: Colors.white,
              ),
              onPressed: () {
                ref.read(themeModeProvider.notifier).setTheme(
                  activeTheme == AppThemeMode.dark 
                      ? AppThemeMode.light 
                      : AppThemeMode.dark,
                );
              },
            ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: LayoutBuilder(
        builder: (context, constraints) {
          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        LocalDictionary.translate('app_title', activeLanguage),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Role: ${activeRole.displayName}',
                        style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                ...filteredItems.map((item) => ListTile(
                  leading: Icon(item.icon, color: currentPath == item.path ? theme.colorScheme.primary : null),
                  title: Text(
                    LocalDictionary.translate(item.labelKey, activeLanguage),
                    style: TextStyle(
                      fontWeight: currentPath == item.path ? FontWeight.bold : null,
                    ),
                  ),
                  selected: currentPath == item.path,
                  onTap: () {
                    Navigator.pop(context);
                    context.go(item.path);
                  },
                )),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.switch_account),
                  title: const Text('Change Portal / Log Out'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/');
                  },
                ),
              ],
            ),
          );
        }
      ),
      body: Column(
        children: [
          // Emergency Instruction Banner
          if (isEmergency)
            Container(
              width: double.infinity,
              color: theme.colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        LocalDictionary.translate('emergency_alert', activeLanguage),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    LocalDictionary.translate('emergency_msg', activeLanguage),
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          
          // Main layout content split responsive
          Expanded(
            child: Row(
              children: [
                // Desktop navigation rail (sidebar)
                if (MediaQuery.of(context).size.width > 900)
                  Container(
                    width: 250,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: theme.dividerColor,
                          width: activeTheme == AppThemeMode.highContrast ? 2.0 : 0.5,
                        ),
                      ),
                      color: theme.cardTheme.color ?? theme.cardColor,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Profile Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                radius: 20,
                                child: Text(activeRole.displayName[0]),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activeRole.displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: activeTheme == AppThemeMode.highContrast 
                                            ? Colors.yellow 
                                            : theme.textTheme.titleLarge?.color,
                                      ),
                                    ),
                                    const Text('FIFA 2026 Crew', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Menu items
                        Expanded(
                          child: ListView(
                            children: filteredItems.map((item) {
                              final isSelected = currentPath == item.path;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: isSelected 
                                      ? theme.colorScheme.primary.withOpacity(0.15) 
                                      : Colors.transparent,
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    item.icon,
                                    color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color,
                                  ),
                                  title: Text(
                                    LocalDictionary.translate(item.labelKey, activeLanguage),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected 
                                          ? theme.colorScheme.primary 
                                          : theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  onTap: () => context.go(item.path),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        
                        // Bottom Log Out Option
                        const Divider(),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.exit_to_app, color: Colors.grey),
                          title: const Text('Change Portal', style: TextStyle(color: Colors.grey)),
                          onTap: () => context.go('/'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                
                // Active workspace page
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
      
      // Bottom navigation bar for mobile devices
      bottomNavigationBar: MediaQuery.of(context).size.width <= 900
          ? BottomNavigationBar(
              currentIndex: filteredItems.indexWhere((item) => item.path == currentPath) == -1 
                  ? 0 
                  : filteredItems.indexWhere((item) => item.path == currentPath),
              type: BottomNavigationBarType.fixed,
              backgroundColor: theme.appBarTheme.backgroundColor,
              selectedItemColor: theme.colorScheme.secondary,
              unselectedItemColor: Colors.white70,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              items: filteredItems.map((item) {
                return BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  label: LocalDictionary.translate(item.labelKey, activeLanguage),
                );
              }).toList(),
              onTap: (index) {
                if (index >= 0 && index < filteredItems.length) {
                  context.go(filteredItems[index].path);
                }
              },
            )
          : null,
    );
  }
}

class _NavData {
  final String path;
  final String labelKey;
  final IconData icon;
  final List<UserRole> roles;

  _NavData({
    required this.path,
    required this.labelKey,
    required this.icon,
    required this.roles,
  });
}
