import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;

class FeatureFlagService {
  FeatureFlagService._();
  static final FeatureFlagService instance = FeatureFlagService._();

  // Reactive state for the UI
  final ValueNotifier<bool> tuitionFeatureEnabled = ValueNotifier(false);
  final ValueNotifier<bool> tutorSessionFeatureEnabled = ValueNotifier(false);

  bool _isInitialized = false;

  /// Call this when the portal loads (Admin, Teacher, or Student)
  Future<void> fetchAndCacheFlags(String orgId) async {
    if (orgId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    
    // 1. Load from cache instantly to prevent UI flicker
    if (!_isInitialized) {
      final cachedTuition = prefs.getBool('feature_flag_tuition_$orgId');
      if (cachedTuition != null) {
        tuitionFeatureEnabled.value = cachedTuition;
      }
      final cachedTutorSession = prefs.getBool('feature_flag_tutor_session_$orgId');
      if (cachedTutorSession != null) {
        tutorSessionFeatureEnabled.value = cachedTutorSession;
      }
      _isInitialized = true;
    }

    // 2. Fetch fresh flags from backend asynchronously
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/feature-flags/org/$orgId'),
        headers: await ApiService.getHeaders(),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['flags'] != null) {
          final flags = body['flags'] as Map<String, dynamic>;
          final bool isTuitionEnabled = flags['TUITION'] == true;
          final bool isTutorSessionEnabled = flags['TUTOR_SESSION'] == true;
          
          // 3. Update reactive state (UI updates automatically if it changed)
          if (tuitionFeatureEnabled.value != isTuitionEnabled) {
            tuitionFeatureEnabled.value = isTuitionEnabled;
          }
          if (tutorSessionFeatureEnabled.value != isTutorSessionEnabled) {
            tutorSessionFeatureEnabled.value = isTutorSessionEnabled;
          }

          // 4. Update cache
          await prefs.setBool('feature_flag_tuition_$orgId', isTuitionEnabled);
          await prefs.setBool('feature_flag_tutor_session_$orgId', isTutorSessionEnabled);
        }
      }
    } catch (e) {
      debugPrint('Error fetching feature flags: $e');
      // On error, we just keep the cached value
    }
  }
}
