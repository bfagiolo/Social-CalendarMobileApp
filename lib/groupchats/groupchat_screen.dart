import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const GroupChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  late CollectionReference messagesRef;
  late DocumentReference chatRef;

  String? title;
  String? date;
  String? time;
  String? location;
  List<dynamic> participants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    chatRef = FirebaseFirestore.instance.collection('groupChats').doc(widget.chatId);
    messagesRef = chatRef.collection('messages');
    _loadChatMeta();
  }

  Future<void> _loadChatMeta() async {
    final chatSnap = await chatRef.get();
    final data = chatSnap.data() as Map<String, dynamic>;

    setState(() {
      title = data['title'];
      date = data['date'];
      time = data['time'];
      location = data['location'];
      participants = data['participantIds'] ?? [];
      isLoading = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.currentUserId).get();
    final name = "${userDoc['firstName']} ${userDoc['lastName']}";

    await messagesRef.add({
      'senderId': widget.currentUserId,
      'senderName': name,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await chatRef.update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  Widget customUnderlinedText(String text) {
    return Stack(
      children: [
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Positioned(
          bottom: -2, // vertical spacing between text and underline
          left: 0,
          right: 0,
          child: Container(
            height: 2.5, // underline thickness
            color: Colors.white,
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title ?? '',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text("$date | $time",
                            style: const TextStyle(fontSize: 14, color: Colors.white)),
                        if (location != null && location!.toLowerCase() != 'none')
                          Text(location!, style: const TextStyle(fontSize: 14, color: Colors.white)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white),

            // Messages
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: messagesRef.orderBy('timestamp').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final data = messages[index].data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            customUnderlinedText(data['senderName'] ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              data['text'] ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Participant Pills
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: participants.map((uid) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final user = snapshot.data!.data() as Map<String, dynamic>;
                      final name = "${user['firstName']} ${user['lastName']}";
                      final isCurrentUser = uid == widget.currentUserId;

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCurrentUser ? Colors.black : Colors.grey[850],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Text(
                          name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),

            // Input bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Write something....',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
