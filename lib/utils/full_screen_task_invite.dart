import 'package:flutter/material.dart';
import '/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnvelopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final topLeft = Offset(0, 0);
    final topRight = Offset(size.width, 0);
    final bottomLeft = Offset(0, size.height);
    final bottomRight = Offset(size.width, size.height);
    final centerTip = Offset(size.width / 2, size.height * 0.6);

    final leftFlapEnd = Offset(
      topLeft.dx + (centerTip.dx - topLeft.dx) * 0.7,
      topLeft.dy + (centerTip.dy - topLeft.dy) * 0.7,
    );

    final rightFlapEnd = Offset(
      topRight.dx + (centerTip.dx - topRight.dx) * 0.7,
      topRight.dy + (centerTip.dy - topRight.dy) * 0.7,
    );

    final path = Path();
    path.moveTo(topLeft.dx, topLeft.dy);
    path.lineTo(centerTip.dx, centerTip.dy);
    path.lineTo(topRight.dx, topRight.dy);

    path.moveTo(bottomLeft.dx, bottomLeft.dy);
    path.lineTo(leftFlapEnd.dx, leftFlapEnd.dy);

    path.moveTo(bottomRight.dx, bottomRight.dy);
    path.lineTo(rightFlapEnd.dx, rightFlapEnd.dy);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class FullScreenTaskInvite extends StatefulWidget {
  final Map<String, dynamic> task;
  final Color borderColor;
  final String categoryEmoji;
  final String userMoodEmoji;
  final String senderId;
  final String inviteId;


  const FullScreenTaskInvite({
    required this.task,
    required this.senderId,
    required this.inviteId,
    required this.borderColor,
    required this.categoryEmoji,
    required this.userMoodEmoji,
    super.key,
  });

  @override
  State<FullScreenTaskInvite> createState() => _FullScreenTaskInviteState();
}

class _FullScreenTaskInviteState extends State<FullScreenTaskInvite> with SingleTickerProviderStateMixin {
  String? selectedAction; // 'accept', 'reject', 'suggest'
  bool _hasAnimatedIn = false;

