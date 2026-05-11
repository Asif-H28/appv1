# Requirements Document

## Introduction

The Global Token Expiration Handler feature provides centralized, automatic handling of authentication token expiration across all API calls in the SchoolSync application. When the backend returns a token expiration response, the system will automatically log out the user, clear local session data, and redirect to the login page without requiring manual checks in each API endpoint method.

This feature addresses the current limitation where token expiration handling must be manually implemented for each API call, creating maintenance overhead and potential security gaps.

## Glossary

- **Token_Expiration_Response**: A JSON response from the backend API with the structure `{"error":"Invalid or expired token","showLoginpage":true}`
- **ApiService**: The centralized service class that handles all HTTP requests using both `http` package and `dio` package
- **Http_Interceptor**: A mechanism that intercepts HTTP responses from the `http` package before they reach the calling code
- **Dio_Interceptor**: A mechanism built into the `dio` package that intercepts responses and errors before they reach the calling code
- **Session_Data**: User authentication and profile information stored in SharedPreferences, including 'authToken', 'isLoggedIn', 'userRole', and role-specific identifiers
- **Login_Page**: The authentication screen where users enter credentials to access the application
- **Response_Handler**: A component that examines API responses and takes action based on specific error conditions

## Requirements

### Requirement 1: Detect Token Expiration in Dio Responses

**User Story:** As a developer, I want the system to automatically detect token expiration responses from Dio API calls, so that I don't have to manually check for token expiration in each endpoint method.

#### Acceptance Criteria

1. WHEN a Dio API call receives a response with `{"error":"Invalid or expired token","showLoginpage":true}`, THE Dio_Interceptor SHALL detect the Token_Expiration_Response
2. WHEN a Dio API call receives a response with `{"error":"Invalid or expired token"}` without the `showLoginpage` field, THE Dio_Interceptor SHALL detect the Token_Expiration_Response
3. WHEN a Dio API call receives a response with `{"showLoginpage":true}` without the error field, THE Dio_Interceptor SHALL detect the Token_Expiration_Response
4. WHEN the response body is not valid JSON, THE Dio_Interceptor SHALL not trigger token expiration handling
5. WHEN the response contains different error messages, THE Dio_Interceptor SHALL not trigger token expiration handling

### Requirement 2: Detect Token Expiration in Http Package Responses

**User Story:** As a developer, I want the system to automatically detect token expiration responses from http package API calls, so that both HTTP clients handle token expiration consistently.

#### Acceptance Criteria

1. WHEN an http package API call receives a response with `{"error":"Invalid or expired token","showLoginpage":true}`, THE Http_Interceptor SHALL detect the Token_Expiration_Response
2. WHEN an http package API call receives a response with `{"error":"Invalid or expired token"}` without the `showLoginpage` field, THE Http_Interceptor SHALL detect the Token_Expiration_Response
3. WHEN an http package API call receives a response with `{"showLoginpage":true}` without the error field, THE Http_Interceptor SHALL detect the Token_Expiration_Response
4. WHEN the response body is not valid JSON, THE Http_Interceptor SHALL not trigger token expiration handling
5. WHEN the response contains different error messages, THE Http_Interceptor SHALL not trigger token expiration handling

### Requirement 3: Clear Session Data on Token Expiration

**User Story:** As a security-conscious system, I want to clear all user session data when a token expires, so that no residual authentication information remains on the device.

#### Acceptance Criteria

1. WHEN a Token_Expiration_Response is detected, THE Response_Handler SHALL clear all Session_Data from SharedPreferences
2. WHEN clearing Session_Data, THE Response_Handler SHALL remove the 'authToken' key
3. WHEN clearing Session_Data, THE Response_Handler SHALL remove the 'isLoggedIn' key
4. WHEN clearing Session_Data, THE Response_Handler SHALL remove the 'userRole' key
5. WHEN clearing Session_Data, THE Response_Handler SHALL remove all role-specific identifier keys including 'userId', 'teacherId', 'studentId', 'orgId', and 'classId'
6. WHEN Session_Data clearing fails, THE Response_Handler SHALL still proceed with navigation to Login_Page

### Requirement 4: Navigate to Login Page on Token Expiration

**User Story:** As a user, I want to be automatically redirected to the login page when my session expires, so that I can re-authenticate without confusion.

#### Acceptance Criteria

1. WHEN Session_Data has been cleared after token expiration, THE Response_Handler SHALL navigate to the Login_Page
2. WHEN navigating to Login_Page, THE Response_Handler SHALL remove all previous routes from the navigation stack
3. WHEN navigation to Login_Page occurs, THE Response_Handler SHALL use the global navigator key to ensure navigation works from any context
4. WHEN the user is already on the Login_Page, THE Response_Handler SHALL not create duplicate navigation actions
5. WHEN multiple simultaneous API calls detect token expiration, THE Response_Handler SHALL navigate to Login_Page only once

