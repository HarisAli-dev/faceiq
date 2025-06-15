import 'package:faceiq/view/signin.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  // Add form key for validation
  final _formKey = GlobalKey<FormState>();

  String _username = '';
  String _email = '';
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _username = prefs.getString('username') ?? '';
        _email = prefs.getString('email') ?? '';
        _usernameController.text = _username;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save updated user data to SharedPreferences
  Future<void> _saveUserData() async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPassword = prefs.getString('password') ?? '';

      // Verify current password
      if (_currentPasswordController.text != storedPassword) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Update password if provided
      if (_newPasswordController.text.isNotEmpty) {
        await prefs.setString('password', _newPasswordController.text);
      }

      // Update username
      await prefs.setString('username', _usernameController.text);

      setState(() {
        _username = _usernameController.text;
        _isEditing = false;
        _isLoading = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Logout function
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF0),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(mq.width * 0.05),
                  child: Column(
                    children: [
                      // Profile Avatar
                      CircleAvatar(
                        radius: mq.width * 0.15,
                        backgroundColor: const Color(0xFF0A3D3F),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: mq.width * 0.15,
                        ),
                      ),
                      SizedBox(height: mq.height * 0.02),

                      // User info or edit form
                      if (_isEditing) ...[
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildFormField(
                                'Username',
                                _usernameController,
                                false,
                                mq,
                                (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Username is required';
                                  }
                                  if (value.length < 3) {
                                    return 'Username must be at least 3 characters';
                                  }
                                  return null;
                                },
                              ),
                              _buildFormField(
                                'Current Password',
                                _currentPasswordController,
                                true,
                                mq,
                                (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Current password is required';
                                  }
                                  return null;
                                },
                              ),
                              _buildFormField(
                                'New Password',
                                _newPasswordController,
                                true,
                                mq,
                                (value) {
                                  if (value != null &&
                                      value.isNotEmpty &&
                                      value.length < 6) {
                                    return 'New password must be at least 6 characters';
                                  }
                                  return null;
                                },
                                hintText:
                                    'Leave blank to keep current password',
                              ),
                              SizedBox(height: mq.height * 0.03),

                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _saveUserData,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0A3D3F,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          vertical: mq.height * 0.02,
                                        ),
                                      ),
                                      child: const Text('Save'),
                                    ),
                                  ),
                                  SizedBox(width: mq.width * 0.04),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          () => setState(() {
                                            _isEditing = false;
                                            _usernameController.text =
                                                _username;
                                            _currentPasswordController.clear();
                                            _newPasswordController.clear();
                                          }),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          vertical: mq.height * 0.02,
                                        ),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Display user info
                        Text(
                          _username,
                          style: TextStyle(
                            fontSize: mq.width * 0.06,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _email,
                          style: TextStyle(
                            fontSize: mq.width * 0.045,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: mq.height * 0.03),
                        _buildListTile(Icons.settings, "Edit profile", mq),

                        SizedBox(height: mq.height * 0.05),

                        // Logout button
                        ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.exit_to_app),
                          label: const Text('Log Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: mq.width * 0.1,
                              vertical: mq.height * 0.015,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    bool obscureText,
    Size mq,
    String? Function(String?) validator, {
    String? hintText,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: mq.height * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: mq.height * 0.01),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            decoration: InputDecoration(
              label: Text(
                label,
                style: TextStyle(
                  fontSize: mq.width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[300],
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: mq.width * 0.04,
                vertical: mq.height * 0.02,
              ),
              errorStyle: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for list tiles
  Widget _buildListTile(IconData icon, String title, Size mq) {
    return Column(
      children: [
        const Divider(),
        ListTile(
          leading: Icon(icon, color: const Color(0xFF0A3D3F)),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              _isEditing = true;
            });
          },
        ),
      ],
    );
  }
}
