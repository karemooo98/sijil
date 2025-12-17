import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/attendance_summary_overview.dart';
import '../../domain/entities/daily_report.dart';
import '../../domain/entities/my_attendance_record.dart';
import '../../domain/entities/my_summary.dart';
import '../../domain/entities/online_attendance_status.dart';
import '../../domain/usecases/get_my_attendance_history_usecase.dart';
import '../../domain/usecases/get_my_summary_usecase.dart';
import '../../domain/usecases/get_my_full_summary_usecase.dart';
import '../../domain/usecases/get_online_status_usecase.dart';
import '../../domain/usecases/online_check_in_usecase.dart';
import '../../domain/usecases/online_check_out_usecase.dart';
import 'auth_controller.dart';
import 'daily_report_controller.dart';

class SelfAttendanceController extends GetxController {
  SelfAttendanceController({
    required this.getOnlineStatusUseCase,
    required this.getMySummaryUseCase,
    required this.getMyFullSummaryUseCase,
    required this.getMyAttendanceHistoryUseCase,
    required this.onlineCheckInUseCase,
    required this.onlineCheckOutUseCase,
  });

  final GetOnlineStatusUseCase getOnlineStatusUseCase;
  final GetMySummaryUseCase getMySummaryUseCase;
  final GetMyFullSummaryUseCase getMyFullSummaryUseCase;
  final GetMyAttendanceHistoryUseCase getMyAttendanceHistoryUseCase;
  final OnlineCheckInUseCase onlineCheckInUseCase;
  final OnlineCheckOutUseCase onlineCheckOutUseCase;

  final Rx<OnlineAttendanceStatus?> onlineStatus = Rx<OnlineAttendanceStatus?>(
    null,
  );
  final Rx<AttendanceSummaryOverview?> mySummary =
      Rx<AttendanceSummaryOverview?>(null);
  final Rx<MySummary?> fullMySummary = Rx<MySummary?>(null);
  final RxList<MyAttendanceRecord> history = <MyAttendanceRecord>[].obs;

  DateTime? summaryFromDate;
  DateTime? summaryToDate;

  final RxBool isStatusLoading = false.obs;
  final RxBool isSummaryLoading = false.obs;
  final RxBool isHistoryLoading = false.obs;
  final RxBool isCheckInProcessing = false.obs;
  final RxBool isCheckOutProcessing = false.obs;
  final RxnString errorMessage = RxnString();

  bool get isEmployee {
    final user = Get.find<AuthController>().session.value?.user;
    // Allow both employees and admins to access employee features
    // Admins can also be employees and should have access to their own attendance
    return user != null && (user.isEmployee || user.isAdmin);
  }

