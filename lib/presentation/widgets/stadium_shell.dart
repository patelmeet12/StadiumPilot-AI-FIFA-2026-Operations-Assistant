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

    final filteredItems = menuItems
        .where((item) => item.roles.contains(activeRole))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.sports_soccer, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                LocalDictionary.translate('app_title', activeLanguage),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
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
              DropdownMenuItem(
                value: 'en',
                child: Text('EN ', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: 'es',
                child: Text('ES ', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: 'fr',
                child: Text('FR ', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: 'hi',
                child: Text('HI ', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: 'ar',
                child: Text('AR ', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: 'pt',
                child: Text('PT ', style: TextStyle(color: Colors.white)),
              ),
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
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
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
                ref
                    .read(themeModeProvider.notifier)
                    .setTheme(AppThemeMode.dark);
              } else {
                ref
                    .read(themeModeProvider.notifier)
                    .setTheme(AppThemeMode.highContrast);
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
                ref
                    .read(themeModeProvider.notifier)
                    .setTheme(
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
                  decoration: BoxDecoration(color: theme.colorScheme.primary),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        LocalDictionary.translate('app_title', activeLanguage),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Role: ${activeRole.displayName}',
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ...filteredItems.map(
                  (item) => ListTile(
                    leading: Icon(
                      item.icon,
                      color: currentPath == item.path
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    title: Text(
                      LocalDictionary.translate(item.labelKey, activeLanguage),
                      style: TextStyle(
                        fontWeight: currentPath == item.path
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                    selected: currentPath == item.path,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(item.path);
                    },
                  ),
                ),
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
        },
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
                        LocalDictionary.translate(
                          'emergency_alert',
                          activeLanguage,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    LocalDictionary.translate('emergency_msg', activeLanguage),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.3,
                    ),
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
                          width: activeTheme == AppThemeMode.highContrast
                              ? 2.0
                              : 0.5,
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
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
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
                                        color:
                                            activeTheme ==
                                                AppThemeMode.highContrast
                                            ? Colors.yellow
                                            : theme.textTheme.titleLarge?.color,
                                      ),
                                    ),
                                    const Text(
                                      'FIFA 2026 Crew',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
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
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: isSelected
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: 0.15,
                                        )
                                      : Colors.transparent,
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    item.icon,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.iconTheme.color,
                                  ),
                                  title: Text(
                                    LocalDictionary.translate(
                                      item.labelKey,
                                      activeLanguage,
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
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
                          leading: const Icon(
                            Icons.exit_to_app,
                            color: Colors.grey,
                          ),
                          title: const Text(
                            'Change Portal',
                            style: TextStyle(color: Colors.grey),
                          ),
                          onTap: () => context.go('/'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                // Active workspace page
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),

      // Bottom navigation bar for mobile devices
      bottomNavigationBar: MediaQuery.of(context).size.width <= 900
          ? BottomNavigationBar(
              currentIndex:
                  filteredItems.indexWhere(
                        (item) => item.path == currentPath,
                      ) ==
                      -1
                  ? 0
                  : filteredItems.indexWhere(
                      (item) => item.path == currentPath,
                    ),
              type: BottomNavigationBarType.fixed,
              backgroundColor: theme.appBarTheme.backgroundColor,
              selectedItemColor: theme.colorScheme.secondary,
              unselectedItemColor: Colors.white70,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              items: filteredItems.map((item) {
                return BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  label: LocalDictionary.translate(
                    item.labelKey,
                    activeLanguage,
                  ),
                );
              }).toList(),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.psychology),
        label: const Text(
          'AI Pilot',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAIChatbot(context, activeLanguage, activeRole),
      ),
    );
  }

  void _showAIChatbot(BuildContext context, String lang, UserRole role) {
    final theme = Theme.of(context);
    final Map<String, Map<String, String>> localChatDict = {
      'en': {
        'title': 'AI Operational Assistant',
        'placeholder': 'Ask StadiumPilot AI...',
        'welcome_fan':
            'Welcome to StadiumPilot AI. Ask me about your match ticket, recommended arrival times, queue bypasses, navigation routes, or transportation!',
        'welcome_volunteer':
            'Volunteer AI Assist ready. Ask me about your tasks, how to report incidents, check facility operations, or evacuation instructions.',
        'welcome_organizer':
            'Operations Desk Console AI active. Ask me about gate density limits, dispatching volunteers, or emergency protocols.',
        'send': 'Send',
      },
      'es': {
        'title': 'Asistente Operativo de IA',
        'placeholder': 'Pregunta a StadiumPilot AI...',
        'welcome_fan':
            'Bienvenido a StadiumPilot AI. ¡Pregúntame sobre tu boleto, tiempos de llegada recomendados, desvíos de colas, rutas de navegación o transporte!',
        'welcome_volunteer':
            'Asistencia de IA de voluntariado lista. Pregúntame sobre tus tareas, cómo informar incidentes o instrucciones de evacuación.',
        'welcome_organizer':
            'IA de Consola activa. Pregúntame sobre límites de densidad de puertas, despacho de voluntarios o protocolos de emergencia.',
        'send': 'Enviar',
      },
      'fr': {
        'title': 'Assistant Opérationnel IA',
        'placeholder': 'Demandez à StadiumPilot IA...',
        'welcome_fan':
            'Bienvenue sur StadiumPilot IA. Posez-moi des questions sur vos billets, heures d\'arrivée, contournement de files, itinéraires ou transports !',
        'welcome_volunteer':
            'IA d\'aide aux bénévoles prête. Interrogez-moi sur vos tâches, signalements d\'incidents ou consignes d\'évacuation.',
        'welcome_organizer':
            'IA de la console des opérations active. Posez des questions sur le flux des portes, affectation des bénévoles ou protocoles d\'urgence.',
        'send': 'Envoyer',
      },
      'hi': {
        'title': 'एआई संचालन सहायक',
        'placeholder': 'StadiumPilot AI से पूछें...',
        'welcome_fan':
            'StadiumPilot AI में आपका स्वागत है। मुझसे अपने टिकट, अनुशंसित आगमन समय, कतार बाईपास, मार्ग या परिवहन के बारे में पूछें!',
        'welcome_volunteer':
            'स्वयंसेवक एआई सहायता तैयार है। अपने कार्यों, घटनाओं की रिपोर्ट करने या निकासी निर्देशों के बारे में पूछें।',
        'welcome_organizer':
            'ऑपरेशन्स डेस्क कंसोल एआई सक्रिय है। गेट घनत्व सीमा, स्वयंसेवकों को भेजने, या आपातकालीन प्रोटोकॉल के बारे में पूछें।',
        'send': 'भेजें',
      },
      'ar': {
        'title': 'مساعد العمليات الذكي',
        'placeholder': 'اسأل مساعد الذكاء الاصطناعي...',
        'welcome_fan':
            'مرحباً بك في StadiumPilot AI. اسألني عن تذكرتك، أو أوقات الوصول الموصى بها، أو تجاوز الطوابير، أو مسارات التنقل، أو وسائل النقل!',
        'welcome_volunteer':
            'مساعد المتطوعين الذكي جاهز. اسألني عن مهامك، أو كيفية الإبلاغ عن الحوادث، أو تعليمات الإخلاء.',
        'welcome_organizer':
            'مساعد لوحة التحكم التشغيلية نشط. اسألني عن حدود كثافة البوابات، أو إرسال المتطوعين، أو بروتوكولات الطوارئ.',
        'send': 'إرسال',
      },
      'pt': {
        'title': 'Assistente Operacional IA',
        'placeholder': 'Pergunte ao StadiumPilot IA...',
        'welcome_fan':
            'Bem-vindo ao StadiumPilot IA. Pergunte-me sobre seu ingresso, horários de chegada recomendados, desvios de filas, rotas ou transporte!',
        'welcome_volunteer':
            'Assistência de IA de voluntários pronta. Pergunte-me sobre suas tarefas, como relatar incidentes ou instruções de evacuação.',
        'welcome_organizer':
            'IA do console de operações ativa. Pergunte sobre densidade de portões, despacho de voluntários ou protocolos de emergência.',
        'send': 'Enviar',
      },
    };
    final t = localChatDict[lang] ?? localChatDict['en']!;
    final welcome = role == UserRole.organizer
        ? t['welcome_organizer']!
        : role == UserRole.volunteer
        ? t['welcome_volunteer']!
        : t['welcome_fan']!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _AIChatWidget(
          lang: lang,
          welcomeMessage: welcome,
          title: t['title']!,
          placeholder: t['placeholder']!,
          sendLabel: t['send']!,
          theme: theme,
        );
      },
    );
  }
}

