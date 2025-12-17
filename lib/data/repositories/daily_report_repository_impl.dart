import '../../domain/entities/daily_report.dart';
import '../../domain/repositories/daily_report_repository.dart';
import '../datasources/remote_api_service.dart';
import '../models/daily_report_model.dart';

class DailyReportRepositoryImpl implements DailyReportRepository {
  DailyReportRepositoryImpl(this._api);

  final RemoteApiService _api;

  @override
  Future<List<DailyReport>> getMyDailyReports({String? date}) async {
    final dynamic response = await _api.getMyDailyReports(date: date);
    final List<Map<String, dynamic>> parsed = _asList(response);
    return parsed
        .map((Map<String, dynamic> item) => DailyReportModel.fromJson(item))
        .toList();
  }

  @override
  Future<List<DailyReport>> getAllDailyReports({
    int? userId,
    String? startDate,
    String? endDate,
  }) async {
    final dynamic response = await _api.getAllDailyReports(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
    final List<Map<String, dynamic>> parsed = _asList(response);
    return parsed
        .map((Map<String, dynamic> item) => DailyReportModel.fromJson(item))
        .toList();
  }

  @override
  Future<DailyReport> createDailyReport({
    required String date,
    required String description,
    required double hoursWorked,
    String? achievements,
    String? challenges,
    String? notes,
  }) async {
    final Map<String, dynamic> response = await _api.createDailyReport(
      date: date,
      description: description,
      hoursWorked: hoursWorked,
      achievements: achievements,
      challenges: challenges,
      notes: notes,
    );
    final Map<String, dynamic> data = _extractData(response);
    return DailyReportModel.fromJson(data);
  }

  @override
  Future<DailyReport> updateDailyReport({
    required int reportId,
    String? description,
    double? hoursWorked,
    String? achievements,
    String? challenges,
    String? notes,
  }) async {
    final Map<String, dynamic> response = await _api.updateDailyReport(
      reportId: reportId,
      description: description,
      hoursWorked: hoursWorked,
      achievements: achievements,
      challenges: challenges,
      notes: notes,
    );
    final Map<String, dynamic> data = _extractData(response);
    return DailyReportModel.fromJson(data);
  }

  @override
  Future<void> deleteDailyReport(int reportId) async {
    await _api.deleteDailyReport(reportId);
  }

  List<Map<String, dynamic>> _asList(dynamic response) {
    if (response is List) {
      return response.map((dynamic item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    if (response is Map<String, dynamic>) {
      if (response['data'] is List) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data.map((dynamic item) => Map<String, dynamic>.from(item as Map)).toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    if (response.containsKey('data') &&
        response['data'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(response['data'] as Map);
    }
    return response;
  }
}

