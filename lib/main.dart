import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/navigation/main_navigation.dart';

import 'core/services/task_repository.dart';
import 'core/services/schedule_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await TaskRepository.instance.init();
  await ScheduleRepository.instance.init();

  runApp(const VortexAI());
}

class VortexAI extends StatelessWidget {
  const VortexAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vortex AI',

      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,

      home: const MainNavigation(),
    );
  }
}
