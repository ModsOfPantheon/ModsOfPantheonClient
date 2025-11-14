import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import '../models/mod.dart';
import '../models/mod_version.dart';
import '../models/installed_mod.dart';
import '../services/api_service.dart';
import '../services/prerequisite_checker.dart';
import '../services/installed_mods_service.dart';
import '../widgets/error_display.dart';
import '../services/file_path_service.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ModDetailsPage extends StatefulWidget {
  final Mod mod;
  final VoidCallback onBack;

  const ModDetailsPage({
    super.key, 
    required this.mod,
    required this.onBack,
  });

  @override
  State<ModDetailsPage> createState() => _ModDetailsPageState();
}

class _ModDetailsPageState extends State<ModDetailsPage> {
  List<ModVersion>? _versions;
  String? _error;
  final Map<int, double> _downloadProgress = {};
  InstalledMod? _installedVersion;

  @override
  void initState() {
    super.initState();
    _loadModVersions();
    _loadInstalledVersion();
  }

  Future<void> _loadInstalledVersion() async {
    final installed = await InstalledModsService.getInstalledVersion(widget.mod.id);
    setState(() {
      _installedVersion = installed;
    });
  }

  Future<void> _loadModVersions() async {
    try {
      setState(() {
        _versions = null;
        _error = null;
      });
      final versions = await ApiService.getModVersions(widget.mod.id);
      setState(() {
        _versions = versions;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _versions = null;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _downloadVersion(ModVersion version) async {
    try {
      setState(() {
        _downloadProgress[version.id] = 0;
      });

      final gameFolder = PrerequisiteChecker.gameFolderPath;
      if (gameFolder == null) {
        throw Exception('Game folder not set');
      }

      // Download the zip file
      final modFile = await ApiService.getModFile(version.fileId);
      // Extract the zip file
      try {
        // Decode base64 string to bytes
        final bytes = base64.decode(modFile.fileContent);
        final archive = ZipDecoder().decodeBytes(bytes);
        
        // Save the archive file
        final archivePath = path.join(
          FilePathService.modArchivesDirPath,
          '${widget.mod.name}_v${version.version}.zip'.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_'),
        );
        await File(archivePath).writeAsBytes(bytes);
        
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
        throw Exception('The mod file appears to be corrupted. Please try downloading again or contact the mod author.');
      }

      // Record the installation
      await InstalledModsService.addInstalledMod(InstalledMod(
        modId: widget.mod.id,
        modName: widget.mod.name,
        versionId: version.id,
        version: version.version,
        installedAt: DateTime.now(),
        archivePath: path.join(
          FilePathService.modArchivesDirPath,
          '${widget.mod.name}_v${version.version}.zip',
        ),
      ));

      setState(() {
        _downloadProgress.remove(version.id);
        _installedVersion = InstalledMod(
          modId: widget.mod.id,
          modName: widget.mod.name,
          versionId: version.id,
          version: version.version,
          installedAt: DateTime.now(),
          archivePath: path.join(
            FilePathService.modArchivesDirPath,
            '${widget.mod.name}_v${version.version}.zip',
          ),
        );
      });

      _showSuccess('Successfully installed ${widget.mod.name} version ${version.version}');
    } catch (e) {
      setState(() {
        _downloadProgress.remove(version.id);
      });

      String errorMessage;
      if (e.toString().contains('Game folder not set')) {
        errorMessage = 'Please set your game folder in the settings before installing mods.';
      } else if (e.toString().contains('corrupted')) {
        errorMessage = 'The mod file appears to be corrupted. Please try downloading again or contact the mod author.';
      } else if (e.toString().contains('game appears to be running')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('Failed to write to')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'The mod file appears to be corrupted. Please try downloading again or contact the mod author.';
      } else {
        errorMessage = 'Failed to install the mod. Please try again later.';
      }

      _showError(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBar(
          title: Row(
            children: [
              TextButton(
                onPressed: widget.onBack,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'Available Mods',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
              Text(
                widget.mod.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          actions: [
            if (widget.mod.githubUrl != null)
              IconButton(
                icon: Image.asset(
                  'assets/images/github_logo.png',
                  width: 24,
                  height: 24,
                ),
                tooltip: 'View on GitHub',
                onPressed: () async {
                  final url = Uri.parse(widget.mod.githubUrl!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadModVersions,
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mod.shortDescription,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Versions:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (_error != null)
                  ErrorDisplay(error: _error!)
                else if (_versions == null)
                  const CircularProgressIndicator()
                else if (_versions!.isEmpty)
                  const Text('No versions available')
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: _versions!.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final version = _versions![index];
                        final progress = _downloadProgress[version.id];
                        final isInstalled = _installedVersion?.versionId == version.id;
                        
                        // Determine if this version is newer or older than the installed version
                        String buttonText = 'Download';
                        if (_installedVersion != null && !isInstalled) {
                          final installedVersion = _versions!.firstWhere(
                            (v) => v.id == _installedVersion!.versionId,
                            orElse: () => _versions!.first,
                          );
                          buttonText = version.createdAt.isAfter(installedVersion.createdAt)
                              ? 'Upgrade'
                              : 'Downgrade';
                        }
                        
                        // Decode changelog if available
                        String? decodedChangelog;
                        if (version.changelog != null && version.changelog!.isNotEmpty) {
                          try {
                            decodedChangelog = utf8.decode(base64.decode(version.changelog!));
                          } catch (e) {
                            // If decoding fails, use the original string
                            decodedChangelog = version.changelog;
                          }
                        }

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            version.version,
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            version.createdAt.toLocal().toString().split(' ')[0],
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (progress != null)
                                      Text('${(progress * 100).toInt()}%')
                                    else
                                      TextButton(
                                        onPressed: isInstalled ? null : () => _downloadVersion(version),
                                        style: TextButton.styleFrom(
                                          foregroundColor: isInstalled 
                                              ? Colors.grey 
                                              : Theme.of(context).colorScheme.secondary,
                                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        child: Text(isInstalled ? 'Installed' : buttonText),
                                      ),
                                  ],
                                ),
                                if (progress != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: LinearProgressIndicator(value: progress),
                                  ),
                                if (decodedChangelog != null && decodedChangelog.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Changelog:',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  MarkdownBody(
                                    data: decodedChangelog,
                                    styleSheet: MarkdownStyleSheet(
                                      p: Theme.of(context).textTheme.bodyMedium,
                                      h1: Theme.of(context).textTheme.headlineSmall,
                                      h2: Theme.of(context).textTheme.titleLarge,
                                      h3: Theme.of(context).textTheme.titleMedium,
                                      code: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontFamily: 'monospace',
                                        backgroundColor: Colors.grey[200],
                                      ),
                                      codeblockDecoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 