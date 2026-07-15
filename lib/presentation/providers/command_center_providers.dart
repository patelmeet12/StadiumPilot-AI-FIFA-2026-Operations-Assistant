import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/simulation_scenario.dart';
import 'stadium_simulation_providers.dart';

/// State representation of the dynamic energy metrics.
class EnergyStats {
  /// The backup power generated from solar panels in kW.
  final double solarProduction;

  /// The additional power demand calculated from active crowd flow in kW.
  final double crowdEnergyDemand;

  /// The total energy consumption of the facility in kW.
  final double totalEnergyConsumption;

  /// Creates a new [EnergyStats] instance.
  const EnergyStats({
    required this.solarProduction,
    required this.crowdEnergyDemand,
    required this.totalEnergyConsumption,
  });
}

/// State representation of the lost child search locator.
class LostChildSearchState {
  /// True if the search is executing asynchronously.
  final bool isSearching;

  /// Holds the match result message if search completes.
  final String? resultMessage;

  /// Creates a new [LostChildSearchState] instance.
  const LostChildSearchState({
    required this.isSearching,
    this.resultMessage,
  });
}

/// Provides sorting on active reported incidents by priority.
final triagedIncidentsProvider = Provider<List<Incident>>((ref) {
  final incidents = ref.watch(incidentListProvider);
  final sorted = List<Incident>.from(incidents);
  sorted.sort((a, b) {
    final aPriority = a.priority == 'Critical' ? 2 : (a.priority == 'High' ? 1 : 0);
    final bPriority = b.priority == 'Critical' ? 2 : (b.priority == 'High' ? 1 : 0);
    return bPriority.compareTo(aPriority);
  });
  return sorted;
});

/// Exposes the replay slider multiplier offset.
class ReplaySliderNotifier extends Notifier<double> {
  @override
  double build() => 1.0;

  /// Updates the current scrubber time value.
  void setReplayOffset(double val) {
    state = val;
  }
}

/// Provider for the event replay timeline slider offset.
final replaySliderProvider = NotifierProvider<ReplaySliderNotifier, double>(() {
  return ReplaySliderNotifier();
});

/// Exposes dynamic calculated energy stats based on crowd flow, weather, and scrubber offsets.
final energyStatsProvider = Provider<EnergyStats>((ref) {
  final activeScenario = ref.watch(activeScenarioProvider);
  final crowdState = ref.watch(crowdStateProvider);
  final replayOffset = ref.watch(replaySliderProvider);

  final isReplay = replayOffset < 1.0;
  final densityMultiplier = isReplay ? 0.6 : 1.0;

  final solarProduction = activeScenario == SimulationScenario.heavyRain ? 12.0 : 85.0;
  const systemBaseLoad = 42.0;
  final crowdEnergyDemand = (crowdState.zoneDensities.values.fold(0.0, (prev, e) => prev + e) * 8.5) * densityMultiplier;
  final totalEnergyConsumption = systemBaseLoad + crowdEnergyDemand + (activeScenario == SimulationScenario.heavyRain ? 25.0 : 0.0);

  return EnergyStats(
    solarProduction: solarProduction,
    crowdEnergyDemand: crowdEnergyDemand,
    totalEnergyConsumption: totalEnergyConsumption,
  );
});

/// Manage the lost child locator AI matching logic.
class LostChildLocatorNotifier extends Notifier<LostChildSearchState> {
  @override
  LostChildSearchState build() => const LostChildSearchState(isSearching: false);

  /// Performs an asynchronous search match against active volunteer patrols.
  Future<void> searchChild({
    required String childDescription,
    required String parentSeatingSection,
  }) async {
    state = const LostChildSearchState(isSearching: true);

    await Future.delayed(const Duration(milliseconds: 600));

    if (childDescription.trim().isEmpty) {
      state = const LostChildSearchState(
        isSearching: false,
        resultMessage: 'ERROR: Please enter a child description/name.',
      );
      return;
    }

    if (parentSeatingSection == 'Section 128') {
      state = LostChildSearchState(
        isSearching: false,
        resultMessage: 'MATCH FOUND: Volunteer patrol B-4 matched description "$childDescription". Location: Concourse West elevator lobby (adjacent to $parentSeatingSection). Safe dispatch route calculated.',
      );
    } else {
      state = LostChildSearchState(
        isSearching: false,
        resultMessage: 'MATCH FOUND: Volunteer patrol D-2 matched description "$childDescription" near Gate D entry. Dispatched parent escort route.',
      );
    }
  }

  /// Resets the search results back to original state.
  void clearSearch() {
    state = const LostChildSearchState(isSearching: false);
  }
}

/// Provider for managing lost child search processes.
final lostChildLocatorProvider = NotifierProvider<LostChildLocatorNotifier, LostChildSearchState>(() {
  return LostChildLocatorNotifier();
});
