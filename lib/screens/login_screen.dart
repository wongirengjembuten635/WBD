import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  final String role; // 'driver' or 'client'

  const LoginScreen({Key? key, required this.role}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authResponse = await Supabase.instance.client.auth
          .signInWithPassword(email: _email.trim(), password: _password);
      final user = authResponse.user;
      if (user == null) {
        setState(() {
          _error = 'Login gagal. User tidak ditemukan.';
          _loading = false;
        });
        return;
      }

      // Ambil info profile user, pastikan role sesuai dengan yang dipilih
      final profileResp = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileResp == null || profileResp['role'] != widget.role) {
        setState(() {
          _error =
              'Role akun tidak sesuai (${profileResp?['role'] ?? "Belum dipilih"}).';
          _loading = false;
        });
        return;
      }

      // Login sukses, arahkan ke home driver/client
      if (widget.role == 'driver') {
        Navigator.of(context).pushReplacementNamed('/driver');
      } else if (widget.role == 'client') {
        Navigator.of(context).pushReplacementNamed('/client');
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _email.trim(),
        password: _password,
      );
      final user = authResponse.user;
      if (user == null) {
        setState(() {
          _error = 'Register gagal.';
          _loading = false;
        });
        return;
      }

      // Simpan role ke profile di table 'profiles'
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'email': _email.trim(),
        'role': widget.role,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      });

      setState(() {
        _error = 'Registrasi sukses. Silakan verifikasi email & login.';
        _loading = false;
      });
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String roleLabel = widget.role == 'driver' ? 'Driver' : 'Client';
    return Scaffold(
      appBar: AppBar(
        title: Text('Login $roleLabel'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Masuk sebagai $roleLabel',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (val) => _email = val,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Email wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  onChanged: (val) => _password = val,
                  validator: (val) => val == null || val.length < 6
                      ? 'Minimal 6 karakter'
                      : null,
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  _login();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text('Login'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum punya akun?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 5),
                OutlinedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _register();
                          }
                        },
                  child: const Text('Daftar Akun Baru'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
