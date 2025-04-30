import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:url_launcher/url_launcher.dart';
import '../prerequisite_checker.dart';
import '../../services/file_path_service.dart';
import 'prerequisite_state.dart';

class MelonLoaderPrerequisite extends PrerequisiteCheck {
  MelonLoaderPrerequisite()
      : super(
          name: 'MelonLoader',
          description: 'Required for running mods',
          failureMessage: 'MelonLoader is not installed',
          check: _checkMelonLoader,
          onFix: (context, prerequisite) => (prerequisite as MelonLoaderPrerequisite)._installMelonLoader(context),
          dependencies: ['Game Folder'],
          state: PrerequisiteState(
            text: 'Downloading...',
          ),
        );

  static Future<bool> _checkMelonLoader() async {
    final gameFolder = await _getGameFolder();
    if (gameFolder == null) return false;

    final versionDll = File(path.join(gameFolder, 'version.dll'));
    return await versionDll.exists();
  }

  static Future<String?> _getGameFolder() async {
    return PrerequisiteChecker.gameFolderPath;
  }

  Future<void> _installMelonLoader(BuildContext context) async {
    try {
      final gameFolder = await _getGameFolder();
      if (gameFolder == null) {
        throw Exception('Game folder not set');
      }

      // Get platform-specific download URL
      String downloadUrl;
      if (Platform.isWindows) {
        downloadUrl = 'https://nightly.link/LavaGang/MelonLoader/workflows/build/alpha-development/MelonLoader.Windows.x64.CI.Release.zip';
      } else if (Platform.isMacOS) {
        downloadUrl = 'https://nightly.link/LavaGang/MelonLoader/workflows/build/alpha-development/MelonLoader.MacOS.x64.CI.Release.zip';
      } else if (Platform.isLinux) {
        downloadUrl = 'https://nightly.link/LavaGang/MelonLoader/workflows/build/alpha-development/MelonLoader.Linux.x64.CI.Release.zip';
      } else {
        throw Exception('Unsupported platform');
      }

      // Download the MelonLoader zip file
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(downloadUrl));
      final response = await request.close();
      
      // Get content length for progress calculation
      final contentLength = response.contentLength;
      var receivedBytes = 0;
      
      // Download with progress tracking
      final tempDir = Directory(FilePathService.tempDirPath);
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      final zipPath = path.join(tempDir.path, 'melonloader.zip');
      final file = File(zipPath);
      final sink = file.openWrite();
      
      // Initialize progress
      state
        ..progress = 0.0
        ..text = 'Downloading...'
        ..isInstalling = true;
      
      await for (final chunk in response) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        
        // Update progress
        if (contentLength > 0) {
          final progress = receivedBytes / contentLength;
          state
            ..progress = progress
            ..text = 'Downloading...'
            ..isInstalling = true;
        }
      }
      await sink.close();
      client.close();

      // Update text to "Installing..." and remove progress bar
      state
        ..progress = null
        ..text = 'Installing...'
        ..isInstalling = true;

      // Extract the zip file
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Extract all files to the game folder
      for (final file in archive.files) {
        if (file.isFile) {
          final filePath = path.join(gameFolder, file.name);
          final outputFile = File(filePath);
          await outputFile.create(recursive: true);
          await outputFile.writeAsBytes(file.content);
        }
      }

      // Clean up
      await file.delete();

      // On Linux, make the version.dll executable
      if (Platform.isLinux) {
        final versionDll = File(path.join(gameFolder, 'version.dll'));
        if (await versionDll.exists()) {
          await Process.run('chmod', ['+x', versionDll.path]);
        }
      }
    } catch (e) {
      // Show error dialog instead of SnackBar
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Failed to Install MelonLoader'),
            content: const Text(
              'The automatic installation failed.\n\n'
              'Would you like to install MelonLoader manually? This will open the MelonLoader releases page in your browser.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await launchUrl(Uri.parse('https://github.com/LavaGang/MelonLoader/releases'));
                },
                child: const Text('Install Manually'),
              ),
            ],
          ),
        );
      }
    }
  }
} 