import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appv1/features/main_app/pages/login_page.dart';
import 'package:appv1/features/notification_studio/controllers/notification_studio_controller.dart';

class AppInterceptor extends Interceptor {
  final GlobalKey<NavigatorState> navigatorKey;

  AppInterceptor(this.navigatorKey);

  // ─── 1. Every REQUEST — attach token automatically ───────────────────
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      // Also ensure Content-Type is set for POST/PUT if not already
      if (!options.headers.containsKey('Content-Type')) {
        options.headers['Content-Type'] = 'application/json';
      }
      debugPrint('[AppInterceptor] 🟢 Requesting: ${options.method} ${options.uri}');
      handler.next(options); // continue
    } catch (e, st) {
      debugPrint('[AppInterceptor] ❌ Request Interceptor Error: $e\n$st');
      handler.next(options); // continue despite error to not block app completely
    }
  }

  // ─── 2. Every RESPONSE — inspect before UI gets it ───────────────────
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      debugPrint('[AppInterceptor] 🟢 Response: ${response.statusCode} for ${response.requestOptions.uri}');
      handler.next(response); // pass to UI
    } catch (e, st) {
      debugPrint('[AppInterceptor] ❌ Response Interceptor Error: $e\n$st');
      handler.next(response);
    }
  }

  // ─── 3. Every ERROR — handle globally ────────────────────────────────
  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    try {
      final statusCode = err.response?.statusCode;
      debugPrint('[AppInterceptor] 🔴 Error: $statusCode for ${err.requestOptions.uri}');

      // 401 — Session expired or invalidated
      if (statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear(); // clear token and session data
        NotificationStudioController().disconnect();
        _redirectToLogin();
        // Resolve or reject properly to prevent hanging
        handler.reject(err);
        return;
      }

      handler.next(err);
    } catch (e, st) {
      debugPrint('[AppInterceptor] ❌ Error Interceptor Error: $e\n$st');
      handler.next(err);
    }
  }

  void _redirectToLogin() {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    }
  }

  void _showSnackbar(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
