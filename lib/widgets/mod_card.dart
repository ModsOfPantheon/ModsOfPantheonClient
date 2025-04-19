import 'package:flutter/material.dart';
import '../models/mod.dart';
import '../models/installed_mod.dart';
import '../services/installed_mods_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  Text(
                    'Installed: ${_installedVersion!.version}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
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