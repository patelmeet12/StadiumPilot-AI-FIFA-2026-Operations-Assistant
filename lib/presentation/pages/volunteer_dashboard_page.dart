import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/incident.dart';
import '../providers/stadium_simulation_providers.dart';
import '../widgets/stadium_shell.dart';

class VolunteerDashboardPage extends ConsumerWidget {
  const VolunteerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(volunteerTasksProvider);
    final incidents = ref.watch(incidentListProvider);
    final theme = Theme.of(context);

    final completedTasksCount = tasks.where((t) => t.isCompleted).length;
    final totalTasksCount = tasks.length;
    final progress = totalTasksCount == 0
        ? 0.0
        : completedTasksCount / totalTasksCount;

    final openIncidents = incidents
        .where((i) => i.status != 'Resolved')
        .toList();

    return StadiumShell(
      currentPath: '/volunteer',
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Volunteer Operations Desk',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Coordinate fan routing, perform visual checks, and claim unresolved field incidents.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Progress Tracker
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shift Duty Completion: ${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade800,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                              minHeight: 10,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Completed $completedTasksCount out of $totalTasksCount assigned tasks.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Splitting tasks and incidents
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Checklist column
                      Expanded(
                        flex: 3,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'My Assigned Task Checklist',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (tasks.isEmpty)
                                  const Text(
                                    'No duties assigned for this shift.',
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: tasks.length,
                                    separatorBuilder: (c, i) => const Divider(),
                                    itemBuilder: (context, index) {
                                      final t = tasks[index];
                                      return CheckboxListTile(
                                        title: Text(
                                          t.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            decoration: t.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: t.isCompleted
                                                ? Colors.grey
                                                : null,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${t.location} • Priority: ${t.priority}',
                                        ),
                                        value: t.isCompleted,
                                        activeColor: theme.colorScheme.primary,
                                        onChanged: (_) {
                                          ref
                                              .read(
                                                volunteerTasksProvider.notifier,
                                              )
                                              .toggleTaskCompleted(t.id);
                                        },
                                        contentPadding: EdgeInsets.zero,
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (isWide) const SizedBox(width: 24),

                      // Incident dispatch board
                      Expanded(
                        flex: isWide ? 2 : 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Active Incident Feed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (openIncidents.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text(
                                    'All reported issues have been fully resolved.',
                                  ),
                                ),
                              )
                            else
                              ...openIncidents.map(
                                (i) =>
                                    _buildIncidentCard(context, ref, i, theme),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Mobile view stack list
              if (MediaQuery.of(context).size.width <= 900)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Column(
                    children: openIncidents
                        .map((i) => _buildIncidentCard(context, ref, i, theme))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentCard(
    BuildContext context,
    WidgetRef ref,
    Incident i,
    ThemeData theme,
  ) {
    Color priorityColor = Colors.grey;
    if (i.priority == 'Critical') priorityColor = Colors.red;
    if (i.priority == 'High') priorityColor = Colors.amber.shade800;
    if (i.priority == 'Medium') priorityColor = Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    i.priority.toUpperCase(),
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    i.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${i.location}',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              i.description,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Status: ${i.status.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: i.status == 'Open' ? Colors.red : Colors.blue,
                  ),
                ),
                const Spacer(),
                if (i.status == 'Open')
                  TextButton.icon(
                    icon: const Icon(Icons.handyman, size: 14),
                    label: const Text(
                      'Assign to Me',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      ref
                          .read(incidentListProvider.notifier)
                          .updateIncidentStatus(i.id, 'Assigned');
                    },
                  )
                else if (i.status == 'Assigned')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text(
                      'Mark Resolved',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    onPressed: () {
                      ref
                          .read(incidentListProvider.notifier)
                          .updateIncidentStatus(i.id, 'Resolved');
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
