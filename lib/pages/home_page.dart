import 'package:flutter/material.dart';
import '../models/mod.dart';
import '../services/api_service.dart';
import '../widgets/mod_card.dart';
import '../widgets/error_display.dart';

class HomePage extends StatefulWidget {
  final Function(Mod) onModSelected;

  const HomePage({
    super.key,
    required this.onModSelected,
  });

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<Mod>? _mods;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadMods();
  }

  Future<void> loadMods() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final mods = await ApiService.getMods();
      mods.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() {
        _mods = mods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Mods'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadMods,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorDisplay(
                  error: _error!,
                  onRetry: loadMods,
                )
              : _mods == null || _mods!.isEmpty
                  ? const Center(child: Text('No mods available'))
                  : Scrollbar(
                      thumbVisibility: true,
                      child: ListView.separated(
                        primary: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _mods!.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final mod = _mods![index];
                          return ModCard(
                            mod: mod,
                            onTap: () => widget.onModSelected(mod),
                          );
                        },
                      ),
                    ),
    );
  }
} 