


import 'dart:math';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'utils/category_icons.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'services/database_helper.dart';
import 'registration_page.dart';
import 'services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'friends_page.dart';
import 'utils/full_screen_task_input.dart';
import '../models/task.dart';
import '../utils/mini_board_stack.dart';



import '../services/firestore_service.dart';
import '../utils/board_card_overlay_stack.dart'; // or wherever the file is
import '../models/board_card_model.dart';



Map<String, List<Map<String, dynamic>>> globalTasksByDate = {};
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NLP Calendar App',
      theme: ThemeData.dark(),
      navigatorKey: navigatorKey, // 👈 Add this line
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isHovered = false;
  String? usernameError;
  String? passwordError;
  String? loginError;

  Future<void> _handleLogin() async {
    // Reset errors
    setState(() {
      usernameError = null;
      passwordError = null;
      loginError = null;
    });

    // Validate fields
    bool hasError = false;
    if (usernameController.text.trim().isEmpty) {
      setState(() => usernameError = 'Username is required');
      hasError = true;
    }
    if (passwordController.text.isEmpty) {
      setState(() => passwordError = 'Password is required');
      hasError = true;
    }

    if (hasError) return;

    try {
      // 🔑 Log in and get credential
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: usernameController.text.trim(),
        password: passwordController.text,
      );

      final uid = credential.user!.uid;

      // 🔍 Load user profile from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final firstName = userDoc.data()?['firstName'] ?? 'User';

      // ✅ Pass userId and firstName forward
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(
            firstName: firstName,
            userId: uid,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Sign in failed. Please try again.';
      if (e.code == 'user-not-found') errorMsg = 'No user found for that email.';
      if (e.code == 'wrong-password') errorMsg = 'Incorrect password.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
      passwordController.clear();
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Image.asset(
                'assets/images/logoslogan.png',
                width: 400, // adjust size as needed
                height: 150,
              ),
              SizedBox(height: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: usernameController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter Username',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  if (usernameError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        usernameError!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter Password',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  if (passwordError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        passwordError!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8),
              if (loginError != null)
                Text(
                  loginError!,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 32),
              InkWell(
                onHover: (hover) {
                  setState(() => isHovered = hover);
                },
                onTap: () async {  // Make sure to make this async
                  await _handleLogin();  // Wait for the login process to complete
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isHovered ? Colors.white : Color(0xFFB8860B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'LOGIN',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Colors.white70, // subtle grey/white
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 40),
              Image.asset(
                'assets/images/stamplogo.png',
                width: 50, // adjust size as needed
                height: 50,
              ),
              SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegistrationPage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.black,
                    side: BorderSide(color: Color(0xFFB8860B), width: 2), // same gold as login
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'CREATE ACCOUNT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),



            ],
          ),
        ),
      ),
    );

  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

// AppBar builder for navigation
PreferredSizeWidget buildAppBar(BuildContext context, int currentIndex, String? firstName, String userId) {
  return AppBar(
    backgroundColor: Colors.black,
    elevation: 0,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(Icons.home, color: currentIndex == 0 ? Colors.orange : Colors.white),
          onPressed: () {
            if (currentIndex != 0) Navigator.push(context, MaterialPageRoute(builder: (_) => DashboardPage(firstName: firstName, userId: userId)));
          },
        ),
        IconButton(
          icon: Icon(Icons.calendar_today, color: currentIndex == 1 ? Colors.orange : Colors.white),
          onPressed: () {
            if (currentIndex != 1) Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarPage(firstName: firstName, userId: userId)));
          },
        ),
        IconButton(
          icon: Icon(Icons.group, color: currentIndex == 2 ? Colors.orange : Colors.white),
          onPressed: () {
            if (currentIndex != 2) Navigator.push(context, MaterialPageRoute(builder: (_) => FriendsPage(firstName: firstName, userId: userId)));
          },
        ),
      ],
    ),
  );
}




class LiveClockDisplay extends StatefulWidget {
  @override
  _LiveClockDisplayState createState() => _LiveClockDisplayState();
}

