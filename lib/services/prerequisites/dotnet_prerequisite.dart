import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../prerequisite_checker.dart';
import '../file_path_service.dart';
import 'prerequisite_state.dart';

class DotNetPrerequisite extends PrerequisiteCheck {
  DotNetPrerequisite()
      : super(
          name: '.NET 6 SDK',
          description: 'Required for running MelonLoader',
          failureMessage: '.NET 6 SDK is not installed',
          check: _checkDotNetSdk,
          onFix: (context, prerequisite) => (prerequisite as DotNetPrerequisite)._installDotNetSdk(context),
          state: PrerequisiteState(
            text: 'Downloading...',
          ),
        );

  static Future<bool> _checkDotNetSdk() async {
    try {
      // First try the direct dotnet command
      final result = await Process.run('dotnet', ['--list-sdks']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        // Look for any SDK version starting with 6.
        if (output.split('\n').any((line) => line.trim().startsWith('6.'))) {
          return true;
        }
      }

      // If that fails, try checking the registry
      final regResult = await Process.run('reg', [
        'query',
        'HKLM\\SOFTWARE\\dotnet\\Setup\\InstalledVersions\\x64\\sdk',
        '/s'
      ]);
      
      if (regResult.exitCode == 0) {
        final output = regResult.stdout.toString();
        return output.contains('6.0');
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _installDotNetSdk(BuildContext context) async {
    try {
      // Create temp directory if it doesn't exist
      final tempDir = Directory(FilePathService.tempDirPath);
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }

      // Get platform-specific download URL
      String installerUrl;
      String installerName;
      if (Platform.isWindows) {
        installerUrl = 'https://builds.dotnet.microsoft.com/dotnet/Sdk/6.0.428/dotnet-sdk-6.0.428-win-x64.exe';
        installerName = 'dotnet-sdk-6.0.428-win-x64.exe';
      } else if (Platform.isMacOS) {
        installerUrl = 'https://builds.dotnet.microsoft.com/dotnet/Sdk/6.0.428/dotnet-sdk-6.0.428-osx-x64.pkg';
        installerName = 'dotnet-sdk-6.0.428-osx-x64.pkg';
      } else if (Platform.isLinux) {
        installerUrl = 'https://builds.dotnet.microsoft.com/dotnet/Sdk/6.0.428/dotnet-sdk-6.0.428-linux-x64.tar.gz';
        installerName = 'dotnet-sdk-6.0.428-linux-x64.tar.gz';
      } else {
        throw Exception('Unsupported platform');
      }

      // Download the installer
      final installerPath = path.join(tempDir.path, installerName);
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(installerUrl));
      final response = await request.close();
      
      // Get content length for progress calculation
      final contentLength = response.contentLength;
      var receivedBytes = 0;
      
      // Download with progress tracking
      final file = File(installerPath);
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

      // Run the installer with platform-specific commands
      ProcessResult result = ProcessResult(0, 0, '', '');
      if (Platform.isWindows) {
        result = await Process.run(installerPath, ['/q', '/norestart']);
      } else if (Platform.isMacOS) {
        result = await Process.run('sudo', ['installer', '-pkg', installerPath, '-target', '/']);
      } else if (Platform.isLinux) {
        // Create dotnet directory
        final dotnetDir = Directory('/usr/share/dotnet');
        if (!await dotnetDir.exists()) {
          await dotnetDir.create(recursive: true);
        }
        // Extract the tar.gz file
        result = await Process.run('tar', ['-xzf', installerPath, '-C', '/usr/share/dotnet']);
        if (result.exitCode == 0) {
          // Create symbolic links
          await Process.run('sudo', ['ln', '-s', '/usr/share/dotnet/dotnet', '/usr/bin/dotnet']);
        }
      }

      // Clean up
      await file.delete();

      if (result.exitCode != 0) {
        throw Exception('Failed to install .NET 6 SDK');
      }
    } catch (e) {
      throw Exception('Failed to install .NET 6 SDK: ${e.toString()}');
    }
  }
} 