import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/overtime_record.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/overtime_controller.dart';

class OvertimePage extends StatelessWidget {
  const OvertimePage({super.key});

  @override
  Widget build(BuildContext context) {
    final OvertimeController controller = Get.find<OvertimeController>();
    final AuthController authController = Get.find<AuthController>();
    final bool isAdmin = authController.session.value?.user?.role == 'admin';

    // Fetch data every time we enter the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isAdmin) {
        controller.loadAllOvertime();
      } else {
        controller.loadMyOvertime();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(),
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
                    onPressed: isAdmin ? controller.loadAllOvertime : controller.loadMyOvertime,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final List<OvertimeRecord> records = isAdmin ? controller.allOvertime : controller.myOvertime;

          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.access_time_filled, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No overtime records',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: isAdmin ? controller.loadAllOvertime : controller.loadMyOvertime,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (BuildContext context, int index) {
                final OvertimeRecord record = records[index];
                return _buildOvertimeCard(context, record, isAdmin);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOvertimeCard(
    BuildContext context,
    OvertimeRecord record,
    bool isAdmin,
  ) {
    final Color statusColor = _getStatusColor(record.status);
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      color: Colors.grey.shade100,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (isAdmin && record.employeeName != null)
                        Text(
                          record.employeeName!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      Text(
                        dateFormat.format(DateTime.parse(record.date)),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                   
                  ),
                  child: Text(
                    record.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${record.hours.toStringAsFixed(1)} hours',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            if (record.description != null && record.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                record.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (isAdmin && record.managerName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Added by: ${record.managerName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
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
}

