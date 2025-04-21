import 'package:flutter/material.dart';
import '../models/mod.dart';
import '../models/installed_mod.dart';
import '../services/installed_mods_service.dart';
import '../services/api_service.dart';

class ModCard extends StatefulWidget {
  final Mod mod;
  final VoidCallback onTap;

  const ModCard({
    super.key,
    required this.mod,
    required this.onTap,
  });

  @override
  State<ModCard> createState() => _ModCardState();
}

class _ModCardState extends State<ModCard> {
  bool isHovered = false;
  bool isPressed = false;
  InstalledMod? _installedVersion;
  bool _isUninstalling = false;
  bool _isInstalling = false;

  @override
  void initState() {
    super.initState();
    _loadInstalledVersion();
  }

  Future<void> _loadInstalledVersion() async {
    final installed = await InstalledModsService.getInstalledVersion(widget.mod.id);
    if (mounted) {
      setState(() {
        _installedVersion = installed;
      });
    }
  }

  Future<void> _installLatestVersion() async {
    try {
      setState(() {
        _isInstalling = true;
      });

      // Get the latest version first
      final versions = await ApiService.getModVersions(widget.mod.id);
      if (versions.isEmpty) {
        throw Exception('No versions available for this mod');
      }

      await InstalledModsService.installLatestVersion(widget.mod);

      final installed = await InstalledModsService.getInstalledVersion(widget.mod.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully installed ${widget.mod.name} ${installed?.version ?? "latest version"}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _installedVersion = installed;
        });
      }
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('Game folder not set')) {
        errorMessage = 'Please set your game folder in the settings before installing mods.';
      } else if (e.toString().contains('game appears to be running')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('No versions available')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('Failed to download')) {
        errorMessage = e.toString();
      } else {
        errorMessage = 'Failed to install mod. Please try again later.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInstalling = false;
        });
      }
    }
  }

  Future<void> _uninstallMod() async {
    try {
      setState(() {
        _isUninstalling = true;
      });

      await InstalledModsService.uninstallMod(widget.mod.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully uninstalled ${widget.mod.name}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      setState(() {
        _installedVersion = null;
      });
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('Game folder not set')) {
        errorMessage = 'Please set your game folder in the settings before uninstalling mods.';
      } else if (e.toString().contains('game appears to be running')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('Mod archive not found')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('Mod not found in installed mods list')) {
        errorMessage = e.toString();
      } else {
        errorMessage = 'Failed to uninstall mod. Please try again later.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUninstalling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUpdate = _installedVersion != null && 
                      _installedVersion!.version != widget.mod.latestVersion;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() {
        isHovered = false;
        isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) => setState(() => isPressed = false),
        onTapCancel: () => setState(() => isPressed = false),
        onTap: widget.onTap,
        onSecondaryTapDown: (details) {
          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
              details.globalPosition.dx,
              details.globalPosition.dy,
              details.globalPosition.dx,
              details.globalPosition.dy,
            ),
            items: [
              PopupMenuItem(
                onTap: _installedVersion == null || hasUpdate
                    ? () {
                        Future.microtask(() async {
                          await _installLatestVersion();
                        });
                        return null;
                      }
                    : null,
                enabled: _installedVersion == null || hasUpdate,
                child: Row(
                  children: [
                    _isInstalling
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.download),
                    const SizedBox(width: 8),
                    Text(_installedVersion == null ? 'Install Latest' : 'Update'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: _installedVersion != null ? _uninstallMod : null,
                enabled: _installedVersion != null,
                child: Row(
                  children: [
                    _isUninstalling
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.delete),
                    const SizedBox(width: 8),
                    const Text('Uninstall'),
                  ],
                ),
              ),
            ],
          );
        },
        child: Card(
          elevation: isPressed ? 0 : (isHovered ? 8 : 2),
          color: isPressed 
              ? theme.colorScheme.surface.withValues(alpha: 0.7)
              : (isHovered ? theme.colorScheme.surface.withValues(alpha: 0.9) : theme.colorScheme.surface),
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
                        widget.mod.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      'by ${widget.mod.author}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                if (_installedVersion != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Installed: ${_installedVersion!.version}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      if (hasUpdate) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF272F88),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Update Available',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  widget.mod.shortDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 