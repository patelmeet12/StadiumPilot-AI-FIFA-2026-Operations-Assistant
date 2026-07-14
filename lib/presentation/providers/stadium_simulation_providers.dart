import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/crowd_state.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/volunteer_task.dart';
import '../../domain/entities/ai_recommendation.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/entities/match_detail.dart';
import '../../domain/entities/volunteer_deployment.dart';
import '../../domain/entities/operational_risk.dart';
import '../../domain/entities/simulation_scenario.dart';
import '../../domain/usecases/get_ai_recommendations.dart';
import 'app_state_providers.dart';

// 1. Crowd State Simulator Provider
class CrowdStateNotifier extends Notifier<CrowdState> {
  Timer? _timer;

  @override
  CrowdState build() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      fetchCrowdState();
    });

    ref.onDispose(() {
      _timer?.cancel();
    });

    fetchCrowdState();
    return CrowdState.initial();
  }

  Future<void> fetchCrowdState() async {
    final repo = ref.read(stadiumRepositoryProvider);
    final stateData = await repo.getLiveCrowdState();
    state = stateData;
  }

  Future<void> forceFluctuate() async {
    await fetchCrowdState();
  }
}

final crowdStateProvider = NotifierProvider<CrowdStateNotifier, CrowdState>(() {
  return CrowdStateNotifier();
});

// 2. Incident Board Provider
class IncidentListNotifier extends Notifier<List<Incident>> {
  @override
  List<Incident> build() {
    fetchIncidents();
    return [];
  }

  Future<void> fetchIncidents() async {
    final repo = ref.read(stadiumRepositoryProvider);
    final list = await repo.getIncidents();
    state = list;
  }

  Future<void> reportIncident(Incident incident) async {
    final repo = ref.read(stadiumRepositoryProvider);
    await repo.reportIncident(incident);
    await fetchIncidents();
  }

  Future<void> updateIncidentStatus(String id, String status) async {
    final list = state;
    final index = list.indexWhere((i) => i.id == id);
    if (index != -1) {
      final updated = list[index].copyWith(status: status);
      final repo = ref.read(stadiumRepositoryProvider);
      await repo.updateIncident(updated);
      await fetchIncidents();
    }
  }
}

final incidentListProvider =
    NotifierProvider<IncidentListNotifier, List<Incident>>(() {
      return IncidentListNotifier();
    });

// 3. Volunteer Tasks Provider
class VolunteerTasksNotifier extends Notifier<List<VolunteerTask>> {
  @override
  List<VolunteerTask> build() {
    fetchTasks();
    return [];
  }

  Future<void> fetchTasks() async {
    final repo = ref.read(stadiumRepositoryProvider);
    final list = await repo.getVolunteerTasks();
    state = list;
  }

  Future<void> toggleTaskCompleted(String taskId) async {
    final list = state;
    final index = list.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updatedTask = list[index].copyWith(
        isCompleted: !list[index].isCompleted,
      );
      final repo = ref.read(stadiumRepositoryProvider);
      await repo.updateVolunteerTask(updatedTask);
      await fetchTasks();
    }
  }
}

final volunteerTasksProvider =
    NotifierProvider<VolunteerTasksNotifier, List<VolunteerTask>>(() {
      return VolunteerTasksNotifier();
    });

// 4. Match Configuration Selection Provider
class SelectedMatchNotifier extends Notifier<String> {
  @override
  String build() {
    final secureStorage = ref.watch(secureStorageProvider);
    return secureStorage.read('sp_selected_match') ?? 'match_argentina_france';
  }

  Future<void> setMatch(String matchId) async {
    state = matchId;
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.write('sp_selected_match', matchId);
    // Also trigger telemetry refresh or force crowd state fetch if needed
    ref.read(crowdStateProvider.notifier).forceFluctuate();
  }
}

final selectedMatchProvider = NotifierProvider<SelectedMatchNotifier, String>(
  () {
    return SelectedMatchNotifier();
  },
);

