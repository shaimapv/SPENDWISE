import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  //final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false; // To manage loading state

  // Replace your _signUp method with this:
  Future<void> _signUp() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true); // Start loading

    try {
      // Use the AuthService to register
      AuthService authService = AuthService();
      User? user = await authService.register(
        _emailController.text,
        _passwordController.text,
      );

      if (user == null) {
        throw Exception("Failed to create user account");
      }

      String uid = user.uid; // Get user UID

      // Save additional user data to Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'dob': _dobController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Navigate to home screen after successful sign-up
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => FinancialDataScreen(
                // Pass necessary user data as a Map, not as PigeonUserDetails
                userData: {
                  'uid': uid,
                  'name': _nameController.text.trim(),
                  'email': _emailController.text.trim(),
                },
              ),
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign-up failed: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false); // Stop loading
    }
  }

  bool _validateInputs() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _mobileController.text.isEmpty ||
        _dobController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All fields are required.")));
      return false;
    }

    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid email address.")),
      );
      return false;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 6 characters."),
        ),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(_nameController, 'Full Name', 'Enter your name'),
            const SizedBox(height: 20),
            _buildTextField(_emailController, 'Email', 'example@example.com'),
            const SizedBox(height: 20),
            _buildTextField(_mobileController, 'Mobile Number', '+123 456 789'),
            const SizedBox(height: 20),
            _buildDatePicker(),
            const SizedBox(height: 20),
            _passwordField(
              _passwordController,
              'Password',
              _isPasswordVisible,
              () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator() // Show loading indicator while signing up
                : ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Sign Up'),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDatePicker() {
    return TextField(
      controller: _dobController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Date Of Birth',
        hintText: 'DD / MM / YYYY',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );

            if (pickedDate != null) {
              setState(() {
                _dobController.text =
                    "${pickedDate.day} / ${pickedDate.month} / ${pickedDate.year}";
              });
            }
          },
        ),
      ),
    );
  }

  Widget _passwordField(
    TextEditingController controller,
    String label,
    bool isVisible,
    VoidCallback toggleVisibility,
  ) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}
