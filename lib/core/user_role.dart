import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRoleScreen extends StatelessWidget {
  const UserRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Peran Pengguna"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Masuk sebagai:",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              icon: const Icon(Icons.drive_eta),
              label: const Text("Driver"),
              onPressed: () async {
                // Simpan role 'driver' di profile (atau Supabase users table)
                if (user != null) {
                  await supabase.from('profiles').upsert({
                    'id': user.id,
                    'role': 'driver',
                  });
                  // Navigasi ke halaman home driver
                  Navigator.of(context).pushReplacementNamed('/driver');
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 50),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text("Client"),
              onPressed: () async {
                // Simpan role 'client' di profile (atau Supabase users table)
                if (user != null) {
                  await supabase.from('profiles').upsert({
                    'id': user.id,
                    'role': 'client',
                  });
                  // Navigasi ke halaman home client
                  Navigator.of(context).pushReplacementNamed('/client');
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
