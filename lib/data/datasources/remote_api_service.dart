import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/typedefs.dart';

class RemoteApiService {
  RemoteApiService(this._client);

  final ApiClient _client;
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  Future<JsonMap> login({
    required String email,
    required String password,
  }) async {
    final dynamic response = await _client.post(
      '/api/v1/auth/login',
      data: <String, dynamic>{'email': email, 'password': password},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> logout() => _client.post('/api/v1/auth/logout');

  Future<JsonMap> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    String? employeeNumber,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
    };
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      payload['phone_number'] = phoneNumber;
    }
    if (employeeNumber != null && employeeNumber.isNotEmpty) {
      payload['employee_number'] = int.tryParse(employeeNumber) ?? employeeNumber;
    }
    final dynamic response = await _client.post('/api/v1/auth/register', data: payload);
    return Map<String, dynamic>.from(response as Map);
  }

  Future<JsonMap> fetchProfile() async {
    final dynamic response = await _client.get('/api/v1/me');
    return Map<String, dynamic>.from(response as Map);
  }

  Future<JsonMap> updateProfile({
    String? name,
    String? email,
    String? password,
    String? phoneNumber,
    String? accountNumber,
    String? walletNumber,
    List<String>? weekendDays,
  }) async {
    // Profile picture should be uploaded separately using uploadProfilePicture
    // This method only handles text fields
    final Map<String, dynamic> payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (email != null) payload['email'] = email;
    if (password != null) payload['password'] = password;
    if (phoneNumber != null) payload['phone_number'] = phoneNumber;
    if (accountNumber != null) payload['account_number'] = accountNumber;
    if (walletNumber != null) payload['wallet_number'] = walletNumber;
    if (weekendDays != null) payload['weekend_days'] = weekendDays;
    final dynamic response = await _client.put('/api/v1/me', data: payload);
    return Map<String, dynamic>.from(response as Map);
  }

  Future<JsonMap> uploadProfilePicture(String profilePicturePath) async {
    try {
      print('📤 Creating FormData for profile picture upload...');
      print('Image path: $profilePicturePath');
      print('Image filename: ${profilePicturePath.split('/').last}');
      
      final MultipartFile multipartFile = await MultipartFile.fromFile(
        profilePicturePath,
        filename: profilePicturePath.split('/').last,
      );
      
      print('✅ MultipartFile created successfully');
      print('File size: ${multipartFile.length} bytes');
      
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'profile_picture': multipartFile,
      });
      
      print('📡 Sending POST request to /api/v1/me/profile-picture');
      print('FormData files: ${formData.files.map((e) => e.key).toList()}');
      
      final dynamic response = await _client.post('/api/v1/me/profile-picture', data: formData);
      
      print('✅ Response received: ${response.runtimeType}');
      print('Response data: $response');
      
      return Map<String, dynamic>.from(response as Map);
    } catch (e, stackTrace) {
      print('❌ ERROR in uploadProfilePicture:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<JsonMap> uploadIdDocument(String documentPath, String type) async {
    try {
      print('📤 Creating FormData for ID document upload...');
      print('Document path: $documentPath');
      print('Document type: $type');
      print('Document filename: ${documentPath.split('/').last}');
      
      final MultipartFile multipartFile = await MultipartFile.fromFile(
        documentPath,
        filename: documentPath.split('/').last,
      );
      
      print('✅ MultipartFile created successfully');
      print('File size: ${multipartFile.length} bytes');
      
      // Map the type to API expected format
      // Based on UserModel fields: id_pic_front, id_pic_back
      // API expects: id_pic_front, id_pic_back
      final String apiType = 'id_pic_$type';
      
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'type': apiType,
        'image': multipartFile,
      });
      
      print('📡 Sending POST request to /api/v1/me/id-document');
      print('FormData fields: type=$apiType');
      print('FormData files: ${formData.files.map((e) => e.key).toList()}');
      
      final dynamic response = await _client.post('/api/v1/me/id-document', data: formData);
      
      print('✅ Response received: ${response.runtimeType}');
      print('Response data: $response');
      
      return Map<String, dynamic>.from(response as Map);
    } catch (e, stackTrace) {
      print('❌ ERROR in uploadIdDocument:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<JsonMap> uploadResidentialId(String documentPath, String type) async {
    try {
      print('📤 Creating FormData for residential ID upload...');
      print('Document path: $documentPath');
      print('Document type: $type');
      print('Document filename: ${documentPath.split('/').last}');
      
      final MultipartFile multipartFile = await MultipartFile.fromFile(
        documentPath,
        filename: documentPath.split('/').last,
      );
      
      print('✅ MultipartFile created successfully');
      print('File size: ${multipartFile.length} bytes');
      
      // For residential ID, we need to check what type the API expects
      // Based on the error, it seems the API expects 'type' and 'image' fields
      // We'll use 'residential_front' or 'residential_back' as the type
      final String apiType = 'residential_$type';
      
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'type': apiType,
        'image': multipartFile,
      });
      
      print('📡 Sending POST request to /api/v1/me/id-document');
      print('FormData fields: type=$apiType');
      print('FormData files: ${formData.files.map((e) => e.key).toList()}');
      
      final dynamic response = await _client.post('/api/v1/me/id-document', data: formData);
      
      print('✅ Response received: ${response.runtimeType}');
      print('Response data: $response');
      
      return Map<String, dynamic>.from(response as Map);
    } catch (e, stackTrace) {
      print('❌ ERROR in uploadResidentialId:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<dynamic> getAttendanceByDate(DateTime date) async {
    final dynamic response = await _client.get(
      '/api/v1/attendance',
      queryParameters: <String, dynamic>{'date': _dateFormatter.format(date)},
    );
    return response;
  }

  Future<JsonMap> getAttendanceSummary(DateTime date) async {
    final dynamic response = await _client.get(
      '/api/v1/attendance/summary',
      queryParameters: <String, dynamic>{'date': _dateFormatter.format(date)},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<JsonMap> updateAttendance({
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
    final Map<String, dynamic> payload = <String, dynamic>{
      'user_id': userId,
      'date': date,
      'status': status,
    };
    if (checkIn != null && checkIn.isNotEmpty) {
      payload['check_in'] = checkIn;
    }
    if (checkOut != null && checkOut.isNotEmpty) {
      payload['check_out'] = checkOut;
    }
    if (hoursAdjustmentType != null && hoursAdjustmentType.isNotEmpty) {
      payload['hours_adjustment_type'] = hoursAdjustmentType;
    }
    if (hoursAdjustment != null) {
      payload['hours_adjustment'] = hoursAdjustment;
    }
    if (reason != null && reason.isNotEmpty) {
      payload['reason'] = reason;
    }
    
    // Use PUT with record ID in URL if available, otherwise fallback to POST
    final String endpoint = recordId != null
        ? '/api/v1/attendance/admin/$recordId'
        : '/api/v1/attendance';
    
    final dynamic response = recordId != null
        ? await _client.put(endpoint, data: payload)
        : await _client.post(endpoint, data: payload);
    
    return Map<String, dynamic>.from(response as Map);
  }

  Future<dynamic> getMyAttendance({int? limit}) async {
    final dynamic response = await _client.get(
      '/api/v1/me/attendance',
      queryParameters: limit != null ? <String, dynamic>{'limit': limit} : null,
    );
    return response;
  }

  Future<dynamic> getMyAttendanceHistory({int? limit}) async {
    final dynamic response = await _client.get(
      '/api/v1/me/attendance',
      queryParameters: limit != null ? <String, dynamic>{'limit': limit} : null,
    );
    return response;
  }

  Future<dynamic> getAllUsersSummary({DateTime? from, DateTime? to, int? userId}) async {
    // API requires both from and to parameters - they must be provided
    if (from == null || to == null) {
      throw ArgumentError('Both from and to dates are required for getAllUsersSummary');
    }
    
    // Convert dates to UTC to avoid timezone issues
    // Extract just the date part (year, month, day) without time/timezone
    final DateTime fromDate = DateTime.utc(from.year, from.month, from.day);
    final DateTime toDate = DateTime.utc(to.year, to.month, to.day);
    
    final Map<String, dynamic> query = <String, dynamic>{
      'from': _dateFormatter.format(fromDate),
      'to': _dateFormatter.format(toDate),
    };
    
    // Only add user_id if explicitly provided (for filtering to a specific user)
    // Omitting user_id means "all users"
    if (userId != null) {
      query['user_id'] = userId;
    }
    
    // Debug logging
    if (kDebugMode) {
      debugPrint('=== getAllUsersSummary API Call ===');
      debugPrint('Endpoint: /api/v1/reports/all-users-summary');
      debugPrint('Original From (local): $from');
      debugPrint('Original To (local): $to');
      debugPrint('UTC From Date: $fromDate');
      debugPrint('UTC To Date: $toDate');
      debugPrint('Query parameters: $query');
      debugPrint('From: ${_dateFormatter.format(fromDate)}');
      debugPrint('To: ${_dateFormatter.format(toDate)}');
      debugPrint('UserId: ${userId ?? "null (all users)"}');
      debugPrint('About to call _client.get with endpoint: /api/v1/reports/all-users-summary');
    }
    
    final dynamic response = await _client.get(
      '/api/v1/reports/all-users-summary',
      queryParameters: query,
    );
    
    if (kDebugMode) {
      debugPrint('_client.get returned for getAllUsersSummary');
    }
    
    return response;
  }

  Future<dynamic> getMyRequests() async {
    final dynamic response = await _client.get('/api/v1/requests');
    return response;
  }

  Future<dynamic> getAllRequests() async {
    final dynamic response = await _client.get('/api/v1/requests/all');
    return response;
  }

  Future<JsonMap> createRequest(JsonMap payload) async {
    final dynamic response = await _client.post(
      '/api/v1/requests',
      data: payload,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<JsonMap> approveRequest({
    required int requestId,
    required JsonMap payload,
  }) async {
    final dynamic response = await _client.post(
      '/api/v1/requests/$requestId/approve',
      data: payload,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<JsonMap> getOnlineAttendanceStatus() async {
    final dynamic response = await _client.get(
      '/api/v1/attendance/online/status',
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> onlineCheckIn({
    required double latitude,
    required double longitude,
  }) async {
    await _client.post(
      '/api/v1/attendance/online/check-in',
      data: <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  Future<void> onlineCheckOut({
    required double latitude,
    required double longitude,
  }) async {
    await _client.post(
      '/api/v1/attendance/online/check-out',
      data: <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  Future<JsonMap> getMySummary({DateTime? from, DateTime? to}) async {
    final Map<String, dynamic> query = <String, dynamic>{};
    if (from != null) {
      query['from'] = _dateFormatter.format(from);
    }
    if (to != null) {
      query['to'] = _dateFormatter.format(to);
    }
    final dynamic response = await _client.get(
      '/api/v1/me/summary',
      queryParameters: query.isEmpty ? null : query,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  // Teams API
  Future<dynamic> getAllTeams() async {
    final dynamic response = await _client.get('/api/v1/teams');
    return response;
  }

  Future<JsonMap> getTeamById(int teamId) async {
    final dynamic response = await _client.get('/api/v1/teams/$teamId');
    return Map<String, dynamic>.from(response as Map);
  }

  Future<JsonMap> createTeam(String name) async {
    final dynamic response = await _client.post(
      '/api/v1/teams',
      data: <String, dynamic>{'name': name},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> deleteTeam(int teamId) async {
    await _client.delete('/api/v1/teams/$teamId');
  }

  Future<void> addMemberToTeam({
    required int teamId,
    required int userId,
    required String teamRole,
  }) async {
    await _client.post(
      '/api/v1/teams/$teamId/members',
      data: <String, dynamic>{'user_id': userId, 'team_role': teamRole},
    );
  }

  Future<void> removeMemberFromTeam({
    required int teamId,
    required int userId,
  }) async {
    await _client.delete('/api/v1/teams/$teamId/members/$userId');
  }

  // Team Tasks API
  Future<JsonMap> createTeamTask({
    required int teamId,
    required int assignedToUserId,
    required String title,
    String? description,
    String? dueDate,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'assigned_to_user_id': assignedToUserId,
      'title': title,
    };
    if (description != null) {
      payload['description'] = description;
    }
    if (dueDate != null) {
      payload['due_date'] = dueDate;
    }
    final dynamic response = await _client.post(
      '/api/v1/teams/$teamId/tasks',
      data: payload,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<JsonMap> updateTaskStatus({
    required int taskId,
    required String status,
  }) async {
    final dynamic response = await _client.put(
      '/api/v1/teams/tasks/$taskId',
      data: <String, dynamic>{'status': status},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  // Shifts API
  Future<dynamic> getAllShifts() async {
    final dynamic response = await _client.get('/api/v1/shifts');
    return response;
  }

  Future<JsonMap> getShiftById(int shiftId) async {
    final dynamic response = await _client.get('/api/v1/shifts/$shiftId');
    return Map<String, dynamic>.from(response as Map);
  }

  Future<JsonMap> createShift({
    required String name,
    required String startTime,
    required String endTime,
    int? gracePeriodMinutes,
    String? description,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
    };
    if (gracePeriodMinutes != null) {
      payload['grace_period_minutes'] = gracePeriodMinutes;
    }
    if (description != null) {
      payload['description'] = description;
    }
    final dynamic response = await _client.post(
      '/api/v1/shifts',
      data: payload,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<JsonMap> updateShift({
    required int shiftId,
    String? name,
    String? startTime,
    String? endTime,
    int? gracePeriodMinutes,
    String? description,
    bool? isActive,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (startTime != null) payload['start_time'] = startTime;
    if (endTime != null) payload['end_time'] = endTime;
    if (gracePeriodMinutes != null) {
      payload['grace_period_minutes'] = gracePeriodMinutes;
    }
    if (description != null) payload['description'] = description;
    if (isActive != null) payload['is_active'] = isActive;
    final dynamic response = await _client.put(
      '/api/v1/shifts/$shiftId',
      data: payload,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> deleteShift(int shiftId) async {
    await _client.delete('/api/v1/shifts/$shiftId');
  }

  Future<void> assignUsersToShift({
    required int shiftId,
    required List<int> userIds,
    String? effectiveFrom,
    String? effectiveTo,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{'user_ids': userIds};
    if (effectiveFrom != null) {
      payload['effective_from'] = effectiveFrom;
    }
    if (effectiveTo != null) {
      payload['effective_to'] = effectiveTo;
    }
    await _client.post('/api/v1/shifts/$shiftId/assign', data: payload);
  }

  Future<void> removeUserFromShift({
    required int shiftId,
    required int userId,
  }) async {
    await _client.delete('/api/v1/shifts/$shiftId/users/$userId');
  }

  // Overtime API
  Future<dynamic> getMyOvertime() async {
    final dynamic response = await _client.get('/api/v1/overtime/my');
    return response;
  }

  Future<dynamic> getAllOvertime() async {
    final dynamic response = await _client.get('/api/v1/overtime/all');
    return response;
  }

  // Daily Reports API
  Future<dynamic> getMyDailyReports({String? date}) async {
    final Map<String, dynamic>? query;
    if (date != null) {
      query = <String, dynamic>{'date': date};
    } else {
      query = null;
    }
    final dynamic response = await _client.get(
      '/api/v1/daily-reports',
      queryParameters: query,
    );
    return response;
  }

  Future<dynamic> getAllDailyReports({
    int? userId,
    String? startDate,
    String? endDate,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{};
    if (userId != null) query['user_id'] = userId;
    if (startDate != null) query['start_date'] = startDate;
    if (endDate != null) query['end_date'] = endDate;
    final dynamic response = await _client.get(
      '/api/v1/daily-reports/all',
      queryParameters: query.isEmpty ? null : query,
    );
    return response;
  }

  Future<JsonMap> createDailyReport({
    required String date,
    required String description,
    required double hoursWorked,
    String? achievements,
    String? challenges,
    String? notes,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'date': date,
      'description': description,
      'hours_worked': hoursWorked,
    };
    if (achievements != null) payload['achievements'] = achievements;
    if (challenges != null) payload['challenges'] = challenges;
    if (notes != null) payload['notes'] = notes;
    final dynamic response = await _client.post(
      '/api/v1/daily-reports',
      data: payload,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<JsonMap> updateDailyReport({
    required int reportId,
    String? description,
    double? hoursWorked,
    String? achievements,
    String? challenges,
    String? notes,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{};
    if (description != null) payload['description'] = description;
    if (hoursWorked != null) payload['hours_worked'] = hoursWorked;
    if (achievements != null) payload['achievements'] = achievements;
    if (challenges != null) payload['challenges'] = challenges;
    if (notes != null) payload['notes'] = notes;
    final dynamic response = await _client.put(
      '/api/v1/daily-reports/$reportId',
      data: payload,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  // Notifications API
  Future<dynamic> getNotifications() async {
    final dynamic response = await _client.get('/api/v1/notifications');
    return response;
  }

  Future<JsonMap> markNotificationAsRead(int notificationId) async {
    final dynamic response = await _client.put(
      '/api/v1/notifications/$notificationId/read',
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<JsonMap> markAllNotificationsAsRead() async {
    final dynamic response = await _client.put(
      '/api/v1/notifications/read-all',
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<JsonMap> sendNotification({
    required String title,
    required String message,
    String? type,
    int? userId,
    List<int>? userIds,
    bool? sendToAll,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'title': title,
      'message': message,
    };
    if (type != null) payload['type'] = type;
    if (userId != null) payload['user_id'] = userId;
    if (userIds != null) payload['user_ids'] = userIds;
    if (sendToAll != null) payload['send_to_all'] = sendToAll;
    final dynamic response = await _client.post(
      '/api/v1/notifications/send',
      data: payload,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  // Reports API
  Future<dynamic> getUserReport({
    required int userId,
    String? from,
    String? to,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{'user_id': userId};
    if (from != null) query['from'] = from;
    if (to != null) query['to'] = to;
    final dynamic response = await _client.get(
      '/api/v1/reports/user',
      queryParameters: query,
    );
    return response;
  }

  // User Management API (Admin only)
  Future<dynamic> getAllUsers({String? role}) async {
    final Map<String, dynamic>? query = role != null
        ? <String, dynamic>{'role': role}
        : null;
    final dynamic response = await _client.get(
      '/api/v1/users',
      queryParameters: query,
    );
    return response;
  }

  Future<JsonMap> getUserById(int userId) async {
    final dynamic response = await _client.get('/api/v1/users/$userId');
    return Map<String, dynamic>.from(response as Map);
  }

  Future<JsonMap> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    int? employeeNumber,
    bool? isActive,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
    if (employeeNumber != null) payload['employee_number'] = employeeNumber;
    if (isActive != null) payload['is_active'] = isActive;
    final dynamic response = await _client.post('/api/v1/users', data: payload);
    return Map<String, dynamic>.from(response as Map);
  }

  Future<JsonMap> updateUser({
    required int userId,
    String? name,
    String? email,
    String? password,
    String? role,
    int? employeeNumber,
    bool? isActive,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (email != null) payload['email'] = email;
    if (password != null) payload['password'] = password;
    if (role != null) payload['role'] = role;
    if (employeeNumber != null) payload['employee_number'] = employeeNumber;
    if (isActive != null) payload['is_active'] = isActive;
    final dynamic response = await _client.put(
      '/api/v1/users/$userId',
      data: payload,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> deleteUser(int userId) async {
    await _client.delete('/api/v1/users/$userId');
  }

  // Daily Reports Update/Delete
  Future<void> deleteDailyReport(int reportId) async {
    await _client.delete('/api/v1/daily-reports/$reportId');
  }

  // Request Details
  Future<JsonMap> getRequestById(int requestId) async {
    final dynamic response = await _client.get('/api/v1/requests/$requestId');
    return Map<String, dynamic>.from(response as Map);
  }

  // Standalone Tasks API
  Future<JsonMap> createTask({
    required String title,
    required String date,
    required double reportedHours,
    String? description,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'title': title,
      'date': date,
      'reported_hours': reportedHours,
    };
    if (description != null) payload['description'] = description;
    final dynamic response = await _client.post('/api/v1/tasks', data: payload);
    return Map<String, dynamic>.from(response as Map);
  }

  Future<dynamic> getMyTasks() async {
    final dynamic response = await _client.get('/api/v1/tasks/my');
    return response;
  }

  Future<dynamic> getAllTasks({String? status}) async {
    final Map<String, dynamic>? query = status != null
        ? <String, dynamic>{'status': status}
        : null;
    final dynamic response = await _client.get(
      '/api/v1/tasks/all',
      queryParameters: query,
    );
    return response;
  }

  Future<JsonMap> approveTask({
    required int taskId,
    required String status,
    double? approvedHours,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{'status': status};
    if (approvedHours != null) payload['approved_hours'] = approvedHours;
    final dynamic response = await _client.post(
      '/api/v1/tasks/$taskId/approve',
      data: payload,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  // My Shift
  Future<dynamic> getMyShift() async {
    final dynamic response = await _client.get('/api/v1/shifts/my');
    return response;
  }

  // User Shift Assignment
  Future<dynamic> getUserShift(int userId) async {
    final dynamic response = await _client.get('/api/v1/users/$userId/shift');
    return response;
  }
}
