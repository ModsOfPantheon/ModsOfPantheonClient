import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/prerequisite_checker.dart';

class GameFolderDialog extends StatelessWidget {
  const GameFolderDialog({super.key});

  static Future<String?> show(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (context) => const GameFolderDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Select Game Folder',
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        'Please select the folder where the game is installed. '
        'This should be the folder containing the game executable.',
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final result = await FilePicker.platform.getDirectoryPath();
            if (result != null) {
              // Check if this looks like a valid game folder
              final gameExe = File('$result/Pantheon.exe'); // Adjust this to match your game's executable name
              if (await gameExe.exists()) {
                await PrerequisiteChecker.setGameFolder(result);
                Navigator.pop(context, result);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Selected folder does not appear to contain the game executable'),
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          child: const Text('Select Folder'),
        ),
      ],
    );
  }
} 