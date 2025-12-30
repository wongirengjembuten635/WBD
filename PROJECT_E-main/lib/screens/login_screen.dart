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
  String _username = '';
  String _passwordConfirm = '';
  bool _loading = false;
  bool _isRegisterMode = false;
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
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
      Map<String, dynamic>? profileResp;
      try {
        profileResp = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
      } on PostgrestException catch (e) {
        // Jika tabel profiles tidak ada, coba gunakan user metadata sebagai fallback
        if (e.code == 'PGRST205' ||
            e.message.contains('Could not find the table')) {
          // Cek user metadata sebagai alternatif
          final userMetadata = user.userMetadata;
          if (userMetadata != null && userMetadata['role'] != null) {
            if (userMetadata['role'] != widget.role) {
              setState(() {
                _error =
                    'Role akun tidak sesuai (${userMetadata['role'] ?? "Belum dipilih"}).';
                _loading = false;
              });
              return;
            }
            // Role sesuai, lanjutkan ke navigasi
          } else {
            setState(() {
              _error =
                  'Tabel profiles tidak ditemukan. Silakan hubungi administrator untuk membuat tabel profiles di database.';
              _loading = false;
            });
            return;
          }
        } else {
          rethrow;
        }
      }

      // Jika profileResp berhasil diambil, cek role
      if (profileResp != null && profileResp['role'] != widget.role) {
        setState(() {
          final role = profileResp!['role'] as String?;
          _error = 'Role akun tidak sesuai (${role ?? "Belum dipilih"}).';
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
    } on PostgrestException catch (e) {
      setState(() {
        if (e.code == 'PGRST205' ||
            e.message.contains('Could not find the table')) {
          _error =
              'Tabel profiles tidak ditemukan di database. Silakan hubungi administrator.';
        } else {
          _error = 'Kesalahan database: ${e.message}';
        }
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
    // Validasi password confirmation
    if (_password != _passwordConfirm) {
      setState(() {
        _error = 'Password dan konfirmasi password tidak sama.';
      });
      return;
    }

    // Validasi checkbox untuk client role
    if (widget.role == 'client' && !_agreeToTerms) {
      setState(() {
        _error =
            'Anda harus menyetujui syarat dan ketentuan untuk membuat akun.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _email.trim(),
        password: _password,
        data: {
          'username': _username.trim(),
          'role': widget.role,
        },
      );
      final user = authResponse.user;
      if (user == null) {
        setState(() {
          _error = 'Register gagal.';
          _loading = false;
        });
        return;
      }

      // Simpan role ke profile di table 'profiles' atau user metadata sebagai fallback
      try {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'username': _username.trim(),
          'email': _email.trim(),
          'role': widget.role,
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } on PostgrestException catch (e) {
        // Jika tabel profiles tidak ada, simpan role di user metadata sebagai fallback
        if (e.code == 'PGRST205' ||
            e.message.contains('Could not find the table')) {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              data: {
                'role': widget.role,
                'username': _username.trim(),
              },
            ),
          );
        } else {
          rethrow;
        }
      }

      setState(() {
        _loading = false;
      });

      // Navigasi langsung ke dashboard setelah registrasi berhasil
      if (widget.role == 'driver') {
        Navigator.of(context).pushReplacementNamed('/driver');
      } else if (widget.role == 'client') {
        Navigator.of(context).pushReplacementNamed('/client');
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } on PostgrestException catch (e) {
      setState(() {
        if (e.code == 'PGRST205' ||
            e.message.contains('Could not find the table')) {
          _error =
              'Tabel profiles tidak ditemukan di database. Silakan hubungi administrator.';
        } else {
          _error = 'Kesalahan database: ${e.message}';
        }
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
        title: Text(_isRegisterMode ? 'Daftar $roleLabel' : 'Login $roleLabel'),
        centerTitle: true,
        leading: _isRegisterMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isRegisterMode = false;
                    _error = null;
                    _username = '';
                    _passwordConfirm = '';
                    _agreeToTerms = false;
                    _obscurePassword = true;
                    _obscurePasswordConfirm = true;
                  });
                },
              )
            : null,
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
                  _isRegisterMode
                      ? 'Daftar sebagai $roleLabel'
                      : 'Masuk sebagai $roleLabel',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                // Tampilkan form registrasi khusus untuk client role
                if (_isRegisterMode && widget.role == 'client') ...[
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => _username = val,
                    validator: (val) => val == null || val.isEmpty
                        ? 'Username wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],
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
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: _obscurePassword,
                  onChanged: (val) => _password = val,
                  validator: (val) => val == null || val.length < 6
                      ? 'Minimal 6 karakter'
                      : null,
                ),
                // Tampilkan password confirmation dan checkbox hanya untuk client role saat registrasi
                if (_isRegisterMode && widget.role == 'client') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password Lagi',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePasswordConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePasswordConfirm = !_obscurePasswordConfirm;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      helperText:
                          'Masukkan password sekali lagi untuk verifikasi',
                    ),
                    obscureText: _obscurePasswordConfirm,
                    onChanged: (val) => _passwordConfirm = val,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Konfirmasi password wajib diisi';
                      }
                      if (val != _password) {
                        return 'Password tidak sama';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _agreeToTerms = !_agreeToTerms;
                            });
                          },
                          child: Text(
                            'Saya setuju dengan syarat dan ketentuan',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (!_isRegisterMode) ...[
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
                            setState(() {
                              _isRegisterMode = true;
                              _error = null;
                            });
                          },
                    child: const Text('Daftar Akun Baru'),
                  ),
                ] else ...[
                  // Tombol untuk submit registrasi
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loading ||
                                  (widget.role == 'client' && !_agreeToTerms)
                              ? null
                              : () {
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    _register();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator()
                              : const Text('Buat Akun'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sudah punya akun?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 5),
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            setState(() {
                              _isRegisterMode = false;
                              _error = null;
                              _username = '';
                              _passwordConfirm = '';
                              _agreeToTerms = false;
                              _obscurePassword = true;
                              _obscurePasswordConfirm = true;
                            });
                          },
                    child: const Text('Kembali ke Login'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
