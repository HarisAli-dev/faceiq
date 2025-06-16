// file: lib/services/face_api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../model/face_analysis.dart';
import 'package:http_parser/http_parser.dart';
import '../model/face_comparison.dart';

class FaceApiService {
  final String baseUrl;

  FaceApiService({required this.baseUrl});
  Future<FaceComparisonResponse> compareFaces(
    File firstImage,
    File secondImage,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/compare');
      print('Sending comparison request to: $uri');

      final request = http.MultipartRequest('POST', uri);

      // Add both image files
      request.files.add(
        await http.MultipartFile.fromPath(
          'file1',
          firstImage.path,
          contentType: MediaType('image', 'jpeg'), // Adjust if needed
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file2',
          secondImage.path,
          contentType: MediaType('image', 'jpeg'), // Adjust if needed
        ),
      );

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Debug response
      print('Comparison response status code: ${response.statusCode}');
      print(
        'Comparison response body preview: ${response.body.substring(0, min(100, response.body.length))}...',
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return FaceComparisonResponse.fromJson(jsonData);
      } else {
        // Parse error response
        String errorMessage = 'HTTP Error: ${response.statusCode}';

        try {
          final errorData = jsonDecode(response.body);

          // Handle specific error types
          if (errorData['error_type'] == 'face_detection_failed') {
            errorMessage = 'Could not detect faces in one or both images';
          } else if (errorData['error_type'] == 'invalid_image') {
            errorMessage = 'Invalid image format or corrupted image';
          } else {
            errorMessage = errorData['message'] ?? 'Unknown error occurred';
          }

          print('Error data from API: $errorData');
        } catch (parseError) {
          print('Failed to parse error JSON: $parseError');
          errorMessage =
              'API Error: ${response.body.substring(0, min(100, response.body.length))}';
        }

        throw FaceApiException(
          message: errorMessage,
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (_) {
      throw FaceApiException(
        message:
            'Network error: Cannot connect to server. Please check your internet connection.',
        statusCode: 0,
      );
    } catch (e) {
      if (e is FaceApiException) rethrow;
      print('Unexpected error: $e');
      throw FaceApiException(
        message: 'Unexpected error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<AnalysisResponse> analyzeFace(
    File imageFile, {
    bool saveRender = false,
  }) async {
    try {
      // Create multipart request
      final uri = Uri.parse('$baseUrl/analyze');

      // Debug the URL
      print('Sending request to: $uri');

      final request = http.MultipartRequest('POST', uri);

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Add optional parameter
      request.fields['save_render'] = saveRender.toString();

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Debug response
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}...');

      // Check if request was successful
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Parse the full response
        final analysisResponse = AnalysisResponse.fromJson(jsonData);

        // Return the first face info if available, otherwise throw an error
        if (analysisResponse.facesDetected > 0 &&
            analysisResponse.faces.isNotEmpty) {
          return analysisResponse;
        } else {
          throw FaceApiException(
            message: 'No faces detected in the image',
            statusCode: response.statusCode,
          );
        }
      } else {
        // Parse error response
        String errorMessage = 'HTTP Error: ${response.statusCode}';

        try {
          final errorData = jsonDecode(response.body);

          // Try different common error message fields
          errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              errorData['detail'] ??
              errorData['error_message'] ??
              errorData.toString();

          print('Error data from API: $errorData');
        } catch (parseError) {
          // If JSON parsing fails, use the raw response body (limited to first 100 chars)
          print('Failed to parse error JSON: $parseError');
          errorMessage =
              'API Error: ${response.body.substring(0, min(100, response.body.length))}';
        }

        throw FaceApiException(
          message: errorMessage,
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw FaceApiException(
        message:
            'Network error: Cannot connect to server. Please check your internet connection.',
        statusCode: 0,
      );
    } catch (e) {
      if (e is FaceApiException) rethrow;
      print('Unexpected error: $e');
      throw FaceApiException(
        message: 'Unexpected error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}

class FaceApiException implements Exception {
  final String message;
  final int statusCode;

  FaceApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'FaceApiException: $message (Code: $statusCode)';
}

// Helper function since Dart's math.min requires import
int min(int a, int b) => a < b ? a : b;
