import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import '/services/firestore_service.dart';


final Random _random = Random();

const highPriorityColors = [
  Colors.red,
  Color(0xFF8B0000), // Dark red
  Color(0xFFAA336A), // Reddish purple
  Color(0xFF800000), // Maroon
];

const mediumPriorityColors = [
  Colors.orange,
  Color(0xFFCD853F), // Light brown
  Color(0xFF8B4513), // Darker brown (SaddleBrown)
];

const lowPriorityColors = [
  Color(0xFF0077B6), // Dark blue
  Color(0xFF61C3F2), // Light blue
  Color(0xFF9B5DE5), // purple
  Color(0xFFFFFFFF) //white
];

final Map<String, List<String>> categoryEmojis = {
  'Food': [
    '🍕', '🍔', '🍜', '🍣', '🍎', '🥗', '🌮', '🍩', '🍪', '🥘'
  ],
  'Social': [
    '🎉', '🗣️', '👯', '📞', '🍻', '🕺', '💃', '👫', '🥂', '🤝'
  ],
  'School': [
    '📚', '📝', '🏫', '📖', '✏️', '🧠', '📓', '📎', '🧑‍🏫', '🎓'
  ],
  'Work': [
    '💼', '🖥️', '📊', '📅', '📈', '🧑‍💼', '📋', '🗂️', '✉️', '🕴️'
  ],
  'Chore': [
    '🧹', '🧺', '🧽', '🗑️', '🛒', '🪣', '🧼', '🪠', '🪜', '🧯'
  ],
  'Health': [
    '💊', '🩺', '🏥', '🧘', '🦷', '🧬', '🛌', '🩻', '🩹', '💉'
  ],
  'Exercise': [
    '🏃', '🏋️', '🤸', '🚴', '⛹️', '🏊', '🧘', '🤼', '🥊', '🏌️'
  ],
  'Religion': [
    '⛪', '🕌', '🕍', '🙏','✝️'
  ],
  'Entertainment': [
    '🎬', '🎮', '🎵', '🎭', '📺', '🎧', '🎤', '📀', '🕹️', '📼'
  ],
  'Shopping': [
    '🛍️', '🛒', '💸', '🧾', '👗', '👠', '👜', '🧥', '💳', '🎁'
  ],
  'Travel': [
    '✈️', '🚗', '🧳', '🚆', '🗺️', '🚢', '⛺', '🏕️', '🏝️', '🏨'
  ],
};



final Map<String, List<String>> moodEmojis = {
  'Happy': ['😀','😄','😁','😃','😆','😊','🤗','😇','🤩','✨'],
  'Sad': ['😞','😔','😟','😢','😭','😿','🥺','🙁','😩','😓','😕','🫤','💔','🥀','😣','😖','😫','☹️'],
  'Excited': ['🤩','🥳','🎉','😆','😄','🔥','💃','🕺','💥','💫','😃','⚡','🙌','🎈','🤘','🚀','🧨','🌟'],
  'Stressed': ['😰','😱','😨','😥','😫','😩','😖','🥵','🥶','😓','🤯','😤','🤬','😣'],
  'Tired': ['😴','🥱','😪','😫','😓','😩','💤','😵','😥','🛌','🧘','😕','😟','🙄','🤯','😔','🌙','😵‍💫'],
  'Relaxed': ['😌','😊','🌿','🌊','🧘','😇','💆','😴','🍃','🌅','😎','☀️'],
  'Motivated': ['💪','🔥','🚀','⚡','🏋️','🧠','🙌','🎯','🏆','🤜🤛','👊','📈','🤩','🏅','🧗'],
  'Anxious': ['😬','😟','😰','😨','😥','🥺','😖','😓','🫣','🫨','💦','🤯','🥶','🤐','😧','😩'],
  'Caring': ['🥰','🤗','❤️','💖','💞','💕','🫶','😇','🌷','🎁','🫂','🐶','💐','🤎','💌','🫰'],
};



class TaskPreviewCard extends StatefulWidget {
  final String title;
  final String date;
  final String time;
  final String category;
  final String priority;
  final String userMood;
  final String relationship;
  final String location;
  final bool postToBoard;
  final String recurring;
  final bool floating;
  final String intent;
  final List<dynamic> people;
  final String userId;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onTaskSaved;
  final Map<String, dynamic>? task;
  final List<Map<String, dynamic>> userFriends;


