class ModVersion {
  final int id;
  final String version;
  final DateTime createdAt;
  final int modId;
  final int fileId;

  ModVersion({
    required this.id,
    required this.version,
    required this.createdAt,
    required this.modId,
    required this.fileId,
  });

  factory ModVersion.fromJson(Map<String, dynamic> json) {
    return ModVersion(
      id: json['Id'] as int,
      version: json['Version'] as String,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      modId: json['ModId'] as int,
      fileId: json['FileId'] as int,
    );
  }
} 