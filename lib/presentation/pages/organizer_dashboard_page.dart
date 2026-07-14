import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/crowd_state.dart';
import '../../domain/entities/match_detail.dart';
import '../../domain/entities/volunteer_deployment.dart';
import '../providers/app_state_providers.dart';
import '../providers/stadium_simulation_providers.dart';
import '../widgets/stadium_shell.dart';

// Local UI state providers for the Staff Reallocation Console
class ReallocateFromNotifier extends Notifier<String> {
  @override
  String build() => 'concourse';

  void set(String val) => state = val;
}

final reallocateFromProvider = NotifierProvider<ReallocateFromNotifier, String>(
  () {
    return ReallocateFromNotifier();
  },
);

class ReallocateToNotifier extends Notifier<String> {
  @override
  String build() => 'plaza';

  void set(String val) => state = val;
}

final reallocateToProvider = NotifierProvider<ReallocateToNotifier, String>(() {
  return ReallocateToNotifier();
});

class ReallocateCountNotifier extends Notifier<int> {
  @override
  int build() => 2;

  void set(int val) => state = val;
}

final reallocateCountProvider = NotifierProvider<ReallocateCountNotifier, int>(
  () {
    return ReallocateCountNotifier();
  },
);

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
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Live venue operations command center. Monitor structural flows, dispatch staff, and manage stadium-wide broadcasts.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),

              _buildMatchFixtureSelector(context, ref, theme),
              const SizedBox(height: 24),

              // Emergency trigger banner controls
              Card(
                color: isEmergency
                    ? Colors.red.withValues(alpha: 0.12)
                    : theme.cardTheme.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isEmergency ? Colors.red : Colors.grey.shade700,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.campaign,
                        color: isEmergency ? Colors.red : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Global Emergency Announcement Broadcast',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              isEmergency
                                  ? 'ACTIVE: Multilingual evacuation guidelines are broadcasting across all user platforms.'
                                  : 'INACTIVE: Venue operates under standard protocol.',
                              style: TextStyle(
                                color: isEmergency ? Colors.red : Colors.grey,
                                fontSize: 12,
                              ),
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
                              content: Text(
                                val
                                    ? 'Emergency broadcast initiated.'
                                    : 'Emergency broadcast terminated.',
                              ),
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildHeatmapGrid(zoneDensities, theme),
                            const SizedBox(height: 24),
                            _buildOperationalInsightsCard(crowdState, theme),
                            const SizedBox(height: 24),
                            _buildAnalyticsKPICard(
                              theme,
                              crowdState,
                              incidents,
                            ),
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildGateOccupancyCard(
                              crowdState.gateWaitTimes,
                              theme,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Volunteer Deployment & Availability',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildVolunteerAvailabilityCard(
                              context,
                              ref,
                              theme,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'AI Risk Prediction & Preventive Action Hub',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildRiskPredictionCard(context, ref, theme),
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
              const SizedBox(height: 32),

              // Transit overview
              const Text(
                'Stadium Transit & Commute Overview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              _buildTransportationOverviewCard(theme),
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
              Text(
                entry.key,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Density Coefficient: ${(density * 100).toInt()}%',
                      style: TextStyle(
                        color: gridColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    density >= 0.8
                        ? Icons.warning
                        : (density >= 0.6
                              ? Icons.info_outline
                              : Icons.check_circle_outline),
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
            Row(
              children: const [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Operational Insights',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isGateBHot) ...[
              const Text(
                '• CAPACITY ALERT: North Entrance (Gate B) queue is operating at 145% safety threshold limits. Recommending redirecting visitors to East Concourse (Gate D).',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.orange,
                ),
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
            final color = val >= 20
                ? Colors.red
                : (val >= 10 ? Colors.amber : Colors.green);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '$val mins wait',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
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
  Widget _buildIncidentsTable(
    BuildContext context,
    WidgetRef ref,
    List<Incident> list,
    ThemeData theme,
  ) {
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
              DataColumn(
                label: Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Location',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Priority',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
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
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: Text(inc.title, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        inc.priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      inc.status.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: inc.status == 'Resolved'
                            ? Colors.green
                            : (inc.status == 'Assigned'
                                  ? Colors.blue
                                  : Colors.red),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        if (inc.status == 'Open')
                          ElevatedButton(
                            child: const Text(
                              'Assign Staff',
                              style: TextStyle(fontSize: 11),
                            ),
                            onPressed: () {
                              ref
                                  .read(incidentListProvider.notifier)
                                  .updateIncidentStatus(inc.id, 'Assigned');
                            },
                          )
                        else if (inc.status == 'Assigned')
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () {
                              ref
                                  .read(incidentListProvider.notifier)
                                  .updateIncidentStatus(inc.id, 'Resolved');
                            },
                            child: const Text(
                              'Mark Resolved',
                              style: TextStyle(fontSize: 11),
                            ),
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

  Widget _buildVolunteerAvailabilityCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final VolunteerDeployment deployment = ref.watch(
      volunteerDeploymentProvider,
    );
    final fromZone = ref.watch(reallocateFromProvider);
    final toZone = ref.watch(reallocateToProvider);
    final reallocateCount = ref.watch(reallocateCountProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_outline, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  '${deployment.totalActive} Active / ${deployment.totalBreak} on Break',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: deployment.totalVolunteers == 0
                  ? 0
                  : deployment.totalActive / deployment.totalVolunteers,
              backgroundColor: theme.brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 16),
            _buildVolunteerRow(
              'Plaza Entry Gates',
              '${deployment.plazaActive} Active',
              '${deployment.plazaBreak} on break',
              Colors.green,
            ),
            const SizedBox(height: 10),
            _buildVolunteerRow(
              'Concourse Concessions',
              '${deployment.concourseActive} Active',
              '${deployment.concourseBreak} on break',
              Colors.green,
            ),
            const SizedBox(height: 10),
            _buildVolunteerRow(
              'Medical & Accessibility',
              '${deployment.medicalActive} Active',
              '${deployment.medicalBreak} on break',
              Colors.amber,
            ),
            const SizedBox(height: 10),
            _buildVolunteerRow(
              'Security Checkpoints',
              '${deployment.securityActive} Active',
              '${deployment.securityBreak} on break',
              Colors.green,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Staff Dispatch Reallocation Controller',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Source',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: fromZone,
                        items: const [
                          DropdownMenuItem(
                            value: 'plaza',
                            child: Text('Plaza'),
                          ),
                          DropdownMenuItem(
                            value: 'concourse',
                            child: Text('Concourse'),
                          ),
                          DropdownMenuItem(
                            value: 'medical',
                            child: Text('Medical'),
                          ),
                          DropdownMenuItem(
                            value: 'security',
                            child: Text('Security'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(reallocateFromProvider.notifier).set(val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Target',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: toZone,
                        items: const [
                          DropdownMenuItem(
                            value: 'plaza',
                            child: Text('Plaza'),
                          ),
                          DropdownMenuItem(
                            value: 'concourse',
                            child: Text('Concourse'),
                          ),
                          DropdownMenuItem(
                            value: 'medical',
                            child: Text('Medical'),
                          ),
                          DropdownMenuItem(
                            value: 'security',
                            child: Text('Security'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(reallocateToProvider.notifier).set(val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Count',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: reallocateCount,
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('1 Volunteer'),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('2 Volunteers'),
                          ),
                          DropdownMenuItem(
                            value: 4,
                            child: Text('4 Volunteers'),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child: Text('5 Volunteers'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(reallocateCountProvider.notifier).set(val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: fromZone == toZone
                      ? null
                      : () {
                          ref
                              .read(volunteerDeploymentProvider.notifier)
                              .reallocate(fromZone, toZone, reallocateCount);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Redeployed $reallocateCount staff successfully!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                  child: const Text('Redeploy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerRow(
    String zone,
    String activeCount,
    String breakCount,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            zone,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          '$activeCount ($breakCount)',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTransportationOverviewCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return isWide
                ? Row(
                    children: [
                      Expanded(
                        child: _buildTransitItem(
                          Icons.subway,
                          'FIFA Metro Line 1',
                          'Normal (72% load)',
                          Colors.green,
                        ),
                      ),
                      const VerticalDivider(width: 24),
                      Expanded(
                        child: _buildTransitItem(
                          Icons.airport_shuttle,
                          'Express Shuttles',
                          'High loops (85% load)',
                          Colors.amber,
                        ),
                      ),
                      const VerticalDivider(width: 24),
                      Expanded(
                        child: _buildTransitItem(
                          Icons.local_parking,
                          'Parking Lots',
                          '94% Occupied',
                          Colors.red,
                        ),
                      ),
                      const VerticalDivider(width: 24),
                      Expanded(
                        child: _buildTransitItem(
                          Icons.local_taxi,
                          'Rideshare Stand',
                          'Normal wait (12% delay)',
                          Colors.green,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildTransitItem(
                        Icons.subway,
                        'FIFA Metro Line 1',
                        'Normal (72% load)',
                        Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildTransitItem(
                        Icons.airport_shuttle,
                        'Express Shuttles',
                        'High loops (85% load)',
                        Colors.amber,
                      ),
                      const SizedBox(height: 16),
                      _buildTransitItem(
                        Icons.local_parking,
                        'Parking Lots',
                        '94% Occupied',
                        Colors.red,
                      ),
                      const SizedBox(height: 16),
                      _buildTransitItem(
                        Icons.local_taxi,
                        'Rideshare Stand',
                        'Normal wait (12% delay)',
                        Colors.green,
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _buildTransitItem(
    IconData icon,
    String title,
    String status,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                status,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }

  Widget _buildMatchFixtureSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final activeMatchId = ref.watch(selectedMatchProvider);
    final currentPreset = MatchPreset.presets.firstWhere(
      (p) => p.matchId == activeMatchId,
      orElse: () => MatchPreset.presets.first,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_soccer, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'FIFA 2026 Fixture Command Panel',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Select Fixture Telemetry Mode',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: activeMatchId,
                        items: MatchPreset.presets.map((preset) {
                          return DropdownMenuItem(
                            value: preset.matchId,
                            child: Text(
                              '${preset.homeTeam} vs ${preset.awayTeam} (${preset.matchId == "match_argentina_france" ? "Final Match" : "Group Stage"})',
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            ref
                                .read(selectedMatchProvider.notifier)
                                .setMatch(val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 550;
                final kids = [
                  _buildTelemetryInfoItem(
                    'Weather Warning',
                    currentPreset.weatherAlert,
                    currentPreset.weatherAlert == 'None'
                        ? Colors.green
                        : Colors.red,
                    theme,
                  ),
                  _buildTelemetryInfoItem(
                    'Temperature',
                    '${currentPreset.temperature.toInt()}°C',
                    Colors.blue,
                    theme,
                  ),
                  _buildTelemetryInfoItem(
                    'Projected Fans',
                    '${currentPreset.attendanceProjection}',
                    Colors.amber.shade800,
                    theme,
                  ),
                  _buildTelemetryInfoItem(
                    'VIP Dispatch',
                    currentPreset.vipMediaPriority,
                    currentPreset.vipMediaPriority == 'Critical'
                        ? Colors.red
                        : Colors.blue,
                    theme,
                  ),
                ];
                return isWide
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: kids.map((w) => Expanded(child: w)).toList(),
                      )
                    : Column(
                        children: kids
                            .map(
                              (w) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: w,
                              ),
                            )
                            .toList(),
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryInfoItem(
    String label,
    String value,
    Color statusColor,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsKPICard(
    ThemeData theme,
    CrowdState crowd,
    List<Incident> incidents,
  ) {
    final resolvedCount = incidents.where((i) => i.status == 'Resolved').length;
    final totalIncidents = incidents.length;
    final incidentRate = totalIncidents == 0
        ? 100
        : (resolvedCount / totalIncidents * 100).toInt();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'AI Operational KPIs & Impact Analytics',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildKPITile(
                  'Concourse Flow',
                  '94.2%',
                  '+3.1% Optimization Benefit',
                  Colors.green,
                  theme,
                ),
                _buildKPITile(
                  'Avg Commuter CO₂',
                  '1.15 kg',
                  '-28.4% Carbon Reduced',
                  Colors.green,
                  theme,
                ),
                _buildKPITile(
                  'Incident Resolve Rate',
                  '$incidentRate%',
                  '$resolvedCount resolved of $totalIncidents',
                  Colors.blue,
                  theme,
                ),
                _buildKPITile(
                  'Staff Utilization Index',
                  '92.6%',
                  'Target threshold: >85%',
                  Colors.amber.shade800,
                  theme,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Live Mitigation Performance Index',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'AI Direct Flow (Optimized)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.94,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Standard Flow (Bottleneck)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.62,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPITile(
    String label,
    String value,
    String benefit,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            benefit,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskPredictionCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final risksAsync = ref.watch(riskPredictionsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.radar, color: theme.colorScheme.error, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'AI Real-Time Predictive Risk Center',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            risksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading risks: $err'),
              data: (risks) {
                if (risks.isEmpty) {
                  return Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No anomalies predicted. All logistics metrics within safety thresholds.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: risks.length,
                  separatorBuilder: (c, i) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final r = risks[index];
                    final isCritical = r.probability >= 0.85;
                    final alertColor = isCritical
                        ? Colors.red
                        : Colors.amber.shade800;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: alertColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(r.probability * 100).toInt()}% RISK PROBABILITY',
                                style: TextStyle(
                                  color: alertColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              r.timeline,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.shield,
                                    color: Colors.blue,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'AI PREVENTIVE RECOMMENDATION ACTION:',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r.preventiveAction,
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.flash_on,
                              color: Colors.green,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Mitigation Benefit: ${r.expectedImpact}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              side: BorderSide(color: alertColor),
                            ),
                            icon: Icon(
                              Icons.send_and_archive,
                              size: 14,
                              color: alertColor,
                            ),
                            label: Text(
                              'Execute Preventive Dispatch',
                              style: TextStyle(fontSize: 11, color: alertColor),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Executed mitigation: ${r.title} preventive routing deployed!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
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
}
