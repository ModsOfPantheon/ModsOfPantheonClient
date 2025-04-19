import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import '../services/prerequisite_checker.dart';
import '../widgets/game_folder_dialog.dart';
import '../services/installed_mods_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isExtracting = false;

  Future<void> _reExtractMods(String newPath) async {
    setState(() {
      _isExtracting = true;
    });

    try {
      final installedMods = await InstalledModsService.getInstalledMods();
      
      for (final mod in installedMods) {
        final archiveFile = File(mod.archivePath);
        if (!await archiveFile.exists()) {
          throw Exception('Mod archive not found: ${mod.modName}');
        }

        final bytes = await archiveFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        
        // Extract all files to the game folder
        for (final file in archive.files) {
          if (file.isFile) {
            final filePath = path.join(newPath, file.name);
            final outputFile = File(filePath);
            await outputFile.parent.create(recursive: true);
            await outputFile.writeAsBytes(file.content);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error re-extracting mods: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isExtracting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Game Folder',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            PrerequisiteChecker.gameFolderPath ?? 'Not set',
                            style: TextStyle(
                              color: PrerequisiteChecker.gameFolderPath != null 
                                ? Colors.white 
                                : Colors.grey,
                            ),
                          ),
                        ),
                        if (PrerequisiteChecker.gameFolderPath != null)
                          IconButton(
                            icon: const Icon(Icons.folder_open),
                            onPressed: () async {
                              final path = PrerequisiteChecker.gameFolderPath;
                              if (path != null) {
                                final uri = Uri.file(path);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              }
                            },
                            tooltip: 'Open game folder',
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final oldPath = PrerequisiteChecker.gameFolderPath;
                        final newPath = await GameFolderDialog.show(context);
                        if (newPath != null && mounted && oldPath != null && oldPath != newPath) {
                          await _reExtractMods(newPath);
                        }
                        setState(() {});
                      },
                      icon: _isExtracting 
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.folder),
                      label: Text(_isExtracting ? 'Extracting mods...' : 'Change Game Folder'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 