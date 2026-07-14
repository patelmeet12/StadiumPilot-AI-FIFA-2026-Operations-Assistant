import '../../entities/user_role.dart';
import '../../entities/simulation_scenario.dart';

/// Context Engine compiling multi-variable environment data.
class DecisiveContext {
  final UserRole role;
  final String location;
  final String weatherAlert;
  final double temperature;
  final DateTime currentTime;
  final bool accessibilityRequired;
  final int familySize;
  final String matchPhase;
  final SimulationScenario activeScenario;

  const DecisiveContext({
    required this.role,
    required this.location,
    required this.weatherAlert,
    required this.temperature,
    required this.currentTime,
    required this.accessibilityRequired,
    required this.familySize,
    required this.matchPhase,
    required this.activeScenario,
  });
}

class ContextEngine {
  DecisiveContext buildContext({
    required UserRole role,
    required String location,
    required String weatherAlert,
    required double temperature,
    required DateTime currentTime,
    required bool accessibilityRequired,
    required int familySize,
    required String matchPhase,
    required SimulationScenario activeScenario,
  }) {
    return DecisiveContext(
      role: role,
      location: location,
      weatherAlert: weatherAlert,
      temperature: temperature,
      currentTime: currentTime,
      accessibilityRequired: accessibilityRequired,
      familySize: familySize,
      matchPhase: matchPhase,
      activeScenario: activeScenario,
    );
  }
}
