import 'package:faceiq/view/compare_screens/compare_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  File? _firstImage;
  File? _secondImage;
  final ImagePicker _picker = ImagePicker();
  bool _isComparing = false;

  // Reusable method to pick images
  Future<void> _pickImage(bool isFirstImage, ImageSource source) async {
    try {
      final XFile? pickedImage = await _picker.pickImage(source: source);
      if (pickedImage != null) {
        setState(() {
          if (isFirstImage) {
            _firstImage = File(pickedImage.path);
          } else {
            _secondImage = File(pickedImage.path);
          }
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _compareImages() {
    if (_firstImage != null && _secondImage != null) {
      setState(() {
        _isComparing = true;
      });

      // Simulate comparison process
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isComparing = false;
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CompareResultScreen(
                    firstImage: _firstImage!,
                    secondImage: _secondImage!,
                  ),
            ),
          );
        }
      });
    }
  }

  Widget _buildImageBox(bool isFirstImage, Size mq) {
    final File? currentImage = isFirstImage ? _firstImage : _secondImage;

    return GestureDetector(
      onTap: () => _showImageSourceDialog(isFirstImage),
      child: Container(
        width: mq.width * 0.42,
        height: mq.width * 0.42,
        decoration: BoxDecoration(
          color: currentImage == null ? Colors.grey[300] : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF0A3D3F), width: 2),
        ),
        child:
            currentImage == null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      color: const Color(0xFF0A3D3F),
                      size: mq.width * 0.1,
                    ),
                    Text(
                      isFirstImage ? "First Photo" : "Second Photo",
                      style: TextStyle(
                        color: const Color(0xFF0A3D3F),
                        fontSize: mq.width * 0.035,
                      ),
                    ),
                  ],
                )
                : ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.file(currentImage, fit: BoxFit.cover),
                ),
      ),
    );
  }

  void _showImageSourceDialog(bool isFirstImage) {
    showDialog(
      context: context,
      builder:
          (context) => SimpleDialog(
            backgroundColor: const Color(0xFFFFFCF0),
            title: Text(
              isFirstImage ? 'Select First Image' : 'Select Second Image',
            ),
            children: [
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(isFirstImage, ImageSource.gallery);
                },
                child: const Row(
                  children: [
                    Icon(Icons.photo_library),
                    SizedBox(width: 10),
                    Text('Choose from Gallery'),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(isFirstImage, ImageSource.camera);
                },
                child: const Row(
                  children: [
                    Icon(Icons.camera_alt),
                    SizedBox(width: 10),
                    Text('Take a Photo'),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF0),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: mq.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: mq.height * 0.03),
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: mq.width * 0.7,
                height: mq.width * 0.3,
              ),
            ),

            SizedBox(height: mq.height * 0.04),

            // Image selection boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_buildImageBox(true, mq), _buildImageBox(false, mq)],
            ),

            SizedBox(height: mq.height * 0.04),
            Text(
              'UPLOAD TWO PHOTOS TO COMPARE',
              style: TextStyle(
                fontSize: mq.width * 0.055,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: mq.height * 0.06),

            // Compare button
            if (_firstImage != null && _secondImage != null)
              SizedBox(
                width: mq.width * 0.6,
                child: ElevatedButton(
                  onPressed: _isComparing ? null : _compareImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A3D3F),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: mq.height * 0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child:
                      _isComparing
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            'Compare Images',
                            style: TextStyle(
                              fontSize: mq.width * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
