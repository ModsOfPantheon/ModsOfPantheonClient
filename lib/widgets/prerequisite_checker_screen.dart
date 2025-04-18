import 'package:flutter/material.dart';
import '../services/prerequisite_checker.dart';

class PrerequisiteCheckerScreen extends StatefulWidget {
  final void Function(BuildContext context) onComplete;

  const PrerequisiteCheckerScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<PrerequisiteCheckerScreen> createState() => PrerequisiteCheckerScreenState();
}

class PrerequisiteCheckerScreenState extends State<PrerequisiteCheckerScreen> {
  List<(PrerequisiteCheck, bool)>? _results;
  final Set<String> _installingChecks = {};
  final Set<String> _updatingChecks = {};

  @override
  void initState() {
    super.initState();
    _runChecks();
  }

  void _listenToStateChanges(PrerequisiteCheck check) {
    if (!_updatingChecks.contains(check.name)) {
      _updatingChecks.add(check.name);
      check.state.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  Future<void> _runChecks() async {
    final results = await PrerequisiteChecker.runChecks();
    
    if (mounted) {
      setState(() {
        _results = results;
        // Set up listeners for all checks
        for (final (check, _) in results) {
          _listenToStateChanges(check);
        }
      });

      if (results.every((result) => result.$2)) {
        widget.onComplete(context);
      }
    }
  }

  Future<void> _handleFix(PrerequisiteCheck check) async {
    if (check.onFix != null) {
      if (mounted) {
        setState(() {
          _installingChecks.add(check.name);
          check.state.isInstalling = true;
        });
      }
      
      try {
        await check.onFix!(context, check);
        _runChecks();
      } finally {
        if (mounted) {
          setState(() {
            _installingChecks.remove(check.name);
            check.state.isInstalling = false;
          });
        }
      }
    }
  }

  bool _canFix(PrerequisiteCheck check) {
    if (_results == null) return false;
    
    // If no dependencies, can always fix
    if (check.dependencies.isEmpty) return true;
    
    // Check if all dependencies have passed
    return check.dependencies.every((dep) {
      return _results!.any((r) => r.$1.name == dep && r.$2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Let\'s Get You Set Up',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_results != null)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _runChecks,
                      color: Colors.white,
                      tooltip: 'Recheck prerequisites',
                    ),
                ],
              ),
              const SizedBox(height: 32),
              if (_results != null)
                ...List.generate(_results!.length, (index) {
                  final (check, passed) = _results![index];
                  final canFix = _canFix(check);
                  final isInstalling = _installingChecks.contains(check.name);
                  final progress = check.state.progress;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        if (isInstalling)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else
                          Icon(
                            passed 
                              ? Icons.check_circle 
                              : (!canFix && check.dependencies.isNotEmpty)
                                ? Icons.help_outline
                                : Icons.error,
                            color: passed 
                              ? Colors.green 
                              : (!canFix && check.dependencies.isNotEmpty)
                                ? Colors.grey
                                : Colors.red,
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                check.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (isInstalling && progress != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.grey[800],
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(progress * 100).toInt()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  passed 
                                    ? check.description 
                                    : (!canFix && check.dependencies.isNotEmpty)
                                      ? 'Waiting for: ${check.dependencies.join(", ")}'
                                      : check.failureMessage,
                                  style: TextStyle(
                                    color: passed 
                                      ? Colors.white 
                                      : (!canFix && check.dependencies.isNotEmpty)
                                        ? Colors.grey
                                        : Colors.red,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!passed && check.onFix != null)
                          TextButton(
                            onPressed: canFix && !isInstalling ? () => _handleFix(check) : null,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: Text(isInstalling ? check.state.text : (canFix ? 'Let\'s Fix It' : 'Not Yet')),
                          ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up listeners
    if (_results != null) {
      for (final (check, _) in _results!) {
        check.state.removeListener(() {});
      }
    }
    super.dispose();
  }
} 