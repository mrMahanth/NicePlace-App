class ProjectMediaModel {
  final int id;
  final String? file;
  final String? videoUrl;
  final String mediaType; // 'image' or 'video'
  final int order;
  final bool isCover;

  ProjectMediaModel({
    required this.id,
    this.file,
    this.videoUrl,
    required this.mediaType,
    this.order = 0,
    this.isCover = false,
  });

  factory ProjectMediaModel.fromJson(Map<String, dynamic> json) {
    return ProjectMediaModel(
      id: json['id'],
      file: json['file'],
      videoUrl: json['video_url'],
      mediaType: json['media_type'] ?? 'image',
      order: json['order'] ?? 0,
      isCover: json['is_cover'] ?? false,
    );
  }
}