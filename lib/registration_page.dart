import 'package:flutter/material.dart';
import 'services/database_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';



class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String? firstNameError;
  String? lastNameError;
  String? usernameError;
  String? passwordError;
  String? confirmPasswordError;
  bool isRegistering = false;
  bool isHovered = false;


  Future<String> generateUniqueUserTag(String firstName, String lastName) async {
    final firestore = FirebaseFirestore.instance;
    final base = "${firstName.toLowerCase()}_${lastName.toLowerCase()}";
    String userTag;

    do {
      String randomDigits = (10000 + Random().nextInt(90000)).toString(); // 5-digit code
      userTag = "$base$randomDigits";

      final existing = await firestore
          .collection('users')
          .where('userTag', isEqualTo: userTag)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) break; // it's unique
    } while (true);

    return userTag;
  }


  void validateAndRegister() async {
    if (isRegistering) return;

    setState(() {
      isRegistering = true; // 🚫 Disable register button
      firstNameError = null;
      lastNameError = null;
      usernameError = null;
      passwordError = null;
      confirmPasswordError = null;
    });

    bool hasError = false;

    // Validate all fields
    if (firstNameController.text.trim().isEmpty) {
      setState(() => firstNameError = 'First name is required');
      hasError = true;
    }

    if (lastNameController.text.trim().isEmpty) {
      setState(() => lastNameError = 'Last name is required');
      hasError = true;
    }

    if (usernameController.text.trim().isEmpty) {
      setState(() => usernameError = 'Username is required');
      hasError = true;
    }

    if (passwordController.text.isEmpty) {
      setState(() => passwordError = 'Password is required');
      hasError = true;
    }

    if (confirmPasswordController.text.isEmpty) {
      setState(() => confirmPasswordError = 'Please confirm your password');
      hasError = true;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() => confirmPasswordError = 'Passwords do not match');
      hasError = true;
    }

    if (hasError) {
      setState(() => isRegistering = false); // ✅ Reset flag on error
      return;
    }

    try {
      final String firstName = firstNameController.text.trim();
      final String lastName = lastNameController.text.trim();
      final String email = usernameController.text.trim();
      final String password = passwordController.text;

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final String userTag = await generateUniqueUserTag(firstName, lastName);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'userTag': userTag,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created successfully! Your tag is $userTag'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ));

      await Future.delayed(Duration(seconds: 2));
      Navigator.pop(context);


    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        setState(() => usernameError = 'Email already in use');
      } else if (e.code == 'invalid-email') {
        setState(() => usernameError = 'Invalid email address');
      } else if (e.code == 'weak-password') {
        setState(() => passwordError = 'Password is too weak');
      } else {
        print('Registration error: $e');
        setState(() => usernameError = 'Registration failed');
      }
    } finally {
      setState(() => isRegistering = false); // ✅ Always reset
    }
  }


  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    String? errorText,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter $label',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              SizedBox(height: 48),
              Text(
                'CREATE ACCOUNT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 48),
              buildTextField(
                label: 'First Name',
                controller: firstNameController,
                errorText: firstNameError,
              ),
              SizedBox(height: 24),
              buildTextField(
                label: 'Last Name',
                controller: lastNameController,
                errorText: lastNameError,
              ),
              SizedBox(height: 24),
              buildTextField(
                label: 'Email',
                controller: usernameController,
                errorText: usernameError,
              ),
              SizedBox(height: 24),
              buildTextField(
                label: 'Password',
                controller: passwordController,
                errorText: passwordError,
                isPassword: true,
              ),
              SizedBox(height: 24),
              buildTextField(
                label: 'Confirm Password',
                controller: confirmPasswordController,
                errorText: confirmPasswordError,
                isPassword: true,
              ),
              SizedBox(height: 32),
              InkWell(
                onHover: (hover) {
                  setState(() => isHovered = hover);
                },
                onTap: validateAndRegister,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isHovered ? Colors.white : Color(0xFFB8860B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'CREATE',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Back to Login',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}