  const TaskPreviewCard({
    Key? key,
    required this.userId,
    required this.title,
    required this.date,
    required this.time,
    required this.category,
    required this.priority,
    required this.userMood,
    required this.relationship,
    required this.location,
    required this.recurring,
    required this.floating,
    required this.intent,
    required this.people,
    required this.onClose,
    required this.onTaskSaved,
    required this.postToBoard,
    required this.task,
    required this.userFriends,
  }) : super(key: key);

  @override
  State<TaskPreviewCard> createState() => _TaskPreviewCardState();
}

class _TaskPreviewCardState extends State<TaskPreviewCard> with SingleTickerProviderStateMixin {
  late bool postToBoard;
  bool isEditMode = false;
  late String editableDate;
  late String editableTime;
  late String editablePriority;
  late Color editableBorderColor;
  late String fixedCategoryEmoji;
  String? fixedMoodEmoji;
  bool _showStamp = false;
  late AnimationController _stampController;
  late Animation<double> _stampScale;
  late Animation<double> _stampOpacity;
  late String originalPriority;
  late Color originalBorderColor;
  late String editableLocation;
  late String originalLocation;
  late List<Map<String, dynamic>> editablePeople;
  late List<Map<String, dynamic>> originalPeople;
  late TextEditingController searchController;
  List<Map<String, dynamic>> filteredFriends = [];
  late TextEditingController locationController;


