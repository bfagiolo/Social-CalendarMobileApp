import 'package:cloud_firestore/cloud_firestore.dart';


class BoardCardModel {
  final String boardcardId;
  final String title;
  final String senderName;
  final String senderId;
  final DateTime eventDate;
  final String time;
  final String location;
  final String moodEmoji;
  final String categoryEmoji;
  final String borderColor;
  final List<String> invitedPeople;
  final DateTime timestamp;

  BoardCardModel({
    required this.boardcardId,
    required this.title,
    required this.senderName,
    required this.senderId,
    required this.eventDate,
    required this.time,
    required this.location,
    required this.moodEmoji,
    required this.categoryEmoji,
    required this.borderColor,
    required this.invitedPeople,
    required this.timestamp,
  });

  factory BoardCardModel.fromMap(Map<String, dynamic> data) {
    return BoardCardModel(
      boardcardId: data['boardcardId'] ?? '',
      title: data['title'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      senderId: data['senderId'] ?? '',
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      location: data['location'] ?? 'none',
      moodEmoji: data['moodEmoji'] ?? '',
      categoryEmoji: data['categoryEmoji'] ?? '',
      borderColor: data['borderColor'] ?? '#FFFFFF',
      invitedPeople: List<String>.from(data['invitedPeople'] ?? []),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'boardcardId': boardcardId,
      'title': title,
      'senderName': senderName,
      'senderId': senderId,
      'eventDate': Timestamp.fromDate(eventDate),
      'time': time,
      'location': location,
      'moodEmoji': moodEmoji,
      'categoryEmoji': categoryEmoji,
      'borderColor': borderColor,
      'invitedPeople': invitedPeople,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }



}
