# ⚡ QuickTask — Smart Task Manager

A premium Flutter productivity app with voice-driven task entry, Google Calendar sync, Firebase authentication, and offline-first Hive storage.

---

## ✨ Features

- 🎙️ **Voice Task Entry** — speak in English or Arabic to add tasks instantly
- 🔒 **Firebase Auth** — Google Sign-In & email/password authentication
- 📅 **Google Calendar Sync** — push tasks directly to your calendar
- 📦 **Offline-First** — Hive local storage syncs with Firestore when online
- 🔔 **Smart Notifications** — local push reminders for due tasks
- 📊 **Dashboard Analytics** — live progress ring, overdue/done counters
- 🌙 **Premium Dark UI** — glassmorphism hero card, smooth micro-animations

---

## 🎨 Current App Theme

### Typography
| Property       | Value                             |
|---------------|-----------------------------------|
| Font Family   | **Inter** (via `google_fonts`)    |
| Body color    | `#111827` (near-black)            |
| Secondary     | `#6B7280` (cool gray)             |
| Hint / Muted  | `#9CA3AF`                         |

### Color Palette

| Token            | Hex         | Preview     | Usage                              |
|-----------------|-------------|-------------|------------------------------------|
| `primary`        | `#1E1B4B`   | 🟣 Deep Indigo | AppBar, text headings             |
| `primaryLight`   | `#4F46E5`   | 🔵 Indigo    | Hero card gradient start, buttons |
| `accent`         | `#8B5CF6`   | 💜 Violet    | Secondary actions, gradient end   |
| `bgLight`        | `#F8F9FA`   | ⬜ Off-white  | Scaffold background               |
| `bgDark`         | `#0D0D14`   | ⬛ Near black | Login screen background           |
| `surface`        | `#FFFFFF`   | ⬜ White      | Cards, AppBar surface             |
| `cardBg`         | `#FFFFFF`   | ⬜ White      | Task cards                        |
| `cardBorder`     | `#1E1E30`   | 🟫 Dark navy  | Dividers on dark surfaces         |
| `textPrimary`    | `#111827`   | ⬛ Near-black | Primary body text                 |
| `textSecondary`  | `#6B7280`   | 🩶 Cool gray  | Subtitles, labels                 |
| `textHint`       | `#9CA3AF`   | 🩶 Light gray | Placeholder / hints               |
| `error`          | `#EF4444`   | 🔴 Red        | Error messages, overdue tasks     |
| `warning`        | `#F59E0B`   | 🟡 Amber      | Due-today indicator               |
| `success`        | `#10B981`   | 🟢 Emerald    | Completed tasks badge             |
| `gradientStart`  | `#312E81`   | 🔵 Deep indigo| Primary gradient                  |
| `gradientEnd`    | `#1E1B4B`   | 🟣 Dark indigo| Primary gradient                  |

### Key Gradients

| Name             | Colors                            | Direction        | Used In           |
|-----------------|-----------------------------------|------------------|-------------------|
| `primaryGradient`| `#312E81` → `#1E1B4B`            | TopLeft→BottomRight | Buttons, headers |
| Hero Card        | `#4F46E5` → `#3730A3`            | TopLeft→BottomRight | Home hero card   |
| Login background | `#0D0D14` (solid dark)           | —                | Login screen bg   |
| Brand blobs      | primary + accent blurs            | ambient          | Login screen blobs|

### Component Styles

| Component       | Details                                               |
|----------------|-------------------------------------------------------|
| Hero card       | Rounded 24px, Indigo gradient, box-shadow @ 35% opacity |
| Quick stat chips| Colored bg tints (red/amber/green), rounded 14px      |
| Dashboard cards | White bg, colored icon bg circles, shadow             |
| Task cards      | White surface, rounded 18px, left accent border       |
| Bottom input bar| Glassmorphism, blur 20, white 60% opacity             |
| FAB / Add button| Indigo (`#4F46E5`) with white icon                    |
| Login screen    | Dark background `#0D0D14`, ambient gradient blobs     |

---

## 🗂 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_colors.dart        ← 🎨 ALL colors live here
│   ├── database/
│   └── router/
├── features/
│   └── auth/
│       └── presentation/
│           ├── screens/
│           │   ├── login_screen.dart
│           │   └── register_screen.dart
│           └── providers/
├── presentation/
│   ├── screens/
│   │   ├── home_screen.dart
│   │   └── add_task_screen.dart
│   ├── widgets/
│   │   ├── task_card.dart
│   │   └── voice_button.dart
│   └── providers/
├── services/
│   ├── notification_service.dart
│   ├── calendar_service.dart
│   └── task_parser_service.dart
└── main.dart                      ← ThemeData defined here
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.x
- Firebase project (Auth + Firestore enabled)
- Google Cloud project (Calendar API enabled)

