import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/route_plan.dart';
import '../../domain/usecases/calculate_route.dart';
import '../providers/stadium_simulation_providers.dart';
import '../widgets/stadium_shell.dart';

class NavigationPage extends ConsumerStatefulWidget {
  const NavigationPage({super.key});

  @override
  ConsumerState<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends ConsumerState<NavigationPage> {
  String _startLocation = 'Gate B';
  String _destination = 'Section 128';
  bool _wheelchairFriendly = false;
  bool _avoidCrowds = true;
  RoutePlan? _calculatedRoute;
  bool _calculating = false;

  final List<String> _startLocations = [
    'Gate A',
    'Gate B',
    'Gate C',
    'Gate D',
    'Bus Dropoff Zone',
    'Metro Plaza',
  ];
  final List<String> _destinations = [
    'Section 128',
    'Section 104',
    'Food Court 1 (North)',
    'Food Court 2 (South)',
    'Restrooms Level 1 East',
    'Sensory Room West',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-calculate a standard route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runCalculation();
    });
  }

  void _runCalculation() async {
    setState(() => _calculating = true);
    final crowd = ref.read(crowdStateProvider);
    final routeFinder = CalculateRoute();

    final plan = await routeFinder.call(
      start: _startLocation,
      destination: _destination,
      wheelchairFriendly: _wheelchairFriendly,
      avoidCrowds: _avoidCrowds,
      crowdState: crowd,
    );

    setState(() {
      _calculatedRoute = plan;
      _calculating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StadiumShell(
      currentPath: '/navigation',
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Navigation Assistant',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Intelligent path finding bypassing crowded bottlenecks and supporting accessible entryways.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Layout grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar Controls
                      Expanded(
                        flex: isWide ? 2 : 5,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Route Planner Parameters',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Start location
                                DropdownButtonFormField<String>(
                                  initialValue: _startLocation,
                                  decoration: const InputDecoration(
                                    labelText: 'Start Location',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _startLocations
                                      .map(
                                        (loc) => DropdownMenuItem(
                                          value: loc,
                                          child: Text(loc),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _startLocation = val);
                                      _runCalculation();
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Destination location
                                DropdownButtonFormField<String>(
                                  initialValue: _destination,
                                  decoration: const InputDecoration(
                                    labelText: 'Destination Venue Zone',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _destinations
                                      .map(
                                        (loc) => DropdownMenuItem(
                                          value: loc,
                                          child: Text(loc),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _destination = val);
                                      _runCalculation();
                                    }
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Wheelchair toggle
                                SwitchListTile(
                                  title: const Text(
                                    'Wheelchair Accessible Only',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Bypass stairs, use ramped gates, and prioritize elevators.',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  value: _wheelchairFriendly,
                                  activeThumbColor: const Color(0xFF6366F1),
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (val) {
                                    setState(() => _wheelchairFriendly = val);
                                    _runCalculation();
                                  },
                                ),

                                // Crowd bypass toggle
                                SwitchListTile(
                                  title: const Text(
                                    'Bypass High Crowd Bottlenecks',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Redirect route to lesser congested entryways.',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  value: _avoidCrowds,
                                  activeThumbColor: Colors.green,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (val) {
                                    setState(() => _avoidCrowds = val);
                                    _runCalculation();
                                  },
                                ),

                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.location_searching),
                                    label: const Text('Recalculate AI Path'),
                                    onPressed: _runCalculation,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Route outputs
                      if (isWide) const SizedBox(width: 24),
                      if (isWide)
                        Expanded(
                          flex: 3,
                          child: _calculating
                              ? const Card(
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(40.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                )
                              : _buildRouteResultsCard(theme),
                        ),
                    ],
                  );
                },
              ),

              // Mobile view route outputs below controls
              if (MediaQuery.of(context).size.width <= 900)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: _calculating
                      ? const Center(child: CircularProgressIndicator())
                      : _buildRouteResultsCard(theme),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteResultsCard(ThemeData theme) {
    if (_calculatedRoute == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('Calculate a route to display navigation results.'),
        ),
      );
    }

    final route = _calculatedRoute!;
    return Column(
      children: [
        // Summary Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: route.isWheelchairFriendly
                            ? const Color(0xFF6366F1)
                            : theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        route.title.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.timeline, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _metricCol(
                      'ESTIMATED TIME',
                      '${route.totalDurationMins} minutes',
                      Colors.green,
                    ),
                    const SizedBox(width: 40),
                    _metricCol(
                      'WALKING DISTANCE',
                      '${route.totalDistanceMeters} meters',
                      null,
                    ),
                    const SizedBox(width: 40),
                    _metricCol(
                      'CROWD CONGESTION',
                      route.crowdCongestionLevel,
                      route.crowdCongestionLevel == 'High'
                          ? Colors.red
                          : Colors.green,
                    ),
                  ],
                ),
                if (route.reasoning.isNotEmpty) ...[
                  const Divider(height: 30),
                  const Text(
                    'AI ROUTE REASONING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    route.reasoning,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Accessible markers
        if (route.accessibilityFeatures.isNotEmpty) ...[
          Card(
            color: const Color(0xFF6366F1).withValues(alpha: 0.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF6366F1), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.accessible_forward,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Accessible Path Features Used:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          route.accessibilityFeatures.join(' • '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Visual Node Layout Chart
        Semantics(
          label:
              'Visual map of route nodes: starting at $_startLocation, routing through Gate entrypoints, utilizing level transition features, and arriving at $_destination.',
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tactical Route Node Map',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Horizontal path representation
                  ExcludeSemantics(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildNodeCircle(
                            route.steps[0].contains('Start')
                                ? _startLocation
                                : 'Origin',
                            Colors.blue,
                          ),
                          _buildNodeLine(Colors.blue),
                          _buildNodeCircle(
                            route.steps.any((s) => s.contains('Gate D'))
                                ? 'Gate D (Bypass)'
                                : 'Gate C',
                            Colors.amber,
                          ),
                          _buildNodeLine(Colors.amber),
                          _buildNodeCircle(
                            route.isWheelchairFriendly
                                ? 'Elevator West'
                                : 'Escalator Level 2',
                            Colors.purple,
                          ),
                          _buildNodeLine(Colors.purple),
                          _buildNodeCircle(_destination, Colors.green),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Step by step directions card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detailed Navigation Itinerary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: route.steps.length,
                  itemBuilder: (context, index) {
                    final isReroute =
                        route.steps[index].contains('REROUTE') ||
                        route.steps[index].contains('CROWD REDIRECT');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: isReroute
                                ? Colors.amber.shade900
                                : theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isReroute
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              route.steps[index],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isReroute
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isReroute
                                    ? Colors.orange.shade300
                                    : null,
                              ),
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
        ),
      ],
    );
  }

  Widget _metricCol(String label, String val, Color? textColour) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColour,
          ),
        ),
      ],
    );
  }

  Widget _buildNodeCircle(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(Icons.circle, color: color, size: 14),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildNodeLine(Color color) {
    return Container(
      width: 50,
      height: 2,
      color: color.withValues(alpha: 0.5),
      margin: const EdgeInsets.only(bottom: 16),
    );
  }
}
