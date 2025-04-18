import 'package:flutter/foundation.dart';

class PrerequisiteState extends ChangeNotifier {
  double? _progress;
  String _text;
  bool _isInstalling;

  PrerequisiteState({
    double? progress,
    required String text,
    bool isInstalling = false,
  }) : _progress = progress,
       _text = text,
       _isInstalling = isInstalling;

  double? get progress => _progress;
  String get text => _text;
  bool get isInstalling => _isInstalling;

  set progress(double? value) {
    if (_progress != value) {
      _progress = value;
      notifyListeners();
    }
  }

  set text(String value) {
    if (_text != value) {
      _text = value;
      notifyListeners();
    }
  }

  set isInstalling(bool value) {
    if (_isInstalling != value) {
      _isInstalling = value;
      notifyListeners();
    }
  }

  PrerequisiteState copyWith({
    double? progress,
    String? text,
    bool? isInstalling,
  }) {
    return PrerequisiteState(
      progress: progress ?? _progress,
      text: text ?? _text,
      isInstalling: isInstalling ?? _isInstalling,
    );
  }
} 