import 'package:flutter/material.dart';                // [IMPORT] Flutter UI framework for building UI
import 'package:firebase_auth/firebase_auth.dart';      // [IMPORT] Firebase Authentication for login
import 'package:provider/provider.dart';                // [IMPORT] State management for UserProvider
import '../providers/user_provider.dart';              // [IMPORT] User state management provider
import 'simple_register_screen.dart';                  // [IMPORT] Registration screen navigation
import 'profile_screen.dart';                          // [IMPORT] Profile screen navigation after login

/// [CLASS] SimpleLoginScreen
/// [PURPOSE] StatefulWidget for user email/password login
/// [FUNCTIONALITY] Authenticates with Firebase, syncs with UserProvider, navigates to Profile
class SimpleLoginScreen extends StatefulWidget {
  const SimpleLoginScreen({super.key});               // [CONSTRUCTOR] Creates login screen widget

  @override
  State<SimpleLoginScreen> createState() => _SimpleLoginScreenState();  // [METHOD] Creates state instance
}

/// [CLASS] _SimpleLoginScreenState
/// [PURPOSE] State management for login screen
/// [FUNCTIONALITY] Form validation, Firebase auth, user state sync, navigation
class _SimpleLoginScreenState extends State<SimpleLoginScreen> {
  
  // [FIELD] _emailController - TextEditingController for email input
  final _emailController = TextEditingController();
  
  // [FIELD] _passwordController - TextEditingController for password input
  final _passwordController = TextEditingController();
  
  // [FIELD] _formKey - GlobalKey for form validation state
  final _formKey = GlobalKey<FormState>();
  
  // [FIELD] _isLoading - Boolean flag for loading state (disables UI)
  bool _isLoading = false;

  /// [FUNCTION] dispose
  /// [PARAMS] None
  /// [RETURNS] void
  /// [PURPOSE] Clean up controllers when widget is destroyed
  @override
  void dispose() {
    _emailController.dispose();                         // [CLEANUP] Dispose email controller
    _passwordController.dispose();                    // [CLEANUP] Dispose password controller
    super.dispose();                                    // [CLEANUP] Call parent dispose
  }

  /// [FUNCTION] _login
  /// [PARAMS] None (uses _emailController, _passwordController)
  /// [RETURNS] Future<void>
  /// [PURPOSE] Authenticate user with Firebase and navigate to profile
  /// [STEP 1] Validate form inputs
  /// [STEP 2] Set loading state
  /// [STEP 3] Authenticate with Firebase Auth
  /// [STEP 4] Update UserProvider with Firebase UID
  /// [STEP 5] Navigate to ProfileScreen
  /// [STEP 6] Handle errors
  /// [STEP 7] Reset loading state
  Future<void> _login() async {
    // [STEP 1] Validate form before submitting
    if (!_formKey.currentState!.validate()) return;

    // [STEP 2] Enable loading state to disable UI
    setState(() => _isLoading = true);

    try {
      // [STEP 3] Authenticate with Firebase Auth email/password
      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),              // [FIELD] Email from input field
        password: _passwordController.text.trim(),       // [FIELD] Password from input field
      );

      // [STEP 4] Load profile from Firestore + Firebase Auth
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUserData();

