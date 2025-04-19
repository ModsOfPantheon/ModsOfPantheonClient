import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/mod_details_page.dart';
import '../pages/installed_mods_page.dart';
import '../pages/information_page.dart';
import '../pages/settings_page.dart';
import '../models/mod.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  Mod? _selectedMod;
  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();

  void _showModDetails(Mod mod) {
    setState(() {
      _selectedMod = mod;
      _selectedIndex = 0; // Keep on Browse tab
    });
  }

  void _clearModDetails() {
    setState(() {
      _selectedMod = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.view_list),
                label: Text('Browse'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.download),
                label: Text('Installed'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.info),
                label: Text('Information'),
              ),
            ],
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
                if (index != 0 || _selectedMod != null) {
                  _selectedMod = null;
                }
                if (index == 0) {
                  _homePageKey.currentState?.loadMods();
                }
              });
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _selectedMod != null
                    ? ModDetailsPage(
                        mod: _selectedMod!,
                        onBack: _clearModDetails,
                      )
                    : HomePage(
                        key: _homePageKey,
                        onModSelected: _showModDetails,
                      ),
                InstalledModsPage(
                  isSelected: _selectedIndex == 1,
                ),
                const SettingsPage(),
                const InformationPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 