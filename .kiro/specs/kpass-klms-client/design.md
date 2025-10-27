# Design Document

## Overview

KPASS is a Flutter mobile application that serves as a client for Keio University's K-LMS (Canvas-based) system. The app follows a clean architecture pattern with clear separation of concerns, ensuring maintainability and testability. The design emphasizes security, offline capability, and cross-platform consistency while providing a native mobile experience.

## Architecture

### High-Level Architecture

The application follows a layered architecture pattern:

```
┌─────────────────────────────────────┐
│           Presentation Layer        │
│  (UI Screens, Widgets, State Mgmt)  │
├─────────────────────────────────────┤
│           Business Layer            │
│     (Services, Use Cases)           │
├─────────────────────────────────────┤
│            Data Layer               │
│  (Repositories, Data Sources)       │
├─────────────────────────────────────┤
│         Infrastructure Layer        │
│ (Network, Storage, Notifications)   │
└─────────────────────────────────────┘
```

### Directory Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── routes.dart
│   └── theme.dart
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   └── utils/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── courses/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── assignments/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── calendar/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── notifications/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── settings/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── shared/
    ├── widgets/
    ├── models/
    └── services/
```

## Components and Interfaces

### Authentication Service

**Purpose:** Manages user authentication and token lifecycle

**Key Methods:**
- `authenticateWithWebView()`: Handles WebView-based Shibboleth login
- `authenticateWithManualToken(String token)`: Validates and stores manual token
- `validateToken()`: Checks token validity with Canvas API
- `logout()`: Clears stored credentials
- `getStoredToken()`: Retrieves encrypted token from secure storage

**Dependencies:**
- `flutter_secure_storage` for token encryption
- `webview_flutter` for authentication flow
- `dio` for API validation calls

### Canvas API Client

**Purpose:** Provides interface to Canvas LMS API endpoints

**Key Methods:**
- `getCourses()`: Fetches user's enrolled courses
- `getAssignments(String courseId)`: Retrieves course assignments
- `getCalendarEvents()`: Fetches calendar events
- `getUserProfile()`: Gets current user information

**Features:**
- Automatic authentication header injection
- Request/response interceptors for logging and error handling
- Pagination support for large datasets
- Retry logic with exponential backoff
- Response caching for offline support

### Calendar Service

**Purpose:** Manages device calendar integration

**Key Methods:**
- `createAssignmentEvent(Assignment assignment)`: Creates calendar event
- `updateAssignmentEvent(Assignment assignment)`: Updates existing event
- `deleteAssignmentEvent(String assignmentId)`: Removes calendar event
- `checkCalendarPermissions()`: Verifies calendar access
- `requestCalendarPermissions()`: Requests calendar permissions

**Implementation Details:**
- Uses `device_calendar` package for cross-platform calendar access
- Stores Canvas assignment ID in event description for duplicate prevention
- Handles platform-specific permission flows
- Provides fallback behavior when permissions are denied

### Notification Service

**Purpose:** Manages local and push notifications

**Key Methods:**
- `scheduleAssignmentReminder(Assignment assignment, Duration beforeDeadline)`: Schedules local notification
- `cancelAssignmentReminder(String assignmentId)`: Cancels scheduled notification
- `initializeFCM()`: Sets up Firebase Cloud Messaging
- `handleBackgroundMessage(RemoteMessage message)`: Processes background notifications

**Features:**
- Cross-platform notification scheduling
- Customizable reminder timing
- FCM integration for server-sent notifications
- Notification permission handling
- Background notification processing

### Background Service

**Purpose:** Handles periodic data synchronization

**Key Methods:**
- `registerBackgroundTask()`: Sets up periodic sync
- `performBackgroundSync()`: Executes sync operation
- `updateSyncFrequency(Duration frequency)`: Modifies sync interval

**Implementation:**
- Uses `workmanager` for Android background tasks
- Uses `background_fetch` for iOS background processing
- Implements battery-aware sync frequency adjustment
- Handles network connectivity checks
- Provides sync status reporting

### State Management

**Architecture:** Provider pattern with ChangeNotifier

**Key Providers:**
- `AuthProvider`: Manages authentication state
- `CoursesProvider`: Handles course data and loading states
- `AssignmentsProvider`: Manages assignment data
- `SettingsProvider`: Controls app configuration
- `CalendarProvider`: Manages calendar sync state
- `NotificationProvider`: Handles notification preferences

## Data Models

### User Model
```dart
class User {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime? lastLogin;
}
```

### Course Model
```dart
class Course {
  final int id;
  final String name;
  final String courseCode;
  final String? description;
  final DateTime? startAt;
  final DateTime? endAt;
  final int enrollmentCount;
  final bool isFavorite;
}
```

### Assignment Model
```dart
class Assignment {
  final int id;
  final String name;
  final String? description;
  final DateTime? dueAt;
  final DateTime? unlockAt;
  final DateTime? lockAt;
  final double pointsPossible;
  final String submissionTypes;
  final bool hasSubmittedSubmissions;
  final String workflowState;
  final int courseId;
}
```

### Calendar Event Model
```dart
class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final bool isAllDay;
  final String? canvasAssignmentId;
}
```

### Notification Model
```dart
class NotificationSettings {
  final bool enabled;
  final Duration reminderTime;
  final List<int> enabledCourseIds;
  final bool soundEnabled;
  final bool vibrationEnabled;
}
```

## Error Handling

### Error Types

1. **Authentication Errors**
   - Invalid token
   - Expired session
   - Network connectivity issues during login

2. **API Errors**
   - Rate limiting
   - Server errors (5xx)
   - Malformed responses
   - Network timeouts

3. **Permission Errors**
   - Calendar access denied
   - Notification permissions denied
   - Background processing restrictions

4. **Data Errors**
   - Corrupted local cache
   - Invalid assignment data
   - Calendar sync conflicts

### Error Handling Strategy

- **User-Friendly Messages:** All errors are translated to actionable user messages
- **Retry Logic:** Automatic retry for transient network errors
- **Graceful Degradation:** App continues to function with cached data when possible
- **Error Reporting:** Non-sensitive error information logged for debugging
- **Recovery Actions:** Clear recovery paths provided for each error type

## Testing Strategy

### Unit Testing
- **Models:** Serialization/deserialization testing
- **Services:** Mock-based testing for all service methods
- **Providers:** State management logic testing
- **Utilities:** Helper function validation

### Integration Testing
- **API Client:** Real API endpoint testing (with test credentials)
- **Calendar Service:** Device calendar integration testing
- **Notification Service:** Local notification scheduling testing
- **Background Service:** Background task execution testing

### Widget Testing
- **Screens:** UI component rendering and interaction testing
- **Forms:** Input validation and submission testing
- **Navigation:** Route transitions and state preservation testing

### End-to-End Testing
- **Authentication Flow:** Complete login process testing
- **Data Synchronization:** Full sync cycle testing
- **Calendar Integration:** Assignment-to-calendar workflow testing
- **Notification Flow:** Reminder scheduling and delivery testing

## Security Considerations

### Data Protection
- **Token Storage:** AES-256 encryption via flutter_secure_storage
- **Local Cache:** Sensitive data encrypted at rest
- **Network Communication:** HTTPS-only with certificate pinning
- **Memory Management:** Sensitive data cleared from memory after use

### Privacy Measures
- **Data Minimization:** Only necessary data is cached locally
- **No External Transmission:** User data never sent to third-party servers
- **Audit Trail:** Security-relevant actions logged (without sensitive data)
- **Permission Transparency:** Clear explanations for all permission requests

### Authentication Security
- **Token Validation:** Regular token health checks
- **Session Management:** Automatic logout on token expiration
- **Secure WebView:** Restricted domain access during authentication
- **Fallback Security:** Manual token input with validation

## Performance Optimization

### Network Optimization
- **Request Batching:** Multiple API calls combined when possible
- **Response Caching:** Intelligent caching with TTL
- **Compression:** GZIP compression for API responses
- **Connection Pooling:** Reuse HTTP connections

### Memory Management
- **Lazy Loading:** Data loaded on-demand
- **Image Caching:** Efficient avatar and course image handling
- **List Virtualization:** Large assignment lists rendered efficiently
- **Memory Monitoring:** Proactive memory cleanup

### Battery Optimization
- **Adaptive Sync:** Background sync frequency based on usage patterns
- **Network Awareness:** Reduced sync on cellular connections
- **Screen State Awareness:** Paused operations when screen is off
- **Battery Level Monitoring:** Reduced functionality on low battery

## Accessibility Features

### Visual Accessibility
- **Dynamic Font Sizing:** Support for system font size preferences
- **High Contrast Mode:** Enhanced color contrast options
- **Color Blind Support:** Color-independent information presentation
- **Screen Reader Support:** Comprehensive VoiceOver/TalkBack integration

### Motor Accessibility
- **Large Touch Targets:** Minimum 44pt touch targets
- **Gesture Alternatives:** Alternative input methods for complex gestures
- **Voice Control:** Support for voice navigation commands

### Cognitive Accessibility
- **Clear Navigation:** Consistent and predictable interface patterns
- **Error Prevention:** Input validation with clear feedback
- **Help Documentation:** Contextual help and tutorials
- **Simplified Modes:** Optional simplified interface for basic functions

## Localization Support

### Supported Languages
- **Japanese:** Primary language for Keio University students
- **English:** Secondary language for international students

### Localization Features
- **Date/Time Formatting:** Culture-appropriate date and time display
- **Number Formatting:** Locale-specific number and currency formatting
- **Text Direction:** Support for different text directions if needed
- **Cultural Adaptations:** Appropriate color schemes and imagery

## Platform-Specific Considerations

### iOS Specific
- **Background App Refresh:** Proper handling of iOS background limitations
- **App Transport Security:** ATS compliance for network requests
- **Privacy Manifests:** Required privacy declarations for App Store
- **Push Notifications:** APNs integration and certificate management

### Android Specific
- **Doze Mode:** Optimization for Android's battery optimization
- **Scoped Storage:** Compliance with Android 10+ storage restrictions
- **Background Execution:** Proper handling of background execution limits
- **Material Design:** Platform-appropriate design language implementation

## Deployment Architecture

### Build Configuration
- **Environment Variables:** Separate configurations for development, staging, and production
- **Code Signing:** Automated signing for both platforms
- **Obfuscation:** Code obfuscation for release builds
- **Asset Optimization:** Image and resource optimization

### Release Pipeline
- **Automated Testing:** Full test suite execution before release
- **Security Scanning:** Automated vulnerability scanning
- **Performance Testing:** Load and performance validation
- **Compliance Checking:** Privacy and security compliance verification