// 5. Volunteer Deployment Notifier Provider
class VolunteerDeploymentNotifier extends Notifier<VolunteerDeployment> {
  @override
  VolunteerDeployment build() {
    final secureStorage = ref.watch(secureStorageProvider);
    final saved = secureStorage.read('sp_volunteer_deployment');
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved);
        return VolunteerDeployment(
          plazaActive: decoded['plazaActive'] ?? 14,
          plazaBreak: decoded['plazaBreak'] ?? 2,
          concourseActive: decoded['concourseActive'] ?? 10,
          concourseBreak: decoded['concourseBreak'] ?? 0,
          medicalActive: decoded['medicalActive'] ?? 8,
          medicalBreak: decoded['medicalBreak'] ?? 1,
          securityActive: decoded['securityActive'] ?? 6,
          securityBreak: decoded['securityBreak'] ?? 0,
        );
      } catch (_) {}
    }
    return VolunteerDeployment.initial();
  }

  Future<void> updateDeployment(VolunteerDeployment deployment) async {
    state = deployment;
    final secureStorage = ref.read(secureStorageProvider);
    final encoded = jsonEncode({
      'plazaActive': deployment.plazaActive,
      'plazaBreak': deployment.plazaBreak,
      'concourseActive': deployment.concourseActive,
      'concourseBreak': deployment.concourseBreak,
      'medicalActive': deployment.medicalActive,
      'medicalBreak': deployment.medicalBreak,
      'securityActive': deployment.securityActive,
      'securityBreak': deployment.securityBreak,
    });
    await secureStorage.write('sp_volunteer_deployment', encoded);
  }

  Future<void> reallocate(String fromZone, String toZone, int count) async {
    int pa = state.plazaActive;
    int ca = state.concourseActive;
    int ma = state.medicalActive;
    int sa = state.securityActive;

    // Subtract from source
    if (fromZone == 'plaza' && pa >= count) pa -= count;
    if (fromZone == 'concourse' && ca >= count) ca -= count;
    if (fromZone == 'medical' && ma >= count) ma -= count;
    if (fromZone == 'security' && sa >= count) sa -= count;

    // Add to destination
    if (toZone == 'plaza') pa += count;
    if (toZone == 'concourse') ca += count;
    if (toZone == 'medical') ma += count;
    if (toZone == 'security') sa += count;

    await updateDeployment(
      state.copyWith(
        plazaActive: pa,
        concourseActive: ca,
        medicalActive: ma,
        securityActive: sa,
      ),
    );
  }

  Future<void> reset() async {
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.delete('sp_volunteer_deployment');
    state = VolunteerDeployment.initial();
  }
}

final volunteerDeploymentProvider =
    NotifierProvider<VolunteerDeploymentNotifier, VolunteerDeployment>(() {
      return VolunteerDeploymentNotifier();
    });

// 6. Shift Check-in Notifier Provider
class ShiftCheckInNotifier extends Notifier<bool> {
  @override
  bool build() {
    final secureStorage = ref.watch(secureStorageProvider);
    return secureStorage.read('sp_shift_checkin') == 'true';
  }

  Future<void> setCheckIn(bool val) async {
    state = val;
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.write('sp_shift_checkin', val.toString());
  }
}

final shiftCheckInProvider = NotifierProvider<ShiftCheckInNotifier, bool>(() {
  return ShiftCheckInNotifier();
});

class ActiveScenarioNotifier extends Notifier<SimulationScenario> {
  @override
  SimulationScenario build() => SimulationScenario.none;

  void setScenario(SimulationScenario scenario) {
    state = scenario;
  }
}

final activeScenarioProvider =
    NotifierProvider<ActiveScenarioNotifier, SimulationScenario>(() {
      return ActiveScenarioNotifier();
    });

// 7. Reactive AI Decision Feed Provider
final aiRecommendationsProvider = FutureProvider<List<AIRecommendation>>((
  ref,
) async {
  final role = ref.watch(userRoleProvider);
  final crowd = ref.watch(crowdStateProvider);
  final incidents = ref.watch(incidentListProvider);
  final tasks = ref.watch(volunteerTasksProvider);
  final matchId = ref.watch(selectedMatchProvider);
  final deployment = ref.watch(volunteerDeploymentProvider);
  final activeScenario = ref.watch(activeScenarioProvider);

  final preset = MatchPreset.presets.firstWhere(
    (p) => p.matchId == matchId,
    orElse: () => MatchPreset.presets.first,
  );

  final engine = GetAIRecommendations();
  return await engine.call(
    role: role,
    location: role == UserRole.fan ? 'Section 128' : 'Operations gate A',
    crowdState: crowd,
    incidents: incidents,
    tasks: tasks,
    weatherAlert: preset.weatherAlert,
    temperature: preset.temperature,
    deployment: deployment,
    activeScenario: activeScenario,
  );
});

// 8. AI Risk Prediction Provider
final riskPredictionsProvider = FutureProvider<List<OperationalRisk>>((
  ref,
) async {
  final crowdState = ref.watch(crowdStateProvider);
  final matchId = ref.watch(selectedMatchProvider);
  final preset = MatchPreset.presets.firstWhere(
    (p) => p.matchId == matchId,
    orElse: () => MatchPreset.presets.first,
  );

  final List<OperationalRisk> risks = [];

  // 1. Gate Congestion Prediction
  final gateBWait = crowdState.gateWaitTimes['Gate B'] ?? 0;
  if (gateBWait >= 15) {
    risks.add(
      const OperationalRisk(
        id: 'risk_gate_b',
        title: 'High Congestion Warning: Gate B entry lanes',
        riskCategory: 'Gate',
        probability: 0.88,
        timeline: 'Within 15 minutes',
        description:
            'RFID inflow sensors detect a surge of 4,500 fans arriving via North Commuter Rail walking routes toward Gate B.',
        preventiveAction:
            'Trigger mobile app push alerts to reroute incoming fans to Gate D and activate volunteer marshalling at MetLife plaza.',
        expectedImpact:
            'Bypasses bottleneck, reducing peak gate queue delays by 22%.',
      ),
    );
  }

  // 2. Medical Station Overload
  if (preset.weatherAlert == 'Extreme Heat Alert') {
    risks.add(
      const OperationalRisk(
        id: 'risk_medical_heat',
        title: 'Thermal Distress Surge: Medical Desk West',
        riskCategory: 'Medical',
        probability: 0.76,
        timeline: 'Within 30 minutes',
        description:
            'Ambient temperatures of 36°C combined with high plaza congestion are projected to double heat exhaust incidents.',
        preventiveAction:
            'Pre-deploy cooling packs, dispatch 3 accessibility volunteers to Section 112 lobby, and increase water supplies.',
        expectedImpact:
            'Stabilizes emergency responder dispatch delay below 3 mins.',
      ),
    );
  }

  // 3. Transportation delays
  final railUsage = preset.railUsageRate;
  if (railUsage >= 0.80) {
    risks.add(
      const OperationalRisk(
        id: 'risk_transit_delay',
        title: 'Platform Overcrowding: FIFA Metro Line 1',
        riskCategory: 'Transit',
        probability: 0.92,
        timeline: 'Post-Match',
        description:
            'Projected train boardings exceed platform holding capacity due to high transit preference (88% commuter rail).',
        preventiveAction:
            'Request transit authority to dispatch 2 additional loop trains and open secondary walking transit routes.',
        expectedImpact:
            'Prevents platform exit locks, saving 25 mins exit queue time.',
      ),
    );
  }

  // 4. Crowd Surge Prediction
  final foodCourt1Wait =
      crowdState.foodCourtWaitTimes['Food Court 1 (North)'] ?? 0;
  if (foodCourt1Wait >= 15) {
    risks.add(
      const OperationalRisk(
        id: 'risk_crowd_surge',
        title: 'Concourse Bottleneck: North Food Court Corridor',
        riskCategory: 'Crowd',
        probability: 0.72,
        timeline: 'During Half-Time',
        description:
            'Crowd densities are projected to exceed 4 persons/sqm near North Food Court during half-time concession rush.',
        preventiveAction:
            'Activate structural routing barrier guide rails, and redirect walk flows to the wider South concessions lobby.',
        expectedImpact:
            'Maintains walkway speeds above 1.1 m/s, preventing localized crushing hazards.',
      ),
    );
  }

  // 5. Weather impact
  if (preset.weatherAlert == 'Heavy Lightning Warning') {
    risks.add(
      const OperationalRisk(
        id: 'risk_weather_lightning',
        title: 'Structural Clearance Risk: Seating Deck Area',
        riskCategory: 'Weather',
        probability: 0.95,
        timeline: 'Immediate',
        description:
            'Active lightning strikes recorded within 5 miles. 82% probability of lightning strike within MetLife stadium envelope.',
        preventiveAction:
            'Initiate immediate seating deck evacuation broadcast and move all open-area fans inside concourses.',
        expectedImpact:
            'Protects personal safety, minimizing severe weather hazard index.',
      ),
    );
  }

  // 6. Exit bottlenecks
  risks.add(
    const OperationalRisk(
      id: 'risk_exit_bottleneck',
      title: 'Gate Clearance Bottleneck: Gate A egress routes',
      riskCategory: 'Exit',
      probability: 0.65,
      timeline: 'Post-Match',
      description:
          'Egress modeling predicts exit bottlenecks at Gate A due to narrow outer fence construction design.',
      preventiveAction:
          'Open secondary escape gates A3 and A4, and flash exit bypass directions on standard big screens.',
      expectedImpact:
          'Reduces post-match stadium exit clearance time by 18 mins.',
    ),
  );

  return risks;
});

