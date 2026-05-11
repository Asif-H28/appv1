# Implementation Plan: Global Token Expiration Handler

## Overview

This implementation plan breaks down the Global Token Expiration Handler feature into discrete, manageable tasks. The feature provides centralized, automatic detection and handling of authentication token expiration across all API calls in the SchoolSync Flutter application using HTTP response interceptors for both the `http` package and `dio` package.

The implementation follows a phased approach: first creating the core handler with detection logic, then integrating it into the existing ApiService, and finally adding comprehensive testing.

## Tasks

- [x] 1. Create TokenExpirationHandler core class
  - [x] 1.1 Create token_expiration_handler.dart file with singleton pattern
    - Create `lib/core/services/token_expiration_handler.dart`
    - Implement singleton pattern with factory constructor
    - Add static `_isLoggingOut` guard flag
    - Add `resetLogoutFlag()` method for testing
    - _Requirements: 4.4, 4.5, 10.3_
  
  - [x] 1.2 Implement detectTokenExpiration method
    - Parse JSON response body safely with try-catch
    - Check for `"error":"Invalid or expired token"` pattern
    - Check for `"showLoginpage":true` pattern
    - Return false for invalid JSON or non-expiration errors
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 8.1, 8.2, 8.3, 8.4, 8.5_
  
  - [x] 1.3 Write unit tests for detectTokenExpiration
    - Test full format: `{"error":"Invalid or expired token","showLoginpage":true}`
    - Test error-only format: `{"error":"Invalid or expired token"}`
    - Test flag-only format: `{"showLoginpage":true}`
    - Test mixed format with other fields
    - Test invalid JSON rejection
    - Test different error messages rejection
    - Test empty response rejection
    - Test case-sensitive matching
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 8.4, 8.5_

- [x] 2. Implement session clearing functionality
  - [x] 2.1 Implement _clearSessionData method
    - Get SharedPreferences instance
    - Remove 'authToken' key
    - Remove 'isLoggedIn' key
    - Remove 'userRole' key
    - Remove 'userId', 'teacherId', 'studentId' keys
    - Remove 'orgId', 'classId' keys
    - Remove 'userEmail', 'teacherName', 'studentName' keys
    - Remove 'userOrg', 'adminEmail' keys
    - Remove 'teacherCount', 'nonTeachingCount' keys
    - Remove 'teacherVerified' key
    - Add error handling with debugPrint
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 9.2, 9.5_
  
  - [x] 2.2 Write unit tests for _clearSessionData
    - Test all session keys are removed
    - Test clearing with missing keys doesn't error
    - Test clearing with SharedPreferences failure continues execution
    - Verify error logging without sensitive data
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 9.5_

- [x] 3. Implement socket disconnection functionality
  - [x] 3.1 Implement _disconnectSocket method
    - Get ChatSocketService instance
    - Check if socket is connected
    - Call disconnect() if connected
    - Add debugPrint logging for disconnection
    - Handle case where socket is not connected gracefully
    - Add error handling with debugPrint
    - _Requirements: 7.1, 7.2, 7.3, 9.2, 9.5_
  
  - [x] 3.2 Write unit tests for _disconnectSocket
    - Test disconnection when socket is connected
    - Test graceful handling when socket is not connected
    - Test error handling when disconnect fails
    - Verify logging without sensitive data
    - _Requirements: 7.1, 7.3, 9.5_

- [x] 4. Implement navigation functionality
  - [x] 4.1 Implement _navigateToLogin method
    - Import navigatorKey from notification_router.dart
    - Import LoginPage
    - Check if navigatorKey.currentState is not null
    - Use pushAndRemoveUntil to navigate to LoginPage
    - Remove all previous routes from stack
    - Add debugPrint logging for navigation
    - Add error logging if navigatorKey is null
    - _Requirements: 4.1, 4.2, 4.3, 9.2, 9.5_
  
  - [x] 4.2 Write widget tests for _navigateToLogin
    - Test navigation to LoginPage occurs
    - Test all previous routes are removed
    - Test navigation uses global navigator key
    - Test error handling when navigator key is null
    - _Requirements: 4.1, 4.2, 4.3_

- [x] 5. Implement handleTokenExpiration orchestration method
  - [x] 5.1 Implement handleTokenExpiration with guard flag logic
    - Check if `_isLoggingOut` is already true, return early if so
    - Set `_isLoggingOut` to true
    - Add debugPrint with timestamp and endpoint
    - Call `_clearSessionData()` with await
    - Call `_disconnectSocket()`
    - Call `_navigateToLogin()`
    - Add comprehensive error handling
    - _Requirements: 4.4, 4.5, 9.1, 9.2, 9.3, 9.4, 10.1, 10.2, 10.3_
  
  - [x] 5.2 Write integration tests for handleTokenExpiration
    - Test complete logout flow executes in order
    - Test guard flag prevents duplicate execution
    - Test logging includes endpoint and timestamp
    - Test logging excludes sensitive data
    - Test error in one step doesn't block others
    - _Requirements: 4.5, 9.1, 9.2, 9.3, 9.4, 9.5, 10.3_

- [~] 6. Checkpoint - Ensure TokenExpirationHandler tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Integrate with ApiService http package methods
  - [-] 7.1 Modify checkResponse method for http package
    - Import TokenExpirationHandler at top of api_service.dart
    - Preserve existing 403 deactivation check (must run FIRST)
    - Add token expiration detection after deactivation check
    - Extract endpoint URL from response.request?.url
    - Call TokenExpirationHandler.handleTokenExpiration if detected
    - Ensure deactivation check returns early to prevent token expiration handling
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 5.1, 5.2, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3, 6.4_
  
  - [~] 7.2 Write integration tests for http package interception
    - Test token expiration response triggers handler
    - Test deactivation response takes priority
    - Test non-expiration errors don't trigger handler
    - Test invalid JSON doesn't trigger handler
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 5.3, 5.5_

