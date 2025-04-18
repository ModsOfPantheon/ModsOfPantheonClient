import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/installed_mod.dart';
import '../services/installed_mods_service.dart';
import '../widgets/error_display.dart';
import '../services/prerequisite_checker.dart';
import 'package:archive/archive.dart';

class InstalledModsPage extends StatefulWidget {
  final bool isSelected;

  const InstalledModsPage({
    super.key,
    required this.isSelected,
  });

  @override
  State<InstalledModsPage> createState() => _InstalledModsPageState();
}

class _InstalledModsPageState extends State<InstalledModsPage> {
  List<InstalledMod>? _installedMods;
  bool _isLoading = true;
  String? _error;
  final Set<int> _uninstallingMods = {};

  @override
  void initState() {
    super.initState();
    _loadInstalledMods();
  }

  @override
  void didUpdateWidget(InstalledModsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _loadInstalledMods();
    }
  }

  Future<void> _loadInstalledMods() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final installedMods = await InstalledModsService.getInstalledMods();
      // Sort mods alphabetically by name
      installedMods.sort((a, b) => a.modName.toLowerCase().compareTo(b.modName.toLowerCase()));

      if (mounted) {
        setState(() {
          _installedMods = installedMods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _uninstallMod(InstalledMod mod) async {
    try {
      setState(() {
        _uninstallingMods.add(mod.modId);
      });

      final gameFolder = PrerequisiteChecker.gameFolderPath;
      if (gameFolder == null) {
        throw Exception('Game folder not set');
      }

      // Load the saved archive
      final archiveFile = File(mod.archivePath);
      if (!await archiveFile.exists()) {
        throw Exception('Mod archive not found. Please reinstall the mod.');
      }

      final bytes = await archiveFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Keep track of files we've successfully deleted
      final deletedFiles = <String>[];
      // Keep track of parent directories
      final parentDirs = <String>{};
      
      try {
        // Delete each file that was installed
        for (final file in archive.files) {
          if (file.isFile) {
            final filePath = path.join(gameFolder, file.name);
            final fileToDelete = File(filePath);
            if (await fileToDelete.exists()) {
              await fileToDelete.delete();
              deletedFiles.add(filePath);
              // Add parent directory to the set
              parentDirs.add(path.dirname(filePath));
            }
          }
        }

        // Clean up empty directories
        for (final dirPath in parentDirs) {
          final dir = Directory(dirPath);
          if (await dir.exists()) {
            // Check if directory is empty
            final isEmpty = await dir.list().isEmpty;
            if (isEmpty) {
              // Only delete if it's a subdirectory of Mods or UserLibs
              final relativePath = path.relative(dirPath, from: gameFolder);
              if (relativePath.startsWith('Mods') || relativePath.startsWith('UserLibs')) {
                await dir.delete();
              }
            }
          }
        }

        // Only remove from installed mods list after successful file deletion
        await InstalledModsService.removeInstalledMod(mod.modId);
        // Delete the archive file
        await archiveFile.delete();
        _showSuccess('Successfully uninstalled ${mod.modName}');
        _loadInstalledMods();
      } catch (e) {
        // Try to restore any files we already deleted
        for (final filePath in deletedFiles) {
          try {
            final file = File(filePath);
            if (!await file.exists()) {
              // Find the file in the archive
              final archiveFile = archive.files.firstWhere(
                (f) => path.join(gameFolder, f.name) == filePath,
              );
              // Create parent directories if they don't exist
              await file.parent.create(recursive: true);
              // Write the file back
              await file.writeAsBytes(archiveFile.content);
            }
          } catch (e) {
            // If we can't restore a file, log it but continue trying to restore others
            print('Failed to restore file: $filePath');
          }
        }
        rethrow; // Re-throw the original error
      }
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('Game folder not set')) {
        errorMessage = 'Please set your game folder in the settings before uninstalling mods.';
      } else if (e.toString().contains('game appears to be running')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('Mod archive not found')) {
        errorMessage = e.toString();
      } else {
        errorMessage = 'Failed to uninstall ${mod.modName}. Please try again later.';
      }
      _showError(errorMessage);
    } finally {
      setState(() {
        _uninstallingMods.remove(mod.modId);
      });
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installed Mods'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInstalledMods,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorDisplay(
                  error: _error!,
                  onRetry: _loadInstalledMods,
                )
              : _installedMods == null || _installedMods!.isEmpty
                  ? const Center(child: Text('No mods installed'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _installedMods!.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final mod = _installedMods![index];
                        final isUninstalling = _uninstallingMods.contains(mod.modId);
                        
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        mod.modName,
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                    ),
                                    if (isUninstalling)
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else
                                      TextButton.icon(
                                        onPressed: () => _uninstallMod(mod),
                                        icon: const Icon(Icons.delete),
                                        label: const Text('Uninstall'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Version: ${mod.version}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  'Installed: ${mod.installedAt.toLocal().toString().split(' ')[0]}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
} 