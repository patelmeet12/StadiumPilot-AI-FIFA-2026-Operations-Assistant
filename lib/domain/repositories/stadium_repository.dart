import '../entities/match_detail.dart';
import '../entities/crowd_state.dart';
import '../entities/incident.dart';
import '../entities/volunteer_task.dart';

abstract class StadiumRepository {
  Future<MatchDetail> getMatchDetails();
  Future<CrowdState> getLiveCrowdState();
  Future<List<Incident>> getIncidents();
  Future<void> reportIncident(Incident incident);
  Future<void> updateIncident(Incident incident);
  Future<List<VolunteerTask>> getVolunteerTasks();
  Future<void> updateVolunteerTask(VolunteerTask task);
  Future<void> resetSimulator();
}
