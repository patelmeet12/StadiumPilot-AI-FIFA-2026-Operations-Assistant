import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/stadium_shell.dart';

class AccessibilityPage extends ConsumerWidget {
  const AccessibilityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // ADA Facility items
    final facilities = [
      _ADAFacility(
        title: 'Elevator West (Express Access)',
        location: 'Concourse Section 120 Lobby',
        icon: Icons.elevator,
        status: 'Operational',
        notes:
            'Provides ramped direct access to seating rows in levels 100-200. Fully equipped with braille numbers and vocal announcements.',
      ),
      _ADAFacility(
        title: 'Elevator East (Express Access)',
        location: 'Concourse Section 142 Lobby',
        icon: Icons.elevator,
        status: 'Operational',
        notes:
            'Accessible path connector. Operates with a dedicated lift host during match hours.',
      ),
      _ADAFacility(
        title: 'Low-Noise Sensory Room',
        location: 'Concourse Level 1, near Section 102',
        icon: Icons.hearing_disabled,
        status: 'Quiet Zone',
        notes:
            'Soundproofed safe space for neurodivergent fans, families with young children, and individuals experiencing sensory overload. Equipped with sensory toys, noise-canceling headphones, and weighted lap pads.',
      ),
      _ADAFacility(
        title: 'Primary ADA Medical Station',
        location: 'Section 112 Concourse Corridor',
        icon: Icons.local_hospital,
        status: 'Staffed 24/7',
        notes:
            'Immediate paramedic response. Wheelchair replacement tires, oxygen tanks, and low-level medical intervention available here.',
      ),
      _ADAFacility(
        title: 'ADA Accessible Family Restrooms',
        location: 'Concourse Section 115 & Section 230',
        icon: Icons.wc,
        status: '0m Queue',
        notes:
            'Equipped with automated sliding doors, adult changing tables, adjustable height sinks, and side-transfer grab rails.',
      ),
    ];

    return StadiumShell(
      currentPath: '/accessibility',
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accessibility Companion',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Personalized stadium facilities support, step-free navigation, and auditory/sensory assist desks.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Categories selection row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar navigation selector
                      Expanded(
                        flex: isWide ? 2 : 5,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Personalized ADA Guides',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildCategoryGuide(
                                  context,
                                  'Wheelchair & Mobility Assist',
                                  'Step-free gates (Gate A/D), elevator paths, seat-side service helpers, and flat thresholds.',
                                  Icons.accessible,
                                ),
                                const Divider(),
                                _buildCategoryGuide(
                                  context,
                                  'Sensory & Auditory Assist',
                                  'Low-noise zones, sensory kits checkout (available at Guest Services Sec 110), and real-time text broadcast transcripts.',
                                  Icons.volume_mute,
                                ),
                                const Divider(),
                                _buildCategoryGuide(
                                  context,
                                  'Visual Assistance Support',
                                  'High contrast interface mode, tactile paving paths, braille directories, and volunteer guidance protocols.',
                                  Icons.visibility,
                                ),
                                const Divider(),
                                _buildCategoryGuide(
                                  context,
                                  'Seniors & Families Desk',
                                  'Stroller check-in, golf cart shuttle service inside gate rings, and nursing pods locator.',
                                  Icons.family_restroom,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // List of facilities
                      if (isWide) const SizedBox(width: 24),
                      if (isWide)
                        Expanded(
                          flex: 3,
                          child: _buildFacilitiesList(facilities, theme),
                        ),
                    ],
                  );
                },
              ),

              // Mobile list view
              if (MediaQuery.of(context).size.width <= 900)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: _buildFacilitiesList(facilities, theme),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGuide(
    BuildContext context,
    String title,
    String desc,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {
          // Inform the user about features
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Semantic audio transcripts optimized for $title.'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilitiesList(List<_ADAFacility> list, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live ADA Facilities Directory',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final f = list[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      child: Icon(f.icon, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  f.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  f.status.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Location: ${f.location}',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            f.notes,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ADAFacility {
  final String title;
  final String location;
  final IconData icon;
  final String status;
  final String notes;

  _ADAFacility({
    required this.title,
    required this.location,
    required this.icon,
    required this.status,
    required this.notes,
  });
}
