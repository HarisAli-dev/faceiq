import 'dart:io';
import 'package:flutter/material.dart';
import '../../model/face_comparison.dart';
import '../../services/face_api_service.dart';

class ComparisonResultScreen extends StatefulWidget {
  final File firstImage;
  final File secondImage;

  const ComparisonResultScreen({
    super.key,
    required this.firstImage,
    required this.secondImage,
  });

  @override
  State<ComparisonResultScreen> createState() => _ComparisonResultScreenState();
}

class _ComparisonResultScreenState extends State<ComparisonResultScreen> {
  bool _isLoading = true;
  FaceComparisonResponse? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _compareFaces();
  }

  Future<void> _compareFaces() async {
    final FaceApiService apiService = FaceApiService(
      baseUrl: 'http://192.168.137.86:8008',
    );

    try {
      final result = await apiService.compareFaces(
        widget.firstImage,
        widget.secondImage,
      );

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } on FaceApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Face Comparison Results',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0A3D3F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFFFFCF0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(mq.width * 0.04),
          child:
              _isLoading
                  ? _buildLoadingState(mq)
                  : _errorMessage != null
                  ? _buildErrorState(mq)
                  : _buildResultContent(mq),
        ),
      ),
    );
  }

  Widget _buildLoadingState(Size mq) {
    return Container(
      height: mq.height * 0.7,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show the two images side by side
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildImageThumbnail(widget.firstImage, mq, 'First Image'),
              _buildImageThumbnail(widget.secondImage, mq, 'Second Image'),
            ],
          ),
          SizedBox(height: mq.height * 0.04),
          const CircularProgressIndicator(
            color: Color(0xFF0A3D3F),
            strokeWidth: 4,
          ),
          SizedBox(height: mq.height * 0.03),
          Text(
            'Comparing faces...',
            style: TextStyle(
              fontSize: mq.width * 0.05,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A3D3F),
            ),
          ),
          SizedBox(height: mq.height * 0.01),
          Text(
            'This may take a moment',
            style: TextStyle(
              fontSize: mq.width * 0.04,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Size mq) {
    return Container(
      height: mq.height * 0.7,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show the two images side by side
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildImageThumbnail(widget.firstImage, mq, 'First Image'),
              _buildImageThumbnail(widget.secondImage, mq, 'Second Image'),
            ],
          ),
          SizedBox(height: mq.height * 0.04),
          Icon(Icons.error_outline, color: Colors.red, size: mq.width * 0.15),
          SizedBox(height: mq.height * 0.02),
          Text(
            'Error',
            style: TextStyle(
              fontSize: mq.width * 0.055,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: mq.height * 0.01),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * 0.05),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: mq.width * 0.04,
                color: Colors.grey[800],
              ),
            ),
          ),
          SizedBox(height: mq.height * 0.03),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _compareFaces();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A3D3F),
              padding: EdgeInsets.symmetric(
                horizontal: mq.width * 0.08,
                vertical: mq.width * 0.03,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Try Again',
              style: TextStyle(
                fontSize: mq.width * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(File image, Size mq, String label) {
    return Column(
      children: [
        Container(
          width: mq.width * 0.35,
          height: mq.width * 0.35,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF0A3D3F), width: 2),
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(image: FileImage(image), fit: BoxFit.cover),
          ),
        ),
        SizedBox(height: mq.height * 0.01),
        Text(
          label,
          style: TextStyle(fontSize: mq.width * 0.035, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildResultContent(Size mq) {
    if (_result == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Images row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildImageThumbnail(widget.firstImage, mq, 'First Face'),
            _buildImageThumbnail(widget.secondImage, mq, 'Second Face'),
          ],
        ),
        SizedBox(height: mq.height * 0.03),

        // Main result card
        _buildResultCard(mq),

        SizedBox(height: mq.height * 0.03),

        // Detailed information card
        _buildDetailsCard(mq),

        SizedBox(height: mq.height * 0.03),

        // Technical details card
        _buildTechnicalDetailsCard(mq),
      ],
    );
  }

  Widget _buildResultCard(Size mq) {
    final result = _result!;
    Color resultColor =
        (result.verified && result.similarityPercentage > 70) ? const Color(0xFF4CAF50) : const Color(0xFFF44336);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mq.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            (result.verified && result.similarityPercentage > 70) ? Icons.check_circle : Icons.cancel,
            color: resultColor,
            size: mq.width * 0.2,
          ),
          SizedBox(height: mq.height * 0.02),
          Text(
            result.resultDescription,
            style: TextStyle(
              fontSize: mq.width * 0.065,
              fontWeight: FontWeight.bold,
              color: resultColor,
            ),
          ),
          SizedBox(height: mq.height * 0.01),
          Text(
            '${result.similarityPercentage.toStringAsFixed(1)}% similarity',
            style: TextStyle(
              fontSize: mq.width * 0.05,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: mq.height * 0.02),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: mq.width * 0.04,
              vertical: mq.width * 0.02,
            ),
            decoration: BoxDecoration(
              color: Color(
                int.parse(result.confidenceColor.substring(1, 7), radix: 16) |
                    0xFF000000,
              ).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Confidence: ${result.confidenceLevel}',
              style: TextStyle(
                fontSize: mq.width * 0.04,
                fontWeight: FontWeight.w500,
                color: Color(
                  int.parse(result.confidenceColor.substring(1, 7), radix: 16) |
                      0xFF000000,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Size mq) {
    final result = _result!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mq.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis Details',
            style: TextStyle(
              fontSize: mq.width * 0.05,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0A3D3F),
            ),
          ),
          const Divider(height: 25),
          Text(
            result.interpretation,
            style: TextStyle(
              fontSize: mq.width * 0.045,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Similarity',
                  '${result.similarityPercentage.toStringAsFixed(1)}%',
                  mq,
                ),
              ),
              Expanded(child: _buildDetailItem('Model', result.model, mq)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Metric', result.similarityMetric, mq),
              ),
              Expanded(child: _buildDetailItem('Status', result.status, mq)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalDetailsCard(Size mq) {
    final result = _result!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mq.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.code,
                size: mq.width * 0.05,
                color: const Color(0xFF0A3D3F),
              ),
              SizedBox(width: mq.width * 0.02),
              Text(
                'Technical Details',
                style: TextStyle(
                  fontSize: mq.width * 0.05,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0A3D3F),
                ),
              ),
            ],
          ),
          const Divider(height: 25),
          _buildTechnicalItem(
            'Distance Value',
            result.distance.toStringAsFixed(4),
            mq,
          ),
          _buildTechnicalItem(
            'Threshold',
            result.threshold.toStringAsFixed(4),
            mq,
          ),
          _buildTechnicalItem(
            'Distance from Threshold',
            result.technicalDetails['distance_from_threshold']?.toString() ??
                'N/A',
            mq,
          ),
          _buildTechnicalItem(
            'Verification Passed',
            result.technicalDetails['verification_passed'] ? 'Yes' : 'No',
            mq,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, Size mq) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: mq.width * 0.035,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: mq.width * 0.04,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalItem(String label, String value, Size mq) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: mq.width * 0.04,
              color: Colors.grey[800],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: mq.width * 0.04,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
