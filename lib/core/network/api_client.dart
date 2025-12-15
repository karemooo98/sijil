import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/app_config.dart';
import '../errors/exceptions.dart';
import '../storage/token_storage.dart';
import '../utils/result.dart';
import 'api_response.dart';

typedef ResponseParser<R> = R Function(dynamic data);

enum HttpMethod { get, post, put, patch, delete }

class ApiClient {
  ApiClient(this._tokenStorage)
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: AppConfig.connectionTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
          headers: const <String, dynamic>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              final String? token = await _tokenStorage.read(
                TokenStorage.tokenKey,
              );
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(requestBody: true, responseBody: true, compact: true),
      );
    }
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _request(() => _dio.get<dynamic>(path, queryParameters: queryParameters));

  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) => _request(
    () =>
        _dio.post<dynamic>(path, data: data, queryParameters: queryParameters),
  );

  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) => _request(
    () => _dio.put<dynamic>(path, data: data, queryParameters: queryParameters),
  );

  Future<dynamic> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) => _request(
    () => _dio.delete<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
    ),
  );

  Future<Result<R>> send<R>({
    required String path,
    required HttpMethod method,
    Map<String, dynamic>? queryParameters,
    Object? data,
    Options? options,
    ResponseParser<R>? parser,
  }) async {
    return Result.guard<R>(() async {
      final Response<dynamic> response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(
          method: _methodToString(method),
        ),
      );

      final ApiResponse<dynamic> apiResponse =
          ApiResponse<dynamic>.fromResponse(response);
      final dynamic payload = apiResponse.data ?? response.data;
      return parser != null ? parser(payload) : payload as R;
    });
  }

  Future<dynamic> _request(Future<Response<dynamic>> Function() request) async {
    try {
      final Response<dynamic> response = await request();
      return response.data;
    } on DioException catch (error) {
      await _handleUnauthorized(error);
      final String message = _resolveErrorMessage(error);
      final int? statusCode = error.response?.statusCode;
      throw ServerException(message, statusCode: statusCode);
    }
  }

  Future<void> _handleUnauthorized(DioException error) async {
    final int? statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      await _tokenStorage.clear();
    }
  }

  String _resolveErrorMessage(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      final Map<String, dynamic> data =
          error.response?.data as Map<String, dynamic>;
      
      // Check for validation errors first
      if (data.containsKey('errors') && data['errors'] is Map<String, dynamic>) {
        final Map<String, dynamic> errors = data['errors'] as Map<String, dynamic>;
        // Get first error message
        if (errors.isNotEmpty) {
          final String firstKey = errors.keys.first;
          final dynamic firstError = errors[firstKey];
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          } else if (firstError is String) {
            return firstError;
          }
        }
      }
      
      // Fallback to general message
      if (data.containsKey('message')) {
        return data['message']?.toString() ?? 'Unexpected server error';
      }
    }
    return error.message ?? 'Unexpected server error';
  }

  String _methodToString(HttpMethod method) {
    switch (method) {
      case HttpMethod.get:
        return 'GET';
      case HttpMethod.post:
        return 'POST';
      case HttpMethod.put:
        return 'PUT';
      case HttpMethod.patch:
        return 'PATCH';
      case HttpMethod.delete:
        return 'DELETE';
    }
  }
}
