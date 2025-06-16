import 'package:faceiq/view/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Custom field method to create form fields
  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    bool isPassword = false,
    required String? Function(String?) validator,
  }) {
    final Size mq = MediaQuery.of(context).size;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: mq.width * 0.045,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: mq.height * 0.01),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText ?? label,
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
        SizedBox(height: mq.height * 0.02),
      ],
    );
  }

  Future<void> _saveUserDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (!_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _usernameController.text);
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setBool('isLoggedIn', true);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF0), // Cream background color
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(mq.width * 0.05),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: mq.height * 0.05),

                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: mq.width * 0.4,
                      height: mq.width * 0.15,
                    ),
                  ),

                  SizedBox(height: mq.height * 0.05),

                  // Sign Up Text
                  Center(
                    child: Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: mq.width * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  SizedBox(height: mq.height * 0.03),

                  _buildFormField(
                    label: 'Username:',
                    controller: _usernameController,
                    hintText: 'Username',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),

                  _buildFormField(
                    label: 'Email:',
                    controller: _emailController,
                    hintText: 'Email',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  _buildFormField(
                    label: 'Password:',
                    controller: _passwordController,
                    hintText: 'Password',
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  _buildFormField(
                    label: 'Confirm Password:',
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveUserDetails,
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
                              'Sign Up',
                              style: TextStyle(
                                fontSize: mq.width * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),

                  SizedBox(height: mq.height * 0.02)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
