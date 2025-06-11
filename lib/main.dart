import 'package:flutter/material.dart';
import 'package:simple_calculator/vault_service.dart';
import 'pages/homepage.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await VaultService().init(); // Init Hive here
    runApp(const MyApp());
  }
  catch (e) {
    print('❌ App crashed during startup: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme() {
    setState(() {
      _themeMode =
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vault Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: _themeMode,
      home: Homepage(onThemeToggle: toggleTheme, isDarkMode: _themeMode == ThemeMode.dark),
    );
  }
}