- [ ] 8. Integrate with ApiService dio interceptor
  - [-] 8.1 Modify dio onResponse interceptor
    - Add token expiration detection in onResponse handler
    - Extract response body from response.data
    - Extract endpoint URL from response.requestOptions.uri
    - Call TokenExpirationHandler.handleTokenExpiration if detected
    - Call handler.next(response) to continue interceptor chain
    - _Requirements: 1.1, 1.2, 1.3, 6.5_
  
  - [ ] 8.2 Modify dio onError interceptor
    - Preserve existing 403 deactivation check (must run FIRST)
    - Add token expiration detection after deactivation check
    - Extract response body from e.response?.data
    - Extract endpoint URL from e.requestOptions.uri
    - Call TokenExpirationHandler.handleTokenExpiration if detected
    - Ensure deactivation check returns early to prevent token expiration handling
    - Call handler.next(e) to continue interceptor chain
    - _Requirements: 1.1, 1.2, 1.3, 5.1, 5.2, 5.3, 5.4, 5.5, 6.5_
  
  - [~] 8.3 Write integration tests for dio interceptor
    - Test token expiration in successful response triggers handler
    - Test token expiration in error response triggers handler
    - Test deactivation response takes priority in onError
    - Test non-expiration errors don't trigger handler
    - Test invalid JSON doesn't trigger handler
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 5.3, 5.5_

- [~] 9. Checkpoint - Ensure ApiService integration tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Add comprehensive logging
  - [~] 10.1 Add logging to all TokenExpirationHandler methods
    - Add success logging for detection with timestamp and endpoint
    - Add success logging for session clearing
    - Add success logging for socket disconnection
    - Add success logging for navigation
    - Add error logging for all failure scenarios
    - Verify no sensitive data (tokens, passwords) in logs
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_
  
  - [~] 10.2 Write tests for logging behavior
    - Test success logs include timestamp and endpoint
    - Test error logs include error details
    - Test logs never include token values
    - Test logs never include password data
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ] 11. Handle background request scenarios
  - [~] 11.1 Verify background request handling
    - Review that session clearing works regardless of app state
    - Review that navigation queues properly when app is backgrounded
    - Review that guard flag prevents duplicate handling from background requests
    - Add comments documenting background behavior
    - _Requirements: 10.1, 10.2, 10.3, 10.4_
  
  - [~] 11.2 Write tests for background scenarios
    - Test session clearing occurs for background requests
    - Test guard flag prevents duplicate handling
    - Test navigation occurs when app returns to foreground
    - _Requirements: 10.1, 10.2, 10.3_

- [ ] 12. Final checkpoint and verification
  - [~] 12.1 Run all tests and verify coverage
    - Run `flutter test` to execute all unit and integration tests
    - Verify all tests pass
    - Review test coverage for TokenExpirationHandler
    - Review test coverage for ApiService modifications
    - _Requirements: All_
  
  - [~] 12.2 Manual testing across user roles
    - Test admin login with expired token redirects to login
    - Test teacher login with expired token redirects to login
    - Test student login with expired token redirects to login
    - Test multiple simultaneous API calls only logout once
    - Test ChatSocket disconnects on token expiration
    - Test all SharedPreferences keys are cleared
    - Test navigation stack is cleared (back button doesn't work)
    - Test 403 deactivated account still shows deactivation screen
    - Verify logs show endpoint and timestamp but not token values
    - _Requirements: All_
  
  - [~] 12.3 Code review and documentation
    - Review all code for consistency with design document
    - Verify all requirements are addressed
    - Add inline comments for complex logic
    - Verify error handling is comprehensive
    - Ensure backward compatibility with existing ApiService usage
    - _Requirements: 6.6_

- [~] 13. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional testing tasks and can be skipped for faster MVP delivery
- Each task references specific requirements from the requirements document for traceability
- The implementation preserves existing 403 deactivated account handling by checking deactivation errors BEFORE token expiration errors
- The guard flag (`_isLoggingOut`) prevents duplicate logout actions when multiple simultaneous API calls detect token expiration
- All logging uses `debugPrint` and never includes sensitive data like token values or passwords
- The feature maintains backward compatibility - no changes required to existing ApiService method calls
- Checkpoints ensure incremental validation and provide opportunities for user feedback
- Property-based testing is not included because this feature primarily tests integration with external Flutter services (SharedPreferences, Navigator, ChatSocketService) which require mocking and are not suitable for PBT

## Task Dependency Graph

```json
{
  "waves": [
    {
      "id": 0,
      "tasks": ["1.1"]
    },
    {
      "id": 1,
      "tasks": ["1.2", "2.1", "3.1", "4.1"]
    },
    {
      "id": 2,
      "tasks": ["1.3", "2.2", "3.2", "4.2", "5.1"]
    },
    {
      "id": 3,
      "tasks": ["5.2"]
    },
    {
      "id": 4,
      "tasks": ["7.1", "8.1", "8.2"]
    },
    {
      "id": 5,
      "tasks": ["7.2", "8.3", "10.1"]
    },
    {
      "id": 6,
      "tasks": ["10.2", "11.1"]
    },
    {
      "id": 7,
      "tasks": ["11.2", "12.1"]
    },
    {
      "id": 8,
      "tasks": ["12.2", "12.3"]
    }
  ]
}
```
