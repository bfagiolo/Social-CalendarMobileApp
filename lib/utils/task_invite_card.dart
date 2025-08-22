import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'full_screen_task_invite.dart';
import 'task_confirmation_card.dart';
import 'rejection_confirmation_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../utils/join_request_overlay.dart';


class TaskInviteCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const TaskInviteCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final eventDate = (data['eventDate'] as Timestamp?)?.toDate();
    final status = data['status']?.toString() ?? '';

    final cardType = data['type'] ?? 'invite';

    final senderName = switch (cardType) {
      'join_request' => data['requesterName'] ?? 'Someone',
      _ => data['senderName'] ?? 'Someone',
    };

    final timeAgo = timestamp != null ? timeago.format(timestamp) : '';
    final now = DateTime.now();

    final isTomorrow = eventDate != null &&
        !eventDate.isAfter(DateTime(now.year, now.month, now.day).add(Duration(days: 1)));


    final iconPath = switch (cardType) {
      'confirmation' => 'assets/images/confirmcard.png',
      'join_request' => 'assets/images/join_request.png', // ✅ BLUE ICON FOR JOIN REQUEST
      _ => isTomorrow
          ? 'assets/images/tmrwletter.png'
          : 'assets/images/newletter.png',
    };


    return GestureDetector(
      onTap: () async {
        final type = data['type'] ?? 'invite';

        if (type == 'confirmation') {
          final status = data['status']?.toString().trim().toLowerCase() ?? '';

          if (status == 'accept') {
            try {
              final hostUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
              final hostUserName = FirebaseAuth.instance.currentUser?.displayName ?? 'Host';

              if (hostUserId.isEmpty) {
                print('❌ No current user ID found');
                return;
              }


              // 🔍 Step 1: Get group_event_link to determine the eventId
              final linkSnap = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(hostUserId)
                  .collection('group_event_links')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .get();

              if (linkSnap.docs.isEmpty) {
                print('❌ No group_event_link found for $hostUserId');
                return;
              }

              final eventId = linkSnap.docs.first.data()['eventId'];
              if (eventId == null || eventId.toString().isEmpty) {
                print('❌ group_event_link had null or empty eventId');
                return;
              }

              // 🔍 Step 1: Lookup the current confirmation card doc (the one we tapped)
              final inviteId = data['inviteId'];
              final wrongInviteSnap = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(hostUserId)
                  .collection('Task_invites')
                  .doc(inviteId) // 👈 this is the "confirmation card" one
                  .get();

              if (!wrongInviteSnap.exists) {
                print('❌ Confirmation card not found');
                return;
              }

              final wrongData = wrongInviteSnap.data();
              if (wrongData == null) {
                print('❌ Confirmation card has no data');
                return;
              }

// ✅ Step 2: Extract the original routing info
              final inviteIdForChat = wrongData['inviteId'];
              final recipientIdForChat = wrongData['recipientId'];

              if (inviteIdForChat == null || recipientIdForChat == null) {
                print('❌ inviteId or recipientId missing in confirmation card');
                return;
              }

// 📩 Step 3: Lookup the response using the corrected info
              final responseSnap = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(hostUserId)
                  .collection('Task_invites')
                  .doc(inviteIdForChat)
                  .collection('responses')
                  .doc(recipientIdForChat)
                  .get();

              if (!responseSnap.exists) {
                print('❌ No response doc found at the corrected path');
                return;
              }

              print('✅ Response found! Data: ${responseSnap.data()}');


              final responseData = responseSnap.data()!;
              final acceptingUserId = responseData['senderId'] ?? 'Someone';
              final acceptingUserName = responseData['senderName'] ?? 'Someone';

              print('👣 Adding host and accepting user to group chat for $eventId');

              // ✅ Add host to groupEvent
              await FirebaseFirestore.instance
                  .collection('groupEvents')
                  .doc(eventId)
                  .update({
                'participantIds': FieldValue.arrayUnion([hostUserId])
              });

              // ✅ Add accepting user to groupEvent
              await FirebaseFirestore.instance
                  .collection('groupEvents')
                  .doc(eventId)
                  .update({
                'participantIds': FieldValue.arrayUnion([acceptingUserId])
              });

              // ✅ Join or create the chat for host
              await FirestoreService.handleGroupEventChatJoin(
                eventId: eventId,
                currentUserId: hostUserId,
                currentUserName: hostUserName,
              );

              // ✅ Join or create the chat for accepting user
              await FirestoreService.handleGroupEventChatJoin(
                eventId: eventId,
                currentUserId: acceptingUserId,
                currentUserName: acceptingUserName,
              );

              print('🎉 Both users added to group chat successfully!');
            } catch (e) {
              print('❌ Error handling accept logic: $e');
            }
          }



          print('🧪 Invite status: ${data['status']}');

          // 👇 Step 1: delete the confirmation doc
          final userId = FirebaseAuth.instance.currentUser?.uid ?? ''; // adjust if needed
          //final docId = data['inviteId'] ?? data['id'];
          final docId = data['id'];
          if (userId.isNotEmpty && docId != null) {
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('Task_invites')
                .doc(docId)
                .delete()
                .then((_) => print('🗑️ Confirmation invite removed from inbox'))
                .catchError((e) => print('❌ Failed to remove confirmation: $e'));
          }
          print('📍 Trying to delete: /users/$userId/Task_invites/$docId');

          // 👇 Step 2: show the confirmation overlay
          final overlayWidget = status == 'accept'
              ? AcceptedCardOverlay(
            chatText: data['message'] ?? '',
            title: data['title'] ?? 'Untitled',
            dateTime: (data['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
            location: data['location'] ?? 'none',
            peopleIncluded: List<String>.from(data['inviteNames'] ?? []),
            categoryEmoji: data['categoryEmoji'] ?? '',
            moodEmoji: data['moodEmoji'] ?? '',
            borderColor: _hexToColor((data['borderColor']?.toString() ?? '#FFFFFFFF')),
            senderFirstName: (data['senderName'] as String?)?.split(' ').first ?? 'Someone',
            senderName: data['senderName'] as String?,
          )
              : RejectedCardOverlay(
            chatText: data['message'] ?? '',
            title: data['title'] ?? 'Untitled',
            dateTime: (data['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
            location: data['location'] ?? 'none',
            peopleIncluded: List<String>.from(data['inviteNames'] ?? []),
            categoryEmoji: data['categoryEmoji'] ?? '',
            moodEmoji: data['moodEmoji'] ?? '',
            borderColor: _hexToColor((data['borderColor']?.toString() ?? '#FFFFFFFF')),
            senderFirstName: (data['senderName'] as String?)?.split(' ').first ?? 'Someone',
            senderName: data['senderName'] as String?,
          );

          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => overlayWidget,
            ),
          );
        }

        else if (type == 'join_request') {
          final requesterName = data['requesterName'] ?? 'Someone';
          final boardcardId = data['boardcardId'] ?? '';
          final requesterId = data['requesterId'] ?? '';
          final hostId = FirebaseAuth.instance.currentUser?.uid ?? '';
          final docId = data['id']; // Pass doc ID of this join request

          if (hostId.isEmpty || docId == null) return;

          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => JoinRequestOverlay(data: data, docId: docId),
            ),
          );

        }
        else {
          // Show full invite (recipient responds)

          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => FullScreenTaskInvite(
                task: {
                  'title': data['title'] ?? 'No title',
                  'date': data['eventDate'] != null
                      ? '${(data['eventDate'] as Timestamp).toDate().toLocal().toString().split(' ')[0]}'
                      : 'Unknown',
                  'time': data['time'] ?? 'Unknown',
                  'location': data['location'] ?? 'Unknown',
                  'people': List<String>.from(data['invitedPeople'] ?? []),
                  'senderName': data['senderName'] ?? 'Unknown',
                  'user_mood': data['user_mood'] ?? 'Neutral',
                  'category': data['category'] ?? 'none',
                  'priority': data['priority'] ?? 'Medium',
                  'relationship': data['relationship'] ?? 'Unknown',
                  'floating': data['floating'] ?? false,
                  'recurring': data['recurring'] ?? 'none',
                  'intent': data['intent'] ?? '',
                  'invitedUserIds': List<String>.from(data['invitedUserIds'] ?? []),
                  'inviteNames': List<String>.from(data['inviteNames'] ?? []),
                },
                senderId: data['senderId'] ?? 'unknown',
                inviteId: data['id'] ?? 'unknownInvite',  //data['inviteId'] ?? data['id'] ?? 'unknownInvite'
                borderColor: _hexToColor((data['borderColor']?.toString() ?? '#FFFFFFFF')),
                categoryEmoji: data['categoryEmoji'] ?? '',
                userMoodEmoji: data['moodEmoji'] ?? '',
              ),
            ),
          );
        }
      },



      child: ListTile(
        leading: Image.asset(
          iconPath,
          width: 36,
          height: 36,
          fit: BoxFit.contain,
        ),
        title: Text(senderName, style: const TextStyle(color: Colors.white)),
        subtitle: Text("New Card  •  $timeAgo", style: const TextStyle(color: Colors.grey)),
      ),
    );

  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex'; // default full opacity
    return Color(int.parse(hex, radix: 16));
  }

}
