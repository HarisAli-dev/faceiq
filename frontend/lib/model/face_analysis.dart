import 'dart:ui';

class AnalysisResponse {
  final String status;
  final int facesDetected;
  final List<FaceInfo> faces;

  AnalysisResponse({
    required this.status,
    required this.facesDetected,
    required this.faces,
  });

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> facesJson = json['faces'] ?? [];
    return AnalysisResponse(
      status: json['status'] ?? '',
      facesDetected: json['faces_detected'] ?? 0,
      faces: facesJson.map((faceJson) => FaceInfo.fromJson(faceJson)).toList(),
    );
  }
}

class FaceInfo {
  final FacePosition position;
  final double confidence;
  final int? age;
  final String? gender;
  final String? dominantRace;
  final String? dominantEmotion;
  final Map<String, double>? emotions;
  final Map<String, double>? race;

  FaceInfo({
    required this.position,
    required this.confidence,
    this.age,
    this.gender,
    this.dominantRace,
    this.dominantEmotion,
    this.emotions,
    this.race,
  });

  factory FaceInfo.fromJson(Map<String, dynamic> json) {
    // Parse position
    final positionJson = json['position'] as Map<String, dynamic>;
    
    // Parse emotions if available
    Map<String, double>? emotionsMap;
    if (json['emotion'] != null) {
      emotionsMap = Map<String, double>.from(
        json['emotion'].map((key, value) => MapEntry(key, value.toDouble()))
      );
    }
    
    // Parse race data if available
    Map<String, double>? raceMap;
    if (json['race'] != null) {
      raceMap = Map<String, double>.from(
        json['race'].map((key, value) => MapEntry(key, value.toDouble()))
      );
    }
    
    return FaceInfo(
      position: FacePosition(
        x: positionJson['x'] as int,
        y: positionJson['y'] as int,
        w: positionJson['w'] as int,
        h: positionJson['h'] as int,
      ),
      confidence: (json['confidence'] as num).toDouble(),
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      dominantRace: json['dominant_race'] as String?,
      dominantEmotion: json['dominant_emotion'] as String?,
      emotions: emotionsMap,
      race: raceMap,
    );
  }
}

class FacePosition {
  final int x;
  final int y;
  final int w;
  final int h;

  FacePosition({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  factory FacePosition.fromJson(Map<String, dynamic> json) {
    return FacePosition(
      x: json['x'] as int,
      y: json['y'] as int,
      w: json['w'] as int,
      h: json['h'] as int,
    );
  }

  // Helper method to convert to Rect
  Rect toRect() {
    return Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble());
  }
}