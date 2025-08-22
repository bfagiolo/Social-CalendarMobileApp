

class Task {
  final String id;
  final String title;
  final String time;
  final String date;
  final String category;
  final String priority;
  final String userMood;
  final String relationship;
  final String location;
  final String recurring;
  final bool floating;
  final String intent;
  final List<String> people;
  final List<String> invitedUserIds;
  final List<String> inviteNames;

  Task({
    required this.id,
    required this.title,
    required this.time,
    required this.date,
    required this.category,
    required this.priority,
    required this.userMood,
    required this.relationship,
    required this.location,
    required this.recurring,
    required this.floating,
    required this.intent,
    required this.people,
    required this.invitedUserIds,
    required this.inviteNames,

  });

  factory Task.fromFirestore(Map<String, dynamic> data, String docId) {
    print("🎯 fromFirestore types: "
        "floating=${data['floating']} (${data['floating'].runtimeType}), "
        "recurring=${data['recurring']} (${data['recurring'].runtimeType}), "
        "postToBoard=${data['postToBoard']} (${data['postToBoard']?.runtimeType})");
    return Task(
      id: docId,
      title: data['title'] ?? '',
      time: data['time'] ?? '',
      date: (data['date'] ?? '').toString().substring(0, 10), // trims to YYYY-MM-DD
      category: data['category'] ?? 'none',
      priority: data['priority'] ?? 'Medium',
      userMood: data['user_mood'] ?? 'Neutral',
      relationship: data['relationship'] ?? 'Unknown',
      location: data['location'] ?? 'none',
      recurring: data['recurring'] ?? 'none',
      floating: data['floating'] ?? false,
      intent: data['intent'] ?? '',
      people: List<String>.from(data['people'] ?? []),
      invitedUserIds: List<String>.from(data['invitedUserIds'] ?? []),
      inviteNames: List<String>.from(data['inviteNames'] ?? []),

    );
  }
}
