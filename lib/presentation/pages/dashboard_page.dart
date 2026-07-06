import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/local_dictionary.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/ai_recommendation.dart';
import '../../domain/entities/crowd_state.dart';
import '../providers/app_state_providers.dart';
import '../providers/stadium_simulation_providers.dart';
import '../widgets/stadium_shell.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLanguage = ref.watch(localeProvider);
    final activeRole = ref.watch(userRoleProvider);
    final crowdState = ref.watch(crowdStateProvider);
    final recommendationsAsync = ref.watch(aiRecommendationsProvider);
    final theme = Theme.of(context);

    return StadiumShell(
      currentPath: '/dashboard',
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header + manual tick action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Operations Desk - ${activeRole.displayName}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Live telemetry streaming from FIFA MetLife Venue Control Center.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Simulate Telemetry Update', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          ref.read(crowdStateProvider.notifier).forceFluctuate();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Crowd sensor telemetry updated successfully.'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Reset Telemetry Data',
                        icon: const Icon(Icons.restore),
                        onPressed: () async {
                          final repo = ref.read(stadiumRepositoryProvider);
                          await repo.resetSimulator();
                          ref.read(crowdStateProvider.notifier).fetchCrowdState();
                          ref.read(incidentListProvider.notifier).fetchIncidents();
                          ref.read(volunteerTasksProvider.notifier).fetchTasks();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All data has been reset to defaults.')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Responsive grid layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  if (width > 1000) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMatchTicketCard(context),
                              const SizedBox(height: 24),
                              _buildDecisionEnginePanel(context, recommendationsAsync, activeLanguage),
                              const SizedBox(height: 24),
                              _buildQuickActionsRow(context, ref),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCrowdStatusPanel(context, crowdState, activeLanguage),
                              const SizedBox(height: 24),
                              _buildEcoScoreCard(context, activeLanguage),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildMatchTicketCard(context),
                        const SizedBox(height: 24),
                        _buildDecisionEnginePanel(context, recommendationsAsync, activeLanguage),
                        const SizedBox(height: 24),
                        _buildCrowdStatusPanel(context, crowdState, activeLanguage),
                        const SizedBox(height: 24),
                        _buildEcoScoreCard(context, activeLanguage),
                        const SizedBox(height: 24),
                        _buildQuickActionsRow(context, ref),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card 1: Ticket & Match Detail
  Widget _buildMatchTicketCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3), width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.12),
              theme.colorScheme.primary.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'FIFA MATCH TICKETS',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.qr_code, color: Colors.grey, size: 28),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Argentina vs France',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'New York New Jersey Stadium (MetLife) • Today 20:00 EST',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ticketField('GATE ENTRANCE', 'Gate B', theme.colorScheme.primary),
                _ticketField('SECTION', 'Sec 128', Colors.white),
                _ticketField('SEAT ROW', 'Row 14', Colors.white),
                _ticketField('STADIUM SEAT', 'Seat 8', Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ticketField(String label, String value, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold, 
            color: accentColor == Colors.white ? null : accentColor,
          ),
        ),
      ],
    );
  }

  // Card 2: AI Recommendations (Decision Engine)
  Widget _buildDecisionEnginePanel(
    BuildContext context, 
    AsyncValue<List<AIRecommendation>> asyncRecommendations,
    String lang,
  ) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: theme.colorScheme.secondary, size: 28),
                const SizedBox(width: 8),
                Text(
                  LocalDictionary.translate('recommendations', lang),
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bolt, color: Colors.green, size: 14),
                      Text('AI Live', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            asyncRecommendations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading recommendations: $err'),
              data: (recs) {
                if (recs.isEmpty) {
                  return const Text('All operations normal. No current anomalies detected.');
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recs.length,
                  separatorBuilder: (c, i) => const Divider(height: 20),
                  itemBuilder: (context, index) {
                    final r = recs[index];
                    Color priorityColor = Colors.grey;
                    if (r.priority == 'Critical') priorityColor = Colors.red;
                    if (r.priority == 'High') priorityColor = Colors.amber.shade800;
                    if (r.priority == 'Medium') priorityColor = Colors.blue;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: priorityColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                r.priority.toUpperCase(),
                                style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              r.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const Spacer(),
                            Text(
                              'Confidence: ${(r.confidenceLevel * 100).toInt()}%',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          r.recommendation,
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.w600, 
                            color: theme.colorScheme.primary == Colors.yellow ? Colors.yellow : theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r.reason,
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.flash_on, size: 12, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              'Benefit: ${r.estimatedBenefit}',
                              style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Card 3: Crowd status simulation
  Widget _buildCrowdStatusPanel(BuildContext context, CrowdState state, String lang) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.blue, size: 26),
                const SizedBox(width: 8),
                Text(
                  'Live Stadium Congestion',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Section 1: Gates wait times
            const Text('GATE CHECKPOINTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            ...state.gateWaitTimes.entries.map((e) {
              final val = e.value;
              final color = val >= 20 ? Colors.red : (val >= 10 ? Colors.amber : Colors.green);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13))),
                    Container(
                      width: 100,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (val / 30.0).clamp(0.05, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '$val mins',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            const Divider(height: 24),
            
            // Section 2: Concession lines
            const Text('FOOD COURTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            ...state.foodCourtWaitTimes.entries.map((e) {
              final val = e.value;
              final color = val >= 18 ? Colors.red : (val >= 10 ? Colors.amber : Colors.green);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                    Text(
                      '${val}m wait',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 24),

            // Section 3: Restrooms lines
            const Text('RESTROOM QUEUES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            ...state.restroomWaitTimes.entries.map((e) {
              final val = e.value;
              final color = val >= 12 ? Colors.red : (val >= 6 ? Colors.amber : Colors.green);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13))),
                    Text(
                      '$val mins',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Card 4: Eco Score & Carbon Savings (Sustainability)
  Widget _buildEcoScoreCard(BuildContext context, String lang) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.green, width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.green.withOpacity(0.04),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.eco, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Green Tournament score',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircularProgressIndicator(
                  value: 0.85,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '85/100 Eco Rating',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'You saved 4.2 kg of CO₂ by using public Metro instead of an individual taxi.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Row 5: Quick action buttons
  Widget _buildQuickActionsRow(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Control Desks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.report_problem),
                  label: const Text('Report Hazard / Incident'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                  onPressed: () => _showIncidentForm(context, ref),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.navigation),
                  label: const Text('Reroute Assist'),
                  onPressed: () => context.go('/navigation'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.directions_bus),
                  label: const Text('Transit Hub'),
                  onPressed: () => context.go('/transport'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.accessible),
                  label: const Text('Step-Free Hub'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  onPressed: () => context.go('/accessibility'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Dialogue for incident report form
  void _showIncidentForm(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    String title = '';
    String location = '';
    String category = 'Crowd';
    String priority = 'Medium';
    String desc = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.report_problem, color: Colors.deepOrange),
                  SizedBox(width: 8),
                  Text('Report Venue Incident'),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Short Title (e.g. Broken scan lane)'),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        onSaved: (val) => title = val ?? '',
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Location (e.g. Section 120 or Gate B outer)'),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        onSaved: (val) => location = val ?? '',
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: ['Medical', 'Crowd', 'Spill', 'Facility', 'Security']
                            .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (val) => setState(() => category = val ?? 'Crowd'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: priority,
                        decoration: const InputDecoration(labelText: 'Priority Level'),
                        items: ['Low', 'Medium', 'High', 'Critical']
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (val) => setState(() => priority = val ?? 'Medium'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Detailed Description'),
                        maxLines: 2,
                        onSaved: (val) => desc = val ?? '',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text('Submit Report'),
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      formKey.currentState?.save();
                      final newIncident = Incident(
                        id: const Uuid().v4(),
                        title: title,
                        category: category,
                        location: location,
                        priority: priority,
                        status: 'Open',
                        description: desc,
                        reportedTime: DateTime.now(),
                      );
                      
                      // Report incident and close
                      await ref.read(incidentListProvider.notifier).reportIncident(newIncident);
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Incident reported. Decision support engine updated.'),
                          backgroundColor: Colors.deepOrange,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
