# Technical Specification: Voice Calendar Sync App

## 1. Project Overview
A Flutter-based mobile application that uses voice input to create and sync tasks directly to Google Calendar.

## 2. Technical Setup (Google Cloud & API)

### Step 1: Google Cloud Console Setup
1.  **Create a Project:** Go to the [Google Cloud Console](https://console.cloud.google.com/) and create a new project.
2.  **Enable APIs:** Search for and enable the **Google Calendar API**.
3.  **Configure OAuth Consent Screen:**
    *   Choose 'External' User Type.
    *   Provide app information (name, support email).
    *   Add the `https://www.googleapis.com/auth/calendar` and `https://www.googleapis.com/auth/calendar.events` scopes.
4.  **Create Credentials:**
    *   Create **OAuth 2.0 Client IDs** for Android and iOS.
    *   You will need the SHA-1 certificate fingerprint for Android and the Bundle ID for iOS.

### Step 2: Flutter Implementation
1.  **Authentication:** Use the `google_sign_in` package to handle OAuth2.
2.  **API Client:** Use the `googleapis` package to interact with the Calendar API.
3.  **Speech-to-Text:** Use the `speech_to_text` package for processing voice input.

## 3. Secure API Access
*   Always use the official Google Sign-In flow; never store user passwords.
*   Request only the "Minimum Scopes" necessary (e.g., only access to the calendar, not the whole Google account).
*   Handle token expiration and refreshing using the `googleapis` client.

## 4. Features & Flow
*   **OAuth Login:** Secure sign-in button.
*   **Voice Trigger:** A prominent microphone button that activates the `speech_to_text` listener.
*   **Natural Language Processing (NLP):** Use simple logic or an external API to parse dates and times from the voice string (e.g., "Lunch with Sarah tomorrow at 1 PM").
*   **Calendar Sync:** POST request to the Calendar API `events` endpoint.
*   **Notifications:** Use `flutter_local_notifications` to schedule alerts based on the calendar event time.