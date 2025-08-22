import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  // Updated user registration method with first and last name

  Future<bool> registerUser(String email, String password, String firstName, String lastName) async {
    try {
      // Create user with email/password
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save additional user details in Firestore
      print('📤 Writing user to Firestore...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
      });
      print('✅ User successfully written to Firestore');

      print('User registration successful via Firebase');
      return true;
    } catch (e) {
      print('Error registering user with Firebase: $e');
      return false;
    }
  }


  // Add method to get user details
  Future<Map<String, dynamic>?> getUserDetails(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        return doc.data();
      } else {
        print('No user found for UID: $uid');
        return null;
      }
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }






  // Insert a task
  Future<void> insertTask(Map<String, dynamic> task, String userId) async {
    try {
      final date = task['date'];
      final tasksRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks');

      await tasksRef.add({
        'title': task['title'],
        'time': task['time'],
        'category': task['category'] ?? 'other',
        'date': date, // should be a string like "2024-12-05"
        'timestamp': FieldValue.serverTimestamp(), // optional: helps with ordering
      });
      print("Task added to Firestore");
    } catch (e) {
      print('Error inserting task: $e');
      throw e;
    }
  }



  // Retrieve all tasks
  Future<Map<String, List<Map<String, dynamic>>>> getAllTasks() async {
    Map<String, List<Map<String, dynamic>>> tasksByDate = {};

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
      // ← Replace with dynamic user ID later
          .collection('tasks')
          .get();

      for (var doc in snapshot.docs) {
        final task = doc.data();
        final date = task['date'];
        if (date != null) {
          if (!tasksByDate.containsKey(date)) {
            tasksByDate[date] = [];
          }
          tasksByDate[date]!.add({
            'title': task['title'],
            'time': task['time'],
            'category': task['category'],
            'date': date,
          });
        }
      }
    } catch (e) {
      print('Error loading tasks from Firestore: $e');
    }

    return tasksByDate;
  }

  // Delete a task
  Future<void> deleteTask(String date, String title, String time, String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('date', isEqualTo: date)
          .where('title', isEqualTo: title)
          .where('time', isEqualTo: time)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      print('Task deleted from Firestore');
    } catch (e) {
      print('Error deleting task from Firestore: $e');
    }
  }


}