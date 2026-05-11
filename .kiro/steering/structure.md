# Project Structure

## Root Directory Layout

```
appv1-1/
├── .agents/              # AI agent workflow configurations
├── .github/              # GitHub Actions CI/CD workflows
├── .kiro/                # Kiro AI assistant steering rules
├── .vscode/              # VS Code launch and settings
└── appv1/                # Main Flutter application directory
```

## Flutter App Structure (`appv1/`)

### Core Application Files

```
appv1/
├── lib/                  # Dart source code
├── android/              # Android-specific native code
├── ios/                  # iOS-specific native code
├── web/                  # Web platform files
├── windows/              # Windows desktop files
├── linux/                # Linux desktop files
├── macos/                # macOS desktop files
├── assets/               # Static resources (images, fonts)
├── test/                 # Unit and widget tests
├── pubspec.yaml          # Dependencies and project metadata
└── analysis_options.yaml # Linting and analysis configuration
```

## Source Code Organization (`lib/`)

The codebase follows a **feature-first architecture** with shared core utilities:

```
lib/
├── main.dart                    # App entry point and startup router
├── firebase_options.dart        # Firebase configuration
├── core/                        # Shared utilities and services
│   ├── constants/               # App-wide constants
│   │   ├── api_constants.dart   # API URLs and endpoints
│   │   ├── app_colors.dart      # Color palette
│   │   └── app_constants.dart   # General constants
│   ├── services/                # Shared business logic
│   │   ├── api_service.dart     # HTTP client with auth
│   │   ├── chat_socket_service.dart  # Socket.IO client
│   │   └── update_service.dart  # App update checker
│   ├── theme/                   # UI theming
│   │   └── app_theme.dart       # Material theme configuration
│   ├── utils/                   # Helper functions
│   │   └── validators.dart      # Form validation utilities
│   └── network/                 # Network layer (currently empty)
├── features/                    # Feature modules (role-based)
│   ├── main_app/                # Admin/organization features
│   │   ├── main_app_screen.dart # Admin dashboard
│   │   └── pages/               # Admin-specific pages
│   ├── student/                 # Student role features
│   │   ├── student_main_screen.dart
│   │   ├── student_home_page.dart
│   │   ├── student_profile_page.dart
│   │   ├── student_attendance_screen.dart
│   │   ├── student_classroom_screen.dart
│   │   ├── notification/        # Student notifications
│   │   └── [other student screens]
│   ├── teacher/                 # Teacher role features
│   │   └── presentation/        # Clean architecture layer
│   │       ├── pages/           # Teacher screens
│   │       └── widgets/         # Reusable teacher widgets
│   ├── onboarding/              # Login and registration
│   │   └── presentation/        # Onboarding UI layer
│   └── chat/                    # Real-time messaging
│       ├── chat_screen.dart
│       ├── conversation_list_screen.dart
│       └── new_chat_screen.dart
└── routes/                      # Navigation (currently empty)
```

## Architecture Patterns

### Feature Organization

Features are organized by **user role** (admin, teacher, student) rather than technical layers. Each feature module is self-contained with its screens, widgets, and role-specific logic.

### Student Feature Pattern
- **Flat structure**: All screens at feature root level
- **Naming convention**: `student_*_screen.dart` or `student_*_page.dart`
- **Widget components**: `student_*_card.dart`, `student_*_widget.dart`
- **Example**: `student_attendance_screen.dart`, `student_profile_page.dart`

### Teacher Feature Pattern
- **Layered structure**: Uses presentation layer separation
- **Directory**: `teacher/presentation/pages/` and `teacher/presentation/widgets/`
- **Suggests**: Potential for clean architecture expansion (domain, data layers)

### Main App (Admin) Pattern
- **Hybrid structure**: Main screen at root, pages in subdirectory
- **Entry point**: `main_app_screen.dart`
- **Pages**: Organized in `pages/` subdirectory

### Core Services Pattern
- **Centralized services**: Shared across all features
- **Singleton pattern**: Services like `ApiService`, `ChatSocketService`
- **Global access**: No dependency injection framework used

## File Naming Conventions

- **Screens/Pages**: `*_screen.dart` or `*_page.dart`
- **Widgets**: `*_card.dart`, `*_widget.dart`, `*_header.dart`
- **Services**: `*_service.dart`
- **Constants**: `*_constants.dart`
- **Utils**: `*_utils.dart` or specific names like `validators.dart`
- **Snake_case**: All file names use lowercase with underscores

## Key Architectural Decisions

1. **No state management library**: Uses `StatefulWidget` and `setState()` directly
2. **SharedPreferences for state**: User session and role stored locally
3. **Role-based routing**: Startup router in `main.dart` determines initial screen based on stored role
4. **Centralized API client**: Single `ApiService` class handles all HTTP requests with automatic auth token injection
5. **Feature isolation**: Each role's features are independent modules
6. **No routing package**: Direct `Navigator` usage with `MaterialPageRoute`

## Asset Organization

```
assets/
└── images/
    ├── school_building.png
    └── screen.png          # App launcher icon source
```

Assets must be declared in `pubspec.yaml` under `flutter.assets` to be bundled.

## Generated Files (Do Not Edit)

- `.dart_tool/` - Build artifacts and plugin registrations
- `build/` - Compiled output for each platform
- `.flutter-plugins-dependencies` - Plugin dependency cache
- Platform-specific generated files in `android/`, `ios/`, etc.

## Testing Structure

```
test/
└── [test files mirror lib/ structure]
```

Currently minimal test coverage. Tests should mirror the `lib/` directory structure.
