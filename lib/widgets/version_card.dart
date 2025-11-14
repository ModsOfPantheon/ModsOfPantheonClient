import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/mod_version.dart';

class VersionCard extends StatelessWidget {
  final ModVersion version;
  final bool isInstalling;
  final bool isInstalled;
  final String buttonText;
  final String? decodedChangelog;
  final VoidCallback? onDownload;

  const VersionCard({
    super.key,
    required this.version,
    required this.isInstalling,
    required this.isInstalled,
    required this.buttonText,
    this.decodedChangelog,
    this.onDownload,
  });

  static String? decodeChangelog(String? changelog) {
    if (changelog == null || changelog.isEmpty) {
      return null;
    }
    try {
      return utf8.decode(base64.decode(changelog));
    } catch (e) {
      // If decoding fails, use the original string
      return changelog;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        version.version,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        version.createdAt.toLocal().toString().split(' ')[0],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isInstalling)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton(
                    onPressed: isInstalled ? null : onDownload,
                    style: TextButton.styleFrom(
                      foregroundColor: isInstalled
                          ? Colors.grey
                          : Theme.of(context).colorScheme.secondary,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: Text(isInstalled ? 'Installed' : buttonText),
                  ),
              ],
            ),
            if (decodedChangelog != null && decodedChangelog!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Changelog:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              MarkdownBody(
                data: decodedChangelog!,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyMedium,
                  h1: Theme.of(context).textTheme.headlineSmall,
                  h2: Theme.of(context).textTheme.titleLarge,
                  h3: Theme.of(context).textTheme.titleMedium,
                  code: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        backgroundColor: Colors.grey[200],
                      ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

