import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../groupchats/groupchat_screen.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final Set<String> tappedChatIds = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('user_chats')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userChatDocs = snapshot.data!.docs;
        final chatIds = userChatDocs.map((doc) => doc.id).toList();

        if (chatIds.isEmpty) {
          return const Center(
              child: Text("No group chats yet.",
                  style: TextStyle(color: Colors.white)));
        }

        return FutureBuilder<List<DocumentSnapshot>>(
          future: _fetchGroupChats(chatIds),
          builder: (context, chatSnapshot) {
            if (!chatSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final chats = chatSnapshot.data!;
            chats.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;

              final aTime =
                  (aData['lastMessageAt'] as Timestamp?)?.toDate() ??
                      DateTime(2000);
              final bTime =
                  (bData['lastMessageAt'] as Timestamp?)?.toDate() ??
                      DateTime(2000);

              return bTime.compareTo(aTime);
            });

            return ListView.separated(
              padding: const EdgeInsets.only(top: 12),
              itemCount: chats.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey.withOpacity(0.6),
                thickness: 0.5,
                height: 0.5,
              ),
              itemBuilder: (context, index) {
                final data = chats[index].data() as Map<String, dynamic>;
                final chatId = chats[index].id;
                final title = data['title'] ?? 'Untitled';
                final lastMessage = data['lastMessage'] ?? '';
                final lastMessageAt =
                (data['lastMessageAt'] as Timestamp?)?.toDate();
                final readTimestamps = data['readTimestamps'] ?? {};
                final lastRead =
                (readTimestamps[currentUserId] as Timestamp?)?.toDate();
                final isUnread = !tappedChatIds.contains(chatId) &&
                    lastMessageAt != null &&
                    (lastRead == null || lastMessageAt.isAfter(lastRead));


                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 15),
                    onTap: () async {
                      // ✅ Add to local tapped set for instant UI update
                      tappedChatIds.add(chatId);

                      // ✅ Update Firestore in background (no await)
                      FirebaseFirestore.instance
                          .collection('groupChats')
                          .doc(chatId)
                          .update({
                        'readTimestamps.$currentUserId': Timestamp.now(),
                      });

                      // ✅ Navigate to chat screen
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupChatScreen(
                            chatId: chatId,
                            currentUserId: currentUserId,
                          ),
                        ),
                      );

                      // ✅ Refresh UI immediately
                      setState(() {});
                    },
                  leading: Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: isUnread ? Colors.white : Colors.grey[800],
                      shape: BoxShape.rectangle,
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread && lastMessageAt != null)
                        Text(
                          timeago.format(lastMessageAt),
                          style:
                          const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                    ],
                  ),
                  subtitle: isUnread
                      ? const Text("1 message",
                      style: TextStyle(color: Colors.white))
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<DocumentSnapshot>> _fetchGroupChats(List<String> chatIds) async {
    final futures = chatIds.map((id) {
      return FirebaseFirestore.instance.collection('groupChats').doc(id).get();
    }).toList();

    final results = await Future.wait(futures);
    return results.where((doc) => doc.exists).toList();
  }
}