class _LiveClockDisplayState extends State<LiveClockDisplay> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // changed to start to match original
      children: [
        Text(
          DateFormat('EEEE').format(_currentTime), // e.g., "Saturday"
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMM\nd, y').format(_currentTime).toUpperCase(), // e.g., "JUL\n20, 2025"
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('h:mm\na').format(_currentTime).toUpperCase(), // e.g., "11:48\nAM"
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}




// Dashboard Page
class DashboardPage extends StatefulWidget {
  final String? firstName; // Optional parameter
  final String userId;

  const DashboardPage({this.firstName, required this.userId});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Color _parseHexColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'ff$hex'; // Add opacity if missing
    return Color(int.parse(hex, radix: 16));
  }


  void _loadTasks() async {
    try {
      final tasks = await FirestoreService.getAllTasks();
      final random = Random();

      // Assign a color to each task ONCE when loaded
      final coloredTasks = <String, List<Map<String, dynamic>>>{};
      for (final date in tasks.keys) {
        coloredTasks[date] = (tasks[date]! as List<Map<String, dynamic>>).map((task) {
          return {
            ...task,
            'color': colors[random.nextInt(colors.length)],
          };
        }).toList();

      }

      setState(() {
        globalTasksByDate = coloredTasks;
      });
    } catch (e) {
      print("Error loading tasks in dashboard: $e");
    }
  }


  @override
  void dispose() {
    super.dispose();
  }



  final List<Color> colors = [
    Colors.red.shade300,
    Colors.green.shade300,
    Colors.purple.shade300,
  ];

  @override
  Widget build(BuildContext context) {
    print("👤 DashboardPage firstName: ${widget.firstName}");
    final today = DateTime.now();
    final todayKey = today.toIso8601String().split('T')[0];


    return Scaffold(
      backgroundColor: Colors.black,
      drawer: AppDrawer(), // 👈 new drawer
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: HamburgerIcon(),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home, color: Colors.orange),
              onPressed: () {}, // already on Dashboard
            ),
            IconButton(
              icon: Icon(Icons.calendar_today, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CalendarPage(
                      firstName: widget.firstName,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.group, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FriendsPage(
                      firstName: widget.firstName,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LiveClockDisplay(),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/boardcards.png',
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 210, // previously auto height — now taller
                    fit: BoxFit.contain, // keep proportions without stretching
                  ),
                  Positioned(
                    bottom: 55,
                    right: 45, // NEW: push it more to the right
                    child: Container(
                      width: 155, // smaller width
                      height: 107, // slightly smaller height
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: GestureDetector(
                        onTap: () async {
                          final boardCards = await FirestoreService.getRecentBoardCards();
                          print("🧩 Loaded ${boardCards.length} boardcards");
                          if (boardCards.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BoardCardOverlayStack(cards: boardCards),
                                fullscreenDialog: true,
                              ),
                            );
                          } else {
                            // optional: show a snack if there are no board cards
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('No board cards to display')),
                            );
                          }
                        },
                        child: MiniBoardStack(),
                      ),

                    ),
                  ),

                ],
              ),
            ),

            Text("Today's Agenda",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .collection('tasks')
                    .where('date', isEqualTo: todayKey)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "You are totally free today",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  }

                  final List<Map<String, dynamic>> tasks = snapshot.data!.docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .toList();

                  tasks.sort((a, b) {
                    final timeA = _parseTime(a['time']);
                    final timeB = _parseTime(b['time']);
                    return timeA.compareTo(timeB);
                  });


                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      print("🟡 Task: $task");

                      final borderHexRaw = task['borderColorHex'];
                      print("🟣 Raw borderColor: $borderHexRaw");
                      final borderHex = borderHexRaw is String ? borderHexRaw : '#ffffffff';
                      final borderColor = _parseHexColor(borderHex);



                      return Card(
                        color: Colors.black,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: borderColor, width: 2),
                        ),
                        child: ListTile(
                          title: Text(
                            task['title'] ?? '',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          trailing: Text(
                            _formatTimeAMPM(task['time']),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18, // 👈 increase this to make it more readable
                              fontWeight: FontWeight.w500, // optional: makes it a bit bolder
                            ),
                          ),


                        ),
                      );

                    },
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }

  //  to Reuse the _parseTime function from CalendarPage
  DateTime _parseTime(String? timeString) {
    final now = DateTime.now();

    if (timeString == null || timeString.isEmpty) {
      // Default to midnight for invalid or missing time
      return DateTime(now.year, now.month, now.day, 0, 0);
    }

    // Ensure a consistent format: Add a colon and space if missing
    final regex = RegExp(r'^(\d{1,2})(:\d{2})?\s?(AM|PM|am|pm)?$');
    final match = regex.firstMatch(timeString);

    if (match == null) {
      // If the format is invalid, default to midnight
      print("Invalid time format: $timeString");
      return DateTime(now.year, now.month, now.day, 0, 0);
    }

    // Extract hours, minutes, and period (AM/PM)
    int hour = int.tryParse(match.group(1)!) ?? 0;
    int minute = int.tryParse(match.group(2)?.substring(1) ?? '0') ?? 0;
    String period = (match.group(3) ?? '').toLowerCase();

    // Convert to 24-hour format
    if (period == 'pm' && hour != 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;

    final parsedTime = DateTime(now.year, now.month, now.day, hour, minute);
    print("Parsed time for $timeString: $parsedTime");
    return parsedTime;
  }

  String _formatTimeAMPM(String? time24) {
    if (time24 == null || time24.isEmpty) return '';
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(0, 1, 1, hour, minute);
      return DateFormat.jm().format(dt); // e.g., "2:20 PM"
    } catch (e) {
      print("⚠️ Failed to format time: $time24");
      return time24;
    }
  }


}

class HamburgerIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 20, height: 2, color: Colors.white),
        SizedBox(height: 4),
        Container(width: 15, height: 2, color: Colors.white),
        SizedBox(height: 4),
        Container(width: 10, height: 2, color: Colors.white),
      ],
    );
  }
}

class AppDrawer extends StatefulWidget {
  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _showProfileInfo = false;
  Map<String, dynamic>? _userDetails;

  void _toggleProfileInfo() async {
    setState(() {
      _showProfileInfo = !_showProfileInfo;
    });

    if (_showProfileInfo && _userDetails == null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userData = await DatabaseHelper.instance.getUserDetails(uid);
        if (mounted) {
          setState(() {
            _userDetails = userData;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    final firstName = _userDetails?['firstName'] ?? '';
    final lastName = _userDetails?['lastName'] ?? '';
    final email = _userDetails?['email'] ?? '';
    final userTag = _userDetails?['userTag'] ?? '';


    return Drawer(
      backgroundColor: Colors.grey[900],
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        children: [
          // Toggleable "My Profile" row
          GestureDetector(
            onTap: _toggleProfileInfo,
            child: Container(
              color: _showProfileInfo ? Colors.black : Colors.transparent,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text(
                'My Profile',
                style: TextStyle(
                  color: _showProfileInfo ? Colors.white : Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Profile info (only shown when toggled on)
          if (_showProfileInfo)
            Container(
              margin: EdgeInsets.only(top: 8, bottom: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _userDetails == null
                  ? Center(child: CircularProgressIndicator(color: Colors.orange))
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$firstName $lastName',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  SizedBox(height: 4),
                  Text(email,
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  SizedBox(height: 4),
                  Text(userTag,
                      style: TextStyle(color: Colors.orange, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('User ID: $uid',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),

          // Settings
          DrawerItem(label: 'Settings', onTap: () {
            Navigator.pop(context); // Placeholder
          }),

          // Logout
          DrawerItem(label: 'Logout', onTap: () {
            Navigator.pop(context);
            _showLogoutDialog();
          }),
        ],
      ),
    );
  }
}


class DrawerItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const DrawerItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: TextStyle(color: Colors.white, fontSize: 18)),
      onTap: onTap,
    );
  }
}



class CalendarPage extends StatefulWidget {
  final String? firstName; // Optional parameter
  final String userId;

  const CalendarPage({this.firstName, required this.userId});
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int? _selectedTaskIndex; // Track the selected task index
  List<Map<String, dynamic>> userFriends = [];

  @override
  void initState() {
    super.initState();
    fetchFriendsForTaskInput().then((friends) {
      setState(() {
        userFriends = friends;
      });
      print("📥 Loaded ${friends.length} friends into CalendarPage");
    });
  }


  void _addTask(Map<String, dynamic> task) {
    final date = task['date'];

    if (globalTasksByDate[date] == null) {
      globalTasksByDate[date] = [];
    }

    setState(() {
      // ✅ Check if the task already exists (edit case)
      final existingIndex = globalTasksByDate[date]!
          .indexWhere((t) => t['id'] == task['id']);

      if (existingIndex != -1) {
        // Replace the existing task
        globalTasksByDate[date]![existingIndex] = task;
      } else {
        // Add new task
        globalTasksByDate[date]!.add(task);
      }
    });
  }



  List<Map<String, dynamic>> _getTasksForDate(String date) {
    final tasks = List<Map<String, dynamic>>.from(globalTasksByDate[date] ?? []);

    print("Before Sorting: $tasks");

    tasks.sort((a, b) {
      final timeA = _parseTime(a['time']);
      final timeB = _parseTime(b['time']);

      // Compare times directly
      final comparisonResult = timeA.compareTo(timeB);
      print("Comparing $timeA and $timeB: $comparisonResult");
      return timeA.compareTo(timeB);
    });


    print("After Sorting: $tasks"); // done

    return tasks; //
  }


  DateTime _parseTime(String? timeString) {
    final now = DateTime.now();

    if (timeString == null || timeString.isEmpty) {
      // Default to midnight for invalid or missing time
      return DateTime(now.year, now.month, now.day, 0, 0);
    }

    // Ensure a consistent format: Add a colon and space if missing
    final regex = RegExp(r'^(\d{1,2})(:\d{2})?\s?(AM|PM|am|pm)?$');
    final match = regex.firstMatch(timeString);

    if (match == null) {
      // If the format is invalid, default to midnight
      print("Invalid time format: $timeString");
      return DateTime(now.year, now.month, now.day, 0, 0);
    }

    // Extract hours, minutes, and period (AM/PM)
    int hour = int.tryParse(match.group(1)!) ?? 0;
    int minute = int.tryParse(match.group(2)?.substring(1) ?? '0') ?? 0;
    String period = (match.group(3) ?? '').toLowerCase();

    // Convert to 24-hour format
    if (period == 'pm' && hour != 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;

    final parsedTime = DateTime(now.year, now.month, now.day, hour, minute);
    print("Parsed time for $timeString: $parsedTime");
    return parsedTime;
  }






  void _openEnterTaskCard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnterTaskCard(
          onTaskAdded: _addTask,
          userId: widget.userId,
          userFriends: userFriends,
        ),
      ),
    );
  }



  // Update the existing _deleteTask method in _CalendarPageState
  void _deleteTask(String date, int index) async {
    try {
      // Get the task before removing it from the map
      final task = globalTasksByDate[date]![index];

      // Delete from database
      await DatabaseHelper.instance.deleteTask(
          date,
          task['title'],
          task['time'],
          widget.userId,
      );

      // Delete from map (your existing logic)
      setState(() {
        globalTasksByDate[date]?.removeAt(index);
        if (globalTasksByDate[date]?.isEmpty ?? false) {
          globalTasksByDate.remove(date);
        }
      });
    } catch (e) {
      print('Error deleting task: $e');
      // Optionally show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete task. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  final _random = Random();

  IconData _getRandomIconForCategory(String? category) {
    if (category == null || category.isEmpty) return Icons.help_outline;

    // Normalize: capitalize first letter
    final normalized = category[0].toUpperCase() + category.substring(1).toLowerCase();

    final icons = categoryIcons[normalized] ?? [Icons.help_outline];
    return icons[_random.nextInt(icons.length)];
  }



  @override
  Widget build(BuildContext context) {
    print("📅 CalendarPage firstName: ${widget.firstName}");

    final selectedDate = _selectedDay ?? _focusedDay;
    final formattedDate = _selectedDay != null
        ? DateFormat('MMM d, y').format(_selectedDay!) // Format date as "Dec 5, 2024"
        : "Select a date";


    final taskDateKey = selectedDate.toIso8601String().split('T')[0];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: buildAppBar(context, 1, widget.firstName, widget.userId), // Use the shared AppBar builder
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                defaultTextStyle: TextStyle(color: Colors.white),
                weekendTextStyle: TextStyle(color: Colors.white),
                todayDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.white60),
                weekendStyle: TextStyle(color: Colors.white60),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                "What's the Plan, ${widget.firstName}?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              color: Colors.grey.shade900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate, // Use the formatted date
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    StreamBuilder<List<Task>>(
                      stream: FirestoreService.getTasksStreamByDate(widget.userId, taskDateKey),
                      builder: (context, snapshot) {
                        final count = snapshot.hasData ? snapshot.data!.length : 0;
                        return Text(
                          "$count Tasks",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 16,
                          ),
                        );
                      },
                    ),

                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Task>>(
                stream: FirestoreService.getTasksStreamByDate(widget.userId, taskDateKey),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final tasks = snapshot.data ?? [];
                  print('📋 All tasks from Firestore:');
                  for (final task in tasks) {
                    print('- ${task.title}, date: ${task.date}');
                  }


                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        "No tasks for this date.",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  tasks.sort((Task a, Task b) {
                    final timeA = _parseTime(a.time ?? '00:00');
                    final timeB = _parseTime(b.time ?? '00:00');
                    return timeA.compareTo(timeB);
                  });





                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final rawCategory = task.category?.trim() ?? 'Other';

// Ensure the category key exists in the map after normalization
                      String normalizedKey;
                      if (rawCategory.isEmpty) {
                        normalizedKey = 'Other';
                      } else {
                        normalizedKey = rawCategory[0].toUpperCase() + rawCategory.substring(1).toLowerCase();
                      }

// Use built-in Flutter icons (like Icons.work, Icons.school, etc.)
                      final icons = categoryIcons[normalizedKey] ?? [Icons.miscellaneous_services];
                      final iconData = icons[Random().nextInt(icons.length)];
                      final icon = Icon(iconData, color: Colors.white);

                      final isSelected = _selectedTaskIndex == index;

// Debug prints
                      print('🔍 Task title: ${task.title}');
                      print('🔍 Task raw category: ${task.category}');
                      print('🔍 Normalized key: $normalizedKey');
                      print('🔍 Icon codePoint: U+${iconData.codePoint.toRadixString(16).toUpperCase()}');
                      print('🔍 Icon fontFamily: ${iconData.fontFamily}');


                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTaskIndex = isSelected ? null : index;
                          });
                        },
                        onLongPress: () {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.userId)
                              .collection('tasks')
                              .doc(task.id)
                              .delete();
                        },
                        child: Card(
                          color: isSelected ? Colors.orange.shade700 : Colors.grey.shade900,
                          child: ListTile(
                            leading: Icon(iconData, color: Colors.white),
                            title: Text(task.title, style: TextStyle(color: Colors.white)),
                            subtitle: Text(task.time, style: TextStyle(color: Colors.white60)),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),


          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEnterTaskCard,
        backgroundColor: Colors.orange.shade700,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}



void _showLogoutDialog() {
  showDialog(
    context: navigatorKey.currentContext!,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.black,
      title: Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white)),
      actions: [
        TextButton(
          child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        TextButton(
          child: Text('Yes', style: TextStyle(color: Colors.red)),
          onPressed: () async {
            print("👋 Logging out...");
            await FirebaseAuth.instance.signOut();

            Navigator.of(ctx).pop(); // Close dialog

            navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => LoginPage()),
                  (route) => false,
            );
          },
        ),
      ],
    ),
  );
}

Future<List<Map<String, dynamic>>> fetchFriendsForTaskInput() async {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null) return [];

  final friendSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('friends')
      .get();

  final friendIds = friendSnapshot.docs.map((doc) => doc.id).toSet();

  final allUsersSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .get();

  final allUsers = allUsersSnapshot.docs.map((doc) => {
    ...doc.data() as Map<String, dynamic>,
    'uid': doc.id,
  }).toList();

  final actualFriends = allUsers
      .where((user) => friendIds.contains(user['uid']))
      .map((user) {
    final nicknameDoc = friendSnapshot.docs
        .where((doc) => doc.id == user['uid'])
        .toList();

    final nickname = nicknameDoc.isNotEmpty
        ? nicknameDoc.first.data()['nickname'] ?? ''
        : '';

    return {
      ...user,
      'nickname': nickname,
    };
  }).toList();


  return actualFriends;
}









