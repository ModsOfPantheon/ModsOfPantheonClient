class Mod {
  final int id;
  final String name;
  final String shortDescription;
  final String author;
  final DateTime createdAt;
  final int? latestVersionId;

  Mod({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.author,
    required this.createdAt,
    this.latestVersionId,
  });

  factory Mod.fromJson(Map<String, dynamic> json) {
    return Mod(
      id: json['Id'],
      name: json['Name'],
      shortDescription: json['ShortDescription'],
      author: json['Author'],
      createdAt: DateTime.parse(json['CreatedAt']),
      latestVersionId: json['LatestVersionId'],
    );
  }
} 