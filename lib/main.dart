import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://olhykkhbsihoglyrwpda.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9saHlra2hic2lob2dseXJ3cGRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY0MzAzNjAsImV4cCI6MjA4MjAwNjM2MH0.RyDS9tAeBt-i7gG7segs4RiXN_FGFvabkbpfADHQSlg',
  );

  runApp(const MyApp());
}

/// The root app widget which controls routing and session state.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nomaden App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const RoleChooserScreen(),
    );
  }
}

/// A screen for user to choose their role.
/// Navigates to login screen with the chosen role.
class RoleChooserScreen extends StatelessWidget {
  const RoleChooserScreen({super.key});

  void _navigateToLogin(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SplashScreen(role: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Role'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Silakan pilih peran Anda:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_outline),
                label: const Text('Saya Client'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () => _navigateToLogin(context, 'client'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.local_taxi),
                label: const Text('Saya Driver'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _navigateToLogin(context, 'driver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
