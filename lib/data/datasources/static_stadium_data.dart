import '../../domain/entities/match_detail.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/volunteer_task.dart';

class StaticStadiumData {
  static final MatchDetail worldCupMatch = MatchDetail(
    homeTeam: 'Argentina',
    awayTeam: 'France',
    matchTime: DateTime.now().add(const Duration(hours: 3)),
    stadiumName: 'New York New Jersey Stadium (MetLife)',
    ticketClass: 'Category 1 Premium',
    section: '128',
    row: '14',
    seat: '8',
    gate: 'Gate B',
    recommendedArrivalTime: DateTime.now().add(const Duration(hours: 1)),
  );

  static List<Incident> getInitialIncidents() {
    final now = DateTime.now();
    return [
      Incident(
        id: 'inc_1',
        title: 'Liquid Spill Near Section 104',
        category: 'Spill',
        location: 'Section 104 Corridor',
        priority: 'Medium',
        status: 'Open',
        description:
            'Large soda spill near the main concession stand. Slip hazard for fans walking to restrooms.',
        reportedTime: now.subtract(const Duration(minutes: 15)),
      ),
      Incident(
        id: 'inc_2',
        title: 'Gate B Entrance Bottleneck',
        category: 'Crowd',
        location: 'Gate B Outer Ring',
        priority: 'High',
        status: 'Open',
        description:
            'High concentration of ticket scanners failing to scan digital barcodes. Backlog is extending into the bus loop.',
        reportedTime: now.subtract(const Duration(minutes: 10)),
      ),
      Incident(
        id: 'inc_3',
        title: 'Power Outage Concession Grill 3',
        category: 'Facility',
        location: 'Food Court 1 (North)',
        priority: 'Low',
        status: 'Resolved',
        description:
            'Breaker tripped on hot dog grill. Spark electrician resolved it.',
        reportedTime: now.subtract(const Duration(minutes: 45)),
      ),
    ];
  }

  static List<VolunteerTask> getInitialTasks() {
    final now = DateTime.now();
    return [
      VolunteerTask(
        id: 'task_1',
        title: 'Direct Fans to Gate D Reroute',
        description:
            'Direct fans approaching congested Gate B towards the less crowded Gate D bypass.',
        location: 'Gate B North Plaza',
        priority: 'High',
        isCompleted: false,
        assignedTime: now.subtract(const Duration(minutes: 20)),
      ),
      VolunteerTask(
        id: 'task_2',
        title: 'Verify Elevator Braille Check',
        description:
            'Ensure elevator West tactile buttons and braille signage are clean and readable.',
        location: 'Elevator West Concourse',
        priority: 'Medium',
        isCompleted: false,
        assignedTime: now.subtract(const Duration(minutes: 15)),
      ),
      VolunteerTask(
        id: 'task_3',
        title: 'Replenish Recycling Bin Signage',
        description:
            'Affix new FIFA sustainability recycling stickers to sorting bins in the West Concourse.',
        location: 'West Concourse Corridor',
        priority: 'Low',
        isCompleted: true,
        assignedTime: now.subtract(const Duration(minutes: 30)),
      ),
    ];
  }
}
