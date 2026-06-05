import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/features/main_app/pages/notification_router.dart';
import 'app_interceptor.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(AppInterceptor(navigatorKey));

    return dio;
  }
}
