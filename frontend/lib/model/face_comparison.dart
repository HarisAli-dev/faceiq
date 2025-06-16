class FaceComparisonResponse {
  final bool verified;
  final double similarityPercentage;
  final String confidenceLevel;
  final String interpretation;
  final double distance;
  final double threshold;
  final String model;
  final String similarityMetric;
  final String status;
  final Map<String, dynamic> technicalDetails;

  FaceComparisonResponse({
    required this.verified,
    required this.similarityPercentage,
    required this.confidenceLevel,
    required this.interpretation,
    required this.distance,
    required this.threshold,
    required this.model,
    required this.similarityMetric,
    required this.status,
    required this.technicalDetails,
  });

  factory FaceComparisonResponse.fromJson(Map<String, dynamic> json) {
    return FaceComparisonResponse(
      verified: json['verified'] ?? false,
      similarityPercentage: json['similarity_percentage']?.toDouble() ?? 0.0,
      confidenceLevel: json['confidence_level'] ?? 'Unknown',
      interpretation: json['interpretation'] ?? 'No interpretation available',
      distance: json['distance']?.toDouble() ?? 0.0,
      threshold: json['threshold']?.toDouble() ?? 0.0,
      model: json['model'] ?? 'Unknown',
      similarityMetric: json['similarity_metric'] ?? 'Unknown',
      status: json['status'] ?? 'error',
      technicalDetails: json['technical_details'] ?? {},
    );
  }

  // Helper method to get a simplified result description
  String get resultDescription {
    return verified ? 'Same Person' : 'Different People';
  }

  // Helper method to get confidence color (for UI)
  String get confidenceColor {
    if (confidenceLevel == 'Very High') return '#4CAF50'; // Green
    if (confidenceLevel == 'High') return '#8BC34A'; // Light Green
    if (confidenceLevel == 'Medium') return '#FFC107'; // Amber
    if (confidenceLevel == 'Low') return '#FF9800'; // Orange
    return '#F44336'; // Red for 'Very Low'
  }
}

class ComparisonError {
  final String status;
  final String message;
  final String errorType;

  ComparisonError({
    required this.status,
    required this.message,
    required this.errorType,
  });

  factory ComparisonError.fromJson(Map<String, dynamic> json) {
    return ComparisonError(
      status: json['status'] ?? 'error',
      message: json['message'] ?? 'Unknown error occurred',
      errorType: json['error_type'] ?? 'unknown_error',
    );
  }
}