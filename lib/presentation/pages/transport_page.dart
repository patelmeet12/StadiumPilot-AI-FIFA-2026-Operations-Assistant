import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transport_plan.dart';
import '../../domain/usecases/get_transport_options.dart';
import '../widgets/stadium_shell.dart';
import '../providers/app_state_providers.dart';

class TransportPage extends ConsumerStatefulWidget {
  const TransportPage({super.key});

  @override
  ConsumerState<TransportPage> createState() => _TransportPageState();
}

class _TransportPageState extends ConsumerState<TransportPage> {
  String _origin = 'Downtown Manhattan Hub (Penn Station)';
  String _destination = 'MetLife Stadium Plaza';
  String _preferredMode = 'metro';
  List<TransportPlan> _options = [];
  bool _loading = false;

  final List<String> _origins = [
    'Downtown Manhattan Hub (Penn Station)',
    'Newark Liberty Airport (EWR)',
    'Grand Central Terminal',
    'Park & Ride North Lot',
  ];

  @override
  void initState() {
    super.initState();
    _fetchTransitOptions();
  }

  void _fetchTransitOptions() async {
    setState(() => _loading = true);
    final usecase = GetTransportOptions();
    final results = await usecase.call(
      origin: _origin,
      destination: _destination,
      preferredMode: _preferredMode,
    );
    setState(() {
      _options = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StadiumShell(
      currentPath: '/transport',
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transportation & Sustainability Advisor',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Plan your low-carbon matchday journey. Real-time traffic, carbon offset monitoring, and transit incentives.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Gamified Green Commuter Badge
              _buildGreenCommuterBadge(theme),
              const SizedBox(height: 24),

              // Config & Options Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Config panel
                      Expanded(
                        flex: isWide ? 2 : 5,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Journey Planner Inputs',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 20),
                                DropdownButtonFormField<String>(
                                  value: _origin,
                                  decoration: const InputDecoration(
                                    labelText: 'Origin Point',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _origins.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _origin = val);
                                      _fetchTransitOptions();
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  initialValue: 'New York New Jersey Stadium (MetLife)',
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Destination Venue',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _preferredMode,
                                  decoration: const InputDecoration(
                                    labelText: 'Preferred Transport Mode',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'metro', child: Text('FIFA Metro Line')),
                                    DropdownMenuItem(value: 'bus', child: Text('Express Shuttle Bus')),
                                    DropdownMenuItem(value: 'taxi', child: Text('Ride-Share Dropoff')),
                                    DropdownMenuItem(value: 'walking', child: Text('Walking / Park & Ride')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _preferredMode = val);
                                      _fetchTransitOptions();
                                    }
                                  },
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    child: const Text('Update Travel Desk'),
                                    onPressed: _fetchTransitOptions,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Travel Options list
                      if (isWide) const SizedBox(width: 24),
                      if (isWide)
                        Expanded(
                          flex: 3,
                          child: _loading 
                              ? const Card(child: Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator())))
                              : _buildTransportOptionsList(theme),
                        ),
                    ],
                  );
                },
              ),
              
              // Mobile view list
              if (MediaQuery.of(context).size.width <= 900)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildTransportOptionsList(theme),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreenCommuterBadge(ThemeData theme) {
    return Card(
      elevation: 0,
      color: Colors.green.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.green, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Green Commuter Level Gold',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('+140 Points', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your calculated eco decisions have saved 12.8 kg of carbon emissions this tournament. Keep walking or riding the metro to earn free concession discount vouchers!',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportOptionsList(ThemeData theme) {
    final activeTheme = ref.watch(themeModeProvider);
    if (_options.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No transportation options generated.')));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _options.length,
      itemBuilder: (context, index) {
        final plan = _options[index];
        IconData icon = Icons.directions_transit;
        if (plan.iconType == 'bus') icon = Icons.directions_bus;
        if (plan.iconType == 'car') icon = Icons.local_taxi;
        if (plan.iconType == 'walk') icon = Icons.directions_walk;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: plan.isRecommended 
                  ? Colors.green 
                  : (activeTheme == AppThemeMode.highContrast ? Colors.white : Colors.transparent),
              width: plan.isRecommended ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              if (plan.isRecommended)
                Container(
                  width: double.infinity,
                  color: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: const Row(
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'AI RECOMMENDED - BEST TRANSIT OPTION',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 10, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mode Header
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: plan.ecoScore >= 80 ? Colors.green.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                          child: Icon(icon, color: plan.ecoScore >= 80 ? Colors.green : Colors.amber),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(plan.modeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Eco Score: ${plan.ecoScore}/100', style: TextStyle(color: plan.ecoScore >= 80 ? Colors.green : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              plan.estimatedCost == 0.0 ? 'FREE' : '\$${plan.estimatedCost.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber),
                            ),
                            const Text('Est. Cost', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    
                    // Metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metricCol('EST. TRAVEL TIME', '${plan.durationMins} mins'),
                        _metricCol('CARBON EMISSIONS', '${plan.co2EmissionsKg} kg CO₂'),
                        _metricCol('SAVINGS VS CAR', '+${plan.co2SavedKg} kg CO₂', textColour: Colors.green),
                        _metricCol('EXPECTED CROWD', plan.crowdLevel, textColour: plan.crowdLevel == 'High' ? Colors.red : Colors.green),
                      ],
                    ),
                    
                    const Divider(height: 24),

                    // Reasoning and Sustainability Tip
                    if (plan.recommendationReason.isNotEmpty) ...[
                      const Text(
                        'AI REASONING',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                      const SizedBox(height: 4),
                      Text(plan.recommendationReason, style: const TextStyle(fontSize: 13, height: 1.4)),
                      const SizedBox(height: 12),
                    ],
                    
                    // Sustainability alert tip
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.eco_outlined, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              plan.sustainabilityTip,
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metricCol(String label, String val, {Color? textColour}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.bold,
            color: textColour,
          ),
        ),
      ],
    );
  }
}
