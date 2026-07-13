import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/crowd_state.dart';
import '../providers/app_state_providers.dart';
import '../providers/stadium_simulation_providers.dart';
import '../widgets/stadium_shell.dart';

class OrganizerDashboardPage extends ConsumerWidget {
  const OrganizerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crowdState = ref.watch(crowdStateProvider);
    final incidents = ref.watch(incidentListProvider);
    final isEmergency = ref.watch(emergencyAlertProvider);
    final theme = Theme.of(context);

    // Heatmap statistics based on crowdState densities
    final zoneDensities = crowdState.zoneDensities;

    return StadiumShell(
      currentPath: '/organizer',
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tournament Organizer Console',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Live venue operations command center. Monitor structural flows, dispatch staff, and manage stadium-wide broadcasts.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Emergency trigger banner controls
              Card(
                color: isEmergency ? Colors.red.withValues(alpha: 0.12) : theme.cardTheme.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isEmergency ? Colors.red : Colors.grey.shade700, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.campaign, color: isEmergency ? Colors.red : Colors.grey, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Global Emergency Announcement Broadcast',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              isEmergency 
                                  ? 'ACTIVE: Multilingual evacuation guidelines are broadcasting across all user platforms.' 
                                  : 'INACTIVE: Venue operates under standard protocol.',
                              style: TextStyle(color: isEmergency ? Colors.red : Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isEmergency,
                        activeThumbColor: Colors.red,
                        onChanged: (val) {
                          ref.read(emergencyAlertProvider.notifier).toggle(val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(val ? 'Emergency broadcast initiated.' : 'Emergency broadcast terminated.'),
                              backgroundColor: val ? Colors.red : Colors.green,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Heatmap grid and Gate telemetry
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Heatmap
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stadium Flow Heatmap',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            _buildHeatmapGrid(zoneDensities, theme),
                            const SizedBox(height: 24),
                            _buildOperationalInsightsCard(crowdState, theme),
                          ],
                        ),
                      ),

                      if (isWide) const SizedBox(width: 24),

                      // Section 2: Gate capacities
                      Expanded(
                        flex: isWide ? 2 : 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gate Entrance Load Analysis',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            _buildGateOccupancyCard(crowdState.gateWaitTimes, theme),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Incident log board
              const Text(
                'Live Incident Dispatch Desk',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              _buildIncidentsTable(context, ref, incidents, theme),
            ],
          ),
        ),
      ),
    );
  }

  // Visual representation of sections using colored containers
  Widget _buildHeatmapGrid(Map<String, double> densities, ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.0,
      ),
      itemCount: densities.length,
      itemBuilder: (context, index) {
        final entry = densities.entries.elementAt(index);
        final density = entry.value;
        Color gridColor = Colors.green;
        if (density >= 0.8) {
          gridColor = Colors.red;
        } else if (density >= 0.6) {
          gridColor = Colors.amber;
        }
        
        return Container(
          decoration: BoxDecoration(
            color: gridColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: gridColor, width: 2),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Density Coefficient: ${(density * 100).toInt()}%',
                    style: TextStyle(color: gridColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Icon(
                    density >= 0.8 
                        ? Icons.warning 
                        : (density >= 0.6 ? Icons.info_outline : Icons.check_circle_outline),
                    color: gridColor,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Text insights box
  Widget _buildOperationalInsightsCard(CrowdState crowdState, ThemeData theme) {
    final isGateBHot = (crowdState.gateWaitTimes['Gate B'] ?? 0) >= 20;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text('AI Operational Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            if (isGateBHot) ...[
              const Text(
                '• CAPACITY ALERT: North Entrance (Gate B) queue is operating at 145% safety threshold limits. Recommending redirecting visitors to East Concourse (Gate D).',
                style: TextStyle(fontSize: 13, height: 1.4, color: Colors.orange),
              ),
              const SizedBox(height: 8),
            ],
            const Text(
              '• SUSTAINABILITY COMMUTE: 74% of matchday commuters took public rail or local park & shuttle, resulting in savings of 124 metric tons of venue CO₂ output today.',
              style: TextStyle(fontSize: 13, height: 1.4, color: Colors.green),
            ),
            const SizedBox(height: 8),
            const Text(
              '• FOOD COURT DISPATCH: Shorter food court queue metrics are being successfully broadcasted to fan mobile apps, reducing Level 1 North concession bottlenecks by 14%.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // Gate check vertical meters
  Widget _buildGateOccupancyCard(Map<String, int> gateTimes, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: gateTimes.entries.map((e) {
            final val = e.value;
            final color = val >= 20 ? Colors.red : (val >= 10 ? Colors.amber : Colors.green);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('$val mins wait', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (val / 30.0).clamp(0.02, 1.0),
                    backgroundColor: Colors.grey.shade800,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Incidents board panel
  Widget _buildIncidentsTable(BuildContext context, WidgetRef ref, List<Incident> list, ThemeData theme) {
    if (list.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('No active incidents reported.')),
        ),
      );
    }

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: list.map((inc) {
              Color priorityColor = Colors.grey;
              if (inc.priority == 'Critical') priorityColor = Colors.red;
              if (inc.priority == 'High') priorityColor = Colors.amber.shade800;
              if (inc.priority == 'Medium') priorityColor = Colors.blue;

              return DataRow(
                cells: [
                  DataCell(Text(inc.category)),
                  DataCell(Text(inc.location)),
                  DataCell(SizedBox(width: 200, child: Text(inc.title, overflow: TextOverflow.ellipsis))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: Text(inc.priority, style: TextStyle(color: priorityColor, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                  DataCell(
                    Text(
                      inc.status.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: inc.status == 'Resolved' 
                            ? Colors.green 
                            : (inc.status == 'Assigned' ? Colors.blue : Colors.red),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        if (inc.status == 'Open')
                          ElevatedButton(
                            child: const Text('Assign Staff', style: TextStyle(fontSize: 11)),
                            onPressed: () {
                              ref.read(incidentListProvider.notifier).updateIncidentStatus(inc.id, 'Assigned');
                            },
                          )
                        else if (inc.status == 'Assigned')
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () {
                              ref.read(incidentListProvider.notifier).updateIncidentStatus(inc.id, 'Resolved');
                            },
                            child: const Text('Mark Resolved', style: TextStyle(fontSize: 11)),
                          )
                        else
                          const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
