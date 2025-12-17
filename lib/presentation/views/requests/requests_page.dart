import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/user_request.dart';
import '../../../domain/usecases/approve_request_usecase.dart';
import '../../../domain/usecases/create_request_usecase.dart';
import '../../controllers/request_controller.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  late final RequestController controller;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDateFormat = DateFormat('MMM d, yyyy');

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final DateTime date = DateTime.parse(dateString);
      return _displayDateFormat.format(date);
    } catch (e) {
      // If parsing fails, try to extract just the date part
      if (dateString.contains('T')) {
        return dateString.split('T')[0];
      }
      return dateString;
    }
  }

  @override
  void initState() {
    super.initState();
    controller = Get.find<RequestController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadMyRequests();
      controller.loadPendingApprovals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool showMyRequests = !controller.canApprove;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(),
      floatingActionButton: showMyRequests
          ? FloatingActionButton.extended(
              onPressed: _openCreateRequestForm,
              label: const Text('New Request'),
              icon: const Icon(Symbols.add),
            )
          : null,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Widget> sections = <Widget>[];
        if (showMyRequests) {
          sections.addAll(<Widget>[
            Text('My requests', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (controller.myRequests.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No requests yet.'),
              )
            else
              ...controller.myRequests.map(_buildRequestTile),
            const SizedBox(height: 24),
          ]);
        }

        // Only show pending approvals section for admins/managers
        if (controller.canApprove) {
          sections.addAll(<Widget>[
            Text(
              'Pending Approvals',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (controller.pendingApprovals.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No pending requests.'),
              )
            else
              ...controller.pendingApprovals.map(_buildApprovalTile),
          ]);
        }

        return ListView(padding: const EdgeInsets.all(16), children: sections);
      }),
    );
  }

  Widget _buildRequestTile(UserRequest request) {
    final Color statusColor = request.isApproved
        ? Colors.green
        : request.isRejected
        ? Colors.red
        : Colors.orange;
    final String statusText = request.status.toUpperCase();

    return GestureDetector(
      onTap: () => _showRequestDetails(context, request),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              radius: 20,
              backgroundColor: statusColor,
              child: Icon(
                request.isApproved
                    ? Symbols.check_circle
                    : request.isRejected
                    ? Symbols.cancel
                    : Symbols.schedule,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    request.type.replaceAll('_', ' ').toUpperCase(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.reason,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      if (request.date != null)
                        _subInfo(
                          Symbols.calendar_today,
                          _formatDate(request.date),
                        ),
                      if (request.startDate != null && request.endDate != null)
                        _subInfo(
                          Symbols.date_range,
                          '${_formatDate(request.startDate)} - ${_formatDate(request.endDate)}',
                        ),
                      if (request.checkIn != null)
                        _subInfo(Symbols.login, request.checkIn!),
                      if (request.checkOut != null)
                        _subInfo(Symbols.logout, request.checkOut!),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                const SizedBox(height: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _subInfo(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalTile(UserRequest request) {
    final Color statusColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: () => _showRequestDetails(context, request),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: statusColor,
              child: Text(
                request.userName != null && request.userName!.isNotEmpty
                    ? request.userName![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _showRequestDetails(context, request),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (request.userName != null && request.userName!.isNotEmpty)
                    Text(
                      request.userName!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  if (request.userName != null && request.userName!.isNotEmpty)
                    const SizedBox(height: 2),
                  Text(
                    request.reason,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        request.type.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (request.date != null)
                        _subInfo(
                          Symbols.calendar_today,
                          _formatDate(request.date),
                        ),
                      if (request.startDate != null && request.endDate != null)
                        _subInfo(
                          Symbols.date_range,
                          '${_formatDate(request.startDate)} - ${_formatDate(request.endDate)}',
                        ),
                      if (request.checkIn != null)
                        _subInfo(Symbols.login, request.checkIn!),
                      if (request.checkOut != null)
                        _subInfo(Symbols.logout, request.checkOut!),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const SizedBox(height: 6),
              // Only show approve/reject buttons if request is still pending
              if (request.isPending)
                Wrap(
                  spacing: 4,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(
                        Symbols.cancel,
                        color: Colors.red,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _handleApproveRequest(request.id, false),
                    ),
                    IconButton(
                      icon: const Icon(
                        Symbols.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _handleApproveRequest(request.id, true),
                    ),
                  ],
                )
              else
                // Show status badge if already reviewed
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: request.isApproved
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      color: request.isApproved
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleApproveRequest(int requestId, bool approve) async {
    try {
      await controller.approveRequest(
        ApproveRequestParams(requestId: requestId, approve: approve),
      );
      // Refresh the list after successful approval
      await controller.loadPendingApprovals();
      await controller.loadMyRequests();

      if (mounted) {
        Get.snackbar(
          'Success',
          'Request ${approve ? 'approved' : 'rejected'} successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (error) {
      // Handle the "already reviewed" error gracefully
      final String errorMessage = error.toString();
      if (errorMessage.contains('already been reviewed')) {
        // Refresh the list to get the updated status
        await controller.loadPendingApprovals();
        await controller.loadMyRequests();

        if (mounted) {
          Get.snackbar(
            'Already Reviewed',
            'This request has already been reviewed',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      } else {
        if (mounted) {
          Get.snackbar(
            'Error',
            'Failed to ${approve ? 'approve' : 'reject'} request: ${errorMessage.replaceAll('Exception: ', '')}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    }
  }

  Future<void> _openCreateRequestForm() async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String type = 'day_off';
    final TextEditingController reasonController = TextEditingController();
    DateTime? selectedDate = DateTime.now();
    DateTimeRange? selectedRange;
    TimeOfDay? selectedCheckIn;
    TimeOfDay? selectedCheckOut;
    bool showDateRangeError = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
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
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      value: type,
                      onChanged: (value) {
                        modalSetState(() {
                          type = value ?? 'day_off';
                          // Reset fields when switching types
                          if (type == 'leave') {
                            selectedRange = null;
                            // Reset date when switching to leave (leave uses range)
                            selectedDate = DateTime.now();
                          } else if (type == 'attendance_correction') {
                            // Reset range when switching to attendance_correction
                            selectedRange = null;
                          } else {
                            // Reset range and time pickers when switching to day_off
                            selectedRange = null;
                            selectedCheckIn = null;
                            selectedCheckOut = null;
                          }
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          value: 'day_off',
                          child: Text('Day off'),
                        ),
                        DropdownMenuItem(value: 'leave', child: Text('Leave')),
                        DropdownMenuItem(
                          value: 'attendance_correction',
                          child: Text('Attendance correction'),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: reasonController,
                      decoration: const InputDecoration(labelText: 'Reason'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Reason required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    if (type == 'leave')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              selectedRange == null
                                  ? 'Select date range *'
                                  : '${_dateFormat.format(selectedRange!.start)} - ${_dateFormat.format(selectedRange!.end)}',
                              style: TextStyle(
                                color: showDateRangeError ? Colors.red : null,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Symbols.calendar_today),
                              onPressed: () async {
                                final DateTimeRange? range =
                                    await showDateRangePicker(
                                      context: context,
                                      firstDate: DateTime.now().subtract(
                                        const Duration(days: 30),
                                      ),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                if (range != null) {
                                  modalSetState(() {
                                    selectedRange = range;
                                    showDateRangeError = false;
                                  });
                                }
                              },
                            ),
                          ),
                          if (showDateRangeError)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 4),
                              child: Text(
                                'Date range is required',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      )
                    else if (type == 'attendance_correction')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _dateFormat.format(selectedDate ?? DateTime.now()),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Symbols.calendar_today),
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 30),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  modalSetState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final TimeOfDay? time = await showTimePicker(
                                context: context,
                                initialTime: selectedCheckIn ?? const TimeOfDay(hour: 8, minute: 0),
                              );
                              if (time != null) {
                                modalSetState(() {
                                  selectedCheckIn = time;
                                });
                              }
                            },
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                selectedCheckIn == null
                                    ? 'Select check-in time *'
                                    : selectedCheckIn!.format(context),
                              ),
                              trailing: const Icon(Icons.access_time),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final TimeOfDay? time = await showTimePicker(
                                context: context,
                                initialTime: selectedCheckOut ?? const TimeOfDay(hour: 16, minute: 0),
                              );
                              if (time != null) {
                                modalSetState(() {
                                  selectedCheckOut = time;
                                });
                              }
                            },
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                selectedCheckOut == null
                                    ? 'Select check-out time *'
                                    : selectedCheckOut!.format(context),
                              ),
                              trailing: const Icon(Icons.access_time),
                            ),
                          ),
                        ],
                      )
                    else
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _dateFormat.format(selectedDate ?? DateTime.now()),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Symbols.calendar_today),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 30),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              modalSetState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                    const SizedBox(height: 24),
                    Obx(
                      () => FilledButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : () async {
                                // Validate form fields first
                                if (formKey.currentState?.validate() != true) {
                                  return;
                                }
                                // Validate based on type
                                if (type == 'leave' && selectedRange == null) {
                                  // Show validation error for date range
                                  modalSetState(() {
                                    showDateRangeError = true;
                                  });
                                  return;
                                }
                                if (type == 'attendance_correction') {
                                  if (selectedCheckIn == null || selectedCheckOut == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please select both check-in and check-out times'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                }

                                try {
                                  // Format check-in and check-out times
                                  String? checkInTime;
                                  String? checkOutTime;
                                  if (type == 'attendance_correction' && selectedCheckIn != null && selectedCheckOut != null) {
                                    checkInTime = '${selectedCheckIn!.hour.toString().padLeft(2, '0')}:${selectedCheckIn!.minute.toString().padLeft(2, '0')}';
                                    checkOutTime = '${selectedCheckOut!.hour.toString().padLeft(2, '0')}:${selectedCheckOut!.minute.toString().padLeft(2, '0')}';
                                  }

                                  await controller.submitRequest(
                                    CreateRequestParams(
                                      type: type,
                                      reason: reasonController.text,
                                      date: type == 'leave'
                                          ? null
                                          : _dateFormat.format(
                                              selectedDate ?? DateTime.now(),
                                            ),
                                      startDate: type == 'leave' && selectedRange != null
                                          ? _dateFormat.format(selectedRange!.start)
                                          : null,
                                      endDate: type == 'leave' && selectedRange != null
                                          ? _dateFormat.format(selectedRange!.end)
                                          : null,
                                      checkIn: checkInTime,
                                      checkOut: checkOutTime,
                                      leaveType: type == 'leave' ? 'annual' : null,
                                    ),
                                  );
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                } catch (_) {
                                  // error message already handled
                                }
                              },
                        child: controller.isSubmitting.value
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Submit'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showRequestDetails(
    BuildContext context,
    UserRequest request,
  ) async {
    await controller.loadRequestById(request.id);
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (BuildContext context) => Obx(() {
          final UserRequest detailedRequest =
              controller.selectedRequest.value ?? request;
          final DateFormat dateFormat = DateFormat('MMM d, yyyy');

          return AlertDialog(
            title: Text(
              detailedRequest.type.replaceAll('_', ' ').toUpperCase(),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (detailedRequest.userName != null &&
                      detailedRequest.userName!.isNotEmpty)
                    _buildDetailRow('Employee', detailedRequest.userName!),
                  _buildDetailRow('Status', detailedRequest.status),
                  _buildDetailRow('Reason', detailedRequest.reason),
                  if (detailedRequest.date != null)
                    _buildDetailRow(
                      'Date',
                      dateFormat.format(DateTime.parse(detailedRequest.date!)),
                    ),
                  if (detailedRequest.startDate != null)
                    _buildDetailRow(
                      'Start Date',
                      dateFormat.format(
                        DateTime.parse(detailedRequest.startDate!),
                      ),
                    ),
                  if (detailedRequest.endDate != null)
                    _buildDetailRow(
                      'End Date',
                      dateFormat.format(
                        DateTime.parse(detailedRequest.endDate!),
                      ),
                    ),
                  if (detailedRequest.totalDays != null)
                    _buildDetailRow(
                      'Total Days',
                      detailedRequest.totalDays.toString(),
                    ),
                  if (detailedRequest.leaveType != null)
                    _buildDetailRow('Leave Type', detailedRequest.leaveType!),
                  if (detailedRequest.checkIn != null)
                    _buildDetailRow('Check In', detailedRequest.checkIn!),
                  if (detailedRequest.checkOut != null)
                    _buildDetailRow('Check Out', detailedRequest.checkOut!),
                  if (detailedRequest.approvedBy != null)
                    _buildDetailRow(
                      'Approved By',
                      'User ID: ${detailedRequest.approvedBy}',
                    ),
                  if (detailedRequest.approvedAt != null)
                    _buildDetailRow('Approved At', detailedRequest.approvedAt!),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        }),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
