// lib/video_model.dart
class VideoModel {
  final String videoId;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String publishedAt;

  VideoModel({
    required this.videoId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.publishedAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      videoId: json['id']['videoId'],
      title: json['snippet']['title'],
      description: json['snippet']['description'],
      thumbnailUrl: json['snippet']['thumbnails']['high']['url'],
      publishedAt: json['snippet']['publishedAt'],
    );
  }
}