  @override
  void onInit() {
    super.onInit();
    if (isEmployee) {
      refreshAll();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait(<Future<void>>[
      loadOnlineStatus(),
      loadSummary(),
      loadHistory(),
    ]);
  }

  Future<void> loadOnlineStatus() async {
    if (!isEmployee) return;
    try {
      isStatusLoading.value = true;
      final OnlineAttendanceStatus status = await getOnlineStatusUseCase();
      onlineStatus.value = status;
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isStatusLoading.value = false;
    }
  }

  Future<void> loadSummary() async {
    if (!isEmployee) return;
    try {
      isSummaryLoading.value = true;
      final AttendanceSummaryOverview summary = await getMySummaryUseCase(
        from: summaryFromDate,
        to: summaryToDate,
      );
      mySummary.value = summary;

      // Also load full summary
      final MySummary fullSummary = await getMyFullSummaryUseCase(
        from: summaryFromDate,
        to: summaryToDate,
      );
      fullMySummary.value = fullSummary;
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isSummaryLoading.value = false;
    }
  }

  Future<void> loadSummaryWithDates(DateTime? from, DateTime? to) async {
    summaryFromDate = from;
    summaryToDate = to;
    await loadSummary();
  }

  Future<void> loadHistory() async {
    if (!isEmployee) return;
    try {
      isHistoryLoading.value = true;
      final List<MyAttendanceRecord> records =
          await getMyAttendanceHistoryUseCase(limit: 10);
      history.assignAll(records);
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isHistoryLoading.value = false;
    }
  }

  Future<void> checkIn() async {
    if (!isEmployee) return;

    // Ensure online status is loaded
    if (onlineStatus.value == null) {
      await loadOnlineStatus();
    }

    // Check if user can check in
    final status = onlineStatus.value;
    if (status?.canCheckIn != true) {
      Get.snackbar(
        'Cannot Check In',
        'You cannot check in at this time. Please check your attendance status.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isCheckInProcessing.value = true;

      // Get current location
      final Position? position = await _getCurrentLocation();
      if (position == null) {
        Get.snackbar(
          'Location Required',
          'Unable to get your current location. Please enable location services and try again.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Call the online check-in API endpoint with location
      await onlineCheckInUseCase(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Show success message
      Get.snackbar(
        'Check-in Successful',
        'You have been checked in successfully.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      // Refresh status and summary
      await loadOnlineStatus();
      await loadSummary();
      await loadHistory();
    } catch (error) {
      errorMessage.value = error.toString();
      Get.snackbar(
        'Error',
        'Failed to check in: ${error.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isCheckInProcessing.value = false;
    }
  }

  Future<void> checkOut() async {
    if (!isEmployee) return;

    // Prevent multiple simultaneous calls
    if (isCheckOutProcessing.value) {
      return;
    }

    // Ensure online status is loaded
    if (onlineStatus.value == null) {
      await loadOnlineStatus();
    }

    // Check if user can check out
    final status = onlineStatus.value;
    if (status?.canCheckOut != true) {
      Get.snackbar(
        'Cannot Check Out',
        'You cannot check out at this time. Please check your attendance status.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Check if user has checked in
    if (status?.checkInTime == null || status!.checkInTime!.isEmpty) {
      Get.snackbar(
        'Cannot Check Out',
        'Please check in first before checking out.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Set processing flag early to prevent multiple calls
    isCheckOutProcessing.value = true;

    try {
      // Get current location first
      final Position? position = await _getCurrentLocation();
      if (position == null) {
        isCheckOutProcessing.value = false;
        return;
      }

      // Check if there's already a report for the check-in date
      final DailyReportController reportController =
          Get.find<DailyReportController>();
      
      // Always reload reports to ensure we have the latest data
      await reportController.loadMyReports();

      // Check if check-in was before midnight and it's now a new day
      // If check-in date is from yesterday (before midnight) and it's now a new day,
      // use check-in endpoint instead of check-out endpoint
      final DateTime now = DateTime.now();
      final String todayDate = DateFormat('yyyy-MM-dd').format(now);
      final bool checkInDateIsYesterday = status.date != todayDate;
      
      // If check-in date is from yesterday, use check-in endpoint instead
      final bool shouldUseCheckInEndpoint = checkInDateIsYesterday;

      // Check if report exists for check-in date (normalize dates for comparison)
      final String checkInDate = status.date; // Format: yyyy-MM-dd
      final bool reportExists = reportController.myReports.any(
        (DailyReport report) {
          // Normalize both dates to yyyy-MM-dd format for comparison
          // Handle different date formats: "2025-12-17", "2025-12-17T00:00:00", "2025-12-17 00:00:00"
          String reportDate = report.date;
          if (reportDate.contains('T')) {
            reportDate = reportDate.split('T')[0];
          } else if (reportDate.contains(' ')) {
            reportDate = reportDate.split(' ')[0];
          }
          return reportDate == checkInDate;
        },
      );

      String? reportDescription;
      if (!reportExists) {
        // No report exists, show dialog to create one
        reportDescription = await _showCheckoutReportDialog();
        if (reportDescription == null) {
          // User cancelled the dialog
          isCheckOutProcessing.value = false;
          return;
        }
      }

      if (!reportExists) {
        // Calculate hours worked from check-in time to current time
        final double hoursWorked = _calculateHoursWorked(
          checkInTime: status.checkInTime!,
          checkInDate: status.date,
        );

        // Create the daily report first
        final bool reportCreated = await reportController.createReport(
          date: status.date, // Use check-in date
          description: reportDescription!,
          hoursWorked: hoursWorked,
        );

        if (!reportCreated) {
          Get.snackbar(
            'Error',
            'Failed to create report. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
          );
          isCheckOutProcessing.value = false;
          return;
        }
      }

      // If check-in was before midnight and it's now after midnight, use check-in endpoint
      // Otherwise, use check-out endpoint
      if (shouldUseCheckInEndpoint) {
        await onlineCheckInUseCase(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } else {
        await onlineCheckOutUseCase(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }

      // Show success message
      Get.snackbar(
        'Check-out Successful',
        'You have been checked out successfully.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      // Refresh status and summary
      await loadOnlineStatus();
      await loadSummary();
      await loadHistory();
    } catch (error) {
      errorMessage.value = error.toString();
      final String message = error.toString();
      if (message.toLowerCase().contains('check-in') &&
          message.toLowerCase().contains('first')) {
        Get.snackbar(
          'Cannot Check Out',
          'Please check in first, then try to check out.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to check out: ${error.toString()}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      // Refresh status so buttons reflect the current allowed action
      await loadOnlineStatus();
    } finally {
      isCheckOutProcessing.value = false;
    }
  }

  Future<String?> _showCheckoutReportDialog() async {
    final TextEditingController descriptionController =
        TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final String? result = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Check-out Report'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Please provide a description of your work today.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  autofocus: true,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Get.back(result: descriptionController.text.trim());
              }
            },
            child: const Text('Check Out'),
          ),
        ],
      ),
    );

    // Delay disposal to allow dialog animation to complete
    Future.delayed(const Duration(milliseconds: 500), () {
      descriptionController.dispose();
    });

    return result;
  }

  double _calculateHoursWorked({
    required String checkInTime,
    required String checkInDate,
  }) {
    try {
      // Parse check-in date and time
      final DateTime checkInDateTime = _parseDateTime(checkInDate, checkInTime);
      
      // Get current date and time
      final DateTime now = DateTime.now();
      
      // Calculate difference in hours
      final Duration difference = now.difference(checkInDateTime);
      final double hours = difference.inMinutes / 60.0;
      
      // Return at least 0 hours (in case of any calculation issues)
      // Round to 2 decimal places for precision
      final double roundedHours = (hours * 100).round() / 100.0;
      return roundedHours > 0 ? roundedHours : 0.0;
    } catch (e) {
      // Log the error for debugging
      print('Error calculating hours worked: $e');
      print('Check-in date: $checkInDate, Check-in time: $checkInTime');
      // If calculation fails, return 0
      return 0.0;
    }
  }

  DateTime _parseDateTime(String date, String time) {
    try {
      // First, try to parse time as a full datetime string (e.g., "2025-11-17 08:30:00" or "2025-11-17T08:30:00")
      DateTime? dateTime = DateTime.tryParse(time);
      if (dateTime != null) {
        // If time is a full datetime, check if the date matches
        // If it does, use it directly; otherwise, update the date part
        final String timeDateStr = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
        if (timeDateStr == date) {
          // Date matches, use the datetime directly
          return dateTime;
        } else {
          // Date doesn't match, use the provided date with time from parsed datetime
          final List<String> dateParts = date.split('-');
          final int year = int.parse(dateParts[0]);
          final int month = int.parse(dateParts[1]);
          final int day = int.parse(dateParts[2]);
          return DateTime(year, month, day, dateTime.hour, dateTime.minute, dateTime.second);
        }
      }

      // Try parsing date in format "yyyy-MM-dd"
      final List<String> dateParts = date.split('-');
      if (dateParts.length != 3) {
        throw FormatException('Invalid date format: $date');
      }
      final int year = int.parse(dateParts[0]);
      final int month = int.parse(dateParts[1]);
      final int day = int.parse(dateParts[2]);

      // Parse time - could be "HH:mm:ss" or "HH:mm" or just "HH"
      final String trimmedTime = time.trim();
      final List<String> timeParts = trimmedTime.split(':');
      
      if (timeParts.isEmpty) {
        throw FormatException('Invalid time format: $time');
      }

      final int hour = int.parse(timeParts[0]);
      final int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
      final int second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

      return DateTime(year, month, day, hour, minute, second);
    } catch (e) {
      // If parsing fails, try using DateFormat
      try {
        final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
        final DateTime dateOnly = dateFormat.parse(date);
        
        // Try to parse time as full datetime first
        DateTime? timeDateTime = DateTime.tryParse(time);
        if (timeDateTime != null) {
          return DateTime(
            dateOnly.year,
            dateOnly.month,
            dateOnly.day,
            timeDateTime.hour,
            timeDateTime.minute,
            timeDateTime.second,
          );
        }
        
        // Parse time separately
        final String trimmedTime = time.trim();
        final List<String> timeParts = trimmedTime.split(':');
        if (timeParts.isEmpty) {
          throw FormatException('Invalid time format: $time');
        }
        final int hour = int.parse(timeParts[0]);
        final int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
        
        return DateTime(
          dateOnly.year,
          dateOnly.month,
          dateOnly.day,
          hour,
          minute,
        );
      } catch (e2) {
        // Last resort: use current date with parsed time
        try {
          final String trimmedTime = time.trim();
          final List<String> timeParts = trimmedTime.split(':');
          if (timeParts.isEmpty) {
            throw FormatException('Invalid time format: $time');
          }
          final int hour = int.parse(timeParts[0]);
          final int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
          
          // Use check-in date if we can parse it
          try {
            final List<String> dateParts = date.split('-');
            if (dateParts.length == 3) {
              final int year = int.parse(dateParts[0]);
              final int month = int.parse(dateParts[1]);
              final int day = int.parse(dateParts[2]);
              return DateTime(year, month, day, hour, minute);
            }
          } catch (_) {
            // Fall through to use current date
          }
          
          return DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day, hour, minute);
        } catch (e3) {
          // If all parsing fails, throw an error
          throw FormatException('Failed to parse date/time: date=$date, time=$time. Errors: $e, $e2, $e3');
        }
      }
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Show dialog with option to open location settings
        final bool? openSettings = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Location Services Disabled'),
            content: const Text(
              'Location services are disabled on your device. Please enable location services to check in/out.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (openSettings == true) {
          try {
            await Geolocator.openLocationSettings();
          } catch (_) {
            await openAppSettings();
          }
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          final bool? openSettings = await Get.dialog<bool>(
            AlertDialog(
              title: const Text('Location Permission Required'),
              content: const Text(
                'Location permission is required to check in/out. Please grant permission in app settings.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Get.back(result: true),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          if (openSettings == true) {
            await openAppSettings();
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        final bool? openSettings = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'Location permission is permanently denied. Please enable it in app settings to check in/out.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (openSettings == true) {
          await openAppSettings();
        }
        return null;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return position;
    } catch (e) {
      Get.snackbar(
        'Location Error',
        'Failed to get your location: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return null;
    }
  }

}
