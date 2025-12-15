import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../domain/entities/team.dart';
import '../../../domain/entities/team_member.dart';
import '../../../domain/entities/team_task.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/team_controller.dart';

class TeamDetailPage extends StatelessWidget {
  const TeamDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final int teamId = int.parse(Get.parameters['id']!);
    final TeamController controller = Get.find<TeamController>();
    final AuthController authController = Get.find<AuthController>();
    final user = authController.session.value?.user;
    final String? userRole = user?.role;
    final bool isAdmin = userRole == 'admin';
    final int? currentUserId = user?.id;

    // Load team details on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadTeamById(teamId);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.selectedTeam.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final Team? team = controller.selectedTeam.value;
          if (team == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value.isEmpty
                        ? 'Team not found'
                        : controller.errorMessage.value,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.loadTeamById(teamId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final bool isManager = team.members.any(
          (member) =>
              member.id == currentUserId && member.teamRole == 'manager',
          );
          final bool canManage = isAdmin || isManager;

          return RefreshIndicator(
            onRefresh: () => controller.loadTeamById(teamId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _buildMembersSection(context, team, controller, canManage),
                const SizedBox(height: 24),
              _buildTasksSection(
                context,
                team,
                controller,
                canManage,
                currentUserId,
              ),
              ],
            ),
          );
      }),
      floatingActionButton: Obx(() {
        final Team? team = controller.selectedTeam.value;
        if (team == null) return const SizedBox.shrink();
        final bool isManager = team.members.any(
          (member) =>
              member.id == currentUserId && member.teamRole == 'manager',
        );
        final bool canManage = isAdmin || isManager;
        if (!canManage) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: () => _showCreateTaskDialog(context, team, controller),
          icon: const Icon(Icons.add_task),
          label: const Text('New Task'),
        );
      }),
    );
  }

  Widget _buildMembersSection(
    BuildContext context,
    Team team,
    TeamController controller,
    bool canManage,
  ) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                'Members',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (canManage)
                  TextButton.icon(
                  onPressed: () =>
                      _showAddMemberDialog(context, team, controller),
                    icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Add Member'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
            if (team.members.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: <Widget>[
                  Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No members yet',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
              )
            else
              ...team.members.map(
            (member) =>
                _buildMemberCard(context, member, team, controller, canManage),
          ),
      ],
    );
  }

  Widget _buildMemberCard(
    BuildContext context,
    TeamMember member,
    Team team,
    TeamController controller,
    bool canManage,
  ) {
    final Color roleColor = _getRoleColor(context, member.teamRole);
    final bool isManagerRole = member.teamRole.toLowerCase() == 'manager';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            _buildMemberAvatar(context, member, roleColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          member.name,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (isManagerRole)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(Icons.star, size: 14, color: roleColor),
                              const SizedBox(width: 4),
                              Text(
                                'Manager',
                                style: TextStyle(
                                  color: roleColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            member.teamRole.toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  if (member.employeeNumber.isNotEmpty) ...[
                    const SizedBox(height: 2),
                  ],
                ],
              ),
            ),
            if (canManage)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red[400],
                  size: 20,
                ),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () =>
                    _confirmRemoveMember(context, team, member.id, controller),
                tooltip: 'Remove member',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberAvatar(BuildContext context, TeamMember member, Color roleColor) {
    // Check if photo exists and is not empty
    if (member.photo != null && member.photo!.trim().isNotEmpty && member.photo != 'null') {
      String imageUrl = member.photo!.trim();
      
      // If photo is a relative URL, prepend base URL
      if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
        // Ensure URL starts with /
        if (!imageUrl.startsWith('/')) {
          imageUrl = '/$imageUrl';
        }
        imageUrl = '${AppConfig.baseUrl}$imageUrl';
      }
      
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
            // Fallback to initial if image fails to load
            return CircleAvatar(
              radius: 24,
              backgroundColor: roleColor.withOpacity(0.15),
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: roleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return CircleAvatar(
              radius: 24,
              backgroundColor: roleColor.withOpacity(0.15),
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(roleColor),
              ),
            );
          },
        ),
      );
    }
    
    return CircleAvatar(
      radius: 24,
      backgroundColor: roleColor.withOpacity(0.15),
      child: Text(
        member.name.isNotEmpty ? member.name[0].toUpperCase() : 'U',
        style: TextStyle(
          color: roleColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getRoleColor(BuildContext context, String role) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    switch (role.toLowerCase()) {
      case 'manager':
        return primaryColor;
      case 'employee':
        return Colors.blueGrey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildTasksSection(
    BuildContext context,
    Team team,
    TeamController controller,
    bool canManage,
    int? currentUserId,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Tasks (${team.tasks.length})',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (team.tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No tasks yet'),
              )
            else
              ...team.tasks.map(
                (task) => _buildTaskCard(
                  context,
                  task,
                  controller,
                  canManage,
                  currentUserId,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    TeamTask task,
    TeamController controller,
    bool canManage,
    int? currentUserId,
  ) {
    final bool canUpdate = canManage || task.assignedToUserId == currentUserId;
    final Color statusColor = _getStatusColor(task.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(task.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (task.description != null) ...[
              Text(task.description!),
              const SizedBox(height: 4),
            ],
            if (task.dueDate != null)
              Text(
                'Due: ${DateFormat('MMM d, yyyy').format(DateTime.parse(task.dueDate!))}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: canUpdate
            ? PopupMenuButton<String>(
                onSelected: (String status) => controller.updateTaskStatus(
                  taskId: task.id,
                  status: status,
                ),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem(value: 'pending', child: Text('Pending')),
                  const PopupMenuItem(
                    value: 'in_progress',
                    child: Text('In Progress'),
                  ),
                  const PopupMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
                  ),
                  const PopupMenuItem(
                    value: 'reviewed',
                    child: Text('Reviewed'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    task.status.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  task.status.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'reviewed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showAddMemberDialog(
    BuildContext context,
    Team team,
    TeamController controller,
  ) async {
    // In a real app, you'd fetch available users here
    // For now, we'll use a simple text input for user ID
    final TextEditingController userIdController = TextEditingController();
    final String teamRole = 'employee';
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Add Member'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: userIdController,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  hintText: 'Enter user ID',
                ),
                keyboardType: TextInputType.number,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'User ID is required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid user ID';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () async {
                      if (formKey.currentState?.validate() == true) {
                        final bool success = await controller.addMember(
                          teamId: team.id,
                          userId: int.parse(userIdController.text),
                          teamRole: teamRole,
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop(success);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Member added successfully'),
                              ),
                            );
                          }
                        }
                      }
                    },
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      userIdController.dispose();
    }
  }

  Future<void> _confirmRemoveMember(
    BuildContext context,
    Team team,
    int userId,
    TeamController controller,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text(
          'Are you sure you want to remove this member from the team?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final bool success = await controller.removeMember(
        teamId: team.id,
        userId: userId,
      );
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed successfully')),
        );
      }
    }
  }

  Future<void> _showCreateTaskDialog(
    BuildContext context,
    Team team,
    TeamController controller,
  ) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController userIdController = TextEditingController();
    DateTime? selectedDate;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Create Task',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: userIdController,
                decoration: const InputDecoration(
                  labelText: 'Assign to User ID',
                ),
                keyboardType: TextInputType.number,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'User ID is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  selectedDate == null
                      ? 'Due Date (optional)'
                      : DateFormat('MMM d, yyyy').format(selectedDate!),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => FilledButton(
                  onPressed: controller.isCreatingTask.value
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() == true) {
                            final bool success = await controller.createTask(
                              teamId: team.id,
                              assignedToUserId: int.parse(
                                userIdController.text,
                              ),
                              title: titleController.text,
                              description: descriptionController.text.isEmpty
                                  ? null
                                  : descriptionController.text,
                              dueDate: selectedDate != null
                                  ? DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(selectedDate!)
                                  : null,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop(success);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Task created successfully'),
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: controller.isCreatingTask.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Task'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      titleController.dispose();
      descriptionController.dispose();
      userIdController.dispose();
    }
  }
}
