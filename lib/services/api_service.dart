import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const baseUrl = 'https://api.example.com/';
}

class ApiService {
  ApiService({String baseUrl = ApiConfig.baseUrl, Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final preferences = await SharedPreferences.getInstance();
          final token = preferences.getString(tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }
          handler.next(options);
        },
      ),
    );
  }

  static const tokenKey = 'jwt_token';

  final Dio _dio;

  Future<Response<dynamic>> getList({
    required String path,
    Map<String, dynamic>? queryParameters,
  }) {
    return _withErrorLogging(
      () => _dio.get<dynamic>(path, queryParameters: queryParameters),
    );
  }

  Future<Response<dynamic>> postFormData({
    required String path,
    required Map<String, dynamic> fields,
  }) {
    return _withErrorLogging(
      () => _dio.post<dynamic>(path, data: FormData.fromMap(fields)),
    );
  }

  Future<Response<dynamic>> postJson({
    required String path,
    required Map<String, dynamic> data,
  }) {
    return _withErrorLogging(() => _dio.post<dynamic>(path, data: data));
  }

  Future<T> _withErrorLogging<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error, stackTrace) {
      debugPrint(
        'API error ${error.response?.statusCode ?? 'network'} '
        '${error.requestOptions.method} ${error.requestOptions.uri}: '
        '${error.response?.data ?? error.message}',
      );
      Error.throwWithStackTrace(error, stackTrace);
    } catch (error, stackTrace) {
      debugPrint('Unexpected API error: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
