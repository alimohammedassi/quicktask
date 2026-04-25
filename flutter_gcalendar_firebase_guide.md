# Flutter Voice Task App — Google Calendar + Firebase Blueprint

> Stack: Flutter · Firebase Auth · Firestore · Cloud Functions · Google Calendar API · speech_to_text · flutter_local_notifications

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Google Cloud & Calendar API Setup](#2-google-cloud--calendar-api-setup)
3. [Firebase Project Setup](#3-firebase-project-setup)
4. [Flutter Project Initialization](#4-flutter-project-initialization)
5. [Google OAuth Authentication](#5-google-oauth-authentication)
6. [Firestore Data Model](#6-firestore-data-model)
7. [Speech-to-Text (Voice Input)](#7-speech-to-text-voice-input)
8. [Google Calendar Sync](#8-google-calendar-sync)
9. [Local Notifications](#9-local-notifications)
10. [Clean Architecture Folder Structure](#10-clean-architecture-folder-structure)
11. [UI Design Guide](#11-ui-design-guide)
12. [Security Checklist](#12-security-checklist)
13. [Full pubspec.yaml](#13-full-pubspecyaml)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                     Flutter App                      │
│                                                     │
│  UI Layer          Domain Layer       Data Layer    │
│  ──────────        ────────────       ──────────    │
│  Screens           Use Cases          Repositories  │
│  Widgets           Entities           Data Sources  │
│  Riverpod          Interfaces         Models        │
└────────────────────┬─────────────────────────────────┘
                     │
          ┌──────────┴──────────┐
          │                     │
   ┌──────▼──────┐    ┌─────────▼────────┐
   │  Firebase   │    │  Google APIs     │
   │  ─────────  │    │  ─────────────── │
   │  Auth       │    │  Calendar v3     │
   │  Firestore  │    │  OAuth 2.0       │
   │  Functions  │    │                  │
   └─────────────┘    └──────────────────┘
```

**Data Flow for a Voice Task:**

```
User speaks → speech_to_text → TaskEntity created
→ Saved to Firestore → Cloud Function triggered
→ Google Calendar event created via Calendar API
→ Notification scheduled locally
```

---

## 2. Google Cloud & Calendar API Setup

### Step 1 — Create a Google Cloud Project

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Click **New Project** → name it (e.g., `voice-task-app`)
3. Note your **Project ID**

### Step 2 — Enable the Google Calendar API

```
APIs & Services → Library → Search "Google Calendar API" → Enable
```

### Step 3 — Configure OAuth Consent Screen

```
APIs & Services → OAuth Consent Screen
→ User Type: External
→ App name, support email, developer email
→ Scopes: add "https://www.googleapis.com/auth/calendar"
→ Save and Continue
```

### Step 4 — Create OAuth 2.0 Credentials

For **Android:**
```
Credentials → Create Credentials → OAuth Client ID
→ Application Type: Android
→ Package name: com.yourname.voicetask
→ SHA-1 fingerprint (get it via keytool):
```

```bash
# Debug keystore SHA-1
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

For **iOS:**
```
→ Application Type: iOS
→ Bundle ID: com.yourname.voicetask
```

> **Important:** Download both `google-services.json` (Android) and `GoogleService-Info.plist` (iOS). These contain your OAuth client IDs.

---

## 3. Firebase Project Setup

### Step 1 — Create Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. **Add project** → link to your existing Google Cloud project
3. Enable **Google Analytics** (optional)

### Step 2 — Register Apps

**Android:** Add package name → download `google-services.json` → place in `android/app/`

**iOS:** Add bundle ID → download `GoogleService-Info.plist` → place in `ios/Runner/`

### Step 3 — Enable Firebase Services

```
Authentication → Sign-in method → Google → Enable
Firestore Database → Create database → Start in production mode
```

### Step 4 — Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=your-project-id
```

This generates `lib/firebase_options.dart` automatically.

### Step 5 — Firestore Security Rules (Initial)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own tasks
    match /users/{userId}/tasks/{taskId} {
      allow read, write: if request.auth != null
        && request.auth.uid == userId;
    }
    // User profile
    match /users/{userId} {
      allow read, write: if request.auth != null
        && request.auth.uid == userId;
    }
  }
}
```

---

## 4. Flutter Project Initialization

### Step 1 — Initialize Firebase in main.dart

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.init(); // see Section 9
  runApp(const ProviderScope(child: MyApp()));
}
```

### Step 2 — Android Configuration

In `android/app/build.gradle`:
```groovy
android {
  defaultConfig {
    minSdkVersion 21   // Required for Firebase
    targetSdkVersion 34
  }
}
```

In `android/build.gradle`:
```groovy
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
  }
}
```

In `android/app/build.gradle` (bottom):
```groovy
apply plugin: 'com.google.gms.google-services'
```

### Step 3 — Android Permissions (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

### Step 4 — iOS Configuration (Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record your voice tasks.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>We use speech recognition to convert your voice to text tasks.</string>
```

---

## 5. Google OAuth Authentication

### AuthRepository

```dart
// lib/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Request Calendar scope during sign-in
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
    ],
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await account.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Store the access token securely for Calendar API calls
      await _storeAccessToken(googleAuth.accessToken!);

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw AuthException('Sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Store token in Firestore (user-scoped, not in client storage)
  Future<void> _storeAccessToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'calendarAccessToken': token}, SetOptions(merge: true));
  }

  Future<String?> getAccessToken() async {
    final account = await _googleSignIn.signInSilently();
    final auth = await account?.authentication;
    return auth?.accessToken;
  }
}
```

### AuthNotifier with Riverpod

```dart
// lib/presentation/providers/auth_provider.dart
final authRepositoryProvider = Provider((ref) => AuthRepository());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;
  AuthNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> signIn() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.signInWithGoogle());
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.signOut());
  }
}
```

---

## 6. Firestore Data Model

### Task Entity

```dart
// lib/domain/entities/task_entity.dart
class TaskEntity {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime scheduledAt;
  final bool isSyncedToCalendar;
  final String? calendarEventId;
  final DateTime createdAt;

  const TaskEntity({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.scheduledAt,
    this.isSyncedToCalendar = false,
    this.calendarEventId,
    required this.createdAt,
  });
}
```

### Task Model (Firestore)

```dart
// lib/data/models/task_model.dart
class TaskModel extends TaskEntity {
  TaskModel({
    required super.id,
    required super.userId,
    required super.title,
    super.description,
    required super.scheduledAt,
    super.isSyncedToCalendar,
    super.calendarEventId,
    required super.createdAt,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      userId: data['userId'],
      title: data['title'],
      description: data['description'],
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      isSyncedToCalendar: data['isSyncedToCalendar'] ?? false,
      calendarEventId: data['calendarEventId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'title': title,
    'description': description,
    'scheduledAt': Timestamp.fromDate(scheduledAt),
    'isSyncedToCalendar': isSyncedToCalendar,
    'calendarEventId': calendarEventId,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
```

### TaskRepository

```dart
// lib/data/repositories/task_repository.dart
class TaskRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  TaskRepository({required this.userId});

  CollectionReference get _tasksRef =>
      _db.collection('users').doc(userId).collection('tasks');

  Stream<List<TaskModel>> watchTasks() {
    return _tasksRef
        .orderBy('scheduledAt')
        .snapshots()
        .map((snap) => snap.docs.map(TaskModel.fromFirestore).toList());
  }

  Future<String> addTask(TaskModel task) async {
    final doc = await _tasksRef.add(task.toFirestore());
    return doc.id;
  }

  Future<void> updateTask(TaskModel task) async {
    await _tasksRef.doc(task.id).update(task.toFirestore());
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksRef.doc(taskId).delete();
  }
}
```

---

## 7. Speech-to-Text (Voice Input)

### VoiceService

```dart
// lib/services/voice_service.dart
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    // Request microphone permission first
    final status = await Permission.microphone.request();
    if (!status.isGranted) return false;

    _isInitialized = await _speech.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String text) onResult,
    required Function() onDone,
  }) async {
    if (!_isInitialized) await initialize();

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          onDone();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US', // Change to 'ar_EG' for Arabic
      cancelOnError: true,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
```

### VoiceButton Widget

```dart
// lib/presentation/widgets/voice_button.dart
class VoiceButton extends ConsumerStatefulWidget {
  final Function(String) onTextCaptured;
  const VoiceButton({required this.onTextCaptured, super.key});

  @override
  ConsumerState<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends ConsumerState<VoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isListening = false;
  final VoiceService _voice = VoiceService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseController.stop();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _voice.stopListening();
      _pulseController.stop();
      setState(() => _isListening = false);
    } else {
      final ok = await _voice.initialize();
      if (!ok) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Microphone permission denied')));
        return;
      }
      setState(() => _isListening = true);
      _pulseController.repeat(reverse: true);
      await _voice.startListening(
        onResult: widget.onTextCaptured,
        onDone: () {
          _pulseController.stop();
          setState(() => _isListening = false);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isListening ? 1.0 + (_pulseController.value * 0.15) : 1.0,
          child: GestureDetector(
            onTap: _toggleListening,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? Colors.red : const Color(0xFF4285F4),
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.red : const Color(0xFF4285F4))
                        .withOpacity(0.4),
                    blurRadius: _isListening ? 20 : 8,
                    spreadRadius: _isListening ? 4 : 1,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
```

---

## 8. Google Calendar Sync

### Option A — Direct from Flutter (Simple)

```dart
// lib/services/calendar_service.dart
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class CalendarService {
  final AuthRepository _authRepo;
  CalendarService(this._authRepo);

  Future<cal.CalendarApi> _getCalendarApi() async {
    final token = await _authRepo.getAccessToken();
    if (token == null) throw Exception('No access token');

    final client = authenticatedClient(
      http.Client(),
      AccessCredentials(
        AccessToken('Bearer', token,
            DateTime.now().add(const Duration(hours: 1)).toUtc()),
        null,
        ['https://www.googleapis.com/auth/calendar'],
      ),
    );
    return cal.CalendarApi(client);
  }

  Future<String> createEvent(TaskEntity task) async {
    final api = await _getCalendarApi();

    final event = cal.Event()
      ..summary = task.title
      ..description = task.description
      ..start = cal.EventDateTime(
        dateTime: task.scheduledAt,
        timeZone: 'Africa/Cairo', // adjust to user's timezone
      )
      ..end = cal.EventDateTime(
        dateTime: task.scheduledAt.add(const Duration(hours: 1)),
        timeZone: 'Africa/Cairo',
      )
      ..reminders = cal.EventReminders(
        useDefault: false,
        overrides: [
          cal.EventReminder(method: 'popup', minutes: 15),
        ],
      );

    final created = await api.events.insert(event, 'primary');
    return created.id!;
  }

  Future<void> deleteEvent(String eventId) async {
    final api = await _getCalendarApi();
    await api.events.delete('primary', eventId);
  }
}
```

### Option B — Via Firebase Cloud Function (Recommended for Production)

This is more secure as your tokens are not exposed on the client.

```javascript
// functions/src/index.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { google } from 'googleapis';

admin.initializeApp();

export const syncTaskToCalendar = functions.firestore
  .document('users/{userId}/tasks/{taskId}')
  .onCreate(async (snap, context) => {
    const task = snap.data();
    const { userId } = context.params;

    // Fetch user's stored access token
    const userDoc = await admin.firestore()
      .collection('users').doc(userId).get();
    const accessToken = userDoc.data()?.calendarAccessToken;

    if (!accessToken) return;

    const auth = new google.auth.OAuth2();
    auth.setCredentials({ access_token: accessToken });

    const calendar = google.calendar({ version: 'v3', auth });

    const event = {
      summary: task.title,
      description: task.description,
      start: {
        dateTime: task.scheduledAt.toDate().toISOString(),
        timeZone: 'Africa/Cairo',
      },
      end: {
        dateTime: new Date(
          task.scheduledAt.toDate().getTime() + 60 * 60 * 1000
        ).toISOString(),
        timeZone: 'Africa/Cairo',
      },
      reminders: {
        useDefault: false,
        overrides: [{ method: 'popup', minutes: 15 }],
      },
    };

    const created = await calendar.events.insert({
      calendarId: 'primary',
      requestBody: event,
    });

    // Save calendarEventId back to Firestore
    await snap.ref.update({
      isSyncedToCalendar: true,
      calendarEventId: created.data.id,
    });
  });
```

Deploy with:
```bash
firebase deploy --only functions
```

---

## 9. Local Notifications

### NotificationService

```dart
// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Cairo')); // set your timezone

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Request permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleTaskNotification(TaskEntity task) async {
    final scheduledTime = tz.TZDateTime.from(
      task.scheduledAt.subtract(const Duration(minutes: 15)),
      tz.local,
    );

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      task.id.hashCode,
      '⏰ Upcoming Task',
      task.title,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tasks_channel',
          'Task Reminders',
          channelDescription: 'Reminders for your scheduled tasks',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotification(String taskId) async {
    await _plugin.cancel(taskId.hashCode);
  }
}
```

---

## 10. Clean Architecture Folder Structure

```
lib/
├── main.dart
├── firebase_options.dart
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   └── app_strings.dart
│   ├── errors/
│   │   └── exceptions.dart
│   └── utils/
│       └── date_utils.dart
│
├── domain/
│   ├── entities/
│   │   └── task_entity.dart
│   └── repositories/
│       ├── i_auth_repository.dart
│       └── i_task_repository.dart
│
├── data/
│   ├── models/
│   │   └── task_model.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   └── task_repository.dart
│   └── datasources/
│       └── firestore_datasource.dart
│
├── services/
│   ├── voice_service.dart
│   ├── calendar_service.dart
│   └── notification_service.dart
│
└── presentation/
    ├── providers/
    │   ├── auth_provider.dart
    │   └── task_provider.dart
    ├── screens/
    │   ├── splash_screen.dart
    │   ├── login_screen.dart
    │   ├── home_screen.dart
    │   └── add_task_screen.dart
    └── widgets/
        ├── voice_button.dart
        ├── task_card.dart
        └── task_list.dart
```

---

## 11. UI Design Guide

### Design Tokens

```dart
// lib/core/constants/app_colors.dart
class AppColors {
  // Primary palette — Google Blue
  static const primary      = Color(0xFF4285F4);
  static const primaryDark  = Color(0xFF1A73E8);
  static const accent       = Color(0xFF34A853); // Google Green for success

  // Backgrounds
  static const bgDark       = Color(0xFF0F1117);
  static const surface      = Color(0xFF1A1D27);
  static const cardBg       = Color(0xFF242736);

  // Text
  static const textPrimary  = Color(0xFFF5F5F5);
  static const textSecondary= Color(0xFF9E9E9E);

  // Status
  static const error        = Color(0xFFEA4335);
  static const warning      = Color(0xFFFBBC05);
  static const success      = Color(0xFF34A853);
}
```

### Key Screen Layout — Home Screen

```dart
// lib/presentation/screens/home_screen.dart
Scaffold(
  backgroundColor: AppColors.bgDark,
  appBar: AppBar(
    backgroundColor: AppColors.surface,
    title: const Text('My Tasks'),
    actions: [
      IconButton(icon: const Icon(Icons.logout), onPressed: () => ref.read(authNotifierProvider.notifier).signOut()),
    ],
  ),
  body: Column(
    children: [
      // Task list
      Expanded(child: TaskList()),

      // Voice input bar pinned at bottom
      Container(
        padding: const EdgeInsets.all(20),
        color: AppColors.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VoiceButton(
              onTextCaptured: (text) => showAddTaskBottomSheet(context, text),
            ),
          ],
        ),
      ),
    ],
  ),
)
```

---

## 12. Security Checklist

| Item | How |
|------|-----|
| OAuth scopes minimal | Only request `calendar` scope, not `calendar.readonly` unless that's all you need |
| Access token storage | Store in Firestore (server-side) not SharedPreferences |
| Firestore Rules | Enforce `request.auth.uid == userId` on all user data |
| Token refresh | Use `googleSignIn.signInSilently()` to refresh tokens transparently |
| API key exposure | Never hardcode API keys in Flutter source code |
| Cloud Function auth | Verify `context.auth` inside every callable function |
| HTTPS only | Firestore and Firebase Functions use HTTPS by default |
| Sensitive data | Never log access tokens; use `--dart-define` for build-time secrets |

---

## 13. Full pubspec.yaml

```yaml
name: voice_task_app
description: Voice-driven task manager synced to Google Calendar

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^2.27.0
  firebase_auth: ^4.18.0
  cloud_firestore: ^4.15.0
  cloud_functions: ^4.6.7

  # Google Sign-In & Calendar
  google_sign_in: ^6.2.1
  googleapis: ^12.0.0
  googleapis_auth: ^1.6.0
  http: ^1.2.1

  # Voice Input
  speech_to_text: ^6.6.2
  permission_handler: ^11.3.1

  # Notifications
  flutter_local_notifications: ^17.1.0
  timezone: ^0.9.4

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^13.2.1

  # Utilities
  uuid: ^4.4.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.3
  flutter_lints: ^3.0.1
```

---

## Quick-Start Checklist

```
□ 1. Create Google Cloud project and enable Calendar API
□ 2. Configure OAuth Consent Screen with calendar scope
□ 3. Generate OAuth 2.0 credentials (Android SHA-1 + iOS Bundle ID)
□ 4. Create Firebase project linked to same Google Cloud project
□ 5. Enable Firebase Auth (Google provider) + Firestore
□ 6. Run: flutterfire configure
□ 7. Place google-services.json and GoogleService-Info.plist
□ 8. Add Android permissions and iOS Info.plist keys
□ 9. Implement AuthRepository with calendar scope
□ 10. Implement TaskRepository with Firestore
□ 11. Build VoiceService and VoiceButton widget
□ 12. Deploy Cloud Function for Calendar sync
□ 13. Initialize NotificationService in main()
□ 14. Test on real device (speech_to_text needs physical mic)
```

---

*Generated for Ali — Flutter + Firebase Stack | Alexandria University CS '25*
