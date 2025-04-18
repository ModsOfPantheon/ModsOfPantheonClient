import 'dart:convert';
import 'dart:io';
import '../models/installed_mod.dart';
import 'file_path_service.dart';

class InstalledModsService {
  static List<InstalledMod> _installedMods = [];

  static Future<void> _loadInstalledMods() async {
    await FilePathService.ensureConfigDirExists();

    final file = File(FilePathService.installedModsFilePath);
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

    final file = File(FilePathService.installedModsFilePath);
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
} 