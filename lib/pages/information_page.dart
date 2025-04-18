import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Information'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mods Of Pantheon',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'A mod manager for Pantheon: Rise of the Fallen',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'About',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mods Of Pantheon is a desktop application that helps you manage mods for Pantheon: Rise of the Fallen. '
              'It allows you to browse, install, and uninstall mods with ease.',
            ),
            const SizedBox(height: 24),
            const Text(
              'Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Browse available mods'),
                Text('• Install and uninstall mods'),
                Text('• Manage installed mods'),
                Text('• Automatic file restoration on failed uninstalls'),
                Text('• Local archive storage for reliable uninstalls'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Links',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _launchUrl('https://github.com/ModsOfPantheon/ModsOfPantheonClient'),
              icon: Image.asset(
                'assets/images/github_logo.png',
                height: 24,
                width: 24,
                color: Colors.white,
              ),
              label: const Text('GitHub Repository'),
            ),
            TextButton.icon(
              onPressed: () => _launchUrl('https://discord.gg/JtyuP26w95'),
              icon: Image.asset(
                'assets/images/discord_logo.png',
                height: 24,
                width: 24,
                color: Colors.white,
              ),
              label: const Text('Mods Of Pantheon Discord'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Version',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('1.0.0'),
          ],
        ),
      ),
    );
  }
} 