import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/match_detail.dart';
import '../../domain/entities/crowd_state.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/volunteer_task.dart';
import '../../domain/repositories/stadium_repository.dart';
import '../datasources/static_stadium_data.dart';

class StadiumRepositoryImpl implements StadiumRepository {
  final SharedPreferences _prefs;
  final Random _random = Random();

  StadiumRepositoryImpl(this._prefs);

  @override
  Future<MatchDetail> getMatchDetails() async {
    return StaticStadiumData.worldCupMatch;
  }

  @override
  Future<CrowdState> getLiveCrowdState() async {
    // Check if crowd state exists in SharedPreferences
    final dataString = _prefs.getString('sp_crowd_state');

    CrowdState baseState;
    if (dataString != null) {
      try {
        final decoded = jsonDecode(dataString) as Map<String, dynamic>;
        baseState = CrowdState(
          gateWaitTimes: Map<String, int>.from(decoded['gateWaitTimes']),
          foodCourtWaitTimes: Map<String, int>.from(
            decoded['foodCourtWaitTimes'],
          ),
          restroomWaitTimes: Map<String, int>.from(
            decoded['restroomWaitTimes'],
          ),
          zoneDensities: Map<String, double>.from(decoded['zoneDensities']),
        );
      } catch (_) {
        baseState = CrowdState.initial();
      }
    } else {
      baseState = CrowdState.initial();
    }

    // Dynamic Fluctuations (Simulation):
    // Add/subtract up to 2 minutes or 5% density to make the UI look alive
    final fluctuatedGates = baseState.gateWaitTimes.map((gate, mins) {
      // Don't fluctuate past boundaries
      int drift = _random.nextInt(3) - 1; // -1, 0, 1
      int newMins = max(1, mins + drift);
      return MapEntry(gate, newMins);
    });

    final fluctuatedFood = baseState.foodCourtWaitTimes.map((court, mins) {
      int drift = _random.nextInt(3) - 1;
      int newMins = max(1, mins + drift);
      return MapEntry(court, newMins);
    });

    final fluctuatedRestrooms = baseState.restroomWaitTimes.map((room, mins) {
      int drift = _random.nextInt(2) - 1; // -1, 0, 1
      int newMins = max(1, mins + drift);
      return MapEntry(room, newMins);
    });

    final fluctuatedZones = baseState.zoneDensities.map((zone, val) {
      double drift = (_random.nextDouble() * 0.06) - 0.03; // -3% to +3%
      double newVal = double.parse(
        max(0.1, min(0.99, val + drift)).toStringAsFixed(2),
      );
      return MapEntry(zone, newVal);
    });

    final simulatedState = CrowdState(
      gateWaitTimes: fluctuatedGates,
      foodCourtWaitTimes: fluctuatedFood,
      restroomWaitTimes: fluctuatedRestrooms,
      zoneDensities: fluctuatedZones,
    );

    // Save back to keep the state progressing
    await _saveCrowdState(simulatedState);
    return simulatedState;
  }

  Future<void> _saveCrowdState(CrowdState state) async {
    final encoded = jsonEncode({
      'gateWaitTimes': state.gateWaitTimes,
      'foodCourtWaitTimes': state.foodCourtWaitTimes,
      'restroomWaitTimes': state.restroomWaitTimes,
      'zoneDensities': state.zoneDensities,
    });
    await _prefs.setString('sp_crowd_state', encoded);
  }

  @override
  Future<List<Incident>> getIncidents() async {
    final dataString = _prefs.getString('sp_incidents');
    if (dataString != null) {
      try {
        final List decoded = jsonDecode(dataString);
        return decoded.map((i) => _parseIncident(i)).toList();
      } catch (_) {
        return _resetIncidents();
      }
    }
    return _resetIncidents();
  }

  List<Incident> _resetIncidents() {
    final initial = StaticStadiumData.getInitialIncidents();
    _saveIncidents(initial);
    return initial;
  }

  Future<void> _saveIncidents(List<Incident> list) async {
    final encoded = jsonEncode(
      list
          .map(
            (i) => {
              'id': i.id,
              'title': i.title,
              'category': i.category,
              'location': i.location,
              'priority': i.priority,
              'status': i.status,
              'description': i.description,
              'reportedTime': i.reportedTime.toIso8601String(),
            },
          )
          .toList(),
    );
    await _prefs.setString('sp_incidents', encoded);
  }

  Incident _parseIncident(Map<String, dynamic> m) {
    return Incident(
      id: m['id'],
      title: m['title'],
      category: m['category'],
      location: m['location'],
      priority: m['priority'],
      status: m['status'],
      description: m['description'],
      reportedTime: DateTime.parse(m['reportedTime']),
    );
  }

  @override
  Future<void> reportIncident(Incident incident) async {
    final list = await getIncidents();
    list.insert(0, incident); // Add at the start (newest first)
    await _saveIncidents(list);
  }

  @override
  Future<void> updateIncident(Incident incident) async {
    final list = await getIncidents();
    final index = list.indexWhere((i) => i.id == incident.id);
    if (index != -1) {
      list[index] = incident;
      await _saveIncidents(list);
    }
  }

  @override
  Future<List<VolunteerTask>> getVolunteerTasks() async {
    final dataString = _prefs.getString('sp_volunteer_tasks');
    if (dataString != null) {
      try {
        final List decoded = jsonDecode(dataString);
        return decoded.map((t) => _parseTask(t)).toList();
      } catch (_) {
        return _resetTasks();
      }
    }
    return _resetTasks();
  }

  List<VolunteerTask> _resetTasks() {
    final initial = StaticStadiumData.getInitialTasks();
    _saveTasks(initial);
    return initial;
  }

  Future<void> _saveTasks(List<VolunteerTask> list) async {
    final encoded = jsonEncode(
      list
          .map(
            (t) => {
              'id': t.id,
              'title': t.title,
              'description': t.description,
              'location': t.location,
              'priority': t.priority,
              'isCompleted': t.isCompleted,
              'assignedTime': t.assignedTime.toIso8601String(),
            },
          )
          .toList(),
    );
    await _prefs.setString('sp_volunteer_tasks', encoded);
  }

  VolunteerTask _parseTask(Map<String, dynamic> m) {
    return VolunteerTask(
      id: m['id'],
      title: m['title'],
      description: m['description'],
      location: m['location'],
      priority: m['priority'],
      isCompleted: m['isCompleted'],
      assignedTime: DateTime.parse(m['assignedTime']),
    );
  }

  @override
  Future<void> updateVolunteerTask(VolunteerTask task) async {
    final list = await getVolunteerTasks();
    final index = list.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      list[index] = task;
      await _saveTasks(list);
    }
  }

  @override
  Future<void> resetSimulator() async {
    await _prefs.remove('sp_crowd_state');
    await _prefs.remove('sp_incidents');
    await _prefs.remove('sp_volunteer_tasks');
    _resetIncidents();
    _resetTasks();
  }
}
