import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

import 'features/home/home_screen.dart';

void main() {
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

      home: const HomeScreen(),
    );
  }
}