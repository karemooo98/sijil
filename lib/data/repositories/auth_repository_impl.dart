import 'dart:convert';

import '../../core/errors/exceptions.dart';
import '../../core/storage/token_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote_api_service.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._storage);

  final RemoteApiService _api;
  final TokenStorage _storage;

  AuthSessionModel? _cachedSession;

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    String? employeeNumber,
  }) async {
    final Map<String, dynamic> response = await _api.register(
      name: name,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      employeeNumber: employeeNumber,
    );
    final Map<String, dynamic> data = _extractData(response);
    final AuthSessionModel session = AuthSessionModel(
      token: data['token']?.toString() ?? '',
      user: UserModel.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
    );
    await _persistSession(session);
    _cachedSession = session;
    return session;
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> response = await _api.login(
      email: email,
      password: password,
    );
    final Map<String, dynamic> data = _extractData(response);
    final AuthSessionModel session = AuthSessionModel(
      token: data['token']?.toString() ?? '',
      user: UserModel.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
    );
    await _persistSession(session);
    _cachedSession = session;
    return session;
  }

  @override
  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (error) {
      // Ignored to ensure local session is cleared even if server call fails.
    } finally {
      await _storage.delete(TokenStorage.tokenKey);
      await _storage.delete(TokenStorage.userKey);
      _cachedSession = null;
    }
  }

  @override
  Future<User> fetchProfile() async {
    final Map<String, dynamic> response = await _api.fetchProfile();
    final Map<String, dynamic> data = _extractData(response);
    final UserModel user = UserModel.fromJson(data);
    if (_cachedSession != null) {
      _cachedSession = _cachedSession!.copyWith(user: user);
      await _storage.write(TokenStorage.userKey, jsonEncode(user.toJson()));
    }
    return user;
  }

  @override
  Future<User> updateProfile({
    String? name,
    String? email,
    String? password,
    String? phoneNumber,
    String? accountNumber,
    String? walletNumber,
    List<String>? weekendDays,
  }) async {
    final Map<String, dynamic> response = await _api.updateProfile(
      name: name,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      accountNumber: accountNumber,
      walletNumber: walletNumber,
      weekendDays: weekendDays,
    );
    
    print('📦 Raw API response: $response');
    print('📦 Response keys: ${response.keys.toList()}');
    
    final Map<String, dynamic> data = _extractData(response);
    
    print('📦 Extracted data: $data');
    print('📦 Data keys: ${data.keys.toList()}');
    print('📦 profile_picture in data: ${data['profile_picture']}');
    print('📦 photo in data: ${data['photo']}');
    
    final UserModel user = UserModel.fromJson(data);
    
    print('📦 UserModel created - photo: ${user.photo}');
    
    if (_cachedSession != null) {
      _cachedSession = _cachedSession!.copyWith(user: user);
      await _storage.write(TokenStorage.userKey, jsonEncode(user.toJson()));
    }
    return user;
  }

  @override
  Future<User> uploadProfilePicture(String profilePicturePath) async {
    print('📤 Uploading profile picture via dedicated endpoint...');
    final Map<String, dynamic> response = await _api.uploadProfilePicture(profilePicturePath);
    
    print('📦 Raw API response: $response');
    print('📦 Response keys: ${response.keys.toList()}');
    
    // The API returns only {message, profile_picture}, not full user object
    // So we need to fetch the profile again to get updated user data
    print('🔄 Fetching updated profile after picture upload...');
    return await fetchProfile();
  }

  @override
  Future<User> uploadIdDocument(String documentPath, String type) async {
    print('📤 Uploading ID document via dedicated endpoint...');
    final Map<String, dynamic> response = await _api.uploadIdDocument(documentPath, type);
    
    print('📦 Raw API response: $response');
    print('📦 Response keys: ${response.keys.toList()}');
    
    // The API returns only {message, ...}, not full user object
    // So we need to fetch the profile again to get updated user data
    print('🔄 Fetching updated profile after ID document upload...');
    return await fetchProfile();
  }

  @override
  Future<User> uploadResidentialId(String documentPath, String type) async {
    print('📤 Uploading residential ID via dedicated endpoint...');
    final Map<String, dynamic> response = await _api.uploadResidentialId(documentPath, type);
    
    print('📦 Raw API response: $response');
    print('📦 Response keys: ${response.keys.toList()}');
    
    // The API returns only {message, ...}, not full user object
    // So we need to fetch the profile again to get updated user data
    print('🔄 Fetching updated profile after residential ID upload...');
    return await fetchProfile();
  }

  @override
  Future<AuthSession?> restoreSession() async {
    if (_cachedSession != null) {
      return _cachedSession;
    }
    final String? token = await _storage.read(TokenStorage.tokenKey);
    final String? userJson = await _storage.read(TokenStorage.userKey);
    if (token == null || userJson == null) {
      return null;
    }
    final UserModel user = UserModel.fromJson(
      jsonDecode(userJson) as Map<String, dynamic>,
    );
    _cachedSession = AuthSessionModel(token: token, user: user);
    return _cachedSession;
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    if (response.containsKey('data') &&
        response['data'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(response['data'] as Map);
    }
    return response;
  }

  Future<void> _persistSession(AuthSessionModel session) async {
    if (session.token.isEmpty) {
      throw ServerException('Token missing in response');
    }
    await _storage.write(TokenStorage.tokenKey, session.token);
    await _storage.write(
      TokenStorage.userKey,
      jsonEncode((session.user as UserModel).toJson()),
    );
  }
}
