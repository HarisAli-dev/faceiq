import 'package:faceiq/view/compare_screens/compare_screen.dart';
import 'package:faceiq/view/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/face_api_service.dart';
import '../model/face_analysis.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  File? _selectedImage;
  bool _isAnalyzing = false;
  AnalysisResponse? _analysisResult;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();
  final FaceApiService _faceApiService = FaceApiService(
    baseUrl: 'http://192.168.137.86:8008', // Replace with your actual API URL
  );

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
        _analysisResult = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final result = await _faceApiService.analyzeFace(_selectedImage!);
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
    } on FaceApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isAnalyzing = false;
      });
    }
  }

 Widget _buildAnalysisResults() {
  if (_errorMessage != null) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(
            'Error: $_errorMessage',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  if (_analysisResult == null) return const SizedBox.shrink();

  final analysis = _analysisResult!;
  final Size mq = MediaQuery.of(context).size;

  if (analysis.facesDetected == 0 || analysis.faces.isEmpty) {
    return Container(
      width: mq.width * 0.9,
      padding: EdgeInsets.all(mq.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.face_retouching_off, color: Colors.orange, size: 48),
          const SizedBox(height: 10),
          Text(
            'No faces detected in the image',
            style: TextStyle(
              fontSize: mq.width * 0.045,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Please try uploading a clearer image with visible faces.',
            style: TextStyle(
              fontSize: mq.width * 0.04,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // If faces are detected, show summary and create a card for each face
  return Column(
    children: [
      Container(
        width: mq.width * 0.9,
        padding: EdgeInsets.all(mq.width * 0.03),
        margin: EdgeInsets.only(bottom: mq.height * 0.02),
        decoration: BoxDecoration(
          color: const Color(0xFF0A3D3F),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Detected ${analysis.facesDetected} ${analysis.facesDetected == 1 ? "Face" : "Faces"}',
          style: TextStyle(
            fontSize: mq.width * 0.05,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      ...analysis.faces.asMap().entries.map((entry) {
        int index = entry.key;
        FaceInfo face = entry.value;
        return _buildFaceCard(face, index + 1, mq);
      }).toList(),
    ],
  );
}

Widget _buildFaceCard(FaceInfo face, int faceNumber, Size mq) {
  return Container(
    width: mq.width * 0.9,
    margin: const EdgeInsets.only(bottom: 20),
    padding: EdgeInsets.all(mq.width * 0.04),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0A3D3F),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$faceNumber',
                  style: TextStyle(
                    fontSize: mq.width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Face #$faceNumber Details',
              style: TextStyle(
                fontSize: mq.width * 0.05,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0A3D3F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        const Divider(),
        const SizedBox(height: 5),

        // Age
        _buildResultItem(
          icon: Icons.calendar_today,
          title: 'Age',
          value: '${face.age?.toString() ?? "Unknown"}',
        ),

        const Divider(height: 20),

        // Gender
        _buildResultItem(
          icon: Icons.person,
          title: 'Gender',
          value: face.gender ?? 'Unknown',
        ),

        const Divider(height: 20),

        // Dominant Race
        _buildResultItem(
          icon: Icons.people,
          title: 'Dominant Race',
          value: face.dominantRace?.capitalize() ?? 'Unknown',
        ),

        // Race details
        if (face.race != null && face.race!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Race Breakdown:',
                  style: TextStyle(
                    fontSize: mq.width * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                ..._buildAttributeBars(face.race!, lightGreenColor),
              ],
            ),
          ),

        const Divider(height: 20),

        // Dominant Emotion
        _buildResultItem(
          icon: Icons.emoji_emotions,
          title: 'Dominant Emotion',
          value: face.dominantEmotion?.capitalize() ?? 'Unknown',
        ),

        // Emotion details
        if (face.emotions != null && face.emotions!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emotion Breakdown:',
                  style: TextStyle(
                    fontSize: mq.width * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                ..._buildAttributeBars(face.emotions!, blueishColor),
              ],
            ),
          ),

        // Confidence score
        const SizedBox(height: 10),
        _buildResultItem(
          icon: Icons.check_circle,
          title: 'Detection Confidence',
          value: '${(face.confidence * 100).toStringAsFixed(1)}%',
        ),
      ],
    ),
  );
}
// Helper method to build attribute bars (emotions, race, etc.)
List<Widget> _buildAttributeBars(Map<String, double> attributes, Color barColor) {
  // Sort entries by value in descending order
  final sortedEntries = attributes.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sortedEntries.map((entry) {
    final attributeName = entry.key.capitalize();
    // For values that are already percentages (like in the API response)
    final percentage = entry.value.toStringAsFixed(1);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$attributeName: $percentage%'),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: entry.value / 100, // Convert percentage to value between 0-1
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }).toList();
}

// Define colors for different attribute types
final blueishColor = const Color(0xFF0A3D3F);
final lightGreenColor = const Color(0xFF4CAF50);
  Widget _buildResultItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0A3D3F), size: 24),
        const SizedBox(width: 10),
        Text(
          '$title: ',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
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
                                title: const Text("Select Image Source"),
                                content: SingleChildScrollView(
                                  child: ListBody(
                                    children: <Widget>[
                                      GestureDetector(
                                        child: const Text("Camera"),
                                        onTap: () {
                                          _pickImage("camera");
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                      ),
                                      GestureDetector(
                                        child: const Text("Gallery"),
                                        onTap: () {
                                          _pickImage("gallery");
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
                          ? const CircularProgressIndicator(
                            color: Color(0xFF0A3D3F),
                          )
                          : _analysisResult != null || _errorMessage != null
                          ? _buildAnalysisResults()
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
                                        fontSize: mq.width * 0.055,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: mq.height * 0.01),
                                    Text(
                                      'AGE, GENDER, EMOTION',
                                      style: TextStyle(
                                        fontSize: mq.width * 0.055,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
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
                                              const SnackBar(
                                                content: Text(
                                                  "Please select an image first.",
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text("Analyze"),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
        size: isSelected ? mq.width * 0.1 : mq.width * 0.08,
      ),
    );
  }
}

// Helper extension for capitalizing strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
