import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Phase 5: Uncomment when Firebase is ready
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

import 'core/db/database_helper.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Phase 5: Firebase Initialization
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // Initialize Database
  await DatabaseHelper.instance.database;

  runApp(
    const ProviderScope(
      child: JMMiniMartApp(),
    ),
  );
}

class JMMiniMartApp extends StatelessWidget {
  const JMMiniMartApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JM Mini Mart ProPOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // To be defined
      darkTheme: AppTheme.darkTheme, // To be defined
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