  final TextEditingController chatController = TextEditingController();

  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));


    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        print('Slide-in animation completed.');
      } else if (status == AnimationStatus.forward) {
        print('Slide-in animation started.');
      }
    });
  }


  void handleButtonPress(String action) {
    if (action == 'stall') {
      Navigator.of(context).pop(); // close overlay
    } else {
      setState(() {
        selectedAction = action;

        // Slide in only once
        if (!_hasAnimatedIn) {
          _controller.forward();
          _hasAnimatedIn = true;
        }
      });
    }
  }


  Widget buildActionButton(String label, String action, Color baseColor) {
    final isSelected = selectedAction == action;

    final backgroundColor = switch (action) {
      'reject' => const Color(0xFFB00020),
      'accept' => const Color(0xFF006400),
      _        => baseColor,
    };

    final button = OutlinedButton(
      onPressed: () => handleButtonPress(action),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: backgroundColor,
        side: BorderSide(
          color: Colors.white.withOpacity(0.3),
          width: 0.8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Button stays underneath
          button,

          // White circle visually *on top*
          if (isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CircleOverlayPainter(),
                ),
              ),
            ),
        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    print("📨 inviteId received: ${widget.inviteId}");
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 📨 Invite Card with Envelope
                  // 📨 Invite Card with Envelope that covers entire card
                  CustomPaint(
                    painter: EnvelopePainter(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: widget.borderColor, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1.0, bottom: 10.0),
                              child: Text(
                                widget.task['senderName'] ?? 'Unknown',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),

                            Center(
                              child: Text(
                                widget.task['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${widget.task['date']}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Builder(
                                  builder: (_) {
                                    final people = List<String>.from(widget.task['people'] ?? []);
                                    final sender = (widget.task['senderName'] ?? '').trim();
                                    final recipient = (widget.task['recipientName'] ?? '').trim(); // optional field, make sure it's in the task

                                    // Filter out sender and recipient
                                    final others = people.where((p) {
                                      final name = p.trim();
                                      return name.isNotEmpty && name != sender && name != recipient;
                                    }).toList();

                                    final displayText = others.isNotEmpty
                                        ? 'Includes: ${others.join(", ")}'
                                        : 'Includes: ?';

                                    return Text(
                                      displayText,
                                      style: const TextStyle(color: Colors.white),
                                    );
                                  },
                                ),

                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.task['time'] ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            if ((widget.task['location'] ?? '').trim().toLowerCase() != 'unknown')
                              Row(
                                children: [
                                  const Icon(Icons.location_pin, color: Colors.white, size: 18),
                                  const SizedBox(width: 4),
                                  Text(widget.task['location'], style: const TextStyle(color: Colors.white)),
                                ],
                              ),

                            const SizedBox(height: 16),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(widget.categoryEmoji, style: const TextStyle(fontSize: 28)),
                                  const SizedBox(width: 12),
                                  Text(widget.userMoodEmoji, style: const TextStyle(fontSize: 28)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),


                  const SizedBox(height: 20),

                  // 🎛 Buttons
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      buildActionButton('REJECT', 'reject', Colors.red),
                      buildActionButton('STALL', 'stall', Colors.black),
                      buildActionButton('ACCEPT', 'accept', Colors.green),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 📝 Chat + Confirm
                  AnimatedOpacity(
                    opacity: (selectedAction != null && selectedAction != 'stall') ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: Column(
                      children: [
                        TextField(
                          controller: chatController,
                          maxLength: 160,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Send a chat',
                            hintStyle: TextStyle(color: Colors.grey),
                            counterStyle: TextStyle(color: Colors.grey),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SlideTransition(
                          position: _offsetAnimation,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

                                  final senderFullName = await FirestoreService.getSenderFullName(currentUserId);

                                  // Send the response to the sender's invite document
                                  await FirestoreService.sendResponseToInvite(
                                    senderId: widget.senderId, // host's UID
                                    senderName: senderFullName ?? '', // 👈 NEW
                                    inviteId: widget.inviteId,
                                    recipientId: currentUserId, // accepting user
                                    status: selectedAction!,
                                    message: chatController.text,
                                  );


                                  final currentUser = FirebaseAuth.instance.currentUser;
                                  String recipientName = 'Someone';

                                  if (currentUser != null) {
                                    recipientName = await FirestoreService.getSenderFullName(currentUser.uid);
                                  }

                                  // If accepted, add to recipient's calendar
                                  if (selectedAction == 'accept') {
                                      final taskData = {
                                      'title': widget.task['title'],
                                      'date': widget.task['date'],
                                      'time': widget.task['time'],
                                      'category': widget.task['category'],
                                      'priority': widget.task['priority'],
                                      'user_mood': widget.task['user_mood'],
                                      'relationship': widget.task['relationship'],
                                      'location': widget.task['location'],
                                      'recurring': widget.task['recurring'],
                                      'floating': widget.task['floating'],
                                      'intent': widget.task['intent'],
                                      'people': widget.task['people'],
                                      'invitedUserIds': widget.task['invitedUserIds'],
                                      'inviteNames': widget.task['inviteNames'],
                                      };


                                      await FirestoreService.addInviteToRecipientCalendar(
                                      recipientId: currentUserId,
                                      taskData: taskData,
                                      );

                                      await FirestoreService.sendConfirmationCardToSender(
                                        senderId: widget.senderId,
                                        recipientName: recipientName,
                                        message: chatController.text,  // ✅ add this line
                                        inviteId: widget.inviteId,
                                        recipientId: FirebaseAuth.instance.currentUser!.uid,
                                        status: 'accept',
                                        taskData: {
                                          'title': widget.task['title'],
                                          'eventDate': DateTime.tryParse(widget.task['date'] ?? '') ?? DateTime.now(),
                                          'time': widget.task['time'],
                                          'location': widget.task['location'],
                                          'categoryEmoji': widget.categoryEmoji,
                                          'moodEmoji': widget.userMoodEmoji,
                                          'borderColor': widget.borderColor.value.toRadixString(16).padLeft(8, '0'),
                                        },
                                      );


                                  }
                                  else {
                                    await FirestoreService
                                        .sendConfirmationCardToSender(
                                      senderId: widget.senderId,
                                      recipientName: recipientName,
                                      message: chatController.text,
                                      // ✅ add this line
                                      inviteId: widget.inviteId,
                                      recipientId: FirebaseAuth.instance.currentUser!.uid,
                                      status: 'reject',
                                      taskData: {
                                        'title': widget.task['title'],
                                        'eventDate': DateTime.tryParse(
                                            widget.task['date'] ?? '') ??
                                            DateTime.now(),
                                        'time': widget.task['time'],
                                        'location': widget.task['location'],
                                        'categoryEmoji': widget.categoryEmoji,
                                        'moodEmoji': widget.userMoodEmoji,
                                        'borderColor': widget.borderColor.value
                                            .toRadixString(16).padLeft(8, '0'),
                                      },
                                    );
                                  }

                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(currentUserId)
                                      .collection('Task_invites')
                                      .doc(widget.inviteId)
                                      .delete();

                                  // ✅ Close the overlay
                                  Navigator.of(context).pop();
                                },

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF57C00),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text("Confirm", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),

        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    chatController.dispose();
    super.dispose();
  }

}

class CircleOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width + 12,  // Wider ellipse
      height: size.height + 6, // Slightly taller
    );

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawOval(rect, paint);
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
