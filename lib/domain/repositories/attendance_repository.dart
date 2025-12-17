import '../entities/attendance_record.dart';
import '../entities/attendance_summary.dart';
import '../entities/attendance_summary_overview.dart';
import '../entities/my_attendance_record.dart';
import '../entities/my_summary.dart';
import '../entities/online_attendance_status.dart';
import '../entities/user_summary.dart';

abstract interface class AttendanceRepository {
  Future<List<AttendanceRecord>> getAttendanceByDate(DateTime date);

  Future<AttendanceSummary> getAttendanceSummary(DateTime date);

  Future<List<AttendanceRecord>> getMyAttendance({int? limit});

  Future<List<UserSummary>> getAllUsersSummary({DateTime? from, DateTime? to});

  Future<OnlineAttendanceStatus> getOnlineStatus();

  Future<AttendanceSummaryOverview> getMySummary({
    DateTime? from,
    DateTime? to,
  });
  Future<MySummary> getMyFullSummary({DateTime? from, DateTime? to});

  Future<List<MyAttendanceRecord>> getMyAttendanceHistory({int limit});

  Future<void> onlineCheckIn({
    required double latitude,
    required double longitude,
  });

  Future<void> onlineCheckOut({
    required double latitude,
    required double longitude,
  });

  Future<AttendanceRecord> updateAttendance({
    required int? recordId,
    required int userId,
    required String date,
    required String status,
    String? checkIn,
    String? checkOut,
    String? hoursAdjustmentType,
    double? hoursAdjustment,
    String? reason,
  });
}
