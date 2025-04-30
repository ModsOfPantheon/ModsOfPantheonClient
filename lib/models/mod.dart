class Mod {
  final int id;
  final String name;
  final String shortDescription;
  final String author;
  final DateTime createdAt;
  final String latestVersion;
  final String? githubUrl;

  Mod({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.author,
    required this.createdAt,
    required this.latestVersion,
    this.githubUrl,
  });

  factory Mod.fromJson(Map<String, dynamic> json) {
    return Mod(
      id: json['Id'],
      name: json['Name'],
      shortDescription: json['ShortDescription'],
      author: json['Author'],
      createdAt: DateTime.parse(json['CreatedAt']),
      latestVersion: json['LatestVersion'],
      githubUrl: json['GithubUrl'],
    );
  }
} 