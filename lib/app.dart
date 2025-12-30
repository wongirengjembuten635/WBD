import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late Future<Widget> _initialScreen;

  @override
  void initState() {
    super.initState();
    _initialScreen = _decideHomeScreen();
  }

  Future<Widget> _decideHomeScreen() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return const LoginScreen();
    }
    // Fetch user role from your database or profile table.
    // Placeholder: Assume metadata or public.user table
    final userId = session.user.id;
    final user = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single()
        .execute();

    final role = user.data != null ? user.data['role'] as String? : null;
    if (role == 'worker') {
      return const HomeWorkerScreen();
    } else if (role == 'client') {
      return const HomeClientScreen();
    } else {
      // fallback to login if unknown role
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nomaden',
      debugShowCheckedModeBanner: false,
      routes: {
        '/splash': (_) => const SplashScreen(role: 'unknown'),
        '/login': (_) => const LoginScreen(),
        '/home_client': (_) => const HomeClientScreen(),
        '/home_worker': (_) => const HomeWorkerScreen(),
      },
      home: FutureBuilder<Widget>(
        future: _initialScreen,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen(
              role: 'role',
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          }
          return snapshot.data ?? const LoginScreen();
        },
      ),
    );
  }
}

extension on PostgrestTransformBuilder<PostgrestMap> {
  Future<dynamic> execute() {
    // You should provide your real logic here. To silence lints:
    throw UnimplementedError();
  }
}

// Placeholder widgets for routes
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key, required String role}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Splash Screen')),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Login Screen')),
    );
  }
}

class HomeClientScreen extends StatelessWidget {
  const HomeClientScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Home - Client')),
    );
  }
}

class HomeWorkerScreen extends StatelessWidget {
  const HomeWorkerScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Home - Worker')),
    );
  }
}
