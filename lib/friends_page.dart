import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // Only if buildAppBar is declared in main.dart
import 'utils/task_invite_card.dart';
import '../groupchats/chat_list_page.dart';


class FriendsPage extends StatefulWidget {
  final String? firstName;
  final String userId;

  const FriendsPage({this.firstName, required this.userId});

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<Map<String, dynamic>> allFriends = [];
  List<Map<String, dynamic>> filteredFriends = [];
  bool isSearching = false;
  String searchQuery = '';
  Set<String> newlyAddedFriendIds = {};
  Map<String, String> friendNicknames = {};
  List<Map<String, dynamic>> userFriends = [];
  List<Map<String, dynamic>> friendsList = [];
  List<Map<String, dynamic>> incomingRequests = [];
  List<Map<String, dynamic>> addedMeUsers = [];




  Set<String> currentFriendIds = {}; // Store IDs of friends you already added

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchFriends();
      fetchNicknames();
      fetchIncomingRequests();
      fetchAddedMe();
    });
  }

  Future<void> fetchAddedMe() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final now = Timestamp.now();

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('friend_accepts')
        .where('expiresAt', isGreaterThan: now)         // ✅ filter non-expired
        .orderBy('timestamp', descending: true)         // ✅ newest first
        .get();

    if (snapshot.docs.isEmpty) {
      setState(() => addedMeUsers = []);
      return;
    }

    final friendIds = snapshot.docs.map((doc) => doc.id).toList();

    final userDocs = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendIds)
        .get();

    // Maintain original order from the sorted snapshot
    final userMap = {for (var doc in userDocs.docs) doc.id: doc.data()};

    setState(() {
      addedMeUsers = friendIds
          .where((id) => userMap.containsKey(id))
          .map((id) {
        final data = userMap[id]!;
        return {
          'id': id,
          'firstName': data['firstName'],
          'lastName': data['lastName'],
          'userTag': data['userTag'] ?? '',
        };
      })
          .toList();
    });
  }




  Future<void> fetchIncomingRequests() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final requestSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('friend_requests_received')
        .get();

    final requesterIds = requestSnapshot.docs.map((doc) => doc.id).toList();

    if (requesterIds.isEmpty) {
      setState(() => incomingRequests = []);
      return;
    }

    final userDocs = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: requesterIds)
        .get();

    setState(() {
      incomingRequests = userDocs.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'firstName': data['firstName'],
          'lastName': data['lastName'],
          'userTag': data['userTag'] ?? '',
        };
      }).toList();
    });
  }


  void fetchFriends() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    final friendSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .get();

    final friendIds = friendSnapshot.docs.map((doc) => doc.id).toSet();

    // Exclude self
    final filtered = snapshot.docs.where((doc) => doc.id != currentUserId).toList();
    print("🧾 Total other users (excluding self): ${filtered.length}");

    // Convert all user docs into usable maps
    final all = filtered.map((doc) => {
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
      'uid': doc.id,
    }).toList();

    // ✅ Extract actual friends from full user list
    final friendList = all.where((user) => friendIds.contains(user['id'])).toList();

    setState(() {
      allFriends = all;
      filteredFriends = allFriends;
      currentFriendIds = friendIds;
      userFriends = friendList;
      friendsList = friendList; // ✅ Make sure both are synced
    });

    print("✅ friendsList populated: ${friendsList.length} friends");
    for (var f in friendsList) {
      print("🔸 ${f['firstName']} ${f['lastName']} (${f['id']})");
    }
  }




  void fetchNicknames() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .get();

    setState(() {
      friendNicknames = {
        for (var doc in snapshot.docs)
          doc.id: doc.data()['nickname'] ?? ''
      };
    });
  }






  void updateSearch(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      searchQuery = query;
      filteredFriends = allFriends.where((friend) {
        final fullName = (friend['firstName'] + ' ' + friend['lastName']).toLowerCase();
        final uid = friend['id'];
        final nickname = friendNicknames[uid]?.toLowerCase() ?? '';
        final userTag = friend['userTag']?.toLowerCase() ?? '';

        return fullName.contains(lowerQuery) ||
            nickname.contains(lowerQuery) ||
            userTag.contains(lowerQuery);
      }).toList();
    });
  }



  void cancelSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      isSearching = false;
      searchQuery = '';
      searchController.clear();
      filteredFriends = allFriends; // ✅ Still needed for future searches
    });
  }


  Widget _buildFindFriendsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              if (!isSearching)
                IconButton(
                  icon: Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      isSearching = true;
                    });
                  },
                ),
              if (isSearching)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: updateSearch,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by name or email',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ),
              if (isSearching)
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: cancelSearch,
                )
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              // 🔹 Requests section (incoming friend requests)
              if (!isSearching && incomingRequests.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Requests",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ...incomingRequests.map((request) {
                        return ListTile(
                          title: Text(
                            '${request['firstName']} ${request['lastName']}',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: request['userTag'] != null && request['userTag'].toString().trim().isNotEmpty

                              ? Text(
                            '@${request['userTag']}',
                            style: TextStyle(color: Colors.grey),
                          )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.check, color: Colors.green),
                                onPressed: () => _acceptFriendRequest(request['id']),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed: () => _ignoreFriendRequest(request['id']),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              if (!isSearching && addedMeUsers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Added Me",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ...addedMeUsers.map((user) {
                        return ListTile(
                          title: Text(
                            '${user['firstName']} ${user['lastName']}',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: user['userTag'] != null && user['userTag'].toString().trim().isNotEmpty
                              ? Text('@${user['userTag']}', style: TextStyle(color: Colors.grey))
                              : null,
                          trailing: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              'Added You',
                              style: TextStyle(color: Colors.black, fontSize: 13),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),


              // 🔹 Find Friends list
              ...(isSearching ? filteredFriends : friendsList).map((friend) {
                final fullName = '${friend['firstName']} ${friend['lastName']}';
                final isFriend = currentFriendIds.contains(friend['id']);
                final isNewlyAdded = newlyAddedFriendIds.contains(friend['id']);

                return ListTile(
                  title: Text(
                    fullName,
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: (!isFriend && !isNewlyAdded)
                      ? AddButton(
                    friendId: friend['id'],
                    onRequestSent: () {
                      setState(() {
                        newlyAddedFriendIds.add(friend['id']);
                      });
                    },
                  )
                      : (isNewlyAdded
                      ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      'Requested',
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
                  )
                      : null),
                  onTap: () {
                    if (isFriend) {
                      showFriendDetailDialog(context, friend, friend['id']);
                    } else {
                      showPublicProfileDialog(context, friend); // 👈 new dialog for non-friends
                    }
                  },

                );
              }).toList(),
            ],
          ),
        ),

      ],
    );
  }


  void showFriendDetailDialog(BuildContext context, Map<String, dynamic> friendData, String friendId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final nicknameController = TextEditingController();

    // Fetch existing nickname from Firestore (if available)
    final nicknameSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .doc(friendId)
        .get();

    if (nicknameSnapshot.exists) {
      nicknameController.text = nicknameSnapshot.data()?['nickname'] ?? '';
    }
    print("Opening friend detail dialog for ${friendData['firstName']}");
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${friendData['firstName']} ${friendData['lastName']}",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              if (friendData['userTag'] != null)
                Text(
                  "@${friendData['userTag']}",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
            ],
          ),

          content: TextField(
            controller: nicknameController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Nickname",
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserId)
                    .collection('friends')
                    .doc(friendId)
                    .set({'nickname': nicknameController.text}, SetOptions(merge: true));
                Navigator.of(context).pop();
              },
              child: Text("Save", style: TextStyle(color: Colors.blue)),
            )
          ],
        );
      },
    );
  }

  void showPublicProfileDialog(BuildContext context, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          contentPadding: EdgeInsets.zero, // removes extra padding

          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // ✅ SHRINK-WRAPS vertically
            children: [
              Text(
                "${userData['firstName']} ${userData['lastName']}",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              if (userData['userTag'] != null && userData['userTag'].toString().trim().isNotEmpty)
                Text(
                  "@${userData['userTag']}",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              const SizedBox(height: 20),

              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/stamplogo.png',
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );

  }



  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: buildAppBar(context, 2, widget.firstName, widget.userId),
        body: Column(
          children: [
            TabBar(
              labelColor: Color(0xFFFFA500), // orange
              unselectedLabelColor: Colors.white,
              indicatorColor: Color(0xFFFFA500),
              tabs: const [
                Tab(text: 'Inbox'),
                Tab(text: 'Find Friends'),
                Tab(text: 'Round Robin'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildInboxTab(),
                  _buildFindFriendsTab(),
                  _buildMyCardsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInboxTab() {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('Task_invites')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final invites = snapshot.data!.docs;

        if (invites.isEmpty) {
          return const Center(
            child: Text("No invites yet", style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          itemCount: invites.length,
          itemBuilder: (context, index) {
            final inviteId = invites[index].id;
            final data = {
              ...invites[index].data() as Map<String, dynamic>,
              'id': inviteId,            // 👈 keep this for backward compatibility
              'inviteId': inviteId,      // 👈 explicitly add this for response logic
              'recipientId': FirebaseAuth.instance.currentUser?.uid,
            };

            print("🟨 invite doc ID: $inviteId");
            print("🟨 full data: ${invites[index].data()}");

            return TaskInviteCard(data: data);
          },
        );

      },
    );
  }


  Widget _buildMyCardsTab() {
    return ChatListPage(); // actual UI
  }

  Future<void> _acceptFriendRequest(String requesterId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // 1. Add each other to friends
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .doc(requesterId)
        .set({'addedAt': Timestamp.now()});

    await FirebaseFirestore.instance
        .collection('users')
        .doc(requesterId)
        .collection('friends')
        .doc(currentUserId)
        .set({'addedAt': Timestamp.now()});

    // 2. Remove friend request docs
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('friend_requests_received')
        .doc(requesterId)
        .delete();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(requesterId)
        .collection('friend_requests_sent')
        .doc(currentUserId)
        .delete();

    // 3. Add to their friend_accepts (for "Added Me")
    final now = DateTime.now();
    final expiresAt = Timestamp.fromDate(now.add(Duration(hours: 24)));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(requesterId)
        .collection('friend_accepts')
        .doc(currentUserId)
        .set({
      'timestamp': Timestamp.now(),
      'expiresAt': expiresAt, // 🔥 add this for TTL
    });


    // 4. Refresh lists
    fetchFriends();
    fetchIncomingRequests();
  }

  Future<void> _ignoreFriendRequest(String requesterId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // Remove request docs only
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('friend_requests_received')
        .doc(requesterId)
        .delete();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(requesterId)
        .collection('friend_requests_sent')
        .doc(currentUserId)
        .delete();

    // Refresh
    fetchIncomingRequests();
  }



}


class AddButton extends StatefulWidget {
  final String friendId;
  final VoidCallback onRequestSent;

  const AddButton({required this.friendId, required this.onRequestSent});

  @override
  State<AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<AddButton> {
  bool isRequested = false;

  @override
  void initState() {
    super.initState();
    checkIfAlreadyRequested();
  }

  Future<void> checkIfAlreadyRequested() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('friend_requests_sent')
          .doc(widget.friendId)
          .get();

      if (doc.exists) {
        setState(() {
          isRequested = true;
        });
      }
    }
  }

  Future<void> sendFriendRequest() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final now = Timestamp.now();

    if (currentUserId != null) {
      // Write to your "sent requests"
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('friend_requests_sent')
          .doc(widget.friendId)
          .set({'timestamp': now});

      // Write to their "received requests"
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.friendId)
          .collection('friend_requests_received')
          .doc(currentUserId)
          .set({'timestamp': now});

      widget.onRequestSent();

      setState(() {
        isRequested = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.75,
      child: TextButton(
        onPressed: isRequested ? null : sendFriendRequest,
        style: TextButton.styleFrom(
          backgroundColor: Colors.black,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
            side: BorderSide(color: Colors.grey),
          ),
        ),
        child: Text(
          isRequested ? 'Requested' : 'Add',
          style: TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}










