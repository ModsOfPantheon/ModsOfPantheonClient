import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'file_path_service.dart';
import 'prerequisites/game_folder_prerequisite.dart';
import 'prerequisites/dotnet_prerequisite.dart';
import 'prerequisites/melonloader_prerequisite.dart';
import 'prerequisites/prerequisite_state.dart';

class PrerequisiteCheck {
  final String name;
  final String description;
  final String failureMessage;
  final Future<bool> Function() check;
  final Future<void> Function(BuildContext context, PrerequisiteCheck prerequisite)? onFix;
  final List<String> dependencies;
  final PrerequisiteState state;

  PrerequisiteCheck({
    required this.name,
    required this.description,
    required this.failureMessage,
    required this.check,
    this.onFix,
    this.dependencies = const [],
    required this.state,
  });
}

class PrerequisiteChecker {
  static final List<PrerequisiteCheck> _checks = [];
  static String? gameFolderPath;
  static List<String> gameFolderPaths = [];

  static Future<void> initialize() async {
    await FilePathService.ensureConfigDirExists();
    final config = await _loadConfig();
    gameFolderPath = config['game_folder_path'] as String?;
    gameFolderPaths = List<String>.from(config['game_folder_paths'] ?? []);
    if (gameFolderPath != null && !gameFolderPaths.contains(gameFolderPath)) {
      gameFolderPaths.add(gameFolderPath!);
    }
  }

  static Future<Map<String, dynamic>> _loadConfig() async {
    final file = File(FilePathService.configFilePath);
    if (!await file.exists()) {
      await file.writeAsString('{}');
    }
    final content = await file.readAsString();
    return jsonDecode(content);
  }

  static Future<void> _saveConfig(Map<String, dynamic> config) async {
    final file = File(FilePathService.configFilePath);
    final content = jsonEncode(config);
    await file.writeAsString(content);
  }

  static Future<void> setGameFolder(String path) async {
    gameFolderPath = path;
    if (!gameFolderPaths.contains(path)) {
      gameFolderPaths.add(path);
    }
    final config = await _loadConfig();
    config['game_folder_path'] = path;
    config['game_folder_paths'] = gameFolderPaths;
    await _saveConfig(config);
  }

  static Future<void> removeGameFolder(String path) async {
    gameFolderPaths.remove(path);
    if (gameFolderPath == path) {
      gameFolderPath = gameFolderPaths.isNotEmpty ? gameFolderPaths.first : null;
    }
    final config = await _loadConfig();
    config['game_folder_path'] = gameFolderPath;
    config['game_folder_paths'] = gameFolderPaths;
    await _saveConfig(config);
  }

  static void registerCheck(PrerequisiteCheck check) {
    _checks.add(check);
  }

  static Future<List<(PrerequisiteCheck, bool)>> runChecks() async {
    List<(PrerequisiteCheck, bool)> results = [];
    
    for (final check in _checks) {
      try {
        final passed = await check.check();
        results.add((check, passed));
      } catch (e) {
        results.add((check, false));
      }
    }
    
    return results;
  }

  static void setupDefaultChecks() {
    _checks.clear();
    _checks.addAll([
      GameFolderPrerequisite(),
      DotNetPrerequisite(),
      MelonLoaderPrerequisite(),
    ]);
  }
} 