// 9. AI Proactive Alert Entities & Provider
class ProactiveAlert {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String time;

  const ProactiveAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.time,
  });
}

final proactiveAlertsProvider = FutureProvider<List<ProactiveAlert>>((
  ref,
) async {
  final role = ref.watch(userRoleProvider);
  final crowd = ref.watch(crowdStateProvider);
  final activeScenario = ref.watch(activeScenarioProvider);
  final incidents = ref.watch(incidentListProvider);
  final matchId = ref.watch(selectedMatchProvider);
  final preset = MatchPreset.presets.firstWhere(
    (p) => p.matchId == matchId,
    orElse: () => MatchPreset.presets.first,
  );

  final List<ProactiveAlert> alerts = [];

  // 1. Leave Now Warning
  if (activeScenario == SimulationScenario.extraTime ||
      activeScenario == SimulationScenario.penaltyShootout ||
      preset.attendanceProjection >= 80000) {
    alerts.add(
      const ProactiveAlert(
        id: 'leave_now',
        title: 'Action Recommended: Leave Now',
        description:
            'Surge projection shows exit platforms are starting to bottleneck. Head to Metro Line 2 immediately.',
        icon: Icons.exit_to_app,
        color: Colors.orange,
        time: 'Just now',
      ),
    );
  }

  // 2. Gate B becoming crowded alert
  final gateBWait = crowd.gateWaitTimes['Gate B'] ?? 0;
  if (gateBWait >= 18) {
    alerts.add(
      ProactiveAlert(
        id: 'gate_b_crowded',
        title: 'Gate B Inflow Surge Warning',
        description:
            'Gate B wait times are currently $gateBWait mins and rising. Rerouting via Gate D (5 min wait) is advised.',
        icon: Icons.sensor_door,
        color: Colors.red,
        time: '2 mins ago',
      ),
    );
  }

  // 3. Metro delayed alert
  if (activeScenario == SimulationScenario.transportDelay) {
    alerts.add(
      const ProactiveAlert(
        id: 'metro_delayed',
        title: 'Transit Delay Alert: FIFA Metro Line 1',
        description:
            '20 minutes signal failure delay reported by Municipal transit authority. Seek walking Eco-Paths.',
        icon: Icons.subway,
        color: Colors.orange,
        time: 'Just now',
      ),
    );
  }

  // 4. Restroom queue increasing alert
  final restroomWait = crowd.restroomWaitTimes['Restrooms Level 1 East'] ?? 0;
  if (restroomWait >= 12) {
    alerts.add(
      ProactiveAlert(
        id: 'restroom_queue',
        title: 'Concourse Restroom Alert',
        description:
            'Level 1 East restroom queue has increased to $restroomWait mins. Level 2 South (3 mins wait) is clear.',
        icon: Icons.wc,
        color: Colors.blue,
        time: '5 mins ago',
      ),
    );
  }

  // 5. Food court overloaded alert
  final foodWait = crowd.foodCourtWaitTimes['Food Court 1 (North)'] ?? 0;
  if (foodWait >= 18) {
    alerts.add(
      ProactiveAlert(
        id: 'food_court_overload',
        title: 'Food Court 1 Overload Warning',
        description:
            'North food court wait time has hit $foodWait mins. Bypassing via South court or ordering on mobile is advised.',
        icon: Icons.fastfood,
        color: Colors.orange,
        time: 'Just now',
      ),
    );
  }

  // 6. Accessibility elevator busy alert
  alerts.add(
    const ProactiveAlert(
      id: 'elevator_busy',
      title: 'Elevator West High Utilization',
      description:
          'Vertical elevator transit near Section 120 has reached high load index. Expect up to 4 mins delay.',
      icon: Icons.elevator,
      color: Colors.blue,
      time: '3 mins ago',
    ),
  );

  // 7. Volunteer assistance needed nearby alert
  if (role == UserRole.volunteer) {
    final openIncidents = incidents.where((i) => i.status == 'Open').toList();
    if (openIncidents.isNotEmpty) {
      alerts.add(
        ProactiveAlert(
          id: 'volunteer_needed',
          title: 'Assistance Needed Nearby: ${openIncidents.first.location}',
          description:
              'Incident "${openIncidents.first.title}" remains unassigned. Report to location immediately.',
          icon: Icons.contact_support,
          color: Colors.red,
          time: 'Just now',
        ),
      );
    }
  }

  return alerts;
});
