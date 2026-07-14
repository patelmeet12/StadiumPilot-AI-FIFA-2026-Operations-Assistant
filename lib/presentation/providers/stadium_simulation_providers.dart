import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/crowd_state.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/volunteer_task.dart';
import '../../domain/entities/ai_recommendation.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/entities/match_detail.dart';
import '../../domain/entities/volunteer_deployment.dart';
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
  );
});
