import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/board_card_model.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class BoardCardOverlayStack extends StatefulWidget {
  final List<BoardCardModel> cards;

  const BoardCardOverlayStack({Key? key, required this.cards}) : super(key: key);

  @override
  State<BoardCardOverlayStack> createState() => _BoardCardOverlayStackState();
}

class _BoardCardOverlayStackState extends State<BoardCardOverlayStack> {
  int currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  double _totalDragDy = 0;
  late PageController _pageController = PageController();
  final ValueNotifier<bool> _triggerExitAnimation = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    _pageController.addListener(() {
      final currentPage = _pageController.page ?? 0;

      final isOnLastCard = currentPage.round() == widget.cards.length - 1;
      final hasScrolledFarEnough = _pageController.position.pixels >
          _pageController.position.maxScrollExtent + 30;

      print("📜 Page listener: $currentPage, last card? $isOnLastCard, overscrolled? $hasScrolledFarEnough");

      if (isOnLastCard && hasScrolledFarEnough && !_triggerExitAnimation.value) {
        _triggerExitAnimation.value = true;
        print("🎯 Triggering exit!");

        Future.delayed(const Duration(milliseconds: 400), () {
          Navigator.pop(context);
        });
      }
    });
  }

  void _nextCard() {
    print("➡️ currentIndex: $currentIndex / total: ${widget.cards.length}");

    if (currentIndex < widget.cards.length - 1) {
      setState(() => currentIndex++);
      print("✅ Swiped to next card: $currentIndex");
    } else {
      print("🚪 No more cards. Exiting.");
      Navigator.pop(context);
    }
  }


  void _exitOverlay() => Navigator.pop(context);

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _totalDragDy += details.delta.dy;
  }


  void _onVerticalDragEnd(DragEndDetails details) {
    if (_totalDragDy < -100) {
      // Swiped up enough
      _nextCard();
    }
    _totalDragDy = 0;
  }


  void _onPanUpdate(DragUpdateDetails details) {
    if (details.delta.dx < -15 && details.delta.dy > 15) {
      // Diagonal down-right swipe
      _exitOverlay();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.cards.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final card = widget.cards[index];
          final isLastCard = index == widget.cards.length - 1;

          return isLastCard
              ? ValueListenableBuilder<bool>(
            valueListenable: _triggerExitAnimation,
            builder: (context, isExiting, child) {
              return AnimatedSlide(
                offset: isExiting ? const Offset(0, -1.2) : Offset.zero,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: child,
              );
            },
            child: _buildBoardCard(card),
          )
              : _buildBoardCard(card);
        },
      ),

    );
  }


  Widget _buildBoardCard(BoardCardModel card) {
    final timeAgo = timeago.format(card.timestamp);
    final includesText = card.invitedPeople.isNotEmpty
        ? card.invitedPeople.take(3).join(', ') +
        (card.invitedPeople.length > 3
            ? ' +${card.invitedPeople.length - 3} more'
            : '')
        : '';

    final formattedDate = DateFormat('EEEE MMM d').format(card.eventDate) +
        _getDaySuffix(card.eventDate.day) +
        ', ${card.eventDate.year}';

    final formattedTime = DateFormat.jm().format(
      DateFormat("HH:mm").parse(card.time),
    );

    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, right: 16),
            child: Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.white, size: 34),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender info
                    Text(card.senderName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(timeAgo,
                        style: const TextStyle(color: Colors.grey, fontSize: 15)),


                    const SizedBox(height: 50),

                    // Title
                    Text(card.title,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 45,
                            fontWeight: FontWeight.bold)),

                    const SizedBox(height: 26),

                    // Date and Time
                    Text(formattedDate,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(formattedTime,
                        style: const TextStyle(color: Colors.grey, fontSize: 18)),

                    const SizedBox(height: 10),
                    Container(
                      height: 4,
                      width: 60,
                      color: _hexToColor(card.borderColor),
                    ),

                    const SizedBox(height: 20),

                    // Includes
                    if (includesText.isNotEmpty)
                      Text('Includes: $includesText',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),

                    const SizedBox(height: 50), // Push emojis further down

                    // Emojis
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(card.categoryEmoji,
                            style: const TextStyle(fontSize: 34)),
                        const SizedBox(width: 20),
                        Text(card.moodEmoji,
                            style: const TextStyle(fontSize: 34)),
                      ],
                    ),

                    const SizedBox(height: 60), // Bigger gap before join button

                    // Join Button
                    JoinButton(card: card),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }




  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}








class JoinButton extends StatefulWidget {
  final BoardCardModel card;

  const JoinButton({super.key, required this.card});

  @override
  State<JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<JoinButton> {
  bool isRequested = false;

  Future<void> handleJoin() async {
    // Simple cooldown lock
    bool locked = true;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final requesterId = currentUser.uid;
    final requesterName = await FirestoreService.getSenderFullName(requesterId);

    try {
      await FirestoreService.sendJoinRequestToHost(
        boardcardId: widget.card.boardcardId,
        hostId: widget.card.senderId,
        requesterId: requesterId,
        requesterName: requesterName,
        boardcardData: widget.card.toMap(),
      );

      if (mounted) {
        _showAnimatedBanner(context, 'Request sent', success: true);
        setState(() => isRequested = true);
      }

      // Hold cooldown before allowing another request
      await Future.delayed(const Duration(seconds: 10));

      if (mounted) {
        setState(() => isRequested = false);
      }

      locked = false;
    } catch (e) {
      print('❌ Join request failed: $e');

      if (mounted) {
        _showAnimatedBanner(context, 'Request not delivered', success: false);
      }

      locked = false;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: isRequested ? null : handleJoin,
          child: Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isRequested ? Colors.white : Colors.transparent,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Text(
              isRequested ? 'Requested' : 'Join?',
              style: TextStyle(
                color: isRequested ? Colors.black : Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
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