  @override
  void initState() {
    super.initState();
    postToBoard = false;
    editableDate = widget.date ?? '';
    editableTime = widget.time ?? '';
    editablePriority = widget.priority ?? 'Medium';
    originalPriority = editablePriority;
    editableBorderColor = _getBorderColor(editablePriority);
    originalBorderColor = editableBorderColor;

    editablePeople = widget.people.map<Map<String, dynamic>>((person) {
      if (person is Map<String, dynamic>) return person;

      if (person is String) {
        // Try to resolve full friend data from userFriends
        final match = widget.userFriends.firstWhere(
              (f) {
            final fn = f['firstName']?.toLowerCase() ?? '';
            final ln = f['lastName']?.toLowerCase() ?? '';
            final nn = f['nickname']?.toLowerCase() ?? '';
            final full = '$fn $ln';
            return person.toLowerCase() == fn ||
                person.toLowerCase() == ln ||
                person.toLowerCase() == nn ||
                person.toLowerCase() == full;
          },
          orElse: () => {'nickname': person},
        );
        return match;
      }

      return {'nickname': 'Unknown'};
    }).toList();


    originalPeople = List<Map<String, dynamic>>.from(editablePeople);

    searchController = TextEditingController();
    filteredFriends = [];
    editableLocation = widget.location;
    originalLocation = widget.location;
    final category = widget.category;
    final mood = widget.userMood;
    locationController = TextEditingController(text: widget.location);


    // Set category emoji once
    final categoryList = categoryEmojis[category];
    if (categoryList != null && categoryList.isNotEmpty) {
      fixedCategoryEmoji = categoryList[_random.nextInt(categoryList.length)];
    } else {
      fixedCategoryEmoji = '';
    }

    // Set mood emoji once
    final moodList = moodEmojis[mood];
    if (moodList != null && moodList.isNotEmpty && mood != 'Neutral') {
      fixedMoodEmoji = moodList[_random.nextInt(moodList.length)];
    } else {
      fixedMoodEmoji = null;
    }

    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _stampScale = Tween<double>(begin: 20.0, end: 1.0)
        .animate(CurvedAnimation(
      parent: _stampController,
      curve: Curves.linear, // or Curves.linear for snappy easeIn
    ));

    _stampOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _stampController, curve: Curves.easeIn));


  }

  void _filterFriends(String query) {
    query = query.toLowerCase();
    final allFriends = widget.userFriends;

    List<Map<String, dynamic>> matchPriority(int priority, bool Function(Map<String, dynamic>) matchFn) {
      return allFriends.where(matchFn).map((f) => {...f, '_matchScore': priority}).toList();

    }

    final matches = [
      ...matchPriority(1, (f) => (f['nickname'] ?? '').toLowerCase().contains(query)),
      ...matchPriority(2, (f) => (f['firstName'] ?? '').toLowerCase().contains(query)),
      ...matchPriority(3, (f) {
        final full = '${f['firstName'] ?? ''} ${f['lastName'] ?? ''}'.toLowerCase();
        return full.contains(query);
      }),
      ...matchPriority(4, (f) => (f['lastName'] ?? '').toLowerCase().contains(query)),
    ];

    final seen = <String>{};
    final uniqueSorted = matches
        .where((f) => seen.add(f['uid']))
        .toList()
      ..sort((a, b) => (a['_matchScore'] as int).compareTo(b['_matchScore'] as int));
    print('🔍 Query: $query → Matches: ${uniqueSorted.map((f) => f['nickname'])}');
    setState(() {
      filteredFriends = uniqueSorted;
    });
  }


  String _formatDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      final weekday = _weekdayName(date.weekday);
      final month = _monthName(date.month);
      return "$weekday $month ${date.day}, ${date.year}";
    } catch (_) {
      return rawDate;
    }
  }

  String _formatTime(String rawTime) {
    try {
      final timeParts = rawTime.split(":");
      int hour = int.parse(timeParts[0]);
      final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
      final ampm = hour >= 12 ? 'pm' : 'am';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      final minStr = minute.toString().padLeft(2, '0');
      return "$hour:$minStr$ampm";
    } catch (_) {
      return rawTime;
    }
  }

  String _weekdayName(int day) =>
      ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][day - 1];

  String _monthName(int month) =>
      ["January", "February", "March", "April", "May", "June", "July",
        "August", "September", "October", "November", "December"][month - 1];


  final _random = Random();

  Color _getBorderColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return highPriorityColors[_random.nextInt(highPriorityColors.length)];
      case 'medium':
        return mediumPriorityColors[_random.nextInt(mediumPriorityColors.length)];
      case 'low':
        return lowPriorityColors[_random.nextInt(lowPriorityColors.length)];
      default:
        return Colors.grey;
    }
  }


  String? getEmojiForMood(String mood) {
    if (mood == 'Neutral') return null;
    final emojis = moodEmojis[mood];
    if (emojis == null || emojis.isEmpty) return null;
    return emojis[Random().nextInt(emojis.length)];
  }

  TimeOfDay parseTimeOfDay(String timeString) {
    final format = DateFormat.jm(); // e.g. "2:20 PM"
    final DateTime dateTime = format.parse(timeString);
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  Future<String?> _showCustomTimePicker(BuildContext context, String initialTime) async {
    // Parse "HH:mm" input string from JSON
    List<String> parts = initialTime.split(':');
    int hour24 = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    // Convert to 12-hour time for picker display
    String period = hour24 >= 12 ? 'PM' : 'AM';
    int hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    int selectedHour = hour12;
    int selectedMinute = minute;
    String selectedPeriod = period;


    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {

            return Container(
              height: 250,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Hour picker
                        Expanded(
                          child: CupertinoPicker(
                            backgroundColor: Colors.black,
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(initialItem: selectedHour - 1),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                selectedHour = index + 1;
                              });
                            },
                            children: List.generate(12, (index) {
                              return Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 20),
                                ),
                              );
                            }),
                          ),
                        ),
                        // Minute picker
                        Expanded(
                          child: CupertinoPicker(
                            backgroundColor: Colors.black,
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(initialItem: selectedMinute),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                selectedMinute = index;
                              });
                            },
                            children: List.generate(60, (index) {
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: const TextStyle(color: Colors.white, fontSize: 20),
                                ),
                              );
                            }),
                          ),
                        ),
                        // AM/PM picker
                        Expanded(
                          child: CupertinoPicker(
                            backgroundColor: Colors.black,
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(initialItem: selectedPeriod == 'AM' ? 0 : 1),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                selectedPeriod = index == 0 ? 'AM' : 'PM';
                              });
                            },
                            children: const [
                              Center(child: Text('AM', style: TextStyle(color: Colors.white, fontSize: 20))),
                              Center(child: Text('PM', style: TextStyle(color: Colors.white, fontSize: 20))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Convert selected 12-hour time back to 24-hour string
                      int finalHour = selectedHour % 12 + (selectedPeriod == 'PM' ? 12 : 0);
                      finalHour = finalHour == 24 ? 0 : finalHour; // handle 12 AM
                      String result = '${finalHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
                      Navigator.pop(context, result);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    child: const Text('Done', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }







  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? 'Untitled Task';
    final date = widget.date ?? '';
    final time = widget.time ?? '';
    final location = widget.location ?? 'none';
    final priority = widget.priority ?? 'Medium';
    //final people = widget.people ?? [];
    final inviteNamesDisplay = editablePeople.map((p) {
      final first = p['firstName'] ?? '';
      final last = p['lastName'] ?? '';
      if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
      return p['nickname'] ?? 'Unknown';
    }).join(', ');
    final inviteText = inviteNamesDisplay.isNotEmpty
        ? 'Invite: $inviteNamesDisplay'
        : '';


    final borderColor = isEditMode ? editableBorderColor : _getBorderColor(priority.toLowerCase());
    final userMood = widget.userMood ?? 'Neutral';
    final moodEmoji = getEmojiForMood(userMood);
    final category = widget.category ?? '';
    final editIcon = const Icon(Icons.edit, color: Colors.white, size: 16);


    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 360,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Date + Priority
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            isEditMode
                                ? InkWell(
                              onTap: () async {
                                final selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.tryParse(editableDate) ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  builder: (BuildContext context, Widget? child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        highlightColor: Colors.white.withOpacity(0.1),
                                        colorScheme: const ColorScheme.dark(
                                          primary: Colors.white,         // Header background & OK button
                                          onPrimary: Colors.black,       // Header text & icons
                                          surface: Colors.black,         // Background of dialog
                                          onSurface: Colors.white,       // Text color
                                        ),
                                        dialogBackgroundColor: Colors.black,
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.white, // Button text color
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (selectedDate != null) {
                                  setState(() {
                                    editableDate = DateFormat('yyyy-MM-dd').format(selectedDate);
                                  });
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatDate(editableDate),
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (isEditMode) ...[
                                    const SizedBox(width: 4),
                                    editIcon,
                                  ],
                                ],
                              ),

                            )
                                : isEditMode
                                ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatDate(editableDate),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(width: 4),
                                editIcon,
                              ],
                            )
                                : Text(
                              _formatDate(date),
                              style: const TextStyle(color: Colors.white),
                            ),


                            isEditMode
                                ? DropdownButton<String>(
                              dropdownColor: Colors.black,
                              value: editablePriority,
                              style: const TextStyle(color: Colors.white),
                              underline: Container(), // hide underline
                              iconEnabledColor: Colors.white,
                              items: ['High', 'Medium', 'Low']
                                  .map((level) => DropdownMenuItem<String>(
                                value: level,
                                child: Text(level),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    editablePriority = value;
                                    editableBorderColor = _getBorderColor(value);
                                  });
                                }
                              },
                            )
                                : Text(
                              '$originalPriority priority',
                              style: const TextStyle(color: Colors.white),
                            ),



                          ],
                        ),
                        const SizedBox(height: 8),

                        // Time
                        Align(
                          alignment: Alignment.centerLeft,
                          child: isEditMode
                              ? InkWell(
                            onTap: () async {
                              final pickedDisplayTime = await _showCustomTimePicker(context, editableTime);
                              print('⏰ pickedDisplayTime: $pickedDisplayTime');

                              if (pickedDisplayTime != null) {
                                try {
                                  // Case 1: picked time is already 24-hour format like "13:00"
                                  if (pickedDisplayTime.contains(':') && !pickedDisplayTime.contains('AM') && !pickedDisplayTime.contains('PM')) {
                                    setState(() {
                                      editableTime = pickedDisplayTime;
                                    });
                                    return;
                                  }

                                  // Case 2: picked time is in "1:00 PM" format
                                  final timeParts = pickedDisplayTime.split(' ');
                                  if (timeParts.length != 2) throw FormatException('Unexpected time format');

                                  final hmParts = timeParts[0].split(':');
                                  int hour = int.parse(hmParts[0]);
                                  final minute = hmParts[1];
                                  final period = timeParts[1];

                                  if (period == 'PM' && hour != 12) hour += 12;
                                  if (period == 'AM' && hour == 12) hour = 0;

                                  final formatted24 = '${hour.toString().padLeft(2, '0')}:$minute';

                                  setState(() {
                                    editableTime = formatted24;
                                  });
                                } catch (e) {
                                  print('❌ Error parsing picked time: $e');
                                }
                              }
                            },


                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(editableTime),
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                if (isEditMode) ...[
                                  const SizedBox(width: 4),
                                  editIcon,
                                ],
                              ],
                            ),

                          )
                              : Text(
                            _formatTime(time),
                            style: const TextStyle(color: Colors.white),
                          ),

                        ),

                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: isEditMode
                                ? SizedBox(
                              width: 200,
                              child: TextField(
                                style: const TextStyle(color: Colors.white),
                                cursorColor: Colors.white,
                                decoration: InputDecoration(
                                  hintText: 'Enter location',
                                  hintStyle: const TextStyle(color: Colors.white54),
                                  filled: true,
                                  fillColor: Colors.transparent, // Or keep white10 if you like
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white, width: 2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),

                                controller: locationController,
                                onChanged: (value) {
                                  setState(() {
                                    editableLocation = value;
                                  });
                                },
                              ),
                            )
                                : Text(
                              location,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),


                        const SizedBox(height: 8),
                        isEditMode
                            ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              children: editablePeople.map((person) {
                                final firstName = person['firstName'] ?? '';
                                final displayName = firstName.isNotEmpty ? firstName : (person['nickname'] ?? 'Unknown');
                                return Chip(
                                  label: Text(displayName, style: const TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.grey[900],
                                  deleteIcon: const Icon(Icons.close, color: Colors.white, size: 18),
                                  onDeleted: () {
                                    setState(() {
                                      editablePeople.remove(person);
                                    });
                                  },
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 6),
                            TextField(
                              controller: searchController,
                              onChanged: _filterFriends,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search friends to invite',
                                hintStyle: const TextStyle(color: Colors.white54),
                                prefixIcon: const Icon(Icons.search, color: Colors.white),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            if (searchController.text.trim().isNotEmpty && filteredFriends.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                constraints: const BoxConstraints(maxHeight: 180),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  border: Border.all(color: Colors.white12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: filteredFriends.length,
                                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white10),
                                  itemBuilder: (context, index) {
                                    final friend = filteredFriends[index];
                                    final fullName = '${friend['firstName'] ?? ''} ${friend['lastName'] ?? ''}'.trim();
                                    final displayName = fullName.isNotEmpty ? fullName : (friend['nickname'] ?? 'Unknown');
                                    final isAlreadyAdded = editablePeople.any((p) => p['uid'] == friend['uid']);

                                    return ListTile(
                                      dense: true,
                                      visualDensity: const VisualDensity(vertical: -3), // tighten vertical spacing
                                      tileColor: Colors.black,
                                      title: Text(
                                        displayName,
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                      trailing: isAlreadyAdded
                                          ? const Icon(Icons.check, color: Colors.green, size: 18)
                                          : null,
                                      onTap: () {
                                        if (!isAlreadyAdded) {
                                          setState(() {
                                            editablePeople.add(friend);
                                            searchController.clear();
                                            filteredFriends = [];
                                          });
                                        }
                                      },
                                    );
                                  },
                                ),
                              )

                          ],
                        )
                            : inviteText.isNotEmpty
                            ? Align(
                          alignment: Alignment.centerLeft,
                          child: Text(inviteText, style: const TextStyle(color: Colors.white)),
                        )
                            : const SizedBox.shrink(),

                        const SizedBox(height: 16),

                        // Post to Board
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left: Toggle
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Post to Board?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  Switch(
                                    value: postToBoard,
                                    activeColor: Colors.white,
                                    inactiveThumbColor: Colors.grey,
                                    inactiveTrackColor: Colors.white24,
                                    onChanged: (value) {
                                      setState(() {
                                        postToBoard = value;
                                      });
                                    },
                                  ),
                                ],
                              ),

                              // Center: Mood emoji
                              Expanded(
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (fixedCategoryEmoji.isNotEmpty)
                                        Text(fixedCategoryEmoji, style: const TextStyle(fontSize: 32)),

                                      if (fixedMoodEmoji != null) ...[
                                        const SizedBox(width: 8),
                                        Text(fixedMoodEmoji!, style: const TextStyle(fontSize: 32)),
                                      ]

                                    ],
                                  ),
                                ),
                              ),

                              // Right: Invisible spacer to balance layout
                              const SizedBox(width: 48),
                            ],
                          ),


                        ),
                      ],
                    ),
                  ),

                  // Envelope Design
                  // Envelope Design – matches the size of the card dynamically
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: EnvelopePainter(),
                      ),
                    ),
                  ),


                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: IgnorePointer( // 👈 This is key!
                      ignoring: true,
                      child: AnimatedBuilder(
                        animation: _stampController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _stampOpacity.value,
                            child: Transform.scale(
                              scale: _stampScale.value,
                              child: Image.asset(
                                'assets/images/boardicon.png',
                                width: 80,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),





                ],
              ),
              //here

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOutlinedButton(
                    label: 'Cancel',
                    borderColor: Colors.red,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildOutlinedButton(
                    label: 'Edit',
                    borderColor: Colors.white,
                    backgroundColor: isEditMode ? Colors.white : Colors.black,
                    textColor: isEditMode ? Colors.black : Colors.white,
                    onPressed: () {
                      setState(() {
                        isEditMode = !isEditMode;
                        if (!isEditMode) {
                          // Reset editable fields to their original values
                          editablePriority = originalPriority;
                          editableBorderColor = originalBorderColor;
                          editableLocation = originalLocation;
                          editablePeople = List<Map<String, dynamic>>.from(originalPeople);
                          searchController.clear();
                          filteredFriends = [];
                        }
                      });
                    },
                  ),

                  const SizedBox(width: 12),
                  _buildOutlinedButton(
                    label: 'Send',
                    borderColor: borderColor,
                    onPressed: () async {
                      print('Current route: ${ModalRoute.of(context)?.settings.name}');
                      if (postToBoard) {
                        setState(() {
                          _showStamp = true;
                        });

                        // Small delay so visibility starts *before* animation triggers
                        await Future.delayed(const Duration(milliseconds: 50));

                        _stampController.forward(from: 0);
                        await Future.delayed(const Duration(milliseconds: 800));
                      }


                      final taskId = widget.task?['id'];

                      final updatedTask = {
                        'id': taskId,
                        'title': widget.title,
                        'time': editableTime,
                        'date': editableDate,
                        'category': widget.category,
                        'priority': editablePriority,
                        'userMood': widget.userMood,
                        'relationship': widget.relationship,
                        'location': editableLocation,
                        'recurring': widget.recurring,
                        'floating': widget.floating,
                        'intent': widget.intent,
                        'people': editablePeople.map((p) => p['uid']).toList(),
                        'postToBoard': postToBoard,
                        'categoryEmoji': fixedCategoryEmoji,
                        'moodEmoji': fixedMoodEmoji ?? '',
                        'borderColorHex': '#${editableBorderColor.value.toRadixString(16).padLeft(8, '0')}',

                      };



                      try {
                        final tasksCollection = FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.userId)
                            .collection('tasks');

                        if (taskId != null) {
                          // Update existing task
                          await tasksCollection.doc(taskId).set(updatedTask);
                          print('✅ Task updated: $updatedTask');
                        } else {
                          // Create new task with autogenerated ID
                          final newDocRef = tasksCollection.doc();
                          final newDocId = newDocRef.id;

                          updatedTask['id'] = newDocId;
                          await newDocRef.set(updatedTask);

                          print('🆕 New task created: $updatedTask');

// ✅ Send invites to friends if any
                          final invitedUserIds = updatedTask['people'] as List<dynamic>;
                          if (invitedUserIds.isNotEmpty) {

                            await FirestoreService.createGroupEvent(
                              eventId: updatedTask['id'],
                              hostId: widget.userId,
                              participantIds: invitedUserIds.cast<String>(),
                              title: updatedTask['title'],
                              date: updatedTask['date'],
                              time: updatedTask['time'],
                              location: updatedTask['location'] ?? 'none',
                              source: 'invite',
                            );

                            for (final userId in invitedUserIds.cast<String>()) {
                              await FirestoreService.linkUserToGroupEvent(
                                userId: userId,
                                eventId: updatedTask['id'],
                              );
                            }

                            await FirestoreService.linkUserToGroupEvent(
                              userId: widget.userId,  // the host
                              eventId: updatedTask['id'],
                            );


                            final inviteData = {
                              'title': updatedTask['title'],
                              'eventDate': Timestamp.fromDate(DateTime.parse(updatedTask['date'])),
                              'time': updatedTask['time'],
                              'categoryEmoji': updatedTask['categoryEmoji'],
                              'moodEmoji': updatedTask['moodEmoji'],
                              'borderColor': updatedTask['borderColorHex'],
                              'location': updatedTask['location'],
                              'invitedPeople': editablePeople.map((p) => p['firstName'] ?? p['nickname'] ?? 'Unknown').toList(),
                              'eventId': newDocId,
                            };
                            final senderId = widget.userId;
                            final senderName = await FirestoreService.getSenderFullName(widget.userId);


                            await FirestoreService.sendTaskInviteToFriends(
                              friendIds: invitedUserIds.cast<String>(),
                              senderId: widget.userId,
                              senderName: senderName, // or however you store sender name
                              taskData: inviteData,
                            );
                          }



                          final posttoBoardData = {
                            'title': updatedTask['title'],
                            'eventDate': Timestamp.fromDate(DateTime.parse(updatedTask['date'])),
                            'time': updatedTask['time'],
                            'categoryEmoji': updatedTask['categoryEmoji'],
                            'moodEmoji': updatedTask['moodEmoji'],
                            'borderColor': updatedTask['borderColorHex'],
                            'location': updatedTask['location'],
                            'invitedPeople': editablePeople.map((p) => p['firstName'] ?? p['nickname'] ?? 'Unknown').toList(),
                          };
                          final senderId = widget.userId;
                          final senderName = await FirestoreService.getSenderFullName(widget.userId);

                          print("Value of post to board: $postToBoard");
                          if (postToBoard) {
                            final boardCardData = {
                              ...posttoBoardData,
                              'senderId': senderId,
                              'senderName': senderName,
                              'type': 'invite',
                            };
                            await FirestoreService.postCardToBoard(boardCardData);
                          }

                        }


                        widget.onTaskSaved({
                          'success': true,
                          'task': updatedTask,
                        });

                        Navigator.pop(context, true);
                      } catch (e) {
                        widget.onTaskSaved({
                          'success': false,
                          'error': e.toString(),
                        });

                        Navigator.pop(context, false);
                      }
                    },



                  ),

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildOutlinedButton({
    required String label,
    required Color borderColor,
    required VoidCallback onPressed,
    Color backgroundColor = Colors.black,
    Color textColor = Colors.white,
  }) {

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor, // this sets text/icon color
        side: BorderSide(color: borderColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      onPressed: onPressed,
      child: Text(label),
    );

  }


  @override
  void dispose() {
    _stampController.dispose();
    super.dispose();
  }


}



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

    // New: intersection points 70% toward triangle tip (closer to tip)
    final leftFlapEnd = Offset(
      topLeft.dx + (centerTip.dx - topLeft.dx) * 0.7,
      topLeft.dy + (centerTip.dy - topLeft.dy) * 0.7,
    );

    final rightFlapEnd = Offset(
      topRight.dx + (centerTip.dx - topRight.dx) * 0.7,
      topRight.dy + (centerTip.dy - topRight.dy) * 0.7,
    );

    final path = Path();

    // Top flap triangle
    path.moveTo(topLeft.dx, topLeft.dy);
    path.lineTo(centerTip.dx, centerTip.dy);
    path.lineTo(topRight.dx, topRight.dy);

    // Bottom corner to triangle edge (left + right)
    path.moveTo(bottomLeft.dx, bottomLeft.dy);
    path.lineTo(leftFlapEnd.dx, leftFlapEnd.dy);

    path.moveTo(bottomRight.dx, bottomRight.dy);
    path.lineTo(rightFlapEnd.dx, rightFlapEnd.dy);

    // Optional border
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}







