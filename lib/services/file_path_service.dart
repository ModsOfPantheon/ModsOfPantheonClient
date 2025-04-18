import 'dart:io';
import 'package:path/path.dart' as path;

class FilePathService {
  static const _configDirName = 'ModsOfPantheon';
  static const _configFileName = 'Config.json';
  static const _installedModsFileName = 'InstalledMods.json';
  static const _modArchivesDirName = 'ModArchives';

  static String? _appDataPath;

  static String get _configDirPath {
    final appData = _appDataPath ?? Platform.environment['APPDATA'];
    if (appData == null) throw Exception('APPDATA environment variable not found');
    return path.join(appData, _configDirName);
  }

  static String get configFilePath => path.join(_configDirPath, _configFileName);
  static String get installedModsFilePath => path.join(_configDirPath, _installedModsFileName);
  static String get modArchivesDirPath => path.join(_configDirPath, _modArchivesDirName);

  static String get tempDirPath => path.join(_configDirPath, 'temp');

  static Future<void> ensureConfigDirExists() async {
    final configDir = Directory(_configDirPath);
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }

    final modArchivesDir = Directory(modArchivesDirPath);
    if (!await modArchivesDir.exists()) {
      await modArchivesDir.create(recursive: true);
    }

    final tempDir = Directory(tempDirPath);
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
  }

  // For testing purposes
  static void setAppDataPath(String path) {
    _appDataPath = path;
  }
} 