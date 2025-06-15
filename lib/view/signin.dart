// SignIn screen widget
import 'package:faceiq/view/home_screen.dart';
import 'package:faceiq/view/signup.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function to validate login with SharedPreferences
  Future<void> _validateLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First validate the form
      if (!_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get stored credentials from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedUsername = prefs.getString('username');
      final storedPassword = prefs.getString('password');

      // Check if credentials match
      if (storedUsername == _usernameController.text &&
          storedPassword == _passwordController.text) {
        // Login successful
        await prefs.setBool('isLoggedIn', true);

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        // Login failed
        setState(() {
          _errorMessage = 'Invalid username or password';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(mq.width * 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: mq.height * 0.15),

                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: mq.width * 0.4,
                    height: mq.width * 0.15,
                  ),
                ),

                SizedBox(height: mq.height * 0.05),

                // Sign In Text
                Center(
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: mq.width * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                SizedBox(height: mq.height * 0.04),

                // Error message if any
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 15),
                    color: Colors.red.shade100,
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                Text(
                  'Username:',
                  style: TextStyle(
                    fontSize: mq.width * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: mq.height * 0.01),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: 'Username',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[300],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: mq.width * 0.04,
                      vertical: mq.height * 0.02,
                    ),
                  ),
                ),

                SizedBox(height: mq.height * 0.03),

                // Password field
                Text(
                  'Password:',
                  style: TextStyle(
                    fontSize: mq.width * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: mq.height * 0.01),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[300],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: mq.width * 0.04,
                      vertical: mq.height * 0.02,
                    ),
                  ),
                ),

                SizedBox(height: mq.height * 0.04),

                // Sign In Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _validateLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF0A3D3F,
                    ), // Dark green like the logo
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: mq.height * 0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: mq.width * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),

                SizedBox(height: mq.height * 0.02),

                // Don't have an account link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: TextStyle(fontSize: mq.width * 0.04),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUp(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: mq.width * 0.04,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0A3D3F),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
