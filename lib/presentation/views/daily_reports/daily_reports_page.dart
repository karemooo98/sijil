import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/daily_report.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/daily_report_controller.dart';

class DailyReportsPage extends StatelessWidget {
  const DailyReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DailyReportController controller = Get.find<DailyReportController>();
    final AuthController authController = Get.find<AuthController>();
    final String? userRole = authController.session.value?.user?.role;
    final bool isAdmin = userRole == 'admin';
    final bool isManager = userRole == 'manager';
    final bool canViewAll = isAdmin || isManager;

    // Fetch data every time we enter the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (canViewAll) {
        controller.loadAllReports();
      } else {
        controller.loadMyReports();
      }
    });

    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateReportDialog(context, controller),
        icon: const Icon(Icons.add),
        label: const Text('New Report'),
      ),
      body: Obx(
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
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: canViewAll ? controller.loadAllReports : controller.loadMyReports,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final List<DailyReport> reports = canViewAll ? controller.allReports : controller.myReports;

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.description, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No daily reports',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first daily report',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: canViewAll ? controller.loadAllReports : controller.loadMyReports,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (BuildContext context, int index) {
                final DailyReport report = reports[index];
                return _buildReportCard(context, report, controller, canViewAll);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    DailyReport report,
    DailyReportController controller,
    bool canViewAll,
  ) {
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');
    final AuthController authController = Get.find<AuthController>();
    final int? currentUserId = authController.session.value?.user?.id;
    final bool canEdit = !canViewAll || report.userId == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showReportDetails(context, report, controller),
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
                      dateFormat.format(DateTime.parse(report.date)),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${report.hoursWorked.toStringAsFixed(1)}h',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (canEdit) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _showEditReportDialog(context, report, controller),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => _confirmDeleteReport(context, report, controller),
                          tooltip: 'Delete',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (report.achievements != null && report.achievements!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Icon(Icons.check_circle_outline, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.achievements!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green[700],
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateReportDialog(
    BuildContext context,
    DailyReportController controller,
  ) async {
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController hoursController = TextEditingController();
    final TextEditingController achievementsController = TextEditingController();
    final TextEditingController challengesController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => Padding(
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
                  'Create Daily Report',
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
                  decoration: const InputDecoration(labelText: 'Hours Worked *'),
                  keyboardType: TextInputType.number,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Hours worked is required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: achievementsController,
                  decoration: const InputDecoration(labelText: 'Achievements (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: challengesController,
                  decoration: const InputDecoration(labelText: 'Challenges (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Obx(
                  () => FilledButton(
                    onPressed: controller.isCreating.value
                        ? null
                        : () async {
                            if (formKey.currentState?.validate() == true) {
                              try {
                                final bool success = await controller.createReport(
                                  date: DateFormat('yyyy-MM-dd').format(selectedDate),
                                  description: descriptionController.text,
                                  hoursWorked: double.parse(hoursController.text),
                                  achievements: achievementsController.text.isEmpty
                                      ? null
                                      : achievementsController.text,
                                  challenges: challengesController.text.isEmpty
                                      ? null
                                      : challengesController.text,
                                  notes: notesController.text.isEmpty ? null : notesController.text,
                                );
                                if (context.mounted) {
                                  Navigator.of(context).pop(success);
                                  if (success) {
                                    // Delay refresh to allow dialog to fully close
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      controller.loadMyReports();
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Report created successfully')),
                                    );
                                  }
                                }
                              } catch (e) {
                                // Extract error message before closing dialog
                                final String errorMsg = e.toString().replaceAll('Exception: ', '').trim();
                                // Close dialog first so snackbar is visible
                                if (context.mounted) {
                                  Navigator.of(context).pop(false);
                                  // Show error in snackbar after dialog closes
                                  Future.delayed(const Duration(milliseconds: 500), () {
                                    // Use Get.snackbar instead of ScaffoldMessenger for better reliability
                                    Get.snackbar(
                                      'Error',
                                      errorMsg,
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                      duration: const Duration(seconds: 3),
                                    );
                                  });
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
                        : const Text('Create Report'),
                  ),
                ),
                const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Delay disposal to ensure dialog animation completes
    Future.delayed(const Duration(milliseconds: 500), () {
      descriptionController.dispose();
      hoursController.dispose();
      achievementsController.dispose();
      challengesController.dispose();
      notesController.dispose();
    });

    if (result == true) {
      // Report was created successfully
    }
  }

  Future<void> _showReportDetails(
    BuildContext context,
    DailyReport report,
    DailyReportController controller,
  ) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(DateFormat('MMM d, yyyy').format(DateTime.parse(report.date))),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildDetailRow('Hours', '${report.hoursWorked.toStringAsFixed(1)}h'),
              const SizedBox(height: 12),
              _buildDetailRow('Description', report.description),
              if (report.achievements != null && report.achievements!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Achievements', report.achievements!),
              ],
              if (report.challenges != null && report.challenges!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Challenges', report.challenges!),
              ],
              if (report.notes != null && report.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Notes', report.notes!),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }

  Future<void> _showEditReportDialog(
    BuildContext context,
    DailyReport report,
    DailyReportController controller,
  ) async {
    final TextEditingController descriptionController = TextEditingController(text: report.description);
    final TextEditingController hoursController = TextEditingController(text: report.hoursWorked.toStringAsFixed(1));
    final TextEditingController achievementsController = TextEditingController(text: report.achievements ?? '');
    final TextEditingController challengesController = TextEditingController(text: report.challenges ?? '');
    final TextEditingController notesController = TextEditingController(text: report.notes ?? '');
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Edit Daily Report',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 16),
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
                decoration: const InputDecoration(labelText: 'Hours Worked *'),
                keyboardType: TextInputType.number,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Hours worked is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: achievementsController,
                decoration: const InputDecoration(labelText: 'Achievements (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: challengesController,
                decoration: const InputDecoration(labelText: 'Challenges (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Obx(
                () => FilledButton(
                  onPressed: controller.isUpdating.value
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() == true) {
                            final bool success = await controller.updateReport(
                              reportId: report.id,
                              description: descriptionController.text,
                              hoursWorked: double.parse(hoursController.text),
                              achievements: achievementsController.text.isEmpty
                                  ? null
                                  : achievementsController.text,
                              challenges: challengesController.text.isEmpty
                                  ? null
                                  : challengesController.text,
                              notes: notesController.text.isEmpty ? null : notesController.text,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop(success);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Report updated successfully')),
                                );
                              }
                            }
                          }
                        },
                  child: controller.isUpdating.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update Report'),
                ),
              ),
              const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );

    // Delay disposal to ensure dialog animation completes
    Future.delayed(const Duration(milliseconds: 500), () {
      descriptionController.dispose();
      hoursController.dispose();
      achievementsController.dispose();
      challengesController.dispose();
      notesController.dispose();
    });

    if (result == true) {
      // Report was updated successfully
    }
  }

  Future<void> _confirmDeleteReport(
    BuildContext context,
    DailyReport report,
    DailyReportController controller,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this daily report?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final bool success = await controller.deleteReport(report.id);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted successfully')),
        );
      }
    }
  }
}

