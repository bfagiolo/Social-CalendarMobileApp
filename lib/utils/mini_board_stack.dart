
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MiniBoardStack extends StatefulWidget {
  const MiniBoardStack({Key? key}) : super(key: key);

  @override
  State<MiniBoardStack> createState() => _MiniBoardStackState();
}

class _MiniBoardStackState extends State<MiniBoardStack> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('boardcards')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();

        final docsList = snapshot.data!.docs;
        final reversedEntries = docsList.asMap().entries.toList().reversed.toList(); // Oldest → Newest

        return AnimatedSwitcher(
          duration: Duration(milliseconds: 800),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: SizedBox(
            key: ValueKey(snapshot.data!.docs.first.id), // 🧠 important for detecting new content
            height: 140,
            child: Stack(
              clipBehavior: Clip.none,
              children: reversedEntries.map((entry) {
                final index = entry.key; // Now: 0 = oldest, 1 = middle, 2 = newest
                final data = entry.value.data() as Map<String, dynamic>;

                final sender = data['senderName'] ?? 'Unknown';
                final title = data['title'] ?? 'Untitled';
                final borderColor = _hexToColor(data['borderColor'] ?? '#FFFFFFFF');

// Use stack positioning logic:
                final double leftOffset = 0.0 + (6.0 * index);   // 👉 newer = more left
                final double topOffset = 20.0 - (6.0 * index);   // 👉 newer = more down

                return Positioned(
                  left: leftOffset,
                  top: topOffset,
                  child: Container(
                    width: 135,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: borderColor, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sender,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          _truncateText(title, 24),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );


              }).toList(),
            ),
          ),
        );



      },
    );
  }

  String _truncateText(String text, int maxLength) {
    return text.length > maxLength ? '${text.substring(0, maxLength - 3)}...' : text;
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
