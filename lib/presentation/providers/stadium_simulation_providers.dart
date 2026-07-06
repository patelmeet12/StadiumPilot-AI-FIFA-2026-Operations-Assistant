import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/crowd_state.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/volunteer_task.dart';
import '../../domain/entities/ai_recommendation.dart';
import '../../domain/entities/user_role.dart';
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

final incidentListProvider = NotifierProvider<IncidentListNotifier, List<Incident>>(() {
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
      final updatedTask = list[index].copyWith(isCompleted: !list[index].isCompleted);
      final repo = ref.read(stadiumRepositoryProvider);
      await repo.updateVolunteerTask(updatedTask);
      await fetchTasks();
    }
  }
}

final volunteerTasksProvider = NotifierProvider<VolunteerTasksNotifier, List<VolunteerTask>>(() {
  return VolunteerTasksNotifier();
});

// 4. Reactive AI Decision Feed Provider
final aiRecommendationsProvider = FutureProvider<List<AIRecommendation>>((ref) async {
  final role = ref.watch(userRoleProvider);
  final crowd = ref.watch(crowdStateProvider);
  final incidents = ref.watch(incidentListProvider);
  final tasks = ref.watch(volunteerTasksProvider);

  final engine = GetAIRecommendations();
  return await engine.call(
    role: role,
    location: role == UserRole.fan ? 'Section 128' : 'Operations gate A',
    crowdState: crowd,
    incidents: incidents,
    tasks: tasks,
  );
});
