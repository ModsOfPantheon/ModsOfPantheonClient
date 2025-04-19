import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../services/prerequisite_checker.dart';
import '../widgets/game_folder_dialog.dart';
import '../widgets/prerequisite_checker_screen.dart';
import '../widgets/main_layout.dart';

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
                        await GameFolderDialog.show(context);
                        if (mounted) {
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
                      icon: const Icon(Icons.folder),
                      label: const Text('Change Game Folder'),
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