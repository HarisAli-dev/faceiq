import 'package:faceiq/view/compare_screens/compare_screen.dart';
import 'package:faceiq/view/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  File? _selectedImage;
  bool _isAnalyzing = false;

  final ImagePicker _picker = ImagePicker();

  // List of screens to navigate to
  final List<Widget> _screens = [
    const HomeScreen(),
    const CompareScreen(),
    const ProfileScreen(),
  ];

  Future<void> _pickImage(String source) async {
    final XFile? pickedImage = await _picker.pickImage(
      source: source == 'gallery' ? ImageSource.gallery : ImageSource.camera,
    );
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    // This is where you would call your facial analysis API
    setState(() {
      _isAnalyzing = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FaceIQ',
          style: TextStyle(
            fontSize: mq.width * 0.06,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0A3D3F),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFFFCF0),
      body:
          _selectedIndex == 0
              ? SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: mq.height * 0.03),
                      Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: mq.width * 0.7,
                          height: mq.width * 0.3,
                        ),
                      ),
                      SizedBox(height: mq.height * 0.05),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Select Image Source"),
                                content: SingleChildScrollView(
                                  child: ListBody(
                                    children: <Widget>[
                                      GestureDetector(
                                        child: Text("Camera"),
                                        onTap: () {
                                          _pickImage("Camera");
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      Padding(padding: EdgeInsets.all(8.0)),
                                      GestureDetector(
                                        child: Text("Gallery"),
                                        onTap: () {
                                          _pickImage("Gallery");
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          width: mq.width * 0.5,
                          height: mq.width * 0.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A3D3F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              _selectedImage == null
                                  ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Add Photo",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: mq.width * 0.045,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Icon(
                                        Icons.photo_library,
                                        color: Colors.white,
                                        size: mq.width * 0.2,
                                      ),
                                    ],
                                  )
                                  : ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                        ),
                      ),

                      SizedBox(height: mq.height * 0.05),
                      _isAnalyzing
                          ? CircularProgressIndicator() // show data here
                          : Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: mq.width * 0.05,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'ANALYZE YOUR FACE WITH AI',
                                      style: TextStyle(
                                        fontSize:
                                            mq.width *
                                            0.055, // Reduced from 0.06
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1, // Reduced from 1.2
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: mq.height * 0.01),
                                    Text(
                                      'AGE, GENDER, EMOTION',
                                      style: TextStyle(
                                        fontSize:
                                            mq.width *
                                            0.055, // Reduced from 0.06
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1, // Reduced from 1.2
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: mq.height * 0.01),
                                    SizedBox(
                                      width: mq.width * 0.5,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0A3D3F,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: mq.height * 0.02,
                                          ),
                                        ),
                                        onPressed: () {
                                          if (_selectedImage != null) {
                                            _analyzeImage();
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Please select an image first.",
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: Text("Analyze"),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Added fixed height instead of Spacer
                              SizedBox(height: mq.height * 0.2),
                            ],
                          ),
                    ],
                  ),
                ),
              )
              : _screens[_selectedIndex],

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        height: mq.height * 0.07,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home, mq),
            _buildNavItem(1, Icons.phone_android, mq),
            _buildNavItem(2, Icons.person, mq),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, Size mq) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Icon(
        icon,
        color: isSelected ? const Color(0xFF0A3D3F) : Colors.grey,
        size:
            isSelected
                ? mq.width * 0.1
                : mq.width * 0.08, // Reduced from 0.08/0.06
      ),
    );
  }
}
