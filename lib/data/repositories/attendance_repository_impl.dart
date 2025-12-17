import '../../core/utils/typedefs.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_summary.dart';
import '../../domain/entities/attendance_summary_overview.dart';
import '../../domain/entities/my_attendance_record.dart';
import '../../domain/entities/my_summary.dart';
import '../../domain/entities/online_attendance_status.dart';
import '../../domain/entities/user_summary.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/remote_api_service.dart';
import '../models/attendance_record_model.dart';
import '../models/attendance_summary_model.dart';
import '../models/attendance_summary_overview_model.dart';
import '../models/my_attendance_record_model.dart';
import '../models/my_summary_model.dart';
import '../models/online_attendance_status_model.dart';
import '../models/user_summary_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl(this._api);

  final RemoteApiService _api;

  @override
  Future<List<AttendanceRecord>> getAttendanceByDate(DateTime date) async {
    final dynamic response = await _api.getAttendanceByDate(date);
    final List<Map<String, dynamic>> parsed = _asList(response);
    return parsed
        .map(
          (Map<String, dynamic> item) => AttendanceRecordModel.fromJson(item),
        )
        .toList();
  }

  @override
  Future<AttendanceSummary> getAttendanceSummary(DateTime date) async {
    final Map<String, dynamic> response = await _api.getAttendanceSummary(date);
    return AttendanceSummaryModel.fromJson(response);
  }

  @override
  Future<List<AttendanceRecord>> getMyAttendance({int? limit}) async {
    final dynamic response = await _api.getMyAttendance(limit: limit);
    final List<Map<String, dynamic>> parsed = _asList(
      response,
      alternativeKeys: <String>['attendance', 'data'],
    );
    return parsed
        .map(
          (Map<String, dynamic> item) => AttendanceRecordModel.fromJson(item),
        )
        .toList();
  }

  @override
  Future<List<UserSummary>> getAllUsersSummary({
    DateTime? from,
    DateTime? to,
  }) async {
    final dynamic response = await _api.getAllUsersSummary(from: from, to: to);
    final List<Map<String, dynamic>> parsed = _asList(
      response,
      alternativeKeys: <String>['data'],
    );
    return parsed
        .map((Map<String, dynamic> item) => UserSummaryModel.fromJson(item))
        .toList();
  }

  @override
  Future<OnlineAttendanceStatus> getOnlineStatus() async {
    final Map<String, dynamic> response = await _api
        .getOnlineAttendanceStatus();
    return OnlineAttendanceStatusModel.fromJson(response);
  }

  @override
  Future<AttendanceSummaryOverview> getMySummary({
    DateTime? from,
    DateTime? to,
  }) async {
    final Map<String, dynamic> response = await _api.getMySummary(
      from: from,
      to: to,
    );
    final MySummaryModel summary = MySummaryModel.fromJson(<String, dynamic>{
      'attendance': response['attendance'] ?? <dynamic>[],
      'missing_days_count': response['missing_days_count'] ?? 0,
      'absent_days': response['absent_days'] ?? <dynamic>[],
      'weekend_days': response['weekend_days'] ?? <dynamic>[],
      'statistics': response['statistics'] ?? <String, dynamic>{},
      'overtime': response['overtime'],
      'tasks': response['tasks'],
    });

    final JsonMap stats = summary.statistics ?? <String, dynamic>{};

    return AttendanceSummaryOverviewModel.fromJson(<String, dynamic>{
      'total_users': stats['total_users'] ?? summary.attendance.length,
      'present':
          stats['present'] ??
          summary.attendance
              .where((MyAttendanceRecord record) => record.status == 'present')
              .length,
      'absent': stats['absent'] ?? summary.missingDaysCount,
      'missing_checkout': stats['missing_checkout'] ?? 0,
      'on_time': stats['on_time'] ?? 0,
      'left_early': stats['left_early'] ?? 0,
      'average_hours': stats['average_hours']?.toDouble() ?? 0,
    });
  }

  @override
  Future<MySummary> getMyFullSummary({DateTime? from, DateTime? to}) async {
    final Map<String, dynamic> response = await _api.getMySummary(
      from: from,
      to: to,
    );
    return MySummaryModel.fromJson(<String, dynamic>{
      'attendance': response['attendance'] ?? <dynamic>[],
      'missing_days_count': response['missing_days_count'] ?? 0,
      'absent_days': response['absent_days'] ?? <dynamic>[],
      'weekend_days': response['weekend_days'] ?? <dynamic>[],
      'statistics': response['statistics'] ?? <String, dynamic>{},
      'overtime': response['overtime'],
      'tasks': response['tasks'],
    });
  }

  @override
  Future<List<MyAttendanceRecord>> getMyAttendanceHistory({
    int limit = 30,
  }) async {
    final dynamic response = await _api.getMyAttendanceHistory(limit: limit);
    final List<Map<String, dynamic>> parsed = _asList(
      response,
      alternativeKeys: <String>['attendance', 'data'],
    );
    return parsed
        .map(
          (Map<String, dynamic> item) => MyAttendanceRecordModel.fromJson(item),
        )
        .toList();
  }

  @override
  Future<void> onlineCheckIn({
    required double latitude,
    required double longitude,
  }) => _api.onlineCheckIn(
        latitude: latitude,
        longitude: longitude,
      );

  @override
  Future<void> onlineCheckOut({
    required double latitude,
    required double longitude,
  }) => _api.onlineCheckOut(
        latitude: latitude,
        longitude: longitude,
      );

  @override
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
  }) async {
    final Map<String, dynamic> response = await _api.updateAttendance(
      recordId: recordId,
      userId: userId,
      date: date,
      status: status,
      checkIn: checkIn,
      checkOut: checkOut,
      hoursAdjustmentType: hoursAdjustmentType,
      hoursAdjustment: hoursAdjustment,
      reason: reason,
    );
    
    // Extract data from response safely
    Map<String, dynamic> data;
    if (response.containsKey('data') && response['data'] != null && response['data'] is Map) {
      data = Map<String, dynamic>.from(response['data'] as Map);
    } else {
      data = Map<String, dynamic>.from(response);
    }
    
    // Ensure required fields are present, use provided values as fallback
    if (!data.containsKey('user_id') || data['user_id'] == null) {
      data['user_id'] = userId;
    }
    if (!data.containsKey('date') || data['date'] == null) {
      data['date'] = date;
    }
    if (!data.containsKey('user_name') || data['user_name'] == null) {
      data['user_name'] = ''; // Will be populated on refresh
    }
    
    return AttendanceRecordModel.fromJson(data);
  }

  List<Map<String, dynamic>> _asList(
    dynamic response, {
    List<String> alternativeKeys = const <String>[],
  }) {
    if (response is List) {
      return response
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    if (response is Map<String, dynamic>) {
      for (final String key in alternativeKeys) {
        final dynamic value = response[key];
        if (value is List) {
          return value
              .map((dynamic item) => Map<String, dynamic>.from(item as Map))
              .toList();
        }
      }
      if (response['data'] is List) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data
            .map((dynamic item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    }
    return <Map<String, dynamic>>[];
  }
}
