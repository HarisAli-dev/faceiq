import 'dart:io';

import 'package:flutter/material.dart';

class CompareResultScreen extends StatelessWidget {
  final File firstImage;
  final File secondImage;

  const CompareResultScreen({
    super.key,
    required this.firstImage,
    required this.secondImage,
  });

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analyze Image',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Images side by side
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(firstImage, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(secondImage, fit: BoxFit.cover),
                    ),
                  ),
                ],
              ),

              SizedBox(height: mq.height * 0.04),

              // Placeholder for comparison results
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0A3D3F)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Similarity Score: 78%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildComparisonItem('Age', '32 years', '30 years'),
                    _buildComparisonItem('Gender', 'Male', 'Male'),
                    _buildComparisonItem('Emotion', 'Happy', 'Neutral'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonItem(String feature, String value1, String value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(child: Text(value1, textAlign: TextAlign.center)),
                const Expanded(
                  child: Text(
                    'vs',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(child: Text(value2, textAlign: TextAlign.center)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
