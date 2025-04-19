import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../services/prerequisite_checker.dart';
import '../widgets/game_folder_dialog.dart';
import '../widgets/prerequisite_checker_screen.dart';
import '../widgets/main_layout.dart';
import '../services/file_path_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
              'App Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'App data is stored in:',
                              style: TextStyle(
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              FilePathService.configDirPath,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.folder_open),
                            onPressed: () async {
                              final uri = Uri.file(FilePathService.configDirPath);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            tooltip: 'Open app data folder',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Game Folder',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Current game path:',
                              style: TextStyle(
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: PrerequisiteChecker.gameFolderPath,
                              items: PrerequisiteChecker.gameFolderPaths.map((path) {
                                return DropdownMenuItem(
                                  value: path,
                                  child: Text(path),
                                );
                              }).toList(),
                              onChanged: (newPath) async {
                                if (newPath != null) {
                                  await PrerequisiteChecker.setGameFolder(newPath);
                                  setState(() {});
                                  // Rerun prerequisite checks
                                  final results = await PrerequisiteChecker.runChecks();
                                  final hasFailures = results.any((result) => !result.$2);
                                  if (hasFailures && mounted) {
                                    // Pop back to root and show prerequisite screen
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PrerequisiteCheckerScreen(
                                          onComplete: (context) {
                                            // Return to the main layout
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const MainLayout(),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                }
                              },
                              dropdownColor: const Color(0xFF1E1E1E),
                              icon: const Icon(Icons.arrow_drop_down),
                              underline: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              isExpanded: true,
                              focusColor: const Color(0xFF1E1E1E),
                            ),
                          ),
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
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () async {
                              final result = await showDialog<String>(
                                context: context,
                                builder: (context) => const GameFolderDialog(),
                              );
                              if (result != null) {
                                await PrerequisiteChecker.setGameFolder(result);
                                setState(() {});
                              }
                            },
                            tooltip: 'Add game folder',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Remove game folder',
                            onPressed: () async {
                              final path = PrerequisiteChecker.gameFolderPath!;
                              final shouldRemove = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Remove Game Folder'),
                                  content: Text('Are you sure you want to remove "$path" from the list?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (shouldRemove == true && mounted) {
                                await PrerequisiteChecker.removeGameFolder(path);
                                setState(() {});
                                
                                // If no folders left, go back to prerequisites screen
                                if (PrerequisiteChecker.gameFolderPaths.isEmpty) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PrerequisiteCheckerScreen(
                                        onComplete: (context) {
                                          // Return to the main layout
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const MainLayout(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    (route) => false,
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 