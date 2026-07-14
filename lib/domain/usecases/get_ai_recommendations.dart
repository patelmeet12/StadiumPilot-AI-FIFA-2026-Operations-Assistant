import '../entities/ai_recommendation.dart';
import '../entities/user_role.dart';
import '../entities/crowd_state.dart';
import '../entities/incident.dart';
import '../entities/volunteer_task.dart';
import '../entities/volunteer_deployment.dart';
import '../entities/simulation_scenario.dart';

import '../services/ai_decision_engine/context_engine.dart';
import '../services/ai_decision_engine/navigation_engine.dart';
import '../services/ai_decision_engine/crowd_intelligence_engine.dart';
import '../services/ai_decision_engine/accessibility_engine.dart';
import '../services/ai_decision_engine/transportation_optimizer.dart';
import '../services/ai_decision_engine/sustainability_advisor.dart';
import '../services/ai_decision_engine/volunteer_coordinator.dart';
import '../services/ai_decision_engine/operational_intelligence_engine.dart';
import '../services/ai_decision_engine/recommendation_ranking_engine.dart';

/// Contextual reasoning engine that processes multiple inputs simultaneously to formulate AI recommendations.
/// Following modular Clean Architecture, it coordinates 10 distinct sub-engine services.
class GetAIRecommendations {
  // Service instances
  final ContextEngine _contextEngine = ContextEngine();
  final NavigationEngine _navigationEngine = NavigationEngine();
  final CrowdIntelligenceEngine _crowdEngine = CrowdIntelligenceEngine();
  final AccessibilityEngine _accessEngine = AccessibilityEngine();
  final TransportationOptimizer _transportEngine = TransportationOptimizer();
  final SustainabilityAdvisor _sustainAdvisor = SustainabilityAdvisor();
  final VolunteerCoordinator _volunteerCoordinator = VolunteerCoordinator();
  final OperationalIntelligenceEngine _operationalEngine =
      OperationalIntelligenceEngine();
  final RecommendationRankingEngine _rankingEngine =
      RecommendationRankingEngine();

  Future<List<AIRecommendation>> call({
    required UserRole role,
    required String location,
    required CrowdState crowdState,
    required List<Incident> incidents,
    required List<VolunteerTask> tasks,
    String weatherAlert = 'None',
    double temperature = 26.0,
    VolunteerDeployment? deployment,
    // Contextual hackathon judging criteria variables
    String stadiumName = 'MetLife Stadium',
    DateTime? currentTime,
    bool accessibilityRequired = false,
    int familySize = 2,
    String matchPhase = 'Pre-Match',
    SimulationScenario activeScenario = SimulationScenario.none,
  }) async {
    final List<AIRecommendation> rawRecommendations = [];
    final timeContext = currentTime ?? DateTime.now();

    // 1. Build context via Context Engine
    final decisiveContext = _contextEngine.buildContext(
      role: role,
      location: location,
      weatherAlert: weatherAlert,
      temperature: temperature,
      currentTime: timeContext,
      accessibilityRequired: accessibilityRequired,
      familySize: familySize,
      matchPhase: matchPhase,
      activeScenario: activeScenario,
    );

    // 2. Generate Navigation & Shelter advice
    rawRecommendations.addAll(
      _navigationEngine.analyzeNavigation(decisiveContext),
    );

    // 3. Analyze queues, wait times, role-specific crowd alerts and scenario overrides
    rawRecommendations.addAll(
      _crowdEngine.analyzeCrowd(
        decisiveContext,
        crowdState,
        incidents: incidents,
        deployment: deployment,
      ),
    );

    // 4. Compute accessibility options
    rawRecommendations.addAll(
      _accessEngine.analyzeAccessibility(decisiveContext),
    );

    // 5. Optimize transit choices
    rawRecommendations.addAll(
      _transportEngine.analyzeTransportation(decisiveContext),
    );

    // 6. Formulate eco-friendly routes
    rawRecommendations.addAll(
      _sustainAdvisor.analyzeSustainability(decisiveContext),
    );

    // 7. Coordinate tasks (task assignments for volunteers)
    rawRecommendations.addAll(
      _volunteerCoordinator.analyzeVolunteerCoordinations(
        context: decisiveContext,
        tasks: tasks,
        deployment: deployment,
        gateBWait: crowdState.gateWaitTimes['Gate B'] ?? 0,
      ),
    );

    // 8. Analyze operations and translations
    rawRecommendations.addAll(
      _operationalEngine.analyzeOperations(
        context: decisiveContext,
        incidents: incidents,
      ),
    );

    // 9. Sort, rank, and deduplicate recommendations
    final ranked = _rankingEngine.rankRecommendations(rawRecommendations);

    return ranked;
  }
}