### Requirement 5: Preserve Existing Deactivated Account Handling

**User Story:** As a developer, I want the existing 403 deactivated account error handling to continue working, so that the new token expiration feature doesn't break existing functionality.

#### Acceptance Criteria

1. WHEN a Dio API call receives a 403 status code with error message "Organization Deactivated", THE Dio_Interceptor SHALL navigate to the Deactivated Account Screen
2. WHEN an http package API call receives a 403 status code with error message "Organization Deactivated", THE Http_Interceptor SHALL navigate to the Deactivated Account Screen
3. WHEN a 403 response contains "Organization Deactivated", THE Response_Handler SHALL not trigger token expiration handling
4. WHEN a 403 response contains "Deactivated" in the error message, THE Response_Handler SHALL navigate to Deactivated Account Screen instead of Login_Page
5. THE Response_Handler SHALL check for deactivated account errors before checking for token expiration errors

### Requirement 6: Integrate with Existing ApiService Methods

**User Story:** As a developer, I want all existing ApiService methods to automatically use the token expiration handler, so that I don't need to modify existing API call implementations.

#### Acceptance Criteria

1. WHEN the `ApiService.get()` method is called, THE Http_Interceptor SHALL automatically intercept the response
2. WHEN the `ApiService.post()` method is called, THE Http_Interceptor SHALL automatically intercept the response
3. WHEN the `ApiService.put()` method is called, THE Http_Interceptor SHALL automatically intercept the response
4. WHEN the `ApiService.delete()` method is called, THE Http_Interceptor SHALL automatically intercept the response
5. WHEN the `ApiService.dio` instance is used for requests, THE Dio_Interceptor SHALL automatically intercept the response
6. THE ApiService SHALL maintain backward compatibility with all existing method signatures

### Requirement 7: Handle Token Expiration During Socket Connection

**User Story:** As a user, I want the chat socket connection to be closed when my token expires, so that I don't receive real-time updates after logout.

#### Acceptance Criteria

1. WHEN token expiration is detected, THE Response_Handler SHALL disconnect the ChatSocketService
2. WHEN ChatSocketService is disconnected due to token expiration, THE Response_Handler SHALL not attempt to reconnect
3. IF ChatSocketService is not connected, THE Response_Handler SHALL proceed with logout without errors
4. WHEN the user logs in again after token expiration, THE ChatSocketService SHALL establish a new connection with the new token

### Requirement 8: Provide Consistent Error Response Format

**User Story:** As a developer, I want a consistent way to identify token expiration responses, so that the detection logic is reliable and maintainable.

#### Acceptance Criteria

1. THE Response_Handler SHALL recognize token expiration when the response body contains `"error":"Invalid or expired token"`
2. THE Response_Handler SHALL recognize token expiration when the response body contains `"showLoginpage":true`
3. THE Response_Handler SHALL recognize token expiration when both conditions are present
4. THE Response_Handler SHALL perform case-sensitive matching for the error message
5. THE Response_Handler SHALL handle responses where the JSON fields appear in any order

### Requirement 9: Log Token Expiration Events

**User Story:** As a developer, I want token expiration events to be logged, so that I can debug authentication issues and monitor session management.

#### Acceptance Criteria

1. WHEN a Token_Expiration_Response is detected, THE Response_Handler SHALL log the event with timestamp
2. WHEN Session_Data is cleared, THE Response_Handler SHALL log the action
3. WHEN navigation to Login_Page occurs due to token expiration, THE Response_Handler SHALL log the navigation action
4. THE Response_Handler SHALL include the API endpoint URL in the log message
5. THE Response_Handler SHALL not log sensitive information such as token values or passwords

### Requirement 10: Handle Token Expiration in Background Requests

**User Story:** As a user, I want background API requests to handle token expiration gracefully, so that I'm redirected to login even when the app is not in the foreground.

#### Acceptance Criteria

1. WHEN a Token_Expiration_Response is detected from a background request, THE Response_Handler SHALL clear Session_Data
2. WHEN a Token_Expiration_Response is detected from a background request, THE Response_Handler SHALL navigate to Login_Page when the app returns to foreground
3. WHEN multiple background requests detect token expiration, THE Response_Handler SHALL handle the first detection and ignore subsequent ones
4. IF the app is terminated before navigation can occur, THE Response_Handler SHALL ensure Session_Data is cleared so the user sees Login_Page on next app launch
