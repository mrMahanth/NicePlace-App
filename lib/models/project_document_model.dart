class ProjectDocumentModel {
  final int id;
  final String label;
  final String file;

  ProjectDocumentModel({required this.id, required this.label, required this.file});

  factory ProjectDocumentModel.fromJson(Map<String, dynamic> json) {
    return ProjectDocumentModel(
      id: json['id'],
      label: json['label'] ?? '',
      file: json['file'] ?? '',
    );
  }
}