import 'package:flutter/material.dart';
import '../models/mod.dart';
import '../models/mod_version.dart';
import '../models/installed_mod.dart';
import '../services/api_service.dart';
import '../services/installed_mods_service.dart';
import '../widgets/error_display.dart';
import '../widgets/version_card.dart';
import 'package:url_launcher/url_launcher.dart';

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
  int? _installingVersionId;
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

  String _getButtonText(ModVersion version, List<ModVersion> allVersions) {
    if (_installedVersion == null) {
      return 'Download';
    }
    if (_installedVersion!.versionId == version.id) {
      return 'Download'; // This won't be shown since isInstalled will be true
    }
    final installedVersion = allVersions.firstWhere(
      (v) => v.id == _installedVersion!.versionId,
      orElse: () => allVersions.first,
    );
    return version.createdAt.isAfter(installedVersion.createdAt)
        ? 'Upgrade'
        : 'Downgrade';
  }

  Future<void> _downloadVersion(ModVersion version) async {
    try {
      setState(() {
        _installingVersionId = version.id;
      });

      final installedMod = await InstalledModsService.installVersion(
        widget.mod,
        version,
      );

      setState(() {
        _installingVersionId = null;
        _installedVersion = installedMod;
      });

      _showSuccess('Successfully installed ${widget.mod.name} version ${version.version}');
    } catch (e) {
      setState(() {
        _installingVersionId = null;
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
                        final isThisInstalling = _installingVersionId == version.id;
                        final isInstalled = _installedVersion?.versionId == version.id;
                        final buttonText = _getButtonText(version, _versions!);
                        final decodedChangelog = VersionCard.decodeChangelog(version.changelog);

                        return VersionCard(
                          version: version,
                          isInstalling: isThisInstalling,
                          isInstalled: isInstalled,
                          buttonText: buttonText,
                          decodedChangelog: decodedChangelog,
                          onDownload: _installingVersionId != null ? null : () => _downloadVersion(version),
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