      // [STEP 5] Navigate to ProfileScreen to complete profile
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),  // [NAVIGATE] Go to profile setup
      );
    } catch (e) {
      // [STEP 6] Show error message on authentication failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // [STEP 7] Reset loading state
    setState(() => _isLoading = false);
  }

  /// [FUNCTION] build
  /// [PARAMS] context - BuildContext for widget tree
  /// [RETURNS] Widget - The login screen UI
  /// [PURPOSE] Build visual interface for user login
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [UI] Allow screen to resize when keyboard appears
      resizeToAvoidBottomInset: true,
      
      // [UI] Main body container with gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,                   // [STYLE] Gradient starts at top
            end: Alignment.bottomCenter,                  // [STYLE] Gradient ends at bottom
            colors: [
              Color(0xFFE8F5E9),                         // [STYLE] Light green color
              Color(0xFFC8E6C9),                         // [STYLE] Medium green color
            ],
          ),
        ),
        
        // [UI] SafeArea prevents notch/camera overlap
        child: SafeArea(
          // [UI] Scrollable content for small screens
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),       // [STYLE] 24px padding all sides
              
              // [UI] Main column layout
              child: Column(
                children: [
                  
                  // [UI SECTION] LOGO & TITLE
                  Column(
                    children: [
                      // [UI] Logo container with white background
                      Container(
                        width: 100,                       // [STYLE] Logo width
                        height: 100,                      // [STYLE] Logo height
                        decoration: BoxDecoration(
                          color: Colors.white,            // [STYLE] White background
                          borderRadius: BorderRadius.circular(20),  // [STYLE] Rounded corners
                        ),
                        child: const Icon(Icons.place,    // [UI] Map pin icon
                            size: 50, color: Color(0xFF66BB6A)),  // [STYLE] Green icon
                      ),
                      const SizedBox(height: 24),         // [UI] Spacing
                      
                      // [UI] App title text
                      const Text(
                        'Social Memories',
                        style: TextStyle(
                          fontSize: 32,                   // [STYLE] Title font size
                          fontWeight: FontWeight.bold,    // [STYLE] Bold text
                          color: Color(0xFF2E7D32),       // [STYLE] Dark green
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),           // [UI] Spacing between sections

                  // [UI SECTION] LOGIN FORM
                  Container(
                    padding: const EdgeInsets.all(24),   // [STYLE] Form padding
                    decoration: BoxDecoration(
                      color: Colors.white,              // [STYLE] White card background
                      borderRadius: BorderRadius.circular(20),  // [STYLE] Rounded corners
                    ),
                    child: Form(
                      key: _formKey,                    // [FIELD] Form validation key
                      child: Column(
                        children: [
                          
                          // [UI] Login title
                          const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 24,              // [STYLE] Header font size
                              fontWeight: FontWeight.bold,  // [STYLE] Bold text
                            ),
                          ),
                          const SizedBox(height: 20),     // [UI] Spacing

                          // [UI FIELD] EMAIL INPUT
                          TextFormField(
                            controller: _emailController, // [FIELD] Email text controller
                            decoration: InputDecoration(
                              labelText: 'Email',       // [UI] Input label
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),  // [STYLE] Rounded border
                              ),
                            ),
                            validator: (value) {        // [VALIDATION] Email validation
                              if (value == null || value.isEmpty) {
                                return 'Enter email';  // [ERROR] Empty email message
                              }
                              return null;             // [VALIDATION] Valid input
                            },
                          ),

                          const SizedBox(height: 16),   // [UI] Spacing

                          // [UI FIELD] PASSWORD INPUT
                          TextFormField(
                            controller: _passwordController,  // [FIELD] Password controller
                            obscureText: true,            // [SECURITY] Hide password
                            decoration: InputDecoration(
                              labelText: 'Password',      // [UI] Input label
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),  // [STYLE] Rounded border
                              ),
                            ),
                            validator: (value) {          // [VALIDATION] Password validation
                              if (value == null || value.length < 6) {
                                return 'Min 6 characters';  // [ERROR] Too short message
                              }
                              return null;               // [VALIDATION] Valid input
                            },
                          ),

                          const SizedBox(height: 24),   // [UI] Spacing

                          // [UI BUTTON] LOGIN BUTTON
                          SizedBox(
                            width: double.infinity,       // [STYLE] Full width button
                            height: 50,                   // [STYLE] Button height
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,  // [LOGIC] Disabled when loading
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF66BB6A),  // [STYLE] Green button
                              ),
                              child: _isLoading          // [CONDITIONAL] Show loading or text
                                  ? const CircularProgressIndicator(
                                  color: Colors.white)   // [UI] Loading spinner
                                  : const Text('Login'),  // [UI] Button text
                            ),
                          ),

                          const SizedBox(height: 10),   // [UI] Spacing

                          // [UI LINK] CREATE ACCOUNT BUTTON
                          TextButton(
                            onPressed: () {              // [ACTION] Navigate to register
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const SimpleRegisterScreen(),  // [NAVIGATE] Go to register
                                ),
                              );
                            },
                            child: const Text("Create Account"),  // [UI] Link text
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