import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stadium_simulation_providers.dart';
import '../providers/command_center_providers.dart';
import '../widgets/stadium_shell.dart';
import '../widgets/accessible_focus_builder.dart';
import '../../domain/entities/incident.dart';

/// Interactive operations Command Center dashboard with Digital Twin 2D visual mapping.
class CommandCenterPage extends ConsumerStatefulWidget {
  /// Creates a new [CommandCenterPage] instance.
  const CommandCenterPage({super.key});

  @override
  ConsumerState<CommandCenterPage> createState() => _CommandCenterPageState();
}

class _CommandCenterPageState extends ConsumerState<CommandCenterPage> {
  // Input Controller for lost child search queries
  final _childNameController = TextEditingController();
  
  // Seating section category state
  String _parentSection = 'Section 128';

  // Selected node identifier on the stadium twin grid map
  String _selectedTwinZone = 'Gate B';

  @override
  void dispose() {
    _childNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final crowdState = ref.watch(crowdStateProvider);

    // Read extracted business calculations from providers (SOLID / SoC separation)
    final triagedIncidents = ref.watch(triagedIncidentsProvider);
    final replayTimeSlider = ref.watch(replaySliderProvider);
    final energyStats = ref.watch(energyStatsProvider);
    final childSearchState = ref.watch(lostChildLocatorProvider);

    final isReplay = replayTimeSlider < 1.0;

    return StadiumShell(
      currentPath: '/command_center',
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Portal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FIFA AI COMMAND CENTER & DIGITAL TWIN',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Simulating real-time energy, incident triaging, and layout mappings.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Layout Matrix
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 950;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Digital Twin and Scrubber
                      Expanded(
                        flex: isWide ? 3 : 5,
                        child: Column(
                          children: [
                            // 1. Digital Twin Sim Grid Card
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Active Digital Twin Layout Map',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Interactive visual grid mapping stadium zones. Click a zone to monitor active parameters.',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(height: 20),

                                    // 2D stadium diagram grid
                                    GridView.count(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.6,
                                      children: [
                                        _twinZoneTile('Gate A', crowdState.zoneDensities['Zone North'] ?? 0.4, Colors.blue),
                                        _twinZoneTile('Suite Level', 0.25, Colors.purple),
                                        _twinZoneTile('Gate B', crowdState.zoneDensities['Zone East'] ?? 0.7, Colors.green),
                                        _twinZoneTile('Plaza East', crowdState.zoneDensities['Zone Plaza'] ?? 0.5, Colors.amber),
                                        _twinZoneTile('Concourse West', crowdState.zoneDensities['Zone Concourse'] ?? 0.6, Colors.orange),
                                        _twinZoneTile('Gate C', 0.35, Colors.indigo),
                                      ],
                                    ),

                                    // Selected zone parameters display
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: theme.brightness == Brightness.dark
                                            ? Colors.grey.shade900
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'SELECTED NODE: ${_selectedTwinZone.toUpperCase()}',
                                              style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'STATUS: NOMINAL',
                                            style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 2. AI Event Replay Telemetry Scrubber
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'AI Event Replay Engine Scrubber',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isReplay ? Colors.blue.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isReplay ? 'REPLAYING HISTORICAL TELEMETRY' : 'REAL-TIME LIVE STREAM',
                                            style: TextStyle(
                                              color: isReplay ? Colors.blue : Colors.green,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Courier',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Scrub back in time to replay simulation steps and analyze how AI recommendations adjusted.',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(height: 16),
                                    Slider(
                                      value: replayTimeSlider,
                                      onChanged: (val) {
                                        ref.read(replaySliderProvider.notifier).setReplayOffset(val);
                                      },
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Text('-15 mins (Evac)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                        Text('-10 mins', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                        Text('-5 mins', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                        Text('LIVE TACTICAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 3. Energy Consumption Dashboard
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Energy Consumption & Weather Impacts',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _metricBox('SOLAR BATTERY', '${energyStats.solarProduction.toStringAsFixed(1)} kW', Colors.green),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _metricBox('CROWD LOAD ADD', '${energyStats.crowdEnergyDemand.toStringAsFixed(1)} kW', Colors.amber),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _metricBox('TOTAL DYNAMIC CONSUMPTION', '${energyStats.totalEnergyConsumption.toStringAsFixed(1)} kW', Colors.blue),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isWide) const SizedBox(width: 24),
                      if (isWide)
                        // Side tools panel: triage, child locator, and timelines
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildTriageConsoleCard(triagedIncidents),
                              const SizedBox(height: 24),
                              _buildLostChildLocatorCard(childSearchState),
                              const SizedBox(height: 24),
                              _buildDecisionHistoryTimelineCard(),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),

              // Mobile bottom layout
              if (MediaQuery.of(context).size.width <= 950) ...[
                const SizedBox(height: 24),
                _buildTriageConsoleCard(triagedIncidents),
                const SizedBox(height: 24),
                _buildLostChildLocatorCard(childSearchState),
                const SizedBox(height: 24),
                _buildDecisionHistoryTimelineCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _twinZoneTile(String zoneName, double density, Color focusColor) {
    final isSelected = _selectedTwinZone == zoneName;
    final color = density >= 0.8
        ? Colors.red
        : (density >= 0.6 ? Colors.amber : Colors.green);

    return AccessibleFocusBuilder(
      semanticLabel: 'Digital Twin Node $zoneName. Crowd load is ${(density * 100).toInt()}%. Status is ${isSelected ? 'Selected' : 'Click to inspect'}',
      onTap: () {
        setState(() {
          _selectedTwinZone = zoneName;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? focusColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? focusColor : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              zoneName.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? focusColor : null,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(density * 100).toInt()}% LOAD',
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Icon(
                  density >= 0.8
                      ? Icons.warning
                      : (density >= 0.6 ? Icons.info_outline : Icons.check_circle_outline),
                  color: color,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontFamily: 'Courier', fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTriageConsoleCard(List<Incident> sortedIncidents) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Incident Triage Console',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Incidents auto-triaged by operational priority, urgency, and category.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (sortedIncidents.isEmpty)
              const Text('No active incidents reported. Operations secure.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedIncidents.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final inc = sortedIncidents[index];
                  final isCritical = inc.priority == 'Critical';
                  final color = isCritical ? Colors.red : Colors.amber;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(isCritical ? Icons.report_problem : Icons.info, color: color, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inc.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Triage Category: ${inc.category} | ${inc.location}',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLostChildLocatorCard(LostChildSearchState childSearchState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Lost Child Assistant matching',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter descriptions to match with active volunteer patrols and safety nodes.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _childNameController,
              decoration: const InputDecoration(
                labelText: 'Child description (e.g. Blue cap, age 7)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _parentSection,
              decoration: const InputDecoration(
                labelText: 'Parent seating area',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Section 128', child: Text('Section 128')),
                DropdownMenuItem(value: 'Section 104', child: Text('Section 104')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _parentSection = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Initiate Smart Search'),
                onPressed: childSearchState.isSearching
                    ? null
                    : () {
                        ref.read(lostChildLocatorProvider.notifier).searchChild(
                              childDescription: _childNameController.text,
                              parentSeatingSection: _parentSection,
                            );
                      },
              ),
            ),
            if (childSearchState.isSearching)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (childSearchState.resultMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Text(
                  childSearchState.resultMessage!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionHistoryTimelineCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendation Timeline & History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _timelineStep('18:24:12', 'STAFF_REALLOCATED', 'Reallocated 5 concourse staff to Gate B due to flow congestion.'),
            _timelineStep('18:24:05', 'RAIN_WAR_INTAKE', 'Heavy Rain scenario enabled. Solar fallback activated.'),
            _timelineStep('18:22:15', 'MED_DISPATCH_NOM', 'Medical team dispatched to Section 104 to handle minor incident.'),
          ],
        ),
      ),
    );
  }

  Widget _timelineStep(String time, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: const TextStyle(fontFamily: 'Courier', fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
