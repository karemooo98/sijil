import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/standalone_task.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/standalone_task_controller.dart';

class StandaloneTasksPage extends StatelessWidget {
  const StandaloneTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final StandaloneTaskController controller = Get.find<StandaloneTaskController>();
    final AuthController authController = Get.find<AuthController>();
    final String? userRole = authController.session.value?.user.role;
    final bool isAdmin = userRole == 'admin';
    final bool isManager = userRole == 'manager';
    final bool canApprove = isAdmin || isManager;

    // Fetch data every time we enter the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadMyTasks();
      if (canApprove) {
        controller.loadAllTasks();
      }
    });

    return DefaultTabController(
      length: canApprove ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          bottom: canApprove
              ? const TabBar(
                  tabs: <Widget>[
                    Tab(text: 'My Tasks'),
                    Tab(text: 'All Tasks'),
                  ],
                )
              : null,
          actions: <Widget>[
            if (canApprove)
              PopupMenuButton<String>(
                onSelected: (String? status) {
                  controller.loadAllTasks(status: status == 'all' ? null : status);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem(value: 'all', child: Text('All')),
                  const PopupMenuItem(value: 'pending', child: Text('Pending')),
                  const PopupMenuItem(value: 'approved', child: Text('Approved')),
                  const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
                ],
                icon: const Icon(Icons.filter_list),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateTaskDialog(context, controller),
          icon: const Icon(Icons.add_task),
          label: const Text('New Task'),
        ),
        body: TabBarView(
          children: <Widget>[
            _buildMyTasksTab(context, controller),
            if (canApprove) _buildAllTasksTab(context, controller, canApprove),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTasksTab(BuildContext context, StandaloneTaskController controller) {
    return Obx(
      () {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadMyTasks,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.myTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.task_alt, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No tasks yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first task',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadMyTasks,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.myTasks.length,
            itemBuilder: (BuildContext context, int index) {
              final StandaloneTask task = controller.myTasks[index];
              return _buildTaskCard(context, task, null);
            },
          ),
        );
      },
    );
  }

  Widget _buildAllTasksTab(
    BuildContext context,
    StandaloneTaskController controller,
    bool canApprove,
  ) {
    return Obx(
      () {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadAllTasks(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.allTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.task_alt, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No tasks found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadAllTasks(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.allTasks.length,
            itemBuilder: (BuildContext context, int index) {
              final StandaloneTask task = controller.allTasks[index];
              return _buildTaskCard(context, task, canApprove ? controller : null);
            },
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    StandaloneTask task,
    StandaloneTaskController? controller,
  ) {
    final Color statusColor = _getStatusColor(task.status);
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    task.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateFormat.format(DateTime.parse(task.date)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Reported: ${task.reportedHours.toStringAsFixed(1)}h',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (task.approvedHours != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Approved: ${task.approvedHours!.toStringAsFixed(1)}h',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green[700],
                        ),
                  ),
                ],
              ],
            ),
            if (controller != null && task.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _approveTask(context, task, controller, 'approved'),
                      icon: const Icon(Icons.check, color: Colors.green),
                      label: const Text('Approve'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _approveTask(context, task, controller, 'rejected'),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showCreateTaskDialog(
    BuildContext context,
    StandaloneTaskController controller,
  ) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController hoursController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Create Task',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Task Title *'),
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
                        decoration: const InputDecoration(labelText: 'Description *'),
                        maxLines: 3,
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: hoursController,
                        decoration: const InputDecoration(labelText: 'Reported Hours *'),
                        keyboardType: TextInputType.number,
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Hours is required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Obx(
                        () => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            if (controller.errorMessage.value.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  controller.errorMessage.value,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            FilledButton(
                              onPressed: controller.isCreating.value
                                  ? null
                                  : () async {
                                      if (formKey.currentState?.validate() == true) {
                                        final bool success = await controller.createTask(
                                          title: titleController.text,
                                          date: DateFormat('yyyy-MM-dd').format(selectedDate),
                                          reportedHours: double.parse(hoursController.text),
                                          description: descriptionController.text.trim(),
                                        );
                                        if (context.mounted) {
                                          if (success) {
                                            Navigator.of(context).pop(true);
                                            // Delay refresh to allow dialog to fully close
                                            Future.delayed(const Duration(milliseconds: 300), () {
                                              controller.loadMyTasks();
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Task created successfully'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            // Error message is already shown above
                                          }
                                        }
                                      }
                                    },
                              child: controller.isCreating.value
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Create Task'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Delay disposal to ensure dialog animation completes
    Future.delayed(const Duration(milliseconds: 500), () {
      titleController.dispose();
      descriptionController.dispose();
      hoursController.dispose();
    });

    if (result == true) {
      // Task was created successfully
    }
  }

  Future<void> _approveTask(
    BuildContext context,
    StandaloneTask task,
    StandaloneTaskController controller,
    String status,
  ) async {
    final TextEditingController hoursController = TextEditingController(
      text: task.reportedHours.toStringAsFixed(1),
    );

    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(status == 'approved' ? 'Approve Task' : 'Reject Task'),
        content: status == 'approved'
            ? TextField(
                controller: hoursController,
                decoration: const InputDecoration(
                  labelText: 'Approved Hours',
                  hintText: 'Leave empty to use reported hours',
                ),
                keyboardType: TextInputType.number,
              )
            : const Text('Are you sure you want to reject this task?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final double? approvedHours = hoursController.text.isNotEmpty
                  ? double.tryParse(hoursController.text)
                  : null;
              final bool success = await controller.approveTask(
                taskId: task.id,
                status: status,
                approvedHours: approvedHours ?? (status == 'approved' ? task.reportedHours : null),
              );
              if (context.mounted) {
                Navigator.of(context).pop(success);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Task ${status == 'approved' ? 'approved' : 'rejected'} successfully'),
                    ),
                  );
                }
              }
            },
            child: Text(status == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    ).whenComplete(() {
      // Dispose controller when dialog is dismissed
    hoursController.dispose();
    });
  }
}

