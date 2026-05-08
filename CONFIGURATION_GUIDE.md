# دليل الإعدادات الشامل - QuickTask
## إعدادات Firebase و Google Calendar وشرح كامل للكود

**التاريخ:** 2026-05-08
**المشروع:** QuickTask
**البريد الإلكتروني للتواصل:** aliassiassi80@gmail.com

---

## الفهرس

1. [نظرة عامة على المشروع](#1-نظرة-عامة-على-المشروع)
2. [إعدادات Firebase](#2-إعدادات-firebase)
3. [إعدادات Google Calendar API](#3-إعدادات-google-calendar-api)
4. [الأمان وقواعد Firestore](#4-الأمان-وقواعد-firestore)
5. [هيكل البيانات في Firestore](#5-هيكل-البيانات-في-firestore)
6. [شرح الكود - CalendarService](#6-شرح-الكود---calendarservice)
7. [شرح الكود - AuthRepository](#7-شرح-الكود---authrepository)
8. [شرح الكود - FirebaseAuthDatasource](#8-شرح-الكود---firebaseauthdatasource)
9. [شرح الكود - VoiceService](#9-شرح-الكود---voiceservice)
10. [شرح الكود - TaskParserService](#10-شرح-الكود---taskparserservice)
11. [شرح الكود - NotificationService](#11-شرح-الكود---notificationservice)
12. [شرح الكود - TaskProvider](#12-شرح-الكود---taskprovider)
13. [قائمة المراجعة للأمان](#13-قائمة-المراجعة-للأمان)
14. [خطوات الإعداد من الصفر](#14-خطوات-الإعداد-من-الصفر)

---

## 1. نظرة عامة على المشروع

**QuickTask** هو تطبيق لإدارة المهام يعمل بالصوت، يتم فيه:

- **تسجيل الدخول** عبر Firebase Auth (Google أو البريد الإلكتروني)
- **إنشاء المهام** بالصوت (التعرف على الكلام)
- **تحليل النص** لاستخراج التاريخ والوقت تلقائياً
- **حفظ المهام** محلياً في Hive (بدون اتصال) وعن بعد في Firestore
- **مزامنة المهام** مع Google Calendar تلقائياً
- **إرسال إشعارات** قبل 15 دقيقة من كل مهمة
- **دعم اللغتين** العربية والإنجليزية

### منصات التشغيل
Android, iOS, Web, macOS, Linux, Windows

### المشروع في Firebase
- **Project ID:** quicktask-a7b47
- **Location:** nam5 (United States)

---

## 2. إعدادات Firebase

### 2.1 هيكل firebase.json

```json
{
  "firestore": {
    "database": "(default)",
    "location": "nam5",
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "auth": {
    "providers": {
      "googleSignIn": {
        "oAuthBrandDisplayName": "QuickTask",
        "supportEmail": "aliassiassi80@gmail.com"
      }
    }
  },
  "flutter": {
    "platforms": {
      "android": {
        "default": {
          "projectId": "quicktask-a7b47",
          "appId": "1:559550639683:android:ab166be89349d0d074eef6",
          "fileOutput": "android/app/google-services.json"
        }
      },
      "dart": {
        "lib/firebase_options.dart": {
          "projectId": "quicktask-a7b47",
          "configurations": {
            "android": "1:559550639683:android:ab166be89349d0d074eef6",
            "ios": "1:559550639683:ios:e177248e228b974974eef6",
            "macos": "1:559550639683:ios:e177248e228b974974eef6",
            "web": "1:559550639683:web:71aea5149ccabd5574eef6",
            "windows": "1:559550639683:web:9589c78a7835087574eef6"
          }
        }
      }
    }
  }
}
```

**شرح:**
- `firestore.rules` → ملف قواعد الأمان (سيأتي شرحه لاحقاً)
- `firestore.indexes.json` → فهارس الاستعلامات
- `auth.providers.googleSignIn` → إعدادات تسجيل الدخول بجوجل في Firebase Console
- `flutter.platforms.android` → معرفات التطبيق لمنصة أندرويد
- `fileOutput` → مكان وضع ملف `google-services.json` في أندرويد

### 2.2 Firebase Options (lib/firebase_options.dart)

هذا الملف يحتوي على **مفاتيح API** لكل منصة، يتم توليده تلقائياً بواسطة أمر `flutterfire configure`.

**شرح كل منصة:**

| المنصة | API Key | App ID |
|--------|---------|--------|
| Web | AIzaSyCQMbHF9K0AmIbuauUEegq6U2zDMofdFwU | 1:559550639683:web:71aea5149ccabd5574eef6 |
| Android | AIzaSyCqJJJCbo1yBQ2HB_iJyLEJf9Qx3HqN2qo | 1:559550639683:android:ab166be89349d0d074eef6 |
| iOS | AIzaSyB_bec2FvCHeIQIs5e6umoKIW9sKZWVs4M | 1:559550639683:ios:e177248e228b974974eef6 |
| macOS | AIzaSyB_bec2FvCHeIQIs5e6umoKIW9sKZWVs4M | 1:559550639683:ios:... |
| Windows | AIzaSyCQMbHF9K0AmIbuauUEegq6U2zDMofdFwU | 1:559550639683:web:... |

**كيف يعمل:**
```dart
// في main.dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform, // يختار الإعدادات المناسبة للمنصة
);
```

الدالة `DefaultFirebaseOptions.currentPlatform` تفحص المنصة الحالية وتُرجع الإعدادات المناسبة لها.

### 2.3 إعداد Firebase في التطبيق (main.dart)

```dart
// lib/main.dart

// الخطوة 1: تهيئة Hive للتخزين المحلي
await DatabaseService.init();

// الخطوة 2: تهيئة Firebase (مع حماية من التكرار)
try {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
} on FirebaseException catch (e) {
  if (e.code != 'duplicate-app') rethrow; // تجاهل إذا كان Firebase уже وُضع
}

// الخطوة 3: تهيئة الإشعارات
await NotificationService.init();
```

**ملاحظة مهمة:** الكود يتحقق من `duplicate-app` لمنع الانهيار عند إعادة تشغيل التطبيق أثناء التطوير (hot reload).

---

## 3. إعدادات Google Calendar API

### 3.1 كيف يعمل التكامل مع Google Calendar

```
┌──────────────┐     Google Sign-In      ┌─────────────────────────┐
│  المستخدم    │ ───────────────────────│  Google OAuth 2.0        │
│              │   (مع نطاق Calendar)    │  scopes: email,          │
│              │                         │  calendar (full access)  │
└──────────────┘                         └────────────┬────────────┘
                                                     │
                                                     │ accessToken
                                                     ▼
┌──────────────┐    Google Calendar API v3           ┌─────────────┐
│  التطبيق     │ ◄────────────────────────────────── │ Calendar API │
│              │     HTTP REST                       │             │
└──────────────┘    (Authorization: Bearer TOKEN)    └─────────────┘
```

### 3.2 CalendarService - شرح كامل

**الموقع:** `lib/services/calendar_service.dart`

```dart
// lib/services/calendar_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../features/auth/domain/repositories/auth_repository.dart';
import '../domain/entities/task_entity.dart';

class CalendarService {
  final AuthRepository _authRepo;
  CalendarService(this._authRepo);
```

**يقوم هذا الـ Service بـ 3 مهام رئيسية:**

#### المهمة 1: إنشاء حدث في Google Calendar

```dart
Future<String> createEvent(TaskEntity task) async {
  // 1) الحصول على HEADERS مع الـ Access Token
  final headers = await _getAuthHeaders();

  // 2) بناء JSON body للـ Event
  final body = jsonEncode({
    'summary': task.title,              // عنوان المهمة
    'description': task.description ?? '', // الوصف
    'start': {
      'dateTime': task.scheduledAt.toUtc().toIso8601String(),  // وقت البداية (بالتوقيت العالمي)
      'timeZone': 'Africa/Cairo',      // التوقيت: القاهرة (مصر)
    },
    'end': {
      // وقت النهاية = وقت البداية + ساعة واحدة
      'dateTime': task.scheduledAt.add(const Duration(hours: 1)).toUtc().toIso8601String(),
      'timeZone': 'Africa/Cairo',
    },
    'reminders': {
      'useDefault': false,             // لا تستخدم التذكير الافتراضي
      'overrides': [
        {'method': 'popup', 'minutes': 15}, // تذكير قبل 15 دقيقة
      ],
    },
  });

  // 3) إرسال طلب POST لإنشاء الحدث
  final resp = await http.post(
    Uri.parse('https://www.googleapis.com/calendar/v3/calendars/primary/events'),
    headers: headers,
    body: body,
  );

  // 4) التحقق من النجاح
  if (resp.statusCode != 200) {
    throw Exception('Failed to create calendar event: ${resp.body}');
  }

  // 5) إرجاع معرف الحدث (لتسجيله في قاعدة البيانات)
  final data = jsonDecode(resp.body);
  return data['id'] as String;
}
```

**ما الذي يحدث هنا بالتفصيل:**

1. **البوابة (Endpoint):** `POST https://www.googleapis.com/calendar/v3/calendars/primary/events`
   - `primary` تعني تقويم المستخدم الرئيسي في Google Calendar

2. **dateTime:** يجب أن يكون بـ ISO 8601 UTC format
   - مثال: `2026-05-08T10:00:00.000Z`
   - `.toUtc().toIso8601String()` في Dart يحول التاريخ لهذا التنسيق

3. **timeZone:** `Africa/Cairo` لأن التوقيت في مصر (UTC+2)

4. **reminders:** التذكير يظهر كـ popup قبل 15 دقيقة من الحدث

#### المهمة 2: حذف حدث من Google Calendar

```dart
Future<void> deleteEvent(String eventId) async {
  final headers = await _getAuthHeaders();

  final resp = await http.delete(
    Uri.parse(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events/$eventId'
    ),
    headers: headers,
  );

  // قبول عدة أكواد HTTP كحالة نجاح:
  // 204 = No Content (النجاح典型)
  // 200 = OK (أيضاً نجاح)
  // 410 = Gone (الحدث محذوف már)
  // 404 = Not Found (الحدث غير موجود)
  if (resp.statusCode != 204 &&
      resp.statusCode != 200 &&
      resp.statusCode != 410 &&
      resp.statusCode != 404) {
    throw Exception('Failed to delete calendar event: ${resp.body}');
  }
}
```

#### المهمة 3: جلب الأحداث القادمة

```dart
Future<List<Map<String, dynamic>>> getUpcomingEvents({int maxResults = 10}) async {
  try {
    final headers = await _getAuthHeaders();

    final now = DateTime.now().toUtc().toIso8601String();
    final resp = await http.get(
      Uri.parse(
        'https://www.googleapis.com/calendar/v3/calendars/primary/events'
        '?timeMin=$now&maxResults=$maxResults&singleEvents=true&orderBy=startTime',
      ),
      headers: headers,
    );

    if (resp.statusCode != 200) return [];

    final data = jsonDecode(resp.body);
    final items = data['items'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>();
  } catch (e) {
    return []; // إرجاع قائمة فارغة عند أي خطأ
  }
}
```

**المعاملات في الرابط:**
- `timeMin` — جلب الأحداث من الآن فصاعداً
- `maxResults` — الحد الأقصى لعدد الأحداث
- `singleEvents=true` — تحويل الأحداث المتكررة إلى أحداث فردية
- `orderBy=startTime` — ترتيب حسب وقت البداية

#### المهمة 4: الحصول على Authorization Headers

```dart
Future<Map<String, String>> _getAuthHeaders() async {
  // 1) الحصول على Access Credentials من AuthRepository
  final credentials = await _authRepo.getAccessCredentials();

  if (credentials == null) {
    throw Exception('No access credentials — user must sign in with Google first');
  }

  // 2) استخراج الـ Access Token
  // credentials.accessToken.data هو Google's AccessTokenData
  // الذي يحتوي على String token
  final token = credentials.accessToken.data;

  // 3) بناء الـ Headers
  return {
    'Authorization': 'Bearer $token',  // Bearer Token Auth
    'Content-Type': 'application/json',
  };
}
```

### 3.3 متغيرات البيئة في CalendarService

```
_calendarBaseUrl = 'https://www.googleapis.com/calendar/v3'
timeZone = 'Africa/Cairo'
eventDuration = 1 hour
reminderMinutes = 15
calendars endpoint = /calendars/primary/events
```

---

## 4. الأمان وقواعد Firestore

### 4.1 firestore.rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ========== مجموعة المهام ==========
    // المسار: users/{userId}/tasks/{taskId}
    match /users/{userId}/tasks/{taskId} {
      // الشرط: المستخدم يجب أن يكون مسجل الدخول
      // AND uid الخاص به يجب أن يساوي userId في المسار
      allow read, write: if request.auth != null
                           && request.auth.uid == userId;
    }

    // ========== بيانات المستخدم ==========
    // المسار: users/{userId}
    match /users/{userId} {
      allow read, write: if request.auth != null
                           && request.auth.uid == userId;
    }
  }
}
```

**شرح القواعد:**

| القاعدة | المعنى |
|---------|--------|
| `rules_version = '2'` | إصدار القواعد (2 هو الأحدث والأفضل) |
| `service cloud.firestore` | هذه القواعد تنطبق على Firestore فقط |
| `match /databases/{database}/documents` | تتطابق مع جميع المسارات في قواعد البيانات |
| `request.auth != null` | المستخدم يجب أن يكون مسجلاً دخوله |
| `request.auth.uid == userId` | uid الخاص بالمستخدم يجب أن يطابق userId في المسار |

**لماذا هذا مهم؟**
- كل مستخدم يمكنه فقط رؤية وتعديل مهامه الخاصة
- لا يمكن للمستخدم (أ) الوصول لمهام المستخدم (ب)
- حتى لو حاول أحدهم إرسال طلب مباشر إلى Firestore، القواعد سترفضه

### 4.2 firestore.indexes.json

```json
{
  "indexes": [],
  "fieldOverrides": []
}
```

**الحالة الحالية:** لا توجد فهارس مخصصة.

**ما هو الفهرس؟** عندما تريد استعلام مثل:
```dart
tasksRef.where('isCompleted', isEqualTo: false)
        .orderBy('scheduledAt')
```
Firestore يحتاج فهرس مركب (composite index) على `[isCompleted ASC, scheduledAt ASC]`.

إذا لم يكن الفهرس موجوداً، سيعطي Firebase خطأ يتطلب إنشاء الفهرس.

---

## 5. هيكل البيانات في Firestore

### 5.1 هيكل المستندات

```
Firestore
└── users/
    └── {uid}/
        ├── .calendarAccessToken  ← رمز OAuth للوصول للـ Calendar
        └── tasks/
            └── {taskId}/
                ├── id
                ├── userId
                ├── title
                ├── description
                ├── scheduledAt      ← Firestore Timestamp
                ├── isSyncedToCalendar ← boolean
                ├── calendarEventId  ← معرف الحدث في Google Calendar
                ├── createdAt        ← Firestore Timestamp
                └── isCompleted      ← boolean
```

### 5.2 TaskModel (lib/data/models/task_model.dart)

هذا الـ Model يربط بين كائن Dart و Firestore.

```dart
class TaskModel extends TaskEntity {
  // المتغيرات الموروثة من TaskEntity:
  // id, userId, title, description, scheduledAt,
  // isSyncedToCalendar, calendarEventId, createdAt, isCompleted

  TaskModel({...});

  // تحويل من Firestore Document إلى كائن Dart
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,                        // doc.id هو الـ document ID في Firestore
      userId: data['userId'],
      title: data['title'],
      description: data['description'],
      // تحويل Firestore Timestamp إلى DateTime
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      isSyncedToCalendar: data['isSyncedToCalendar'] ?? false,
      calendarEventId: data['calendarEventId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  // تحويل من كائن Dart إلى Firestore Document
  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'title': title,
    'description': description,
    'scheduledAt': Timestamp.fromDate(scheduledAt), // تحويل DateTime إلى Timestamp
    'isSyncedToCalendar': isSyncedToCalendar,
    'calendarEventId': calendarEventId,
    'createdAt': Timestamp.fromDate(createdAt),
    'isCompleted': isCompleted,
  };
}
```

---

## 6. شرح الكود - CalendarService

### 6.1 لماذا نستخدم HTTP مباشرة بدلاً من googleapis package؟

في التطبيق يُستخدم `http` package مع REST API مباشرة:

```dart
import 'package:http/http.dart' as http;
// ...
await http.post(
  Uri.parse('https://www.googleapis.com/calendar/v3/...'),
  headers: headers,
  body: body,
);
```

**لماذا؟**
- أكثر تحكماً في الـ JSON structure
- لا يحتاج generated client library
- أسهل في معالجة الأخطاء
- يعمل بشكل جيد مع tokens من google_sign_in

### 6.2 لماذا Access Token من AuthRepository؟

```dart
final credentials = await _authRepo.getAccessCredentials();
final token = credentials.accessToken.data;
```

**السبب:** عند تسجيل الدخول بجوجل، يُطلب نطاق `calendar`:
```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'https://www.googleapis.com/auth/calendar', // هذا النطاق!
  ],
);
```

هذا يعني المستخدم أعطى إذن للتطبيق لقراءة وكتابة تقويمه. الـ Access Token يسمح لنا بفعل ذلك.

### 6.3 لماذا Africa/Cairo؟

```dart
'timeZone': 'Africa/Cairo',
```

- مصر لا تتبع التوقيت الصيفي (DST) بشكل منتظم
- UTC+2 ثابت طوال العام
- مناسب للمستخدمين العرب

---

## 7. شرح الكود - AuthRepository

### 7.1 الواجهة (Abstract Interface)

**الموقع:** `lib/features/auth/domain/repositories/auth_repository.dart`

```dart
abstract class AuthRepository {
  Future<User?> signInWithEmail(String email, String password);
  Future<User?> signUpWithEmail(String email, String password, String name);
  Future<User?> signInWithGoogle();
  Future<void> signOut();
  Stream<User?> authStateChanges();
  Future<void> sendPasswordResetEmail(String email);
  Future<AccessCredentials?> getAccessCredentials();
}
```

**ما هو AccessCredentials؟**

من `package:googleapis_auth`، يحتوي على:
```dart
AccessCredentials(
  accessToken,   // Token للـ API calls
  refreshToken,   // Token لتجديد Access Token (عندما ينتهي)
  scopes,         // النطاقات المسموحة
  expiryDate,     // متى ينتهي الـ Access Token
)
```

### 7.2 التعامل مع أخطاء Firebase

**الموقع:** `lib/features/auth/data/datasources/firebase_auth_datasource.dart`

```dart
String mapFirebaseError(String code) {
  switch (code) {
    case 'user-not-found':
      return 'لا يوجد مستخدم بهذا البريد الإلكتروني';
    case 'wrong-password':
      return 'كلمة المرور غير صحيحة';
    case 'email-already-in-use':
      return 'هذا البريد الإلكتروني مستخدم بالفعل';
    case 'weak-password':
      return 'كلمة المرور ضعيفة جداً';
    case 'invalid-email':
      return 'البريد الإلكتروني غير صالح';
    case 'user-disabled':
      return 'هذا الحساب معطل';
    case 'operation-not-allowed':
      return 'تسجيل الدخول غير مفعّل';
    case 'invalid-credential':
      return 'بيانات الاعتماد غير صالحة';
    case 'network-request-failed':
      return 'فشل الاتصال بالإنترنت';
    default:
      return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
  }
}
```

### 7.3 تسجيل الدخول بجوجل

```dart
Future<User?> signInWithGoogle() async {
  // 1) فتح نافذة تسجيل الدخول بجوجل
  final GoogleSignInAccount? account = await _googleSignIn.signIn();

  if (account == null) return null; // المستخدم ألغى العملية

  // 2) الحصول على Authentication من جوجل
  final GoogleSignInAuthentication googleAuth =
      await account.authentication;

  // 3) إنشاء Credential لـ Firebase
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,  // لـ Firebase Auth
    idToken: googleAuth.idToken,          // للتعرف على المستخدم
  );

  // 4) تسجيل الدخول في Firebase
  return await _auth.signInWithCredential(credential);
}
```

### 7.4 الحصول على Calendar Access Token

```dart
Future<AccessCredentials?> getAccessCredentials() async {
  // google_sign_in يعطي OAuth2AccessToken
  final account = await _googleSignIn.signInSilently();

  if (account == null) return null;

  final auth = await account.authentication;
  final token = auth.accessToken;

  if (token == null) return null;

  // تحويل Google's OAuth2AccessToken إلى googleapis_auth's AccessCredentials
  return AccessCredentials(
    AccessToken(
      'Bearer',
      token,
      DateTime.now().add(const Duration(hours: 1)).toUtc(), // expiry
    ),
    null, // refreshToken (لا نحتاجه لأن google_sign_in يتعامل مع التجديد)
    ['https://www.googleapis.com/auth/calendar'],
  );
}
```

---

## 8. شرح الكود - FirebaseAuthDatasource

### 8.1 الهيكل العام

```dart
class FirebaseAuthDatasource {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign-In مع نطاق Calendar
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
    ],
  );
```

### 8.2 إنشاء مستند مستخدم في Firestore

```dart
Future<void> _createUserDocument(User user, {String? displayName}) async {
  await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
    {
      'email': user.email,
      'displayName': displayName ?? user.displayName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
}
```

- `SetOptions(merge: true)` — إذا كان المستند موجوداً، دمج البيانات الجديدة مع القديمة
- `FieldValue.serverTimestamp()` — تستخدم وقت خادم Firestore (دائماً متسق)

---

## 9. شرح الكود - VoiceService

### 9.1 ما هو VoiceService؟

**الموقع:** `lib/services/voice_service.dart`

هذا الـ Service يغلف مكتبتين:
1. `speech_to_text` — للتعرف على الكلام (Speech-to-Text)
2. `flutter_tts` — لتحويل النص إلى كلام (Text-to-Speech)

### 9.2 الكود الكامل مع الشرح

```dart
class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  enum TtsLocale { english, arabic }

  Future<bool> initialize() async {
    // 1) طلب إذن الميكروفون
    final micStatus = await Permission.microphone.request();

    if (!micStatus.isGranted) {
      debugPrint('Microphone permission denied');
      return false;
    }

    // 2) تهيئة Speech-to-Text engine
    _isInitialized = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );

    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required VoidCallback? onListeningComplete,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          onListeningComplete?.call();
        }
      },
      listenFor: const Duration(seconds: 30),   // مدة الاستماع
      pauseFor: const Duration(seconds: 3),      // التوقف بعد 3 ثوانٍ من الصمت
      localeId: _currentLocaleId(),              // اللغة الحالية
      cancelOnError: true,                        // إلغاء عند حدوث خطأ
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  Future<void> setLocale(TtsLocale locale) async {
    _locale = locale;
    await _speech.stop();
  }

  String _currentLocaleId() {
    return _locale == TtsLocale.arabic ? 'ar-SA' : 'en-US';
  }
}
```

### 9.3 لماذا ar-SA وليس ar-EG؟

| Locale | الاستخدام |
|--------|-----------|
| `ar-SA` | العربية الفصحى (سعودية) — الأكثر دعماً في speech_to_text |
| `ar-EG` | المصرية — قد لا تكون مدعومة على جميع الأجهزة |
| `ar'AR` | العربية (عام) — fallback |

---

## 10. شرح الكود - TaskParserService

### 10.1 ما هو؟

هذا الـ Service يحلل النص المنطوق (من VoiceService) ويستخرج:
- **العنوان** — عنوان المهمة
- **التاريخ والوقت** — متى يجب تنفيذها
- **النص الكامل** — للحفظ كمرجع

### 10.2 مثال على العمل

```
النص المنطوق: "meeting with team at 3 PM tomorrow"

النتيجة:
  title: "meeting with team"
  scheduledAt: 2026-05-09 15:00:00
  fullText: "meeting with team at 3 PM tomorrow"
```

### 10.3 أنماط التوقيت المدعومة (بالإنجليزية)

```dart
static const List<RegExp> _timePatterns = [
  // "at 3 PM", "at 3:30 PM"
  RegExp(r'at\s+(\d{1,2})(?::(\d{2}))?\s*(AM|PM)', caseSensitive: false),

  // "in 30 minutes", "in 2 hours"
  RegExp(r'in\s+(\d+)\s*(minutes?|hours?|mins?|hrs?)', caseSensitive: false),

  // "every day at 10"
  RegExp(r'every\s+day\s+at\s+(\d{1,2})', caseSensitive: false),

  // "tomorrow at 10 AM"
  RegExp(r'tomorrow\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?', caseSensitive: false),
];

static const List<RegExp> _datePatterns = [
  // "tomorrow", "today", "next week"
  RegExp(r'\b(tomorrow|today|next\s+week)\b', caseSensitive: false),

  // "on Monday", "on Friday"
  RegExp(r'\bon\s+([A-Za-z]+)\b', caseSensitive: false),

  // "on the 15th", "on 25"
  RegExp(r'\bon\s+(?:the\s+)?(\d{1,2})(?:st|nd|rd|th)?', caseSensitive: false),
];
```

### 10.4 تحويل الأرقام العربية

```dart
// هذا النص: "الساعة العاشرة مساءً"
// يجب أن يُقرأ كـ: "الساعة 10 مساءً"

static final Map<String, String> _arabicNumbers = {
  'صفر': '0', 'واحد': '1', 'اثنين': '2', 'ثلاثة': '3',
  'أربعة': '4', 'خمسة': '5', 'ستة': '6', 'سبعة': '7',
  'ثمانية': '8', 'تسعة': '9', 'عشرة': '10',
  'الحادية عشر': '11', 'الثانية عشر': '12',
};

// والأنجليزية أيضاً:
// "ten" → "10", "twelve" → "12"
static final Map<String, String> _englishNumbers = {
  'zero': '0', 'one': '1', 'two': '2', 'three': '3',
  'four': '4', 'five': '5', 'six': '6', 'seven': '7',
  'eight': '8', 'nine': '9', 'ten': '10',
  'eleven': '11', 'twelve': '12',
};
```

### 10.5 مثال عملي كامل

```dart
// المدخلات
final input = "meeting with ali at 4 PM tomorrow";

// المعالجة
final parsed = TaskParserService.parse(input);

// النتيجة
// parsed.title = "meeting with ali"
// parsed.scheduledAt = DateTime(2026, 5, 9, 16, 0)
// parsed.fullText = "meeting with ali at 4 PM tomorrow"
```

---

## 11. شرح الكود - NotificationService

### 11.1 ما هو؟

جدولة إشعارات محلية قبل 15 دقيقة من كل مهمة.

### 11.2 الخطوات

```dart
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1) تهيئة timezone
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

    // 2) إعداد الإعدادات لكل منصة
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 3) تهيئة الـ plugin
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // 4) طلب إذن الإشعارات (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleTaskNotification(TaskEntity task) async {
    // حساب وقت الإشعار = وقت المهمة - 15 دقيقة
    final notificationTime = tz.TZDateTime.from(
      task.scheduledAt.subtract(const Duration(minutes: 15)),
      tz.local,
    );

    // لا تخطط إذا كان الوقت قد فات
    if (notificationTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      task.id.hashCode,              // معرف الإشعار = hash كود المهمة
      '⏰ Upcoming Task',
      task.title,
      notificationTime,
      const NotificationDetails(...),
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

### 11.3 لماذا exactAllowWhileIdle؟

```dart
androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle
```

هذا يسمح للإشعارات بالعمل حتى عندما يكون الجهاز في وضع توفير البطارية (Doze mode). الإشعارات ستظهر في الوقت المحدد بالضبط.

---

## 12. شرح الكود - TaskProvider

### 12.1 ما هو؟

**الموقع:** `lib/presentation/providers/task_provider.dart`

الـ Provider الرئيسي لإدارة المهام. يجمع بين:
- **التخزين المحلي** (Hive)
- **التخزين السحابي** (Firestore)
- **Google Calendar** (إنشاء/حذف الأحداث)
- **الإشعارات** (جدولة/إلغاء)

### 12.2 استراتيجية الكتابة المتدرجة (Tiered Write)

```dart
Future<void> addTask(TaskEntity task) async {
  // الخطوة 1: حفظ محلياً أولاً (دائماً ينجح)
  await _localRepo.addTask(task);

  // الخطوة 2: إنشاء حدث في Calendar (إذا فشل، لا تقلق)
  String? calendarEventId;
  try {
    calendarEventId = await _calendarService.createEvent(task);
    task = task.copyWith(
      isSyncedToCalendar: true,
      calendarEventId: calendarEventId,
    );
  } catch (e) {
    debugPrint('Calendar sync failed: $e');
  }

  // الخطوة 3: حفظ في Firestore (إذا فشل، البيانات محفوظة محلياً)
  try {
    await _taskRepo.addTask(task);
  } catch (e) {
    debugPrint('Firestore write failed: $e');
  }

  // الخطوة 4: جدولة الإشعار
  await NotificationService.scheduleTaskNotification(task);

  // الخطوة 5: تحديث القائمة المحلية
  _tasks.add(task);
  notifyListeners();
}
```

### 12.3 استراتيجية المزامنة (Cloud-to-Local Sync)

```dart
void _initSync() {
  _syncSubscription?.cancel();
  _syncSubscription = _taskRepo.watchTasks().listen(
    (cloudTasks) async {
      // لكل مهمة من Cloud
      for (final cloudTask in cloudTasks) {
        // إذا لم تكن محفوظة محلياً، أضفها
        final existsLocal = _tasks.any((t) => t.id == cloudTask.id);
        if (!existsLocal) {
          await _localRepo.addTask(cloudTask);
          _tasks.add(cloudTask);
        }
      }
      notifyListeners();
    },
    onError: (e) => debugPrint('Sync error: $e'),
  );
}
```

هذا يضمن أن المستخدم يرى مهامه حتى عندما يكون offline ثم يعود online.

### 12.4 حذف المهمة (مع تنظيف كل شيء)

```dart
Future<void> deleteTask(String taskId) async {
  final task = _tasks.firstWhere((t) => t.id == taskId);

  // 1) حذف من Firestore
  try {
    await _taskRepo.deleteTask(taskId);
  } catch (e) {
    debugPrint('Firestore delete failed: $e');
  }

  // 2) حذف من Calendar
  if (task.calendarEventId != null) {
    try {
      await _calendarService.deleteEvent(task.calendarEventId!);
    } catch (e) {
      debugPrint('Calendar delete failed: $e');
    }
  }

  // 3) إلغاء الإشعار
  await NotificationService.cancelNotification(taskId);

  // 4) حذف محلياً
  await _localRepo.deleteTask(taskId);
  _tasks.removeWhere((t) => t.id == taskId);

  notifyListeners();
}
```

---

## 13. قائمة المراجعة للأمان

| # | العنصر | كيف يتم حله |
|---|--------|-------------|
| 1 | الوصول للبيانات | Firestore Rules: `request.auth.uid == userId` |
| 2 | OAuth Scopes | فقط `calendar` — ليس read-only فقط |
| 3 | تخزين الـ Token | `google_sign_in` يتعامل مع التجديد تلقائياً |
| 4 | عرض الـ API Key | لا توجد مفاتيح في الكود — `firebase_options.dart` مُولَّد |
| 5 | أخطاء Firebase | رسائل خطأ مخصصة بالعربية (لا تكشف تفاصيل تقنية) |
| 6 | إعدادات Android | `INTERNET`, `RECORD_AUDIO`, `SCHEDULE_EXACT_ALARM` |
| 7 | HTTPS | Firestore و Google Calendar APIs يستخدمان HTTPS دائماً |
| 8 | التحقق من المستخدم | `AuthState` sealed class يضمن كل الحالات |

---

## 14. خطوات الإعداد من الصفر

### الخطوة 1: إنشاء مشروع Google Cloud

```
1. اذهب إلى console.cloud.google.com
2. أنشئ مشروع جديد
3. فعّل Google Calendar API
4. اذهب إلى APIs & Services → OAuth Consent Screen
5. اختر External
6. أضف النطاق: https://www.googleapis.com/auth/calendar
7. أنشئ OAuth 2.0 Client IDs (Android, iOS, Web)
8. سجّل SHA-1 fingerprint للـ Android:
   keytool -list -v -keystore ~/.android/debug.keystore
```

### الخطوة 2: إنشاء مشروع Firebase

```
1. اذهب إلى console.firebase.google.com
2. أضف مشروع وربطه بنفس Google Cloud project
3. فعّل Authentication → Google Sign-in
4. فعّل Firestore Database (production mode)
5. سجل التطبيقات (Android, iOS, Web)
```

### الخطوة 3: إعداد Flutter

```bash
# تثبيت FlutterFire CLI
dart pub global activate flutterfire_cli

# تشغيل المعالج
flutterfire configure --project=quicktask-a7b47

# ضع google-services.json في android/app/
# ضع GoogleService-Info.plist في ios/Runner/
```

### الخطوة 4: Android Permissions

في `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### الخطوة 5: iOS Permissions

في `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>نحتاج الوصول للميكروفون لتسجيل المهام الصوتية</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>نستخدم التعرف على الكلام لتحويل صوتك إلى نصوص</string>
```

### الخطوة 6: التحقق

```
□ التطبيق يفتح ويسجل الدخول بجوجل
□ يمكنك إنشاء مهمة نصية
□ يمكنك إنشاء مهمة صوتياً
□ المهمة تظهر في Google Calendar
□ الإشعار يصل قبل 15 دقيقة
□ البيانات تظهر بدون إنترنت (offline)
□ البيانات تتزامن عند عودة الاتصال
□ تسجيل الخروج يمسح البيانات المحلية
```

---

## ملخص المفاهيم الأساسية

```
┌─────────────────────────────────────────────────────────────┐
│                        المستخدم                            │
│                              │                              │
│            ┌─────────────────┴─────────────────┐           │
│       [صوت] │                                │ [نص]         │
│            ▼                                     ▼           │
│   ┌──────────────────┐              ┌──────────────────┐     │
│   │   VoiceService   │              │  AddTaskScreen   │     │
│   │ speech_to_text   │              │  (نص عادي)       │     │
│   └────────┬─────────┘              └────────┬─────────┘     │
│            │                                 │               │
│            ▼                                 │               │
│   ┌──────────────────┐                        │               │
│   │ TaskParserService│◄───────────────────────┘               │
│   │ يستخرج الوقت/التاريخ  │                                │
│   └────────┬─────────┘                                     │
│            ▼                                                │
│   ┌──────────────────────────────────────────────┐         │
│   │              TasksNotifier                    │         │
│   │  (يجمع كل شيء معاً)                           │         │
│   └───────┬────────────┬────────────┬────────────┘         │
│           │            │            │                      │
│           ▼            ▼            ▼                      │
│   ┌──────────┐ ┌───────────┐ ┌──────────┐                │
│   │   Hive   │ │ Firestore  │ │ Calendar │                │
│   │ (محلي)    │ │ (سحابي)   │ │   API    │                │
│   └──────────┘ └───────────┘ └──────────┘                │
│                         │                                  │
│                         ▼                                  │
│                  ┌────────────┐                            │
│                  │ Notifica-  │                            │
│                  │   tion     │                            │
│                  └────────────┘                            │
└─────────────────────────────────────────────────────────────┘
```

---

*تم إنشاء هذا الملف بواسطة Claude Code*
*للمستخدم: Ali — Alexandria University CS '25*
*البريد: aliassiassi80@gmail.com*