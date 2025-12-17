import '../../core/utils/typedefs.dart';
import '../../domain/entities/user_request.dart';
import '../../domain/repositories/request_repository.dart';
import '../datasources/remote_api_service.dart';
import '../models/user_request_model.dart';

class RequestRepositoryImpl implements RequestRepository {
  RequestRepositoryImpl(this._api);

  final RemoteApiService _api;

  @override
  Future<List<UserRequest>> getMyRequests() async {
    final dynamic response = await _api.getMyRequests();
    final List<Map<String, dynamic>> data = _asList(response);
    return data.map(UserRequestModel.fromJson).toList();
  }

  @override
  Future<List<UserRequest>> getAllRequests() async {
    final dynamic response = await _api.getAllRequests();
    final List<Map<String, dynamic>> data = _asList(response);
    return data.map(UserRequestModel.fromJson).toList();
  }

  @override
  Future<UserRequest> createRequest({
    required String type,
    required String reason,
    String? date,
    String? startDate,
    String? endDate,
    String? checkIn,
    String? checkOut,
    String? leaveType,
  }) async {
    final JsonMap payload = <String, dynamic>{
      'type': type,
      'reason': reason,
    };

    // Add fields based on request type
    if (type == 'day_off') {
      // Day off: only type, date, and reason
      if (date != null) {
        payload['date'] = date;
      }
    } else if (type == 'leave') {
      // Leave: type, reason, start_date, end_date, leave_type
      if (startDate != null) {
        payload['start_date'] = startDate;
      }
      if (endDate != null) {
        payload['end_date'] = endDate;
      }
      if (leaveType != null) {
        payload['leave_type'] = leaveType;
      }
    } else if (type == 'attendance_correction') {
      // Attendance correction: type, reason, date, check_in, check_out
      if (date != null) {
        payload['date'] = date;
      }
      if (checkIn != null) {
        payload['check_in'] = checkIn;
      }
      if (checkOut != null) {
        payload['check_out'] = checkOut;
      }
    }

    final Map<String, dynamic> response = await _api.createRequest(payload);
    final Map<String, dynamic> data = response.containsKey('data')
        ? Map<String, dynamic>.from(response['data'] as Map)
        : response;
    return UserRequestModel.fromJson(data);
  }

  @override
  Future<UserRequest> approveRequest({
    required int requestId,
    required bool approve,
    String? note,
  }) async {
    final JsonMap payload = <String, dynamic>{
      'action': approve ? 'approve' : 'reject',
      if (note != null && note.isNotEmpty) 'note': note,
    };
    final Map<String, dynamic> response = await _api.approveRequest(
      requestId: requestId,
      payload: payload,
    );
    final Map<String, dynamic> data = response.containsKey('data')
        ? Map<String, dynamic>.from(response['data'] as Map)
        : response;
    return UserRequestModel.fromJson(data);
  }

  @override
  Future<UserRequest> getRequestById(int requestId) async {
    final Map<String, dynamic> response = await _api.getRequestById(requestId);
    final Map<String, dynamic> data = response.containsKey('data')
        ? Map<String, dynamic>.from(response['data'] as Map)
        : response;
    return UserRequestModel.fromJson(data);
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
}

