import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'theme.dart';

void main() {
  runApp(const CampusConciergeApp());
}

class CampusConciergeApp extends StatelessWidget {
  const CampusConciergeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Concierge',
      theme: buildAppTheme(),
      home: const MainShell(),
    );
  }
}
