import 'package:flutter/material.dart';
import 'package:finalproject3/services/task_submit_service.dart';
import 'package:finalproject3/utils/task_preview_card.dart';
import '../utils/invite_matcher.dart' as matcher;

class EnterTaskCard extends StatefulWidget {
  final Function(Map<String, dynamic>) onTaskAdded;
  final String userId;
  final List<Map<String, dynamic>> userFriends;

  const EnterTaskCard({Key? key, required this.onTaskAdded, required this.userId, required this.userFriends}) : super(key: key);

  @override
  State<EnterTaskCard> createState() => _EnterTaskCardState();
}

class _EnterTaskCardState extends State<EnterTaskCard> {
  final TextEditingController _controller = TextEditingController();
  // Toggle this to quickly switch between mock and live backend parsing
  final bool useMock = false;
  double _fontSize = 55.0; // Starting font size
  final double _minFontSize = 16.0;
  final double _maxFontSize = 55.0;

  void _adjustFontSize(BoxConstraints constraints) {
    final text = _controller.text;
    if (text.isEmpty) {
      setState(() => _fontSize = _maxFontSize);
      return;
    }

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: _fontSize,
          fontFamily: 'BricolageGrotesque',
        ),
      ),
      textDirection: TextDirection.ltr,
      textWidthBasis: TextWidthBasis.longestLine,
      maxLines: null,
    )..layout(maxWidth: constraints.maxWidth - 64);

    final confirmButtonHeight = 60;
    final marginAboveConfirm = 80;
    final availableHeight = constraints.maxHeight - confirmButtonHeight - marginAboveConfirm;

    while (tp.height > availableHeight && _fontSize > _minFontSize) {
      _fontSize -= 1;
      tp.text = TextSpan(
        text: text,
        style: TextStyle(fontSize: _fontSize, fontFamily: 'BricolageGrotesque'),
      );
      tp.layout(maxWidth: constraints.maxWidth - 64);
    }
    while (tp.height < availableHeight && _fontSize < _maxFontSize) {
      final testFontSize = _fontSize + 1;
      final testPainter = TextPainter(
        text: TextSpan(text: text, style: TextStyle(fontSize: testFontSize, fontFamily: 'BricolageGrotesque')),
        textDirection: TextDirection.ltr,
        textWidthBasis: TextWidthBasis.longestLine,
        maxLines: null,
      )..layout(maxWidth: constraints.maxWidth - 64);
      if (testPainter.height > availableHeight) break;
      _fontSize = testFontSize;
    }
    setState(() {});
  }

  void _showAnimatedBanner(BuildContext context, String message, {required bool success}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0),
              child: SlideBanner(
                message: message,
                success: success,
              ),
            ),
          ),
        );
      },
    );



    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _adjustFontSize(constraints);
          });
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 64.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    iconSize: 60,
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: _controller,
                      onChanged: (_) => _adjustFontSize(constraints),
                      maxLines: null,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _fontSize,
                        height: 1.4,
                        fontFamily: 'BricolageGrotesque',
                      ),
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                      cursorColor: Colors.orange,
                      autofocus: true,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 48.0, bottom: 12.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        print('🟢 Confirm button pressed');
                        final inputText = _controller.text.trim();
                        if (inputText.isEmpty) return;

                        final parsedTask = useMock
                            ? {
                          'title': 'Review for Bio Exam',
                          'category': 'School',
                          'people': ['Paulo'],
                          'date': '2025-07-28',
                          'time': '14:20',
                          'floating': false,
                          'recurring': 'none',
                          'intent': 'Study together',
                          'priority': 'Low',
                          'relationship': 'Friend',
                          'location': 'Starbucks',
                          'user_mood': 'Motivated',
                          'postToBoard': false,
                        }
                            : await TaskSubmitService.submitTask(inputText, widget.userFriends);

// ✅ Manually call invite matching if using mock
                        if (useMock) {
                          final inviteMatchResult = matcher.getInviteMatches(
                            people: List<String>.from(parsedTask['people'] ?? []),
                            friends: widget.userFriends,
                          );

                          parsedTask['inviteNames'] = inviteMatchResult['inviteNames'];
                          parsedTask['invitedUserIds'] = inviteMatchResult['invitedUserIds'];
                        }




                        // Add this block right here 👇
                        parsedTask.forEach((key, value) {
                          print('🧩 $key = $value (${value.runtimeType})');
                        });
                        print('🧪 Using mock mode: $useMock');
                        print('✅ parsedTask: $parsedTask');


                        print("🐛 DEBUG: floating = ${parsedTask['floating']} (${parsedTask['floating'].runtimeType})");
                        if (parsedTask != null && parsedTask['title'] != null && parsedTask['date'] != null) {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskPreviewCard(
                                key: null,
                                title: parsedTask['title'] ?? 'Untitled Task',
                                date: parsedTask['date'] ?? '',
                                time: parsedTask['time'] ?? '',
                                category: parsedTask['category'] ?? 'Chore',
                                priority: parsedTask['priority'] ?? 'Medium',
                                userMood: parsedTask['userMood'] ?? parsedTask['user_mood'] ?? 'Neutral',
                                relationship: parsedTask['relationship'] ?? 'Unknown',
                                location: parsedTask['location'] ?? 'none',
                                recurring: parsedTask['recurring'] ?? 'none',
                                floating: parsedTask['floating'] ?? false,
                                intent: parsedTask['intent'] ?? '',
                                people: List<String>.from(parsedTask['inviteNames'] ?? []),
                                postToBoard: parsedTask['postToBoard'] ?? false,
                                userId: widget.userId,
                                task: parsedTask,
                                userFriends: widget.userFriends,
                                onClose: () {
                                  Navigator.popUntil(context, (route) => route.isFirst);
                                },
                                onTaskSaved: (response) {
                                  if (response['success'] == true && response['task'] != null) {
                                    widget.onTaskAdded(response['task']);
                                  }
                                  Navigator.pop(context, true);
                                },
                              )


                            ),
                          );

                          // Remove the input overlay
                          Navigator.pop(context);

                          // ✅ Show green SnackBar if successful
                          if (result == true) {
                            Future.delayed(Duration(milliseconds: 200), () {
                              if (mounted) {
                                _showAnimatedBanner(context, 'Card sent successfully!', success: true);
                              }
                            });
                          }
                        }


                        else {
                          print('❌ Failed to parse task or essential fields were missing');
                          Future.delayed(Duration(milliseconds: 200), () {
                            if (mounted) {
                              _showAnimatedBanner(context, 'Card creation error', success: false);
                            }
                          });
                        }
                      },


                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Confirm", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}




class SlideBanner extends StatefulWidget {
  final String message;
  final bool success;

  const SlideBanner({Key? key, required this.message, required this.success}) : super(key: key);

  @override
  State<SlideBanner> createState() => _SlideBannerState();
}

class _SlideBannerState extends State<SlideBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: widget.success ? const Color(0xFF1B8147) : const Color(0xFFB00020),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          widget.message,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'OpenSans',
            fontSize: 13,              // ✅ smaller, more subtle
            fontWeight: FontWeight.normal, // ✅ not thick
            decoration: TextDecoration.none, // ✅ no underline
          ),
        ),
      ),
    );
  }
}

