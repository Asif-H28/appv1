# Technology Stack

## Framework & Language

- **Flutter SDK**: ^3.11.1
- **Dart**: Language version aligned with Flutter SDK
- **Platform Support**: Android, iOS, Web, Windows, Linux, macOS

## Build System

Flutter uses its own build system with platform-specific tooling:
- **Android**: Gradle-based build system
- **iOS**: Xcode/CocoaPods
- **Desktop**: Platform-specific build tools

## Core Dependencies

### State Management & Storage
- `shared_preferences: ^2.3.2` - Local key-value storage for user sessions and preferences

### Networking
- `http: ^1.2.2` - Standard HTTP client for REST API calls
- `dio: 5.0.0` - Advanced HTTP client with interceptors and better error handling
- `socket_io_client: ^2.0.3+1` - Real-time bidirectional communication

### Firebase Services
- `firebase_core: ^4.6.0` - Firebase initialization
- `firebase_messaging: ^16.1.2` - Push notifications (FCM)
- `flutter_local_notifications: ^19.2.1` - Local notification handling

### File & Media Handling
- `image_picker: ^1.0.7` - Camera and gallery access
- `file_picker: ^8.0.3` - Document file selection
- `path_provider: ^2.1.2` - Access to device file system paths
- `open_file: ^3.3.2` - Open files with default system apps
- `permission_handler: ^11.3.1` - Runtime permissions management

### UI & Visualization
- `fl_chart: ^1.2.0` - Charts and data visualization
- `webview_flutter: ^4.4.2` - In-app web content rendering
- `url_launcher: ^6.2.5` - Launch URLs and external apps

### Utilities
- `http_parser: ^4.0.2` - HTTP content type parsing
- `path: ^1.9.0` - File path manipulation
- `excel: ^4.0.0` - Excel file generation and parsing
- `package_info_plus: 8.1.0` - App version and package information
- `intl: 0.19.0` - Internationalization and date formatting

### Development Tools
- `flutter_test` - Testing framework
- `flutter_lints: ^6.0.0` - Recommended linting rules
- `flutter_launcher_icons: ^0.14.1` - App icon generation

## Backend Integration

- **Base URL**: `https://appv1-backend.onrender.com`
- **API Base**: `https://appv1-backend.onrender.com/api`
- **Authentication**: Bearer token-based (JWT)
- **API Client**: Centralized `ApiService` class with automatic token injection

## Common Commands

### Development
```bash
# Get dependencies
flutter pub get

# Run app in debug mode
flutter run

# Run on specific device
flutter run -d <device-id>

# Hot reload (press 'r' in terminal during flutter run)
# Hot restart (press 'R' in terminal during flutter run)
```

### Building
```bash
# Build Android APK
flutter build apk

# Build Android App Bundle (for Play Store)
flutter build appbundle

# Build iOS (requires macOS)
flutter build ios

# Build for release with specific version
flutter build apk --build-name=1.0.6 --build-number=6
```

### Testing & Analysis
```bash
# Run all tests
flutter test

# Analyze code for issues
flutter analyze

# Check for outdated dependencies
flutter pub outdated

# Format code
dart format .
```

### Maintenance
```bash
# Clean build artifacts
flutter clean

# Upgrade Flutter SDK
flutter upgrade

# Check Flutter installation
flutter doctor

# List connected devices
flutter devices
```

## Code Generation

The project uses Flutter's build system for:
- **Plugin registration**: Auto-generated in `.dart_tool/flutter_build/`
- **Platform channels**: Native code integration
- **Asset bundling**: Images and resources defined in `pubspec.yaml`

## Linting

Uses `package:flutter_lints/flutter.yaml` for recommended Flutter linting rules. Configuration in `analysis_options.yaml`.
