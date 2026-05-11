import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appv1/core/services/chat_socket_service.dart';
import 'package:appv1/features/main_app/pages/notification_router.dart';
import 'package:appv1/features/main_app/pages/login_page.dart';

/// Centralized handler for detecting and processing token expiration responses.
/// 
/// This singleton class provides automatic detection of token expiration patterns
/// in API responses and coordinates the complete logout flow including:
/// - Clearing session data from SharedPreferences
/// - Disconnecting the ChatSocketService
/// - Navigating to the login page
/// 
/// **Requirements**: 4.4, 4.5, 10.3
class TokenExpirationHandler {
  // Singleton instance
  static final TokenExpirationHandler _instance = TokenExpirationHandler._internal();
  
  /// Factory constructor returns the singleton instance
  factory TokenExpirationHandler() => _instance;
  
  /// Private constructor for singleton pattern
  TokenExpirationHandler._internal();
  
  /// Guard flag to prevent duplicate logout actions when multiple API calls fail simultaneously
  static bool _isLoggingOut = false;
  
  /// Detects if a response body indicates token expiration.
  /// 
  /// Returns true if the response contains any of these patterns:
  /// - `{"error":"Invalid or expired token"}`
  /// - `{"showLoginpage":true}`
  /// - Both fields present
  /// 
  /// Returns false for:
  /// - Invalid JSON
  /// - Different error messages
  /// - Empty responses
  /// 
  /// **Validates**: Requirements 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 8.1, 8.2, 8.3, 8.5
  static bool detectTokenExpiration(String responseBody) {
    try {
      final json = jsonDecode(responseBody);
      if (json is! Map<String, dynamic>) return false;
      
      // Check for token expiration indicators
      final hasExpiredError = json['error']?.toString().contains('Invalid or expired token') ?? false;
      final hasShowLoginPage = json['showLoginpage'] == true;
      
      return hasExpiredError || hasShowLoginPage;
    } catch (e) {
      // Invalid JSON - not a token expiration response
      return false;
    }
  }
  
  /// Handles the complete token expiration flow.
  /// 
  /// This method:
  /// 1. Checks the guard flag to prevent duplicate logout
  /// 2. Clears all session data from SharedPreferences
  /// 3. Disconnects the ChatSocketService
  /// 4. Navigates to the login page
  /// 
  /// [endpoint] - The API endpoint URL that returned the token expiration response
  /// 
  /// **Validates**: Requirements 3.1-3.6, 4.1-4.5, 7.1-7.3, 9.1-9.5, 10.1-10.4
  static Future<void> handleTokenExpiration(String endpoint) async {
    // Check guard flag to prevent duplicate logout
    if (_isLoggingOut) {
      debugPrint('[TokenExpiration] ERROR: Duplicate logout attempt prevented');
      return;
    }
    
    // Set guard flag
    _isLoggingOut = true;
    
    // Log the token expiration event
    debugPrint('[TokenExpiration] Detected at ${DateTime.now()} for endpoint: $endpoint');
    
    try {
      // Clear session data
      await _clearSessionData();
      
      // Disconnect socket
      _disconnectSocket();
      
      // Navigate to login
      _navigateToLogin();
    } catch (e) {
      debugPrint('[TokenExpiration] ERROR: Exception during logout flow: $e');
    } finally {
      // Reset guard flag after a delay to allow navigation to complete
      Future.delayed(const Duration(seconds: 2), () {
        _isLoggingOut = false;
      });
    }
  }
  
  /// Clears all session data from SharedPreferences.
  /// 
  /// Removes all authentication and user-related keys including:
  /// - authToken, isLoggedIn, userRole
  /// - userId, teacherId, studentId, orgId, classId
  /// - userEmail, teacherName, studentName, userOrg, adminEmail
  /// - teacherCount, nonTeachingCount, teacherVerified
  /// 
  /// **Validates**: Requirements 3.1, 3.2, 3.3, 3.4, 3.5
  static Future<void> _clearSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Authentication keys
      await prefs.remove('authToken');
      await prefs.remove('isLoggedIn');
      await prefs.remove('userRole');
      
      // User identifier keys
      await prefs.remove('userId');
      await prefs.remove('teacherId');
      await prefs.remove('studentId');
      await prefs.remove('orgId');
      await prefs.remove('classId');
      
      // User information keys
      await prefs.remove('userEmail');
      await prefs.remove('teacherName');
      await prefs.remove('studentName');
      await prefs.remove('userOrg');
      await prefs.remove('adminEmail');
      
      // Organization data keys
      await prefs.remove('teacherCount');
      await prefs.remove('nonTeachingCount');
      
      // Status flag keys
      await prefs.remove('teacherVerified');
      
      debugPrint('[TokenExpiration] Session data cleared');
    } catch (e) {
      debugPrint('[TokenExpiration] ERROR: Failed to clear session data: $e');
      // Continue with logout flow even if clearing fails
    }
  }
  
  /// Disconnects the ChatSocketService.
  /// 
  /// If the socket is connected, it will be disconnected.
  /// If the socket is not connected, this method proceeds without errors.
  /// 
  /// **Validates**: Requirements 7.1, 7.2, 7.3
  static void _disconnectSocket() {
    try {
      final socketService = ChatSocketService();
      if (socketService.socket?.connected ?? false) {
        socketService.disconnect();
        debugPrint('[TokenExpiration] ChatSocket disconnected');
      } else {
        debugPrint('[TokenExpiration] ChatSocket was not connected');
      }
    } catch (e) {
      debugPrint('[TokenExpiration] ERROR: Failed to disconnect socket: $e');
      // Continue with logout flow even if socket disconnect fails
    }
  }
  
  /// Navigates to the login page and removes all previous routes.
  /// 
  /// Uses the global navigator key to ensure navigation works from any context.
  /// Clears the entire navigation stack so the login page becomes the root route.
  /// 
  /// **Validates**: Requirements 4.1, 4.2, 4.3, 4.4
  static void _navigateToLogin() {
    try {
      if (navigatorKey.currentState == null) {
        debugPrint('[TokenExpiration] ERROR: Navigator key is null, cannot navigate');
        return;
      }
      
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
      
      debugPrint('[TokenExpiration] Navigating to login page');
    } catch (e) {
      debugPrint('[TokenExpiration] ERROR: Failed to navigate to login: $e');
    }
  }
  
  /// Resets the logout guard flag.
  /// 
  /// This method is intended for testing purposes to reset the handler state
  /// between test cases.
  /// 
  /// **Note**: Should only be used in test environments.
  static void resetLogoutFlag() {
    _isLoggingOut = false;
  }
}
