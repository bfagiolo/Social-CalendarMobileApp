import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinRequestOverlay extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const JoinRequestOverlay({super.key, required this.data, required this.docId});

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final requesterName = data['requesterName'] ?? 'Someone';
    final boardcardId = data['boardcardId'] ?? '';
    final requesterId = data['requesterId'] ?? '';
    final hostId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final borderColor = _hexToColor(data['borderColor'] ?? '#FFFFFF');
    final title = data['title'] ?? 'Untitled';
    final eventDate = (data['eventDate'] as Timestamp?)?.toDate();
    final time = data['time'] ?? 'Unknown';
    final location = data['location'] ?? 'none';

    final dateFormatted = eventDate != null
        ? '${eventDate.month}/${eventDate.day}/${eventDate.year}'
        : 'Unknown';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // X Button
            Positioned(
              top: 12,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),

            // Center Card
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Requester Text
                    Text(
                      '$requesterName wants to join',
                      style: const TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // Date & Time
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$dateFormatted at $time',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Location (optional)
                    if (location != 'none')
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Location: $location',
                          style: const TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(hostId)
                                .collection('Task_invites')
                                .doc(docId)
                                .delete();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // 🟥 Less rounded
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Ignore', style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await FirestoreService.acceptJoinRequest(
                              hostId: hostId,
                              joinRequestDocId: docId,
                              requesterId: requesterId,
                              requesterName: requesterName,
                              boardcardId: boardcardId,
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF267A38), // ✅ Darker green
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // 🟥 Less rounded
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(color: Colors.white),
                          ),

                        ),
                      ],
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