class _AIChatWidget extends StatefulWidget {
  final String lang;
  final String welcomeMessage;
  final String title;
  final String placeholder;
  final String sendLabel;
  final ThemeData theme;

  const _AIChatWidget({
    required this.lang,
    required this.welcomeMessage,
    required this.title,
    required this.placeholder,
    required this.sendLabel,
    required this.theme,
  });

  @override
  State<_AIChatWidget> createState() => _AIChatWidgetState();
}

class _AIChatWidgetState extends State<_AIChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messages.add({'sender': 'ai', 'text': widget.welcomeMessage});
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _controller.clear();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final reply = _generateAIReply(text, widget.lang);
      setState(() {
        _messages.add({'sender': 'ai', 'text': reply});
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  String _generateAIReply(String query, String lang) {
    final q = query.toLowerCase();

    if (q.contains('ticket') ||
        q.contains('boleto') ||
        q.contains('billet') ||
        q.contains('टिकट') ||
        q.contains('تذكر') ||
        q.contains('ingresso')) {
      if (lang == 'es') {
        return 'StadiumPilot AI (95% de confianza): Su boleto para Argentina vs Francia está confirmado en la Sección 128, Fila N, Asiento 12. Se recomienda ingresar por la Puerta C a las 18:30 para evitar controles.';
      } else if (lang == 'fr') {
        return 'StadiumPilot IA (Confiance 95%) : Votre billet pour Argentine vs France est validé dans la Section 128, Rangée N, Siège 12. L\'entrée recommandée est la Porte C à 18h30.';
      } else if (lang == 'hi') {
        return 'StadiumPilot AI (95% विश्वास स्तर): अर्जेंटीना बनाम फ्रांस के लिए आपका टिकट सेक्शन 128, पंक्ति N, सीट 12 पर पुष्ट है। भीड़ से बचने के लिए शाम 18:30 बजे गेट C से प्रवेश करें।';
      } else if (lang == 'ar') {
        return 'StadiumPilot AI (ثقة 95٪): تم تأكيد تذكرتك لمباراة الأرجنتين ضد فرنسا في القسم 128، الصف N، المقعد 12. يوصى بالدخول عبر البوابة C الساعة 18:30.';
      } else if (lang == 'pt') {
        return 'StadiumPilot IA (95% de confiança): Seu ingresso para Argentina vs França está confirmado na Seção 128, Fileira N, Assento 12. Recomenda-se a entrada pelo Portão C às 18h30.';
      }
      return 'StadiumPilot AI (95% confidence): Your ticket for Argentina vs France is confirmed in Section 128, Row N, Seat 12. Recommended entry is via Gate C at 18:30 to bypass congested checkpoints.';
    }

    if (q.contains('route') ||
        q.contains('navigate') ||
        q.contains('ruta') ||
        q.contains('ir a') ||
        q.contains('मार्ग') ||
        q.contains('مسار') ||
        q.contains('caminho')) {
      if (lang == 'es') {
        return 'StadiumPilot AI (98% de confianza): La ruta más rápida es a través de la explanada norte. Si necesita una ruta sin escalones, active el modo Silla de ruedas para usar los ascensores del sector oeste.';
      } else if (lang == 'fr') {
        return 'StadiumPilot IA (Confiance 98%) : L\'itinéraire le plus rapide passe par l\'esplanade Nord. Si vous avez besoin d\'un accès PMR, activez le mode Fauteuil Roulant.';
      } else if (lang == 'hi') {
        return 'StadiumPilot AI (98% विश्वास स्तर): सबसे तेज़ मार्ग उत्तरी एस्प्लेनेड के माध्यम से है। यदि आपको सीढ़ी-मुक्त मार्ग की आवश्यकता है, तो पश्चिमी लिफ्ट का उपयोग करने के लिए व्हीलचेयर अनुकूल मोड सक्रिय करें।';
      } else if (lang == 'ar') {
        return 'StadiumPilot AI (ثقة 98٪): المسار الأسرع هو عبر الساحة الشمالية. إذا كنت بحاجة إلى مسار خالٍ من السلالم، يرجى تفعيل وضع الكراسي المتحركة لاستخدام المصاعد الغربية.';
      } else if (lang == 'pt') {
        return 'StadiumPilot IA (98% de confiança): A rota mais rápida é pela esplanada norte. Se precisar de acessibilidade sem degraus, ative o modo Cadeira de Rodas.';
      }
      return 'StadiumPilot AI (98% confidence): The fastest route is via the North Esplanade. If you need step-free access, enable Wheelchair-friendly mode to prioritize elevator shafts in the West corridor.';
    }

    if (q.contains('food') ||
        q.contains('eat') ||
        q.contains('comida') ||
        q.contains('concession') ||
        q.contains('खा') ||
        q.contains('طعام') ||
        q.contains('restaurante')) {
      return 'StadiumPilot AI (94% confidence): Food Court A has a 20-minute wait. AI suggests ordering from Concession C (Zone G) where wait time is currently under 4 minutes. You will save approximately 16 minutes.';
    }

    if (q.contains('metro') ||
        q.contains('bus') ||
        q.contains('transit') ||
        q.contains('transport') ||
        q.contains('परिवहन') ||
        q.contains('حافلة') ||
        q.contains('مترو') ||
        q.contains('trânsito')) {
      return 'StadiumPilot AI (97% confidence): Express Metro Line 1 is operating with 3m frequencies. Parking Lots are at 92% capacity. Taking the Metro reduces carbon footprint by 84% compared to ride-sharing.';
    }

    if (q.contains('incident') ||
        q.contains('spill') ||
        q.contains('medical') ||
        q.contains('घटना') ||
        q.contains('حادث') ||
        q.contains('spills')) {
      return 'StadiumPilot AI Dispatch: Active incident (Spill in Sec 104 Corridor) has been assigned to Volunteer Zone B. Staff is en-route. Use the Organizer console to dispatch additional personnel.';
    }

    if (q.contains('emergency') ||
        q.contains('evacuate') ||
        q.contains('safety') ||
        q.contains('आपात') ||
        q.contains('طوارئ') ||
        q.contains('segurança')) {
      return 'StadiumPilot AI Emergency Protocol: Evacuate calmly. Proceed to nearest illuminated green exit signage. Avoid lift shafts. Follow instructions from Zone A/B Volunteer leaders.';
    }

    if (q.contains('accessibility') ||
        q.contains('elevator') ||
        q.contains('wheelchair') ||
        q.contains('सुगमता') ||
        q.contains('سهولة') ||
        q.contains('acessib')) {
      return 'StadiumPilot AI (99% confidence): Elevator shafts East & West are fully operational. Accessibility golf cart loops are running. Low-noise sensory rooms are available in Zones C and G.';
    }

    if (lang == 'es') {
      return 'StadiumPilot AI (91% de confianza): Registrando métricas en tiempo real. Intente preguntar acerca de "boleto", "rutas rápidas", "tiempo de cola de comida" o "líneas de metro".';
    } else if (lang == 'fr') {
      return 'StadiumPilot IA (Confiance 91%) : Télémétrie en cours. Posez des questions sur "billet", "itinéraires d\'accès", "attente nourriture" ou "lignes de métro".';
    } else if (lang == 'hi') {
      return 'StadiumPilot AI (91% विश्वास स्तर): मैं लाइव टेलीमेट्री ट्रैक कर रहा हूँ। कृपया "टिकट", "नेविगेशन मार्ग", "भोजन कतार समय" या "मेट्रो कनेक्शन" के बारे में पूछें।';
    } else if (lang == 'ar') {
      return 'StadiumPilot AI (ثقة 91٪): تتبع القياسات المباشرة. حاول السؤال عن "التذاكر"، أو "مسارات الملاحة السريعة"، أو "طوابير الطعام"، أو "خطوط المترو".';
    } else if (lang == 'pt') {
      return 'StadiumPilot IA (91% de confiança): Rastreando dados da arena. Tente perguntar sobre "ingresso", "melhores rotas", "filas de alimentação" ou "linhas de metrô".';
    }
    return 'StadiumPilot AI (91% confidence): Currently tracking live tournament telemetry. Try asking me about "ticket info", "navigation routes", "concessions queue", or "metro connections".';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.psychology, color: widget.theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAI = msg['sender'] == 'ai';
                return Align(
                  alignment: isAI
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isAI
                          ? (widget.theme.brightness == Brightness.dark
                                ? Colors.grey.shade900
                                : Colors.grey.shade200)
                          : widget.theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12).copyWith(
                        topLeft: isAI
                            ? const Radius.circular(0)
                            : const Radius.circular(12),
                        topRight: isAI
                            ? const Radius.circular(12)
                            : const Radius.circular(0),
                      ),
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isAI
                            ? (widget.theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87)
                            : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _sendMessage,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    widget.sendLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
