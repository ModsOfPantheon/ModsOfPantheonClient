import 'package:flutter/material.dart';
import '../prerequisite_checker.dart';
import '../../widgets/game_folder_dialog.dart';
import 'prerequisite_state.dart';

class GameFolderPrerequisite extends PrerequisiteCheck {
  GameFolderPrerequisite()
      : super(
          name: 'Game Folder',
          description: 'Path to the game installation',
          failureMessage: 'Game folder not set',
          check: _checkGameFolder,
          onFix: (context, prerequisite) => (prerequisite as GameFolderPrerequisite)._setGameFolder(context),
          state: PrerequisiteState(
            text: 'Selecting...',
          ),
        );

  static Future<bool> _checkGameFolder() async {
    return PrerequisiteChecker.gameFolderPath != null;
  }

  Future<void> _setGameFolder(BuildContext context) async {
    state
      ..progress = null
      ..text = 'Selecting...'
      ..isInstalling = true;
    
    await GameFolderDialog.show(context);
    
    state
      ..progress = null
      ..text = 'Selected'
      ..isInstalling = false;
  }
} 