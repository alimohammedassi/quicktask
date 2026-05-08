// lib/services/calendar_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../features/auth/domain/repositories/auth_repository.dart';
import '../domain/entities/task_entity.dart';

class CalendarService {
  final AuthRepository _authRepo;
  CalendarService(this._authRepo);

  Future<Map<String, String>> _getAuthHeaders() async {
    final credentials = await _authRepo.getAccessCredentials();
    if (credentials == null) {
      throw Exception('No access credentials — user must sign in with Google first');
    }
    final token = credentials.accessToken.data;
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static const String _calendarBaseUrl =
      'https://www.googleapis.com/calendar/v3';

  Future<String> createEvent(TaskEntity task) async {
    final headers = await _getAuthHeaders();

    final body = jsonEncode({
      'summary': task.title,
      'description': task.description ?? '',
      'start': {
        'dateTime': task.scheduledAt.toUtc().toIso8601String(),
        'timeZone': 'Africa/Cairo',
      },
      'end': {
        'dateTime': task.scheduledAt.add(const Duration(hours: 1)).toUtc().toIso8601String(),
        'timeZone': 'Africa/Cairo',
      },
      'reminders': {
        'useDefault': false,
        'overrides': [
          {'method': 'popup', 'minutes': 15},
        ],
      },
    });

    final resp = await http.post(
      Uri.parse('$_calendarBaseUrl/calendars/primary/events'),
      headers: headers,
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to create calendar event: ${resp.body}');
    }

    final data = jsonDecode(resp.body);
    return data['id'] as String;
  }

  Future<void> deleteEvent(String eventId) async {
    final headers = await _getAuthHeaders();

    final resp = await http.delete(
      Uri.parse('$_calendarBaseUrl/calendars/primary/events/$eventId'),
      headers: headers,
    );

    if (resp.statusCode != 204 && 
        resp.statusCode != 200 && 
        resp.statusCode != 410 && 
        resp.statusCode != 404) {
      throw Exception('Failed to delete calendar event: ${resp.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingEvents({int maxResults = 10}) async {
    try {
      final headers = await _getAuthHeaders();

      final now = DateTime.now().toUtc().toIso8601String();
      final resp = await http.get(
        Uri.parse(
          '$_calendarBaseUrl/calendars/primary/events'
          '?timeMin=$now&maxResults=$maxResults&singleEvents=true&orderBy=startTime',
        ),
        headers: headers,
      );

      if (resp.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(resp.body);
      final items = data['items'] as List<dynamic>? ?? [];
      return items.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
}