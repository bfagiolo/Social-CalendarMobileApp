import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finalproject3/models/task.dart';
import '../models/board_card_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetch all tasks for the currently signed-in user (one-time fetch)
  static Future<Map<String, List<Task>>> getAllTasks() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user signed in');
    }

    final tasksSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .get();

    Map<String, List<Task>> tasksByDate = {};

    for (var doc in tasksSnapshot.docs) {
      final data = doc.data();
      final task = Task(
        id: doc.id,
        title: data['title'] ?? '',
        time: data['time'] ?? '',
        date: data['date'] ?? '',
        category: data['category'] ?? 'none',
        priority: data['priority'] ?? 'Medium',
        userMood: data['user_mood'] ?? 'Neutral',
        relationship: data['relationship'] ?? 'Unknown',
        location: data['location'] ?? 'none',
        recurring: data['recurring'] ?? 'none',
        floating: data['floating'] ?? false,
        intent: data['intent'] ?? '',
        people: List<String>.from(data['people'] ?? []),
        invitedUserIds: List<String>.from(data['invitedUserIds'] ?? []),
        inviteNames: List<String>.from(data['inviteNames'] ?? []),
      );


      tasksByDate.putIfAbsent(task.date, () => []);
      tasksByDate[task.date]!.add(task);
    }

    return tasksByDate;
  }

  /// 🔁 Live stream of tasks for a specific date
  static Stream<List<Task>> getTasksStreamByDate(String userId, String date) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Task(
          id: doc.id,
          title: data['title'] ?? '',
          time: data['time'] ?? '',
          date: data['date'] ?? '',
          category: data['category'] ?? 'none',
          priority: data['priority'] ?? 'Medium',
          userMood: data['user_mood'] ?? 'Neutral',
          relationship: data['relationship'] ?? 'Unknown',
          location: data['location'] ?? 'none',
          recurring: data['recurring'] ?? 'none',
          floating: data['floating'] ?? false,
          intent: data['intent'] ?? '',
          people: List<String>.from(data['people'] ?? []),
          invitedUserIds: List<String>.from(data['invitedUserIds'] ?? []),
          inviteNames: List<String>.from(data['inviteNames'] ?? []),
        );

      }).toList();
    });
  }

  /// 📩 Send task invites to multiple friends
  static Future<Map<String, String>> sendTaskInviteToFriends({
    required List<String> friendIds,
    required String senderId,
    required String senderName,
    required Map<String, dynamic> taskData,
  }) async {
    Map<String, String> inviteIdMap = {}; // recipientId -> inviteDocId

    for (final friendId in friendIds) {
      final inviteData = {
        ...taskData,
        'senderId': senderId,
        'senderName': senderName,
        'timestamp': FieldValue.serverTimestamp(),
      };

      print("📨 Sending to $friendId");

      final docRef = await _firestore
          .collection('users')
          .doc(friendId)
          .collection('Task_invites')
          .add(inviteData);

      inviteIdMap[friendId] = docRef.id; // ✅ store the doc ID
    }

    return inviteIdMap; // ✅ you can now use this to attach to confirmation cards later
  }



  /// 🧾 Fetch first and last name from Firestore by user ID
  static Future<String> getSenderFullName(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    final first = data?['firstName'] ?? '';
    final last = data?['lastName'] ?? '';
    return '$first $last';
  }

  /// ✅ Add a response to an invite
  static Future<void> sendResponseToInvite({
    required String senderId,
    required String senderName, // 👈 NEW
    required String inviteId,
    required String recipientId,
    required String status,     // 'accepted', 'rejected', 'suggested'
    required String message,
  }) async {
    final responseRef = _firestore
        .collection('users')
        .doc(senderId) // senderId is the host’s UID
        .collection('Task_invites')
        .doc(inviteId)
        .collection('responses')
        .doc(recipientId); // this is the accepting user (i.e., current user)

    await responseRef.set({
      'status': status,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': recipientId,      // 👈 Add accepting user’s ID
      'senderName': senderName,     // 👈 Add accepting user’s name
    });
  }


  /// 📆 Add accepted invite to recipient's calendar
  static Future<void> addInviteToRecipientCalendar({
    required String recipientId,
    required Map<String, dynamic> taskData,
  }) async {
    await _firestore
        .collection('users')
        .doc(recipientId)
        .collection('tasks')
        .add(taskData);
  }


  /// 🟩 Add a confirmation card to the original sender when an invite is accepted
  static Future<void> sendConfirmationCardToSender({
    required String senderId,
    required String recipientName,
    required Map<String, dynamic> taskData,
    required String message,
    required String inviteId,
    required String recipientId, // ✅ NEW
    required String status,
  }) async {
    final confirmationCard = {
      'type': 'confirmation',
      'title': taskData['title'] ?? 'Untitled',
      'eventDate': taskData['eventDate'] ?? FieldValue.serverTimestamp(),
      'time': taskData['time'] ?? 'Unknown',
      'location': taskData['location'] ?? 'none',
      'categoryEmoji': taskData['categoryEmoji'] ?? '',
      'moodEmoji': taskData['moodEmoji'] ?? '',
      'borderColor': taskData['borderColor'] ?? 'FFFFFFFF',
      'senderName': recipientName,
      'message': message,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),

      // ✅ Store this metadata for future lookup
      'inviteId': inviteId,
      'recipientId': recipientId,
    };

    await _firestore
        .collection('users')
        .doc(senderId)
        .collection('Task_invites')
        .add(confirmationCard);

    print("📤 Sent confirmation card with correct invite + recipient metadata");
  }



  /// 📬 Post a card to the public board
  static Future<void> postCardToBoard(Map<String, dynamic> cardData) async {
    final boardRef = _firestore.collection('boardcards').doc(); // Auto-ID
    final eventDate = cardData['eventDate'] as Timestamp;
    print("Event Date: $eventDate");
    print("📬 postCardToBoard() called with: ${cardData['title']}");
    final expiresAt = eventDate.toDate().add(const Duration(hours: 24));

    final boardCard = {
      ...cardData,
      'boardcardId': boardRef.id,                      // For future deletion
      'timestamp': FieldValue.serverTimestamp(),       // For sorting
      'expiresAt': Timestamp.fromDate(expiresAt),      // For TTL auto-deletion
    };
    print("📌 Writing boardcard ID ${boardRef.id} with timestamp...");

    await boardRef.set(boardCard);
    print("📌 Board card posted with ID: ${boardRef.id}");
  }


  /// 🔄 Get recent (non-expired) boardcards from Firestore
  static Future<List<BoardCardModel>> getRecentBoardCards() async {
    final now = Timestamp.now();

    final snapshot = await _firestore
        .collection('boardcards')
        .where('expiresAt', isGreaterThan: now)
        .orderBy('timestamp', descending: true)
        .orderBy('expiresAt') // 👈 Add this
        .limit(10)
        .get();


    return snapshot.docs.map((doc) => BoardCardModel.fromMap(doc.data())).toList();
  }


  static Future<void> sendJoinRequestToHost({
    required String boardcardId,
    required String hostId,
    required String requesterId,
    required String requesterName,
    required Map<String, dynamic> boardcardData,
  }) async {
    final joinRequest = {
      'type': 'join_request',
      'boardcardId': boardcardId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'timestamp': FieldValue.serverTimestamp(),

      // Copy these fields so host sees what they're accepting
      'title': boardcardData['title'] ?? 'Untitled',
      'eventDate': boardcardData['eventDate'],
      'time': boardcardData['time'],
      'location': boardcardData['location'] ?? 'none',
      'categoryEmoji': boardcardData['categoryEmoji'] ?? '',
      'moodEmoji': boardcardData['moodEmoji'] ?? '',
      'borderColor': boardcardData['borderColor'] ?? 'FFFFFFFF',
    };

    await _firestore
        .collection('users')
        .doc(hostId)
        .collection('Task_invites')
        .add(joinRequest);

    print("📩 Join request sent from $requesterName to host $hostId for boardcard $boardcardId");
  }



  static Future<void> acceptJoinRequest({
    required String hostId,
    required String joinRequestDocId,
    required String requesterId,
    required String requesterName,
    required String boardcardId,
  }) async {
    // 1. Get the boardcard
    final boardRef = _firestore.collection('boardcards').doc(boardcardId);
    final boardSnap = await boardRef.get();

    if (!boardSnap.exists || boardSnap.data() == null) {
      print("❌ Boardcard $boardcardId not found.");
      return;
    }

    final boardData = boardSnap.data()!;

// ✅ SAFELY extract all fields
    final title = boardData['title'] ?? 'Untitled';
    final eventDate = boardData['eventDate'] as Timestamp? ?? Timestamp.now();
    final time = boardData['time'] ?? 'Unknown';
    final location = boardData['location'] ?? 'none';
    final categoryEmoji = boardData['categoryEmoji'] ?? '';
    final moodEmoji = boardData['moodEmoji'] ?? '';
    final borderColor = boardData['borderColor'] ?? 'FFFFFFFF';
    final senderName = boardData['senderName'] ?? 'Someone';
    final invited = List<String>.from(boardData['invitedPeople'] ?? []);


    // 2. Update invitedPeople on the boardcard
    if (!invited.contains(requesterName)) {
      invited.add(requesterName);
      await boardRef.update({'invitedPeople': invited});
    }

    // 3. Send ✅ confirmation card to requester
    await _firestore
        .collection('users')
        .doc(requesterId)
        .collection('Task_invites')
        .add({
      'type': 'confirmation',
      'title': title,
      'eventDate': eventDate,
      'time': time,
      'location': location,
      'categoryEmoji': categoryEmoji,
      'moodEmoji': moodEmoji,
      'borderColor': borderColor,
      'senderName': senderName, // the host
      'message': '', // optional
      'status': 'accept',
      'timestamp': FieldValue.serverTimestamp(),
      'inviteNames': invited, // Include updated people list
    });

    // 4. Add task to requester’s calendar
    await _firestore
        .collection('users')
        .doc(requesterId)
        .collection('tasks')
        .add({
      'title': title,
      'date': eventDate.toDate().toString().split(' ')[0],
      'time': time,
      'category': boardData['category'] ?? 'Social',
      'priority': 'Medium',
      'user_mood': 'Neutral',
      'relationship': 'Friend',
      'location': boardData['location'] ?? 'none',
      'floating': false,
      'recurring': 'none',
      'intent': '',
      'people': invited,
      'invitedUserIds': [],
      'inviteNames': invited,
    });


    // 5. Delete the original join request
    await _firestore
        .collection('users')
        .doc(hostId)
        .collection('Task_invites')
        .doc(joinRequestDocId)
        .delete();

    print("✅ Join request accepted: $requesterName added to $boardcardId");
  }



  static Future<void> createGroupEvent({
    required String eventId,
    required String hostId,
    required List<String> participantIds,
    required String title,
    required String date,      // format: 'YYYY-MM-DD'
    required String time,      // format: 'HH:mm'
    required String location,  // e.g. 'none' if empty
    required String source,    // 'invite' or 'board'
  }) async {
    // Parse date + time into DateTime
    final DateTime eventDateTime = DateTime.parse('$date $time');

    // Add 24 hours for expiry
    final Timestamp expiresAt = Timestamp.fromDate(eventDateTime.add(Duration(hours: 24)));

    final docData = {
      'eventId': eventId,
      'hostId': hostId,
      'participantIds': participantIds,
      'chatId': null,
      'title': title,
      'date': date,
      'time': time,
      'location': location,
      'source': source,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt,
    };

    await _firestore.collection('groupEvents').doc(eventId).set(docData);
    print("✅ groupEvents doc created for $eventId");


  }


  static Future<void> handleGroupEventChatJoin({
    required String eventId,
    required String currentUserId,
    required String currentUserName,
  }) async {
    final docRef = _firestore.collection('groupEvents').doc(eventId);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      print('❌ groupEvents/$eventId not found');
      return;
    }

    print('📨 Running handleGroupEventChatJoin for $eventId');

    final data = docSnap.data()!;
    final chatId = data['chatId'];
    final participantIds = List<String>.from(data['participantIds'] ?? []);

    if (!participantIds.contains(currentUserId)) {
      print('🚫 User $currentUserId is not a participant of this group event.');
      return;
    }

    String finalChatId = ''; // 👈 Track the actual chatId used

    if (chatId == null) {
      final latestDoc = await docRef.get();
      final latestData = latestDoc.data();
      final latestChatId = latestData?['chatId'];

      if (latestChatId == null) {
        final newChatRef = await _firestore.collection('groupChats').add({
          'createdAt': Timestamp.now(),
          'eventId': eventId,
          'participantIds': [currentUserId],
          'messages': [],

          // ✅ Core metadata
          'title': data['title'] ?? 'Untitled',
          'date': data['date'] ?? '',  // use string date like '2025-11-01'
          'time': data['time'] ?? 'Unknown',
          'location': data['location'] ?? 'none',

          // ✅ New: display + sorting metadata
          'lastMessage': 'Group chat started',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'readTimestamps': {
            currentUserId: FieldValue.serverTimestamp(),
          },
        });



        finalChatId = newChatRef.id; // ✅ assigned here
        await docRef.update({'chatId': finalChatId});
        print('💬 Created new chat: $finalChatId');

      } else {
        finalChatId = latestChatId; // ✅ assigned here
        final chatRef = _firestore.collection('groupChats').doc(finalChatId);
        await chatRef.update({
          'participantIds': FieldValue.arrayUnion([currentUserId]),
        });
        print('👥 Chat already created. Added $currentUserId to chat $finalChatId');
      }

    } else {
      finalChatId = chatId; // ✅ assigned here
      final chatRef = _firestore.collection('groupChats').doc(finalChatId);
      await chatRef.update({
        'participantIds': FieldValue.arrayUnion([currentUserId]),
      });
      print('👥 Added $currentUserId to chat $finalChatId');
    }

    // ✅ This is now guaranteed to use a non-null, correct chat ID
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('user_chats')
        .doc(finalChatId)
        .set({
      'chatId': finalChatId,
      'joinedAt': Timestamp.now(),
      'lastOpened': null,
      'muted': false,
      'pinned': false,
    });
    print('📌 Synced user_chats for $currentUserId');
    print('📥 Writing to: users/$currentUserId/user_chats/$finalChatId');
  }






  static Future<void> linkUserToGroupEvent({
    required String userId,
    required String eventId,
  }) async {
    final eventDoc = await FirebaseFirestore.instance
        .collection('groupEvents')
        .doc(eventId)
        .get();

    if (!eventDoc.exists) {
      print('❌ GroupEvent not found for $eventId');
      return;
    }

    final expiresAt = eventDoc.data()?['expiresAt'];

    final userLinkRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('group_event_links')
        .doc(eventId);

    await userLinkRef.set({
      'eventId': eventId,
      'expiresAt': expiresAt,
      'timestamp': FieldValue.serverTimestamp(), // optional for sorting
    });

    print('✅ Linked user $userId to groupEvent $eventId');
  }


}
