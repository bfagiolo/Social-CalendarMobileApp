import 'package:flutter/material.dart';

class AcceptedCardOverlay extends StatelessWidget {
  final String chatText; // e.g., "I'm down bro. It's gonna be great!"
  final String title;
  final DateTime dateTime;
  final String location;
  final List<String> peopleIncluded;
  final String categoryEmoji;
  final String moodEmoji;
  final Color borderColor;
  final String? senderFirstName;
  final String? senderName;




  const AcceptedCardOverlay({
    super.key,
    required this.chatText,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.peopleIncluded,
    required this.categoryEmoji,
    required this.moodEmoji,
    required this.borderColor,
    required this.senderFirstName,
    required this.senderName
  });

  @override
  Widget build(BuildContext context) {
    print("Showing ACCEPTED overlay");
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(), // dismiss overlay
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.9),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Chat Text (if exists)
              if ((chatText ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 45.0, vertical: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${senderName ?? 'User'}:",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12), // more space between name and message
                      Expanded(
                        child: Text(
                          chatText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),



              // Card with green checkmark overlaid
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 320,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(
                          senderName ?? 'Someone',
                          style: const TextStyle(color: Colors.white),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontSize: 24),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              _formatDateTime(dateTime),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("Location: $location", style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(
                          "Includes ${peopleIncluded.join(', ')}",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(categoryEmoji, style: TextStyle(fontSize: 32)), // increased size too
                            const SizedBox(width: 12),
                            Text(moodEmoji, style: TextStyle(fontSize: 32)),
                          ],
                        ),


                      ],
                    ),
                  ),
                  // Green Checkmark Overlay
                  const Positioned(
                    child: Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 380, // big and bold
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime dt) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final weekday = weekdays[dt.weekday - 1];
    return "$weekday ${dt.month}/${dt.day}/${dt.year}  •  ${_formatTime(dt)}";
  }


  static String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute$ampm";
  }

}
