import 'package:flutter/material.dart';                // [IMPORT] Flutter UI framework
import 'package:firebase_auth/firebase_auth.dart';      // [IMPORT] Firebase Authentication service
import 'package:cloud_firestore/cloud_firestore.dart';  // [IMPORT] Firebase Cloud Firestore database
import 'simple_login_screen.dart';                      // [IMPORT] Login screen for navigation after register
import 'profile_screen.dart';                           // [IMPORT] Profile screen for navigation after register

/// [CLASS] SimpleRegisterScreen
/// [PURPOSE] StatefulWidget that provides user registration interface
/// [FUNCTIONALITY] Email/password registration only (no profile image during register)
class SimpleRegisterScreen extends StatefulWidget {
  const SimpleRegisterScreen({super.key});                 // [CONSTRUCTOR] Creates register screen instance

  @override
  State<SimpleRegisterScreen> createState() => _SimpleRegisterScreenState();  // [METHOD] Creates state for this widget
}

/// [CLASS] _SimpleRegisterScreenState
/// [PURPOSE] State management for SimpleRegisterScreen
/// [FUNCTIONALITY] Handles form validation and Firebase registration
class _SimpleRegisterScreenState extends State<SimpleRegisterScreen> {
  
  // [FIELD] _emailController - Text controller for email input field
  final _emailController = TextEditingController();

  // [FIELD] _usernameController - Public display name / search handle
  final _usernameController = TextEditingController();
  
  // [FIELD] _passwordController - Text controller for password input field
  final _passwordController = TextEditingController();
  
  // [FIELD] _formKey - Global key for form validation state
  final _formKey = GlobalKey<FormState>();
  
  // [FIELD] _isLoading - Loading state flag to disable UI during registration
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// [FUNCTION] _register
  /// [PARAMS] None (uses _emailController, _passwordController)
  /// [RETURNS] Future<void>
  /// [PURPOSE] Complete user registration: Firebase Auth + Firestore only
  /// [STEP 1] Validate form inputs
  /// [STEP 2] Create Firebase Auth account with email/password
  /// [STEP 3] Save user data to Cloud Firestore (without image)
  /// [STEP 4] Navigate to login screen on success
  Future<void> _register() async {
    // [STEP 1] Validate form fields before proceeding
    if (!_formKey.currentState!.validate()) return;

    // [STEP 2] Set loading state to disable UI
    setState(() => _isLoading = true);

    try {
      // [STEP 3] Create Firebase Authentication account
      UserCredential userCred =                     // [VAR] Stores Firebase auth credentials
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),          // [FIELD] User email from input
        password: _passwordController.text.trim(),   // [FIELD] User password from input
      );

      String uid = userCred.user!.uid;                // [VAR] Firebase-generated unique user ID
      final email = _emailController.text.trim();
      final username = _usernameController.text.trim();

      // [STEP 4] Save user profile for search, feed, and profile screens
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'username': username,
        'usernameLower': username.toLowerCase(),
        'profileImageUrl': '',
        'profileImage': '',
        'bio': '',
        'followersCount': 0,
        'followingCount': 0,
        'createdAt': Timestamp.now(),
        'lastActive': Timestamp.now(),
        'accountVisibility': 'public',
      });

      // [STEP 6] Show success message to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Color(0xFF66BB6A),
        ),
      );

      // [STEP 7] Navigate to profile screen if widget still mounted
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),  // [NAVIGATE] Go to profile setup
        );
        return; // Prevent calling setState after route replacement.
      }
    } catch (e) {
      // [ERROR] Show error message if registration fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // [STEP 8] Reset loading state regardless of success/failure
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// [FUNCTION] build
  /// [PARAMS] context - BuildContext for widget tree
  /// [RETURNS] Widget - The registration screen UI
  /// [PURPOSE] Build the visual interface for user registration
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [UI] Allow screen to resize when keyboard appears
      resizeToAvoidBottomInset: true,
      // [UI] Main body container with gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9),
              Color(0xFFC8E6C9),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // [UI SECTION] LOGO & TITLE
                  Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.person_add,
                          size: 50,
                          color: Color(0xFF66BB6A),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Social Memories',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // [UI SECTION] REGISTER FORM
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // [UI FIELD] USERNAME INPUT
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              hintText: 'How others find you in search',
                            ),
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.length < 2) return 'At least 2 characters';
                              if (v.length > 30) return 'Max 30 characters';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // [UI FIELD] EMAIL INPUT
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email'),
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.isEmpty) return 'Enter email';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // [UI FIELD] PASSWORD INPUT
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Password'),
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.length < 6) return 'Min 6 characters';
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // [UI BUTTON] REGISTER BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF66BB6A),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text('Register'),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // [UI LINK] BACK TO LOGIN
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SimpleLoginScreen(),
                                ),
                              );
                            },
                            child: const Text("Already have an account? Login"),
                          ),
                        ],
                      ),
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
}