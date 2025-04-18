import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'services/prerequisite_checker.dart';
import 'widgets/prerequisite_checker_screen.dart';
import 'widgets/error_display.dart';
import 'widgets/main_layout.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Mods Of Pantheon',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    final size = await windowManager.getSize();
    await windowManager.setMinimumSize(size);
    await windowManager.show();
    await windowManager.focus();
  });

  await PrerequisiteChecker.initialize();
  PrerequisiteChecker.setupDefaultChecks();
  runApp(const ModsOfPantheonClient());
}

class ModsOfPantheonClient extends StatelessWidget {
  const ModsOfPantheonClient({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mods Of Pantheon',
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: FutureBuilder<List<(PrerequisiteCheck, bool)>>(
        future: PrerequisiteChecker.runChecks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return ErrorDisplay(
              error: snapshot.error!,
              onRetry: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const ModsOfPantheonClient()),
                );
              },
            );
          }
          
          final results = snapshot.data!;
          final allPassed = results.every((result) => result.$2);
          
          if (allPassed) {
            return const MainLayout();
          }
          
          return PrerequisiteCheckerScreen(
            onComplete: (BuildContext context) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const MainLayout()),
              );
            },
          );
        },
      ),
    );
  }
}
