# QuickTask — Complete Architectural Documentation

> "The silent partner in your daily workflow"
> Voice-driven task manager synced to Google Calendar

**Version:** 1.0.0+1
**Date:** 2026-05-08

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [Directory Structure](#3-directory-structure)
4. [Architecture Pattern](#4-architecture-pattern)
5. [Feature Breakdown](#5-feature-breakdown)
6. [Data Layer](#6-data-layer)
7. [State Management](#7-state-management)
8. [Routing & Navigation](#8-routing--navigation)
9. [Services](#9-services)
10. [Authentication System](#10-authentication-system)
11. [UI Components & Design System](#11-ui-components--design-system)
12. [Entry Points & Bootstrap](#12-entry-points--bootstrap)
13. [Notable Patterns & Infrastructure](#13-notable-patterns--infrastructure)

---

## 1. Project Overview

**QuickTask** is a cross-platform voice-driven task management application built with Flutter. Users can create tasks by speaking them aloud — the app parses natural language for date/time information, saves tasks locally (offline-first), syncs to Firebase Cloud Firestore, and automatically creates Google Calendar events.

**Platform targets:** Android, iOS, Web, macOS, Linux, Windows
**Firebase project:** `quicktask-a7b47`

---

## 2. Technology Stack

### Framework & Language

| Item | Version |
|------|---------|
| Flutter SDK | >= 3.38.4 |
| Dart SDK | >= 3.10.3, < 4.0.0 |

### Key Packages / Dependencies

**Firebase (Backend)**
- `firebase_core` ^3.0.0 — Firebase initialization
- `firebase_auth` ^5.0.0 — Authentication (email/password + Google OAuth)
- `cloud_firestore` ^5.0.0 — Cloud database for task sync

**Local Storage**
- `hive` ^2.2.3 — NoSQL local database
- `hive_flutter` ^1.1.0 — Hive Flutter integration

**Google Integration**
- `google_sign_in` ^6.2.1 — Google OAuth sign-in
- `googleapis` ^12.0.0 — Google Calendar API client
- `googleapis_auth` ^1.6.0 — OAuth access credentials

**Voice / Speech**
- `speech_to_text` ^7.0.0 — Real-time speech recognition
- `permission_handler` ^11.3.1 — Runtime permissions (microphone)
- `flutter_tts` ^4.0.2 — Text-to-speech (voice prompts)
- `intl` ^0.19.0 — Date/time formatting

**Notifications**
- `flutter_local_notifications` ^17.2.4 — Local push notifications
- `timezone` ^0.9.4 — Timezone support for scheduled notifications

**State Management**
- `provider` ^6.1.2 — InheritedWidget-based state management

**Navigation**
- `go_router` ^14.0.0 — Declarative routing with auth guards

**Utilities**
- `uuid` ^4.4.0 — UUID generation for task IDs
- `http` ^1.2.1 — HTTP client for Google Calendar REST API
- `google_fonts` ^6.2.1 — Google Fonts (Inter typeface)
- `cupertino_icons` ^1.0.8 — iOS-style icons

---

## 3. Directory Structure

```
quicktask/
├── lib/
│   ├── main.dart                          # Entry point
│   ├── firebase_options.dart             # Firebase platform config
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_colors.dart           # Design tokens / color palette
│   │   ├── database/
│   │   │   ├── database_service.dart      # Hive initialization & CRUD helpers
│   │   │   ├── user_model.dart            # Hive model: UserModel
│   │   │   ├── user_model.g.dart          # Generated Hive adapter
│   │   │   ├── task_model_hive.dart       # Hive model: TaskModelHive
│   │   │   └── task_model_hive.g.dart     # Generated Hive adapter
│   │   └── router/
│   │       └── app_router.dart            # GoRouter setup + auth guard
│   │
│   ├── domain/
│   │   └── entities/
│   │       └── task_entity.dart           # Core task entity (pure Dart)
│   │
│   ├── data/
│   │   ├── models/
│   │   │   └── task_model.dart            # Firestore task model with to/from converters
│   │   └── repositories/
│   │       ├── auth_repository.dart       # Legacy auth repository
│   │       ├── task_repository.dart       # Firestore task repository
│   │       └── local_task_repository.dart # Hive local task repository
│   │
│   ├── features/
│   │   └── auth/
│   │       ├── domain/
│   │       │   └── repositories/
│   │       │       └── auth_repository.dart    # Abstract auth interface
│   │       ├── data/
│   │       │   ├── datasources/
│   │       │   │   └── firebase_auth_datasource.dart  # Direct Firebase calls
│   │       │   └── repositories/
│   │       │       └── auth_repository_impl.dart    # AuthRepository impl
│   │       └── presentation/
│   │           ├── providers/
│   │           │   └── auth_provider.dart   # AuthNotifier (ChangeNotifier)
│   │           ├── screens/
│   │           │   ├── login_screen.dart    # Login screen
│   │           │   └── register_screen.dart # Registration screen
│   │           └── widgets/
│   │               └── google_sign_in_button.dart  # Reusable Google sign-in button
│   │
│   ├── presentation/
│   │   ├── providers/
│   │   │   └── task_provider.dart          # TasksNotifier (main task state)
│   │   ├── screens/
│   │   │   ├── home_screen.dart            # Main home screen
│   │   │   └── add_task_screen.dart        # Add/edit task screen
│   │   └── widgets/
│   │       ├── task_card.dart               # Premium glassmorphism task card
│   │       └── voice_button.dart            # Voice input button widget
│   │
│   └── services/
│       ├── voice_service.dart              # Speech-to-text + TTS wrapper
│       ├── task_parser_service.dart        # NLP: parses date/time from speech text
│       ├── calendar_service.dart           # Google Calendar REST API integration
│       └── notification_service.dart       # Local notification scheduling
│
├── assets/
│   ├── logo.png                           # App logo
│   └── google_logo.png                   # Google logo image
│
├── test/
│   ├── app_test.dart                     # Flutter template test
│   └── widget_test.dart                 # Flutter template test
│
├── test_parser.dart                      # Standalone parser unit test
├── pubspec.yaml                          # Project manifest
├── pubspec.lock                          # Locked dependency versions
├── analysis_options.yaml                # Dart analyzer config
├── devtools_options.yaml                # DevTools extension settings
├── firebase.json                         # Firebase CLI config
├── firestore.indexes.json               # Firestore composite index definitions
├── firestore.rules                      # Firestore security rules
└── flutter_gcalendar_firebase_guide.md  # Integration guide
```

---

## 4. Architecture Pattern

The app uses a **hybrid architecture** combining Clean Architecture principles with a feature-first organization.

### Layer Separation

| Layer | Location | Purpose |
|-------|----------|---------|
| **Presentation** | `lib/presentation/` + `features/auth/presentation/` | Widgets, Screens, Providers (ChangeNotifiers) |
| **Domain** | `lib/domain/` | Pure Dart entities (no Flutter/Firebase deps), abstract interfaces |
| **Data** | `lib/data/` | Concrete model classes (Firestore models), repository implementations |
| **Core/Infrastructure** | `lib/core/` | Database, routing, constants — shared cross-cutting concerns |
| **Services** | `lib/services/` | Business logic services (voice, calendar, notifications, parsing) |

### Feature-First Organization (Auth)

Auth is the only feature module organized in the `features/` directory, following full Clean Architecture layering within itself:

```
features/auth/
  domain/         → abstract interfaces (port)
  data/           → implementations (adapter)
  presentation/   → UI + state (providers, screens, widgets)
```

### State Management Approach

- **Provider** (not Riverpod/Bloc) — `ChangeNotifier` classes wrapped in `ChangeNotifierProvider` / `ChangeNotifierProxyProvider4`
- Two main notifiers: `AuthNotifier` and `TasksNotifier`
- One stream provider: `StreamProvider<User?>` for Firebase auth state
- Two proxy providers that re-instantiate repositories on user change

### Naming Conventions

- Dart files: `snake_case.dart`
- Classes: `PascalCase`
- Private members: `_camelCase`
- Hive models: `ModelName` + `ModelNameAdapter` (generated `.g.dart`)

---

## 5. Feature Breakdown

### 5.1 Authentication

| File | Role |
|------|------|
| `lib/features/auth/domain/repositories/auth_repository.dart` | Abstract interface: `signInWithEmail`, `signUpWithEmail`, `signInWithGoogle`, `signOut`, `authStateChanges`, `sendPasswordResetEmail`, `getAccessCredentials` |
| `lib/features/auth/data/datasources/firebase_auth_datasource.dart` | All direct Firebase/Google calls. Error codes mapped to Arabic user-friendly messages via `mapFirebaseError` |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | Decorator pattern: delegates all calls to `FirebaseAuthDatasource` |
| `lib/features/auth/presentation/providers/auth_provider.dart` | `AuthNotifier extends ChangeNotifier`: manages `AuthState`, persists user to Hive on sign-in, clears Hive on sign-out |
| `lib/features/auth/presentation/screens/login_screen.dart` | Light-themed login with ambient background glows, Google Sign-In button, tagline, privacy/terms links |
| `lib/features/auth/presentation/screens/register_screen.dart` | Dark-themed (glassmorphism) registration form with name/email/password/confirm fields, password strength indicator, Google sign-in option |
| `lib/features/auth/presentation/widgets/google_sign_in_button.dart` | Reusable animated button with Google logo (loaded from URL with fallback), press scale animation |

### 5.2 Task Management

| File | Role |
|------|------|
| `lib/domain/entities/task_entity.dart` | Base entity: `id`, `userId`, `title`, `description?`, `scheduledAt`, `isSyncedToCalendar`, `calendarEventId?`, `createdAt`, `isCompleted` |
| `lib/core/database/task_model_hive.dart` | Hive-persisted task model, extends `TaskEntity`, `typeId: 1` |
| `lib/data/models/task_model.dart` | Firestore-persisted task model with `fromFirestore()` / `toFirestore()` converters |
| `lib/data/repositories/local_task_repository.dart` | Wrapper around `DatabaseService` for local CRUD |
| `lib/data/repositories/task_repository.dart` | Firestore CRUD: `watchTasks()` (stream), `addTask`, `updateTask`, `deleteTask` |
| `lib/presentation/providers/task_provider.dart` | `TasksNotifier extends ChangeNotifier`: dual-write to local (Hive) + remote (Firestore) with graceful offline fallback. Subscribes to Firestore stream for cloud-to-local sync. Creates Google Calendar events on task add |
| `lib/presentation/screens/home_screen.dart` | Main dashboard: hero greeting, progress arc, dashboard stat cards (Today/Done), task filter chips (All/Today/Done), task list with OVERDUE/UPCOMING dividers, frosted bottom input bar with quick time chips + voice button |
| `lib/presentation/screens/add_task_screen.dart` | Task creation form: voice hero card, title + notes fields, date/time picker, quick-pick time chips, priority selector, reminder row, category chips, submit CTA |
| `lib/presentation/widgets/task_card.dart` | Premium glassmorphism card with 4 visual states (upcoming=violet, overdue=red, completed=green, synced=gold), swipe-to-delete/done, tap-scale animation, haptics |

### 5.3 Voice Input

| File | Role |
|------|------|
| `lib/services/voice_service.dart` | `VoiceService`: wraps `SpeechToText` + `FlutterTts`. `TtsLocale` enum (`english`/`arabic`). Initialises microphone permission. `initialize()`, `startListening()`, `stop()`, `setLocale()`, `speakPrompt()`. 30s listen timeout, 3s pause timeout |
| `lib/services/task_parser_service.dart` | `TaskParserService`: NLP-style regex parser for English and Arabic. Converts word numbers to digits. Extracts time from patterns like "at 10 PM tomorrow", "الساعة 10 مساءً غداً". Returns `ParsedTask(title, scheduledAt?, fullText)` |

### 5.4 Google Calendar Integration

| File | Role |
|------|------|
| `lib/services/calendar_service.dart` | REST API client for Google Calendar v3. `_getAuthHeaders()` obtains `AccessCredentials` from `AuthRepository`. `createEvent()` POSTs to `/calendars/primary/events` (1-hour duration, 15-min popup reminder, timezone Africa/Cairo). `deleteEvent()` DELETE. `getUpcomingEvents()` queries events from now |
| `lib/data/repositories/auth_repository.dart` | GoogleSignIn configured with `calendar` scope to obtain OAuth token for Calendar API |

### 5.5 Notifications

| File | Role |
|------|------|
| `lib/services/notification_service.dart` | `NotificationService` static class. `init()` registers timezone data, requests permissions. `scheduleTaskNotification()` schedules 15 minutes before `scheduledAt`. Uses `zonedSchedule` with `AndroidScheduleMode.exactAllowWhileIdle`. `cancelNotification()` by task ID hash |

---

## 6. Data Layer

### 6.1 Task Entity Fields

```
id              String          (UUID v4)
userId          String          (Firebase UID)
title           String
description?    String?
scheduledAt     DateTime        (scheduled execution time)
isSyncedToCalendar bool         (default: false)
calendarEventId? String?        (Google Calendar event ID)
createdAt       DateTime
isCompleted     bool            (default: false)
```

### 6.2 Local Storage (Hive)

- **Box: `users`** (typeId 0, `UserModel`) — stores authenticated user info locally
- **Box: `tasks`** (typeId 1, `TaskModelHive`) — stores all tasks locally keyed by `task.id`
- `DatabaseService` (lines 6–87): static helper class managing box lifecycle, CRUD operations, and cleanup

### 6.3 Cloud Storage (Firestore)

- **Collection:** `users/{uid}/tasks/{taskId}`
- Document fields mirror `TaskEntity` using `Timestamp` for dates
- `TaskModel.fromFirestore()` handles timestamp-to-DateTime conversion

### 6.4 Sync Strategy

The `TasksNotifier.addTask()` method implements a **tiered write** pattern:

1. Save to Hive first (guaranteed offline success)
2. Attempt Google Calendar event creation (best-effort, non-blocking failure)
3. Attempt Firestore write (best-effort, non-blocking failure)
4. Schedule local notification

The `_initSync()` stream listens to Firestore and mirrors remote tasks to local Hive, providing **cloud-to-local sync** for offline→online transitions.

---

## 7. State Management

### Provider Tree (main.dart)

```
MultiProvider
├── FirebaseAuthDatasource            (Provider — stateless)
├── AuthRepository                    (ProxyProvider from datasource)
├── AuthNotifier                     (ChangeNotifierProvider)
├── StreamProvider<User?>            (Firebase auth state stream)
├── LocalTaskRepository               (ProxyProvider — keyed by user.uid)
├── TaskRepository                   (ProxyProvider — keyed by user.uid)
├── CalendarService                  (Provider — needs AuthRepository)
└── TasksNotifier                    (ChangeNotifierProxyProvider4)
```

### AuthState Machine

```
AuthInitial
    ↓
AuthLoading ← action triggered
    ↓
AuthAuthenticated(user) ← on successful auth
    ↓
AuthUnauthenticated ← on sign-out
    ↓
AuthError(message) ← on exception
```

### TasksNotifier Derived State

- `tasks` — all tasks
- `completedTasks` — `tasks.where(isCompleted)`
- `pendingTasks` — `tasks.where(!isCompleted)`
- `upcomingTasks` — pending tasks with `scheduledAt > now`, sorted by time
- `overdueTasks` — pending tasks with `scheduledAt < now`, sorted by time

---

## 8. Routing & Navigation

### GoRouter Routes

| Path | Screen | Auth Required |
|------|---------|---------------|
| `/login` | `LoginScreen` | No |
| `/register` | `RegisterScreen` | No |
| `/home` | `HomeScreen` | Yes (via `ShellRoute` + `AuthWrapper`) |

### Redirect Logic

```dart
if (user != null) {
  return isLoggingIn ? '/home' : null;  // logged-in users → home
}
return isLoggingIn ? null : '/login';   // guest users → login
```

### Navigation Patterns

- **Authenticated routes:** wrapped in a `ShellRoute` with `AuthWrapper` child
- **AddTaskScreen:** opened via `Navigator.push()` with a custom slide-up `PageRouteBuilder` (320ms ease-out-cubic transition)
- **Voice input callback:** `VoiceButton` accepts `onParsed: (ParsedTask) → AddTaskScreen(initialParsed: parsed)` — a pre-filled task from voice

---

## 9. Services

| Service | File | Lines | Responsibilities |
|---------|------|-------|-------------------|
| `VoiceService` | `lib/services/voice_service.dart` | L10–L72 | Speech-to-text recognition + TTS. Manages microphone permission, locale (EN/AR), listen timeout |
| `TaskParserService` | `lib/services/task_parser_service.dart` | L15–L180 | NLP regex parser. Converts word numbers to digits in both Arabic and English. Extracts time/date from natural language. Returns `ParsedTask` |
| `CalendarService` | `lib/services/calendar_service.dart` | L7–L101 | Google Calendar REST API. OAuth header injection, create/delete event, fetch upcoming events |
| `NotificationService` | `lib/services/notification_service.dart` | L7–L71 | Local notification scheduling. 15-min-before reminders, permission requests, timezone-aware scheduling |
| `DatabaseService` | `lib/core/database/database_service.dart` | L6–L87 | Hive init, box management, user/task CRUD helpers |

---

## 10. Authentication System

### Providers Supported

1. **Google Sign-In** — OAuth via `google_sign_in` package. Requests `email` + `https://www.googleapis.com/auth/calendar` scopes. Access token stored in Firestore (`users/{uid}.calendarAccessToken`). Used for both Firebase auth AND Calendar API.
2. **Email/Password** — `FirebaseAuth.createUserWithEmailAndPassword` / `signInWithEmailAndPassword`. Display name update on signup. User document created in Firestore.

### Auth Flow

```
main.dart startup
  → DatabaseService.init()              // Hive
  → Firebase.initializeApp()            // Firebase (duplicate-safe)
  → NotificationService.init()          // Notifications
  → MultiProvider setup                 // All providers
  → QuickTaskApp (MaterialApp.router)
      → createAppRouter(authNotifier)   // GoRouter with redirect
          → redirect checks FirebaseUser
              → /login or /home
```

### Error Handling

`mapFirebaseError()` in `firebase_auth_datasource.dart` maps Firebase error codes to Arabic human-readable strings for UI display.

### Persistence

- On sign-in: `AuthNotifier._persistUser()` writes `UserModel` to Hive `users` box
- On sign-out: `DatabaseService.deleteUser()` and `deleteTasksForUser()` clean up local data

---

## 11. UI Components & Design System

### Design System

- **Color palette** (`app_colors.dart`): Deep Indigo primary (`#1E1B4B`), Violet accent (`#8B5CF6`), Rose error (`#EF4444`), Emerald success (`#10B981`), Gold warning/calendar sync (`#F59E0B`)
- **Typography:** `GoogleFonts.inter` text theme
- **Two distinct visual themes:** Light (login screen) and Dark (register screen)

### Key Widgets

| Widget | File | Lines | Description |
|--------|------|-------|-------------|
| `TaskCard` | `lib/presentation/widgets/task_card.dart` | L73–L638 | 639-line premium glassmorphism card. State-based accent colors, swipe-to-delete/done, scale animation, status orb, time chip, sync badge |
| `VoiceButton` | `lib/presentation/widgets/voice_button.dart` | L7–L218 | 72x72px circular button with pulse animation, locale switch (EN↔AR via long-press), microphone/stop icon states |
| `GoogleSignInButton` | `lib/features/auth/presentation/widgets/google_sign_in_button.dart` | L4–L97 | Animated scale press effect, Google logo from network with icon fallback |
| `_ProgressArc` | `home_screen.dart` | L469–L629 | CustomPainter animated arc showing completion ratio with micro-copy |
| `_VoiceHero` | `add_task_screen.dart` | L683–L843 | Full-width blue card that animates to listening state with wave bar animation |
| `_DashboardCard` | `home_screen.dart` | L674–L756 | Stats card with icon, large count number, title/subtitle |

### Home Screen Layout

1. **TopAppBar** — avatar, brand mark ("TaskVoice"), sign-out button
2. **HeroSection** — greeting, user name, date label, progress arc
3. **DashboardCards** — Today count + Done count side by side
4. **SectionHeader** — filter label with count badge + filter chips (All / Today / Done)
5. **TaskList** or **EmptyState** — with OVERDUE and UPCOMING dividers
6. **BottomInputBar** (frosted glass overlay) — quick time chips + input bar + voice button

### Add Task Screen Layout

1. **ProgressStrip** — 3px top progress indicator
2. **TopBar** — back arrow, "New Task" title, overflow menu
3. **VoiceHero** — tap-to-speak card with wave animation when listening
4. **Title + Notes** — text fields
5. **Date & Time** — date/time chips + quick-pick row
6. **Priority** — Low/Medium/High toggle buttons
7. **Reminder** — cycling reminder time row
8. **Categories** — wrap chip selector (Work, Personal, Health, Study, Family)
9. **CtaBar** — fixed bottom "Create Task" button with gradient fade

---

## 12. Entry Points & Bootstrap

### `lib/main.dart` Bootstrap Sequence

```dart
main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();              // Hive
  await Firebase.initializeApp(...);         // Firebase (duplicate-safe)
  await NotificationService.init();          // Notifications
  runApp(MultiProvider(...));               // Provider tree
}
```

### QuickTaskApp Widget

- Material app with `go_router` (`MaterialApp.router`)
- Light theme only (no dark mode toggle)
- `AppColors.bgLight` as scaffold background
- Inter font via `GoogleFonts.interTextTheme`

---

## 13. Notable Patterns & Infrastructure

### Duplicate-Firebase-Init Safety

```dart
try {
  await Firebase.initializeApp(...);
} on FirebaseException catch (e) {
  if (e.code != 'duplicate-app') rethrow;
  // Already initialized — safe to continue
}
```

This prevents crashes during hot reload / debug restarts.

### Offline-First Architecture

Every `TasksNotifier` mutation method (add, toggle, delete, update) wraps each operation in a `try/catch` that silently fails the cloud operation while continuing with local persistence.

### Bi-lingual (EN/AR) Support

- `TaskParserService` branches on Arabic script detection (`RegExp(r'[؀-ۿ]')`)
- `VoiceService` has `TtsLocale` enum and `setLocale()` method for Arabic (ar-SA) and English (en-US)
- `VoiceButton` long-press toggles locale

### Haptic Feedback

Extensively used at multiple interaction points: task card deletion confirmation, filter chip taps, quick time chip taps, form submission, voice button toggles.

### Sealed Class Pattern

Used for `AuthState` and `_ListItem` (home_screen.dart), enabling exhaustive pattern matching in `switch` expressions.

### Animation Highlights

- Task cards: 130ms scale + glow animation on press
- Task list items: staggered fade+slide entrance (280ms base + 35ms per item)
- Progress arc: 900ms easeOutCubic animation on mount and ratio change
- Add task screen: staggered card entrance (6 cards, 10% delay per card, 800ms total duration)
- VoiceButton: 800ms pulse animation while listening
- VoiceHero: wave bar animation (5 bars, 150ms stagger) while listening

---

## File Path Index

```
c:/Users/mabou/Desktop/quicktask/lib/main.dart
c:/Users/mabou/Desktop/quicktask/lib/firebase_options.dart
c:/Users/mabou/Desktop/quicktask/lib/core/constants/app_colors.dart
c:/Users/mabou/Desktop/quicktask/lib/core/router/app_router.dart
c:/Users/mabou/Desktop/quicktask/lib/core/database/database_service.dart
c:/Users/mabou/Desktop/quicktask/lib/core/database/user_model.dart
c:/Users/mabou/Desktop/quicktask/lib/core/database/user_model.g.dart
c:/Users/mabou/Desktop/quicktask/lib/core/database/task_model_hive.dart
c:/Users/mabou/Desktop/quicktask/lib/core/database/task_model_hive.g.dart
c:/Users/mabou/Desktop/quicktask/lib/domain/entities/task_entity.dart
c:/Users/mabou/Desktop/quicktask/lib/data/models/task_model.dart
c:/Users/mabou/Desktop/quicktask/lib/data/repositories/auth_repository.dart
c:/Users/mabou/Desktop/quicktask/lib/data/repositories/task_repository.dart
c:/Users/mabou/Desktop/quicktask/lib/data/repositories/local_task_repository.dart
c:/Users/mabou/Desktop/quicktask/lib/features/auth/domain/repositories/auth_repository.dart
c:/Users/mabou/Desktop/quicktask/lib/features/auth/data/datasources/firebase_auth_datasource.dart
c:/Users/mabou/Desktop/quicktask/lib/features/auth/data/repositories/auth_repository_impl.dart
c:/Users/mabou/Desktop/quicktask/lib/features/auth/presentation/providers/auth_provider.dart
c:/Users/mabou/Desktop/quicktask/lib/features/auth/presentation/screens/login_screen.dart
c:/Users/mabou/Desktop/quicktask/lib/features/auth/presentation/screens/register_screen.dart
c:/Users/mabou/Desktop/quicktask/lib/features/auth/presentation/widgets/google_sign_in_button.dart
c:/Users/mabou/Desktop/quicktask/lib/presentation/providers/task_provider.dart
c:/Users/mabou/Desktop/quicktask/lib/presentation/screens/home_screen.dart
c:/Users/mabou/Desktop/quicktask/lib/presentation/screens/add_task_screen.dart
c:/Users/mabou/Desktop/quicktask/lib/presentation/widgets/task_card.dart
c:/Users/mabou/Desktop/quicktask/lib/presentation/widgets/voice_button.dart
c:/Users/mabou/Desktop/quicktask/lib/services/voice_service.dart
c:/Users/mabou/Desktop/quicktask/lib/services/task_parser_service.dart
c:/Users/mabou/Desktop/quicktask/lib/services/calendar_service.dart
c:/Users/mabou/Desktop/quicktask/lib/services/notification_service.dart
```