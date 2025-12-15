import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../domain/entities/attendance_record.dart';
import '../../../domain/entities/attendance_summary.dart';
import '../../controllers/attendance_controller.dart';
import '../../widgets/employee_card.dart';

class AttendanceManagementPage extends StatefulWidget {
  const AttendanceManagementPage({super.key});

  @override
  State<AttendanceManagementPage> createState() =>
      _AttendanceManagementPageState();
}

class _AttendanceManagementPageState extends State<AttendanceManagementPage> {
  late final AttendanceController controller;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    controller = Get.find<AttendanceController>();
    // Always refresh data when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshForDate(DateTime.now());
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(),
      body: Obx(() {
        if (controller.isAttendanceLoading.value ||
            controller.isSummaryLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value != null &&
            controller.errorMessage.value!.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value ?? 'Unknown error',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.refreshForDate(
                    controller.selectedDate.value,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshForDate(
            controller.selectedDate.value,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(2.0.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildDateHeader(context, controller),
                SizedBox(height: 2.5.h),
                _buildSearchField(context),
                SizedBox(height: 2.5.h),
                _buildSummaryCards(context, controller),
                SizedBox(height: 3.0.h),
                _buildSectionTitle(context, 'All Employees'),
                SizedBox(height: 1.5.h),
                _buildAttendanceList(context, controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDateHeader(
    BuildContext context,
    AttendanceController controller,
  ) {
    final DateFormat dateFormat = DateFormat('EEEE, MMM d, yyyy');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.0.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1.5.h),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.calendar_today,
                  size: 2.5.h,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 1.5.w),
                Flexible(
                  child: Text(
                    dateFormat.format(controller.selectedDate.value),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 1.8.h,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              size: 2.5.h,
              color: Theme.of(context).colorScheme.primary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showDatePicker(context, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    AttendanceController controller,
  ) {
    final AttendanceSummary? summary = controller.summary.value;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _buildStatCard(
                context,
                'Present',
                summary.present.toString(),
                'employees',
                Icons.check_circle,
                primaryColor,
              ),
            ),
            SizedBox(width: 1.5.w),
            Expanded(
              child: _buildStatCard(
                context,
                'Absent',
                summary.absent.toString(),
                'employees',
                Icons.event_busy,
                primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildStatCard(
                context,
                'Missing Checkout',
                summary.missingCheckout.toString(),
                'employees',
                Icons.warning_amber,
                primaryColor,
              ),
            ),
            SizedBox(width: 1.5.w),
            Expanded(
              child: _buildStatCard(
                context,
                'Left Early',
                summary.leftEarly.toString(),
                'employees',
                Icons.trending_down,
                primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(1.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(1.2.h),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(0.6.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(0.8.h),
                ),
                child: Icon(icon, color: color, size: 2.0.h),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: 1.0.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 3.0.h, // Increased from 2.2.h to make numbers bigger
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 0.4.w),
              Padding(
                padding: EdgeInsets.only(bottom: 0.15.h),
                child: Text(
                  unit,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                        fontSize: 1.1.h,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.2.h),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 1.1.h,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(top: 1.0.h),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontSize: 2.0.h,
            ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      style: TextStyle(fontSize: 1.8.h),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[50],
        hintText: 'Search by name or employee number...',
        hintStyle: TextStyle(fontSize: 1.6.h),
        prefixIcon: Icon(Icons.search, size: 2.5.h),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 2.5.h),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1.5.h),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1.5.h),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1.5.h),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 2.0.w,
          vertical: 1.5.h,
        ),
      ),
    );
  }

  Widget _buildAttendanceList(
    BuildContext context,
    AttendanceController controller,
  ) {
    final List<AttendanceRecord> allRecords = controller.attendanceByDate;
    
    // Filter records based on search query
    final List<AttendanceRecord> records = _searchQuery.isEmpty
        ? allRecords
        : allRecords.where((AttendanceRecord record) {
            final String name = record.userName.toLowerCase();
            final String employeeNumber = record.userEmployeeNumber?.toLowerCase() ?? '';
            final String userId = record.userId.toString();
            return name.contains(_searchQuery) ||
                employeeNumber.contains(_searchQuery) ||
                userId.contains(_searchQuery);
          }).toList();

    if (allRecords.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.0.h),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(1.5.h),
        ),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.info_outline,
              size: 6.0.h,
              color: Colors.grey[400],
            ),
            SizedBox(height: 2.0.h),
            Text(
              'No attendance records for this date',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 1.8.h,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (records.isEmpty && _searchQuery.isNotEmpty) {
      return Container(
        padding: EdgeInsets.all(4.0.h),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(1.5.h),
        ),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.search_off,
              size: 6.0.h,
              color: Colors.grey[400],
            ),
            SizedBox(height: 2.0.h),
            Text(
              'No results found for "$_searchQuery"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 1.8.h,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: records
          .map((AttendanceRecord record) => _buildEmployeeCard(context, record))
          .toList(),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, AttendanceRecord record) {
    final Map<String, dynamic> badge = _statusBadge(record);

    return EmployeeCard(
      userName: record.userName,
      employeeNumber: record.userEmployeeNumber,
      userId: record.userId,
      photo: record.userPhoto,
      onTap: () => _showEditAttendanceDialog(context, record),
      subtitle: Wrap(
        spacing: 1.0.w,
        runSpacing: 0.5.h,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _subInfo(Symbols.login, _formatTime(record.firstCheckIn)),
          _subInfo(Symbols.logout, _formatTime(record.lastCheckOut)),
          _subInfo(
            Symbols.timer,
            _formatDuration(record.workedHours),
          ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          SizedBox(height: 0.8.h),
          Text(
            '${record.workedHours?.toStringAsFixed(1) ?? '0'}h',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 1.8.h,
                ),
          ),
          SizedBox(height: 0.5.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 1.0.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: badge['color'] as Color,
              borderRadius: BorderRadius.circular(1.0.h),
            ),
            child: Text(
              badge['label'] as String,
              style: TextStyle(
                color: badge['textColor'] as Color,
                fontWeight: FontWeight.w600,
                fontSize: 1.3.h,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditAttendanceDialog(
    BuildContext context,
    AttendanceRecord record,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return _EditAttendanceDialog(record: record, onSave: _updateAttendance);
      },
    );
  }

  Future<void> _updateAttendance(
    AttendanceRecord record,
    String status,
    String checkIn,
    String checkOut,
    String? hoursAdjustmentType,
    double? hoursAdjustment,
    String reason,
  ) async {
    try {
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
      final DateFormat dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final DateTime recordDate = DateTime.parse(record.date);
      
      // Format check_in and check_out as full datetime strings
      String? formattedCheckIn;
      String? formattedCheckOut;
      
      if (checkIn.isNotEmpty) {
        // Parse time (HH:mm) and combine with date
        try {
          final List<String> timeParts = checkIn.split(':');
          if (timeParts.length == 2) {
            final int hour = int.parse(timeParts[0]);
            final int minute = int.parse(timeParts[1]);
            if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
              final DateTime checkInDateTime = DateTime(
                recordDate.year,
                recordDate.month,
                recordDate.day,
                hour,
                minute,
              );
              formattedCheckIn = dateTimeFormat.format(checkInDateTime);
            }
          }
        } catch (e) {
          // Invalid time format, will be handled by API validation
        }
      }
      
      if (checkOut.isNotEmpty) {
        // Parse time (HH:mm) and combine with date
        try {
          final List<String> timeParts = checkOut.split(':');
          if (timeParts.length == 2) {
            final int hour = int.parse(timeParts[0]);
            final int minute = int.parse(timeParts[1]);
            if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
              final DateTime checkOutDateTime = DateTime(
                recordDate.year,
                recordDate.month,
                recordDate.day,
                hour,
                minute,
              );
              formattedCheckOut = dateTimeFormat.format(checkOutDateTime);
            }
          }
        } catch (e) {
          // Invalid time format, will be handled by API validation
        }
      }
      
      await controller.updateAttendance(
        recordId: record.id,
        userId: record.userId,
        date: dateFormat.format(recordDate),
        status: status,
        checkIn: formattedCheckIn,
        checkOut: formattedCheckOut,
        hoursAdjustmentType: hoursAdjustmentType,
        hoursAdjustment: hoursAdjustment,
        reason: reason.isNotEmpty ? reason : null,
      );
      if (mounted) {
        Get.snackbar(
          'Success',
          'Attendance updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to update attendance: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Widget _subInfo(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 1.4.h, color: Colors.grey[600]),
        SizedBox(width: 0.4.w),
        Text(
          value,
          style: TextStyle(color: Colors.grey[700], fontSize: 1.2.h),
        ),
      ],
    );
  }

  Map<String, dynamic> _statusBadge(AttendanceRecord record) {
    String label = 'Present';
    Color background = Colors.green.shade100;
    Color textColor = Colors.green.shade800;

    if (record.lastCheckOut == null && record.firstCheckIn != null) {
      label = 'In Progress';
      background = Colors.blue.shade100;
      textColor = Colors.blue.shade800;
    } else if ((record.missingHours ?? 0) > 0.1) {
      label = 'Late';
      background = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
    } else if ((record.status ?? '') != 'present') {
      label = record.status?.toUpperCase() ?? 'Status';
      background = Colors.grey.shade200;
      textColor = Colors.grey.shade800;
    } else {
      label = 'On Time';
      background = Colors.green.shade100;
      textColor = Colors.green.shade800;
    }

    return <String, dynamic>{
      'label': label,
      'color': background,
      'textColor': textColor,
    };
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '--';

    // Try to parse as full datetime string (e.g., "2025-11-17 08:30:00")
    DateTime? dateTime = DateTime.tryParse(value);

    // If parsing fails, try to parse as time-only string (e.g., "08:30")
    if (dateTime == null) {
      final RegExp timePattern = RegExp(r'^(\d{1,2}):(\d{2})$');
      final Match? match = timePattern.firstMatch(value.trim());
      if (match != null) {
        final int hour = int.parse(match.group(1)!);
        final int minute = int.parse(match.group(2)!);
        dateTime = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          hour,
          minute,
        );
      }
    }

    if (dateTime == null) return value;

    return DateFormat('hh:mm a').format(dateTime);
  }

  String _formatDuration(double? hours) {
    if (hours == null) return '--';
    if (hours < 1) {
      final int minutes = (hours * 60).round();
      return '${minutes}m';
    }
    return '${hours.toStringAsFixed(1)}h';
  }

  Future<void> _showDatePicker(
    BuildContext context,
    AttendanceController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      await controller.refreshForDate(picked);
    }
  }
}

class _EditAttendanceDialog extends StatefulWidget {
  final AttendanceRecord record;
  final Future<void> Function(
    AttendanceRecord record,
    String status,
    String checkIn,
    String checkOut,
    String? hoursAdjustmentType,
    double? hoursAdjustment,
    String reason,
  ) onSave;

  const _EditAttendanceDialog({
    required this.record,
    required this.onSave,
  });

  @override
  State<_EditAttendanceDialog> createState() => _EditAttendanceDialogState();
}

class _EditAttendanceDialogState extends State<_EditAttendanceDialog> {
  late final TextEditingController checkInController;
  late final TextEditingController checkOutController;
  late final TextEditingController hoursAdjustmentController;
  late final TextEditingController reasonController;
  late String selectedStatus;
  String? hoursAdjustmentType;

  @override
  void initState() {
    super.initState();
    final DateFormat timeFormat = DateFormat('HH:mm');
    selectedStatus = widget.record.status ?? 'present';

    // Parse existing times or use empty strings
    String checkInTime = '';
    String checkOutTime = '';
    if (widget.record.firstCheckIn != null && widget.record.firstCheckIn!.isNotEmpty) {
      try {
        // Try to parse as time-only string (HH:mm)
        final RegExp timePattern = RegExp(r'^(\d{1,2}):(\d{2})$');
        final Match? match = timePattern.firstMatch(widget.record.firstCheckIn!);
        if (match != null) {
          checkInTime = widget.record.firstCheckIn!;
        } else {
          // Try to parse as full datetime
          final DateTime? dt = DateTime.tryParse(widget.record.firstCheckIn!);
          if (dt != null) {
            checkInTime = timeFormat.format(dt);
          }
        }
      } catch (_) {
        // Keep empty if parsing fails
      }
    }
    if (widget.record.lastCheckOut != null && widget.record.lastCheckOut!.isNotEmpty) {
      try {
        final RegExp timePattern = RegExp(r'^(\d{1,2}):(\d{2})$');
        final Match? match = timePattern.firstMatch(widget.record.lastCheckOut!);
        if (match != null) {
          checkOutTime = widget.record.lastCheckOut!;
        } else {
          final DateTime? dt = DateTime.tryParse(widget.record.lastCheckOut!);
          if (dt != null) {
            checkOutTime = timeFormat.format(dt);
          }
        }
      } catch (_) {
        // Keep empty if parsing fails
      }
    }

    checkInController = TextEditingController(text: checkInTime);
    checkOutController = TextEditingController(text: checkOutTime);
    hoursAdjustmentController = TextEditingController(text: '0');
    reasonController = TextEditingController();
  }

  @override
  void dispose() {
    checkInController.dispose();
    checkOutController.dispose();
    hoursAdjustmentController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      final List<String> parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {
      // Return current time if parsing fails
    }
    return TimeOfDay.now();
  }

  @override
  Widget build(BuildContext context) {
    final AttendanceController controller = Get.find<AttendanceController>();
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');
    final bool isNewRecord = widget.record.id == null;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Text('Edit Attendance'),
          IconButton(
            icon: const Icon(Icons.close),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${dateFormat.format(DateTime.parse(widget.record.date))} - ${widget.record.userName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (isNewRecord) ...[
                const SizedBox(height: 8),
                Text(
                  'New Record',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Status',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: <String>[
                  'present',
                  'absent',
                  'day_off',
                  'on_leave',
                  'partial',
                  'late',
                  'missing_checkout',
                  'overnight',
                  'still_working',
                ].map<DropdownMenuItem<String>>((String value) {
                  String displayName = value;
                  switch (value) {
                    case 'day_off':
                      displayName = 'Day Off';
                      break;
                    case 'on_leave':
                      displayName = 'On Leave';
                      break;
                    case 'missing_checkout':
                      displayName = "Didn't Check Out";
                      break;
                    case 'still_working':
                      displayName = 'Still Working';
                      break;
                    default:
                      displayName = value
                          .split('_')
                          .map((String word) =>
                              word[0].toUpperCase() + word.substring(1))
                          .join(' ');
                  }
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(displayName),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedStatus = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              // Check In field
              Text(
                'Check In',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: checkInController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  hintText: '--:--',
                  prefixIcon: const Icon(Icons.access_time, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                keyboardType: TextInputType.datetime,
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: checkInController.text.isNotEmpty
                        ? _parseTime(checkInController.text)
                        : TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      checkInController.text =
                          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Check Out field
              Text(
                'Check Out',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: checkOutController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  hintText: '--:--',
                  prefixIcon: const Icon(Icons.access_time, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                keyboardType: TextInputType.datetime,
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: checkOutController.text.isNotEmpty
                        ? _parseTime(checkOutController.text)
                        : TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      checkOutController.text =
                          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              // Hours Adjustment section
              Text(
                'Hours Adjustment',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: hoursAdjustmentType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50],
                        hintText: 'Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: <String>['add', 'subtract']
                          .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value == 'add' ? 'Add' : 'Subtract',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          hoursAdjustmentType = newValue;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: hoursAdjustmentController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50],
                        hintText: '0',
                        suffixText: 'Hours',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Reason field
              Text(
                'Reason',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  hintText: 'Enter reason for this change...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: controller.isUpdating.value
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        Obx(
          () => FilledButton(
            onPressed: controller.isUpdating.value
                ? null
                : () async {
                    // Read controller values BEFORE closing dialog
                    final String checkIn = checkInController.text.trim();
                    final String checkOut = checkOutController.text.trim();
                    final String hoursAdjustmentText = hoursAdjustmentController.text.trim();
                    final String reason = reasonController.text.trim();
                    
                    Navigator.of(context).pop();
                    await widget.onSave(
                      widget.record,
                      selectedStatus,
                      checkIn,
                      checkOut,
                      hoursAdjustmentType,
                      double.tryParse(hoursAdjustmentText),
                      reason,
                    );
                  },
            child: controller.isUpdating.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save'),
          ),
        ),
      ],
    );
  }
}
