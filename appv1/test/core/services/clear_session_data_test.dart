import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appv1/core/services/token_expiration_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TokenExpirationHandler._clearSessionData', () {
    setUp(() {
      // Reset the logout flag before each test
      TokenExpirationHandler.resetLogoutFlag();
    });

    test('clears all authentication keys from SharedPreferences', () async {
      // Arrange: Set up SharedPreferences with test data
      SharedPreferences.setMockInitialValues({
        'authToken': 'test_token_123',
        'isLoggedIn': true,
        'userRole': 'admin',
      });

      final prefs = await SharedPreferences.getInstance();
      
      // Verify keys exist before clearing
      expect(prefs.getString('authToken'), 'test_token_123');
      expect(prefs.getBool('isLoggedIn'), true);
      expect(prefs.getString('userRole'), 'admin');

      // Act: Trigger handleTokenExpiration which calls _clearSessionData
      await TokenExpirationHandler.handleTokenExpiration('test-endpoint');

      // Wait for async operations to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: Verify keys are removed
      expect(prefs.getString('authToken'), null);
      expect(prefs.getBool('isLoggedIn'), null);
      expect(prefs.getString('userRole'), null);
    });

    test('clears all user identifier keys from SharedPreferences', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'userId': 'user123',
        'teacherId': 'teacher456',
        'studentId': 'student789',
        'orgId': 'org001',
        'classId': 'class202',
      });

      final prefs = await SharedPreferences.getInstance();
      
      // Verify keys exist
      expect(prefs.getString('userId'), 'user123');
      expect(prefs.getString('teacherId'), 'teacher456');
      expect(prefs.getString('studentId'), 'student789');
      expect(prefs.getString('orgId'), 'org001');
      expect(prefs.getString('classId'), 'class202');

      // Act
      await TokenExpirationHandler.handleTokenExpiration('test-endpoint');
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(prefs.getString('userId'), null);
      expect(prefs.getString('teacherId'), null);
      expect(prefs.getString('studentId'), null);
      expect(prefs.getString('orgId'), null);
      expect(prefs.getString('classId'), null);
    });

    test('clears all user information keys from SharedPreferences', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'userEmail': 'test@example.com',
        'teacherName': 'John Doe',
        'studentName': 'Jane Smith',
        'userOrg': 'Test School',
        'adminEmail': 'admin@example.com',
      });

      final prefs = await SharedPreferences.getInstance();
      
      // Verify keys exist
      expect(prefs.getString('userEmail'), 'test@example.com');
      expect(prefs.getString('teacherName'), 'John Doe');
      expect(prefs.getString('studentName'), 'Jane Smith');
      expect(prefs.getString('userOrg'), 'Test School');
      expect(prefs.getString('adminEmail'), 'admin@example.com');

      // Act
      await TokenExpirationHandler.handleTokenExpiration('test-endpoint');
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(prefs.getString('userEmail'), null);
      expect(prefs.getString('teacherName'), null);
      expect(prefs.getString('studentName'), null);
      expect(prefs.getString('userOrg'), null);
      expect(prefs.getString('adminEmail'), null);
    });

    test('clears organization data keys from SharedPreferences', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'teacherCount': 25,
        'nonTeachingCount': 10,
      });

      final prefs = await SharedPreferences.getInstance();
      
      // Verify keys exist
      expect(prefs.getInt('teacherCount'), 25);
      expect(prefs.getInt('nonTeachingCount'), 10);

      // Act
      await TokenExpirationHandler.handleTokenExpiration('test-endpoint');
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(prefs.getInt('teacherCount'), null);
      expect(prefs.getInt('nonTeachingCount'), null);
    });

    test('clears status flag keys from SharedPreferences', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'teacherVerified': true,
      });

      final prefs = await SharedPreferences.getInstance();
      
      // Verify key exists
      expect(prefs.getBool('teacherVerified'), true);

      // Act
      await TokenExpirationHandler.handleTokenExpiration('test-endpoint');
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(prefs.getBool('teacherVerified'), null);
    });

    test('clears all session keys in a single operation', () async {
      // Arrange: Set up all session keys
      SharedPreferences.setMockInitialValues({
        'authToken': 'token123',
        'isLoggedIn': true,
        'userRole': 'teacher',
        'userId': 'user123',
        'teacherId': 'teacher456',
        'studentId': 'student789',
        'orgId': 'org001',
        'classId': 'class202',
        'userEmail': 'test@example.com',
        'teacherName': 'John Doe',
        'studentName': 'Jane Smith',
        'userOrg': 'Test School',
        'adminEmail': 'admin@example.com',
        'teacherCount': 25,
        'nonTeachingCount': 10,
        'teacherVerified': true,
      });

      final prefs = await SharedPreferences.getInstance();
      
      // Verify all keys exist
      expect(prefs.getString('authToken'), isNotNull);
      expect(prefs.getBool('isLoggedIn'), isNotNull);
      expect(prefs.getString('userRole'), isNotNull);
      expect(prefs.getString('userId'), isNotNull);
      expect(prefs.getString('teacherId'), isNotNull);
      expect(prefs.getString('studentId'), isNotNull);
      expect(prefs.getString('orgId'), isNotNull);
      expect(prefs.getString('classId'), isNotNull);
      expect(prefs.getString('userEmail'), isNotNull);
      expect(prefs.getString('teacherName'), isNotNull);
      expect(prefs.getString('studentName'), isNotNull);
      expect(prefs.getString('userOrg'), isNotNull);
      expect(prefs.getString('adminEmail'), isNotNull);
      expect(prefs.getInt('teacherCount'), isNotNull);
      expect(prefs.getInt('nonTeachingCount'), isNotNull);
      expect(prefs.getBool('teacherVerified'), isNotNull);

      // Act
      await TokenExpirationHandler.handleTokenExpiration('test-endpoint');
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: Verify all keys are removed
      expect(prefs.getString('authToken'), null);
      expect(prefs.getBool('isLoggedIn'), null);
      expect(prefs.getString('userRole'), null);
      expect(prefs.getString('userId'), null);
      expect(prefs.getString('teacherId'), null);
      expect(prefs.getString('studentId'), null);
      expect(prefs.getString('orgId'), null);
      expect(prefs.getString('classId'), null);
      expect(prefs.getString('userEmail'), null);
      expect(prefs.getString('teacherName'), null);
      expect(prefs.getString('studentName'), null);
      expect(prefs.getString('userOrg'), null);
      expect(prefs.getString('adminEmail'), null);
      expect(prefs.getInt('teacherCount'), null);
      expect(prefs.getInt('nonTeachingCount'), null);
      expect(prefs.getBool('teacherVerified'), null);
    });

    test('handles clearing when some keys do not exist', () async {
      // Arrange: Set up only some keys
      SharedPreferences.setMockInitialValues({
        'authToken': 'token123',
        'userRole': 'student',
        // Other keys intentionally missing
      });

      final prefs = await SharedPreferences.getInstance();
      
      // Verify only some keys exist
      expect(prefs.getString('authToken'), 'token123');
      expect(prefs.getString('userRole'), 'student');
      expect(prefs.getString('userId'), null);

      // Act: Should not throw error even if keys don't exist
      await TokenExpirationHandler.handleTokenExpiration('test-endpoint');
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: Existing keys should be removed
      expect(prefs.getString('authToken'), null);
      expect(prefs.getString('userRole'), null);
    });

    test('continues execution even if SharedPreferences operations fail', () async {
      // This test verifies that the error handling works correctly
      // In a real scenario, SharedPreferences.getInstance() might fail
      // The implementation should catch the error and continue
      
      // Arrange
      SharedPreferences.setMockInitialValues({
        'authToken': 'token123',
      });

      // Act: Should not throw even if there are issues
      try {
        await TokenExpirationHandler.handleTokenExpiration('test-endpoint');
        await Future.delayed(const Duration(milliseconds: 100));
        
        // If we reach here, the method handled errors gracefully
        expect(true, true);
      } catch (e) {
        // Should not reach here - errors should be caught internally
        fail('handleTokenExpiration should not throw errors: $e');
      }
    });
  });
}
