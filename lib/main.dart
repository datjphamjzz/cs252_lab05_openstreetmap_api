import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:openstreetmap_api/auth_service.dart';
import 'package:openstreetmap_api/login_screen.dart';
import 'package:openstreetmap_api/my_app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const MyApp();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