### Setup

```bash
git clone https://github.com/your-repo/quicktask.git
cd quicktask
flutter pub get
```

Configure Firebase:
```bash
flutterfire configure
```

Run the app:
```bash
flutter run
```

---

## 🔄 Re-Theme Prompt

> Use the prompt below when you want to change the entire app color theme with AI assistance.

---

### 🤖 AI Re-Theming Prompt

Copy and paste this prompt to your AI assistant to change the app's color theme:

---

```
I have a Flutter app called QuickTask. I want to completely re-theme it
to a new color palette. Here is the full context:

---

## Current Theme File
File: lib/core/constants/app_colors.dart

```dart
class AppColors {
  static const primary        = Color(0xFF1E1B4B); // Deep Indigo (main brand)
  static const primaryLight   = Color(0xFF4F46E5); // Indigo accent (hero card, buttons)
  static const accent         = Color(0xFF8B5CF6); // Violet accent (gradients, icons)

  static const bgLight        = Color(0xFFF8F9FA); // Scaffold background (light)
  static const surface        = Color(0xFFFFFFFF); // Cards / AppBar
  static const cardBg         = Color(0xFFFFFFFF); // Task card bg
  static const bgDark         = Color(0xFF0D0D14); // Login screen background

  static const textPrimary    = Color(0xFF111827); // Main body text
  static const textSecondary  = Color(0xFF6B7280); // Subtitles/labels
  static const textHint       = Color(0xFF9CA3AF); // Placeholder text
  static const cardBorder     = Color(0xFF1E1E30); // Border on dark surfaces

  static const error          = Color(0xFFEF4444); // Red – errors, overdue
  static const warning        = Color(0xFFF59E0B); // Amber – due-today
  static const success        = Color(0xFF10B981); // Emerald – completed

  static const gradientStart  = Color(0xFF312E81); // Primary gradient start
  static const gradientEnd    = Color(0xFF1E1B4B); // Primary gradient end

  static const primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
```

## ThemeData (in lib/main.dart)
```dart
theme: ThemeData.light().copyWith(
  scaffoldBackgroundColor: AppColors.bgLight,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.surface,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surface,
    elevation: 0,
  ),
  textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).copyWith(
    bodyMedium: const TextStyle(color: AppColors.textPrimary),
  ),
),
```

## Key hardcoded colors to also update:
- Home screen hero card gradient: `Color(0xFF4F46E5)` → `Color(0xFF3730A3)`
- Quick stat "Due Today" card color: `Color(0xFFF59E0B)`
- Quick stat "Due Today" bg: `Color(0xFFFFFBEB)`
- Brand logo dot gradient: `[Color(0xFF8B5CF6), Color(0xFF6366F1)]`
- Login screen ambient blobs use: `AppColors.primaryLight`, `AppColors.accent`, `AppColors.primary`

---

## New Theme I Want
[DESCRIBE YOUR NEW THEME HERE — e.g.:]
"I want a warm sunset theme: coral/orange primary, soft peach backgrounds,
dark charcoal text, with amber accents. Keep the dark login screen but
change the blobs to warm tones."

OR

"I want a minimal green/teal productivity theme: emerald primary,
mint-tinted light background, white cards, teal accents."

---

## Instructions for the AI:
1. Replace ALL color values in `app_colors.dart` with the new palette.
2. Update the `ThemeData` in `main.dart` if needed.
3. Update the hardcoded color values in `home_screen.dart`:
   - Hero card gradient (`Color(0xFF4F46E5)`, `Color(0xFF3730A3)`)
   - Brand dot gradient
   - Quick stat colors
4. Update the login screen blob colors if they differ from `AppColors.*`.
5. Keep the font (Inter / Google Fonts) unchanged unless I specify otherwise.
6. Keep `error`, `warning`, `success` semantically correct (red/amber/green range)
   unless I explicitly ask to change them.
7. Show me the complete updated `app_colors.dart` file and the diff for
   any other files that need changes.
```

---

## 📦 Dependencies

| Package                    | Purpose                        |
|---------------------------|-------------------------------|
| `firebase_core`            | Firebase initialization        |
| `firebase_auth`            | Authentication                 |
| `cloud_firestore`          | Remote task storage            |
| `hive` / `hive_flutter`   | Offline-first local DB         |
| `provider`                 | State management               |
| `go_router`                | Navigation                     |
| `google_fonts`             | Inter typography               |
| `speech_to_text`           | Voice input                    |
| `flutter_local_notifications`| Push reminders               |
| `googleapis` / `http`      | Google Calendar API            |
| `intl`                     | Date formatting                |

---

## 📄 License

MIT © 2025 QuickTask
