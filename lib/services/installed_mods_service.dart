import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import '../models/installed_mod.dart';
import '../models/mod.dart';
import 'file_path_service.dart';
import 'prerequisite_checker.dart';
import 'api_service.dart';

class InstalledModsService {
  static List<InstalledMod> _installedMods = [];

  static String get _modsFilePath {
    final gameFolder = PrerequisiteChecker.gameFolderPath;
    if (gameFolder == null) {
      throw Exception('Game folder not set');
    }
    // Create a unique identifier for the game folder
    final folderHash = gameFolder.hashCode.toRadixString(16);
    return path.join(FilePathService.modArchivesDirPath, 'mods_$folderHash.json');
  }

  static Future<void> _loadInstalledMods() async {
    await FilePathService.ensureConfigDirExists();

    final file = File(_modsFilePath);
    if (!await file.exists()) {
      _installedMods = [];
      return;
    }

    try {
      final json = await file.readAsString();
      final List<dynamic> data = jsonDecode(json);
      _installedMods = data.map((e) => InstalledMod.fromJson(e)).toList();
    } catch (e) {
      _installedMods = [];
    }
  }

  static Future<void> _saveInstalledMods() async {
    await FilePathService.ensureConfigDirExists();

    final file = File(_modsFilePath);
    final json = jsonEncode(_installedMods.map((e) => e.toJson()).toList());
    await file.writeAsString(json);
  }

  static Future<List<InstalledMod>> getInstalledMods() async {
    await _loadInstalledMods();
    return _installedMods;
  }

  static Future<void> addInstalledMod(InstalledMod mod) async {
    await _loadInstalledMods();
    // Remove any existing version of this mod
    _installedMods.removeWhere((m) => m.modId == mod.modId);
    _installedMods.add(mod);
    await _saveInstalledMods();
  }

  static Future<void> removeInstalledMod(int modId) async {
    await _loadInstalledMods();
    _installedMods.removeWhere((m) => m.modId == modId);
    await _saveInstalledMods();
  }

  static Future<InstalledMod?> getInstalledVersion(int modId) async {
    await _loadInstalledMods();
    try {
      return _installedMods.firstWhere((m) => m.modId == modId);
    } catch (e) {
      return null;
    }
  }

  static Future<void> restoreAllMods() async {
    final gameFolder = PrerequisiteChecker.gameFolderPath;
    if (gameFolder == null) {
      throw Exception('Game folder not set');
    }

    await _loadInstalledMods();
    for (final mod in _installedMods) {
      try {
        // Load the saved archive
        final archiveFile = File(mod.archivePath);
        if (!await archiveFile.exists()) {
          throw Exception('Mod archive not found for ${mod.modName}. Please reinstall the mod.');
        }

        final bytes = await archiveFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        
        // Extract all files to the game folder
        for (final file in archive.files) {
          if (file.isFile) {
            final filePath = path.join(gameFolder, file.name);
            final outputFile = File(filePath);
            try {
              await outputFile.create(recursive: true);
              await outputFile.writeAsBytes(file.content);
            } on FileSystemException catch (e) {
              if (e.osError?.message.toLowerCase().contains('access denied') ?? false) {
                throw Exception('The game appears to be running. Please close the game and try again.');
              }
              throw Exception('Failed to write to ${e.path}: ${e.message}');
            }
          }
        }
      } catch (e) {
        throw Exception('Failed to restore ${mod.modName}: ${e.toString()}');
      }
    }
  }

  static Future<void> uninstallMod(int modId) async {
    final gameFolder = PrerequisiteChecker.gameFolderPath;
    if (gameFolder == null) {
      throw Exception('Game folder not set');
    }

    // Get the installed mod record to get the archive path
    final installedMod = await getInstalledVersion(modId);
    if (installedMod == null) {
      throw Exception('Mod not found in installed mods list');
    }

    // Load the saved archive
    final archiveFile = File(installedMod.archivePath);
    if (!await archiveFile.exists()) {
      throw Exception('Mod archive not found');
    }

    final bytes = await archiveFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Track which files we've successfully deleted
    final deletedFiles = <String>[];

    // Delete all files from the game folder
    for (final file in archive.files) {
      if (file.isFile) {
        final filePath = path.join(gameFolder, file.name);
        final outputFile = File(filePath);
        if (await outputFile.exists()) {
          try {
            await outputFile.delete();
            deletedFiles.add(filePath);
          } on FileSystemException catch (e) {
            if (e.osError?.message.toLowerCase().contains('access denied') ?? false) {
              throw Exception('The game appears to be running. Please close the game and try again.');
            }
            throw Exception('Failed to delete ${e.path}: ${e.message}');
          }
        }
      }
    }

    // Clean up empty directories
    for (final file in archive.files) {
      if (file.isFile) {
        final filePath = path.join(gameFolder, file.name);
        final directory = Directory(path.dirname(filePath));
        if (await directory.exists()) {
          try {
            // Try to delete the directory, but don't throw if it fails
            // (it might contain other files)
            await directory.delete(recursive: false);
          } catch (e) {
            // Ignore errors when deleting directories
          }
        }
      }
    }

    // Remove from installed mods list but keep the archive for future restoration
    await removeInstalledMod(modId);
  }

  static Future<void> installLatestVersion(Mod mod) async {
    final gameFolder = PrerequisiteChecker.gameFolderPath;
    if (gameFolder == null) {
      throw Exception('Game folder not set');
    }

    // Get the latest version
    final versions = await ApiService.getModVersions(mod.id);
    if (versions.isEmpty) {
      throw Exception('No versions available for this mod');
    }
    final latestVersion = versions.first;

    // Get the mod file
    final modFile = await ApiService.getModFile(latestVersion.fileId);
    
    // Decode base64 string to bytes
    final bytes = base64.decode(modFile.fileContent);
    
    // Save the archive
    final archivePath = path.join(
      FilePathService.modArchivesDirPath,
      '${mod.id}_${latestVersion.id}.zip',
    );
    final archiveFile = File(archivePath);
    await archiveFile.create(recursive: true);
    await archiveFile.writeAsBytes(bytes);

    // Extract the files
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive.files) {
      if (file.isFile) {
        final filePath = path.join(gameFolder, file.name);
        final outputFile = File(filePath);
        try {
          await outputFile.create(recursive: true);
          await outputFile.writeAsBytes(file.content);
        } on FileSystemException catch (e) {
          if (e.osError?.message.toLowerCase().contains('access denied') ?? false) {
            throw Exception('The game appears to be running. Please close the game and try again.');
          }
          throw Exception('Failed to write to ${e.path}: ${e.message}');
        }
      }
    }

    // Save the installed mod record
    final installedMod = InstalledMod(
      modId: mod.id,
      modName: mod.name,
      versionId: latestVersion.id,
      version: latestVersion.version,
      archivePath: archivePath,
      installedAt: DateTime.now(),
    );
    await addInstalledMod(installedMod);
  }
} 