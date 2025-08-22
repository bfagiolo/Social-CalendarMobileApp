import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/invite_matcher.dart' as matcher;

class TaskSubmitService {
  // TODO: put your PC's IPv4 here (e.g., 192.168.1.25)
  static const String apiBase = 'http://192.168.1.34:8080';

  static Future<Map<String, dynamic>> submitTask(
      String inputText,
      List<Map<String, dynamic>> userFriends,
      ) async {
    // Get short timezone (PST, EDT, etc.)
    final String shortTimeZone = DateTime.now().timeZoneName;

    // Map common abbreviations → IANA TZ (optional, harmless if server ignores)
    String fullTimeZone;
    switch (shortTimeZone) {
      case 'CST':
      case 'CDT':
        fullTimeZone = 'America/Chicago';
        break;
      case 'EST':
      case 'EDT':
        fullTimeZone = 'America/New_York';
        break;
      case 'MST':
      case 'MDT':
        fullTimeZone = 'America/Denver';
        break;
      case 'PST':
      case 'PDT':
        fullTimeZone = 'America/Los_Angeles';
        break;
      default:
        fullTimeZone = shortTimeZone;
    }

    debugPrint('TaskSubmitService: Sending → "$inputText" ($fullTimeZone)');

    try {
      // Body format that your server expects
      final body = {
        "instances": [
          {
            "input": inputText,
            // timezone included if your backend uses it; safe to keep
            "timezone": fullTimeZone,
          }
        ]
      };

      final res = await http.post(
        Uri.parse('$apiBase/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('TaskSubmitService: status=${res.statusCode}');
      debugPrint('TaskSubmitService: body=${res.body}');

      if (res.statusCode != 200) {
        throw Exception('Bad status: ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body);

      // Support both shapes:
      // 1) {"predictions":[{"success":true,"task":{...}}]}
      // 2) {"task":{...}}
      Map<String, dynamic>? task;
      if (decoded is Map && decoded['predictions'] is List && decoded['predictions'].isNotEmpty) {
        final first = decoded['predictions'][0];
        if (first is Map && first['task'] is Map) {
          task = Map<String, dynamic>.from(first['task']);
        }
      }
      task ??= (decoded['task'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(decoded['task'])
          : null;

      if (task == null) {
        throw Exception('Response missing "task"');
      }

      // Invite matching
      final people = List<String>.from(task['people'] ?? []);
      final inviteMatch = matcher.getInviteMatches(
        people: people,
        friends: userFriends,
      );
      final inviteNames = List<String>.from(inviteMatch['inviteNames'] ?? []);
      final invitedUserIds = List<String>.from(inviteMatch['invitedUserIds'] ?? []);

      return {
        'title': task['title'] ?? '',
        'category': task['category'] ?? 'none',
        'people': people,
        'date': task['date'] ?? '',
        'time': task['time'] ?? '',
        'floating': task['floating'] ?? false,
        'recurring': task['recurring'] ?? 'none',
        'intent': task['intent'] ?? '',
        'priority': task['priority'] ?? 'Medium',
        'relationship': task['relationship'] ?? 'Unknown',
        'location': task['location'] ?? 'none',
        'user_mood': task['user_mood'] ?? 'Neutral',
        'inviteNames': inviteNames,
        'invitedUserIds': invitedUserIds,
      };
    } catch (e) {
      debugPrint('TaskSubmitService: ERROR $e');
      throw Exception('Network or parse error: $e');
    }
  }
}
