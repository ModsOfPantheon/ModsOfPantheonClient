class ModFile {
  final int id;
  final String originalFileName;
  final String fileContent;

  ModFile({
    required this.id,
    required this.originalFileName,
    required this.fileContent,
  });

  factory ModFile.fromJson(Map<String, dynamic> json) {
    return ModFile(
      id: json['Id'],
      originalFileName: json['OriginalFileName'],
      fileContent: json['FileContent']
    );
  }
} 