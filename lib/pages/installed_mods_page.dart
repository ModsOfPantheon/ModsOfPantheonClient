import 'package:flutter/material.dart';
import '../models/installed_mod.dart';
import '../services/installed_mods_service.dart';
import '../widgets/error_display.dart';

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

      await InstalledModsService.uninstallMod(mod.modId);

      _showSuccess('Successfully uninstalled ${mod.modName}');
      _loadInstalledMods();
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