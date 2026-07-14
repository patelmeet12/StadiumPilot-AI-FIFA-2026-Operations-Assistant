import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/volunteer_deployment.dart';
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

              _buildActiveZoneHeader(ref, theme),
              const SizedBox(height: 20),
              _buildQRShiftCheckInCard(context, ref, theme),
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

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;

                  final checklistWidget = Card(
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
                            const Text('No duties assigned for this shift.')
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
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
                                      color: t.isCompleted ? Colors.grey : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${t.location} • Priority: ${t.priority}',
                                  ),
                                  value: t.isCompleted,
                                  activeColor: theme.colorScheme.primary,
                                  onChanged: (_) {
                                    ref
                                        .read(volunteerTasksProvider.notifier)
                                        .toggleTaskCompleted(t.id);
                                  },
                                  contentPadding: EdgeInsets.zero,
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  );

                  final incidentFeedWidget = Column(
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
                          (i) => _buildIncidentCard(context, ref, i, theme),
                        ),
                    ],
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: checklistWidget),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: incidentFeedWidget),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        checklistWidget,
                        const SizedBox(height: 24),
                        incidentFeedWidget,
                      ],
                    );
                  }
                },
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

  Widget _buildActiveZoneHeader(WidgetRef ref, ThemeData theme) {
    final VolunteerDeployment deployment = ref.watch(volunteerDeploymentProvider);
    // Determine active assignment zone based on staff distributions
    String assignedZone = 'Plaza Entry Gates';
    if (deployment.plazaActive < 10) {
      assignedZone = 'Security Checkpoints (Redeployed by Command Console)';
    } else if (deployment.concourseActive > 10) {
      assignedZone = 'Concourse Concessions';
    } else if (deployment.medicalActive > 8) {
      assignedZone = 'Medical & Accessibility Desk';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.assignment_ind,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVE VOLUNTEER ASSIGNMENT ZONE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  assignedZone,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRShiftCheckInCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final isCheckedIn = ref.watch(shiftCheckInProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.qr_code_2,
                  color: isCheckedIn
                      ? Colors.green
                      : theme.colorScheme.secondary,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text(
                  isCheckedIn
                      ? 'Shift Duty: ACTIVE'
                      : 'Shift Duty: CHECK-IN REQUIRED',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isCheckedIn) ...[
              const Text(
                'Please scan the FIFA Volunteer Host City QR code at your entry checkpoint to register your shift and receive active task briefs.',
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.secondary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey.shade900
                            : Colors.grey.shade100,
                        child: Center(
                          child: Icon(
                            Icons.qr_code_scanner,
                            size: 80,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Scan Check-In QR Code'),
                      onPressed: () {
                        ref
                            .read(shiftCheckInProvider.notifier)
                            .setCheckIn(true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Shift check-in successful! Welcome to duty.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                'You are checked in for this shift. Live dispatch notifications and local safety logs are active.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Shift Active Time:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Text(
                    '07 hours 45 mins remaining',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('End Duty Shift (Check Out)'),
                  onPressed: () {
                    ref.read(shiftCheckInProvider.notifier).setCheckIn(false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Shift check-out successful! Shift summary logged.',
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
