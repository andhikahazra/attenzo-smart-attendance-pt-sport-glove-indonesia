class FacePhotosData {
  final int userId;
  final List<String> photoPath;
  final List<String> photoUrls;

  FacePhotosData({
    required this.userId,
    required this.photoPath,
    required this.photoUrls,
  });

  factory FacePhotosData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return FacePhotosData(
      userId: data['user_id'] as int? ?? 0,
      photoPath: List<String>.from(data['photo_path'] ?? const []),
      photoUrls: List<String>.from(data['photo_urls'] ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'photo_path': photoPath,
      'photo_urls': photoUrls,
    };
  }
}
