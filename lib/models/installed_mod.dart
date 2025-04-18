class InstalledMod {
  final int modId;
  final String modName;
  final int versionId;
  final String version;
  final DateTime installedAt;
  final String archivePath;

  InstalledMod({
    required this.modId,
    required this.modName,
    required this.versionId,
    required this.version,
    required this.installedAt,
    required this.archivePath,
  });

  Map<String, dynamic> toJson() => {
    'modId': modId,
    'modName': modName,
    'versionId': versionId,
    'version': version,
    'installedAt': installedAt.toIso8601String(),
    'archivePath': archivePath,
  };

  factory InstalledMod.fromJson(Map<String, dynamic> json) => InstalledMod(
    modId: json['modId'],
    modName: json['modName'],
    versionId: json['versionId'],
    version: json['version'],
    installedAt: DateTime.parse(json['installedAt']),
    archivePath: json['archivePath'],
  );
} 