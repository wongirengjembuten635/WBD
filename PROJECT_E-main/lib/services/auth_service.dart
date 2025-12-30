import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Register with email & password (no email verification)
  /// Returns User? (null if failed)
  Future<User?> register(String email, String password) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
    );
    // Fix: SignUpResponse now has 'user' or 'user' may be null, check for error
    if (res.user != null) {
      return res.user;
    }
    return null;
  }

  /// Login with email & password
  /// Returns Session? (null if failed)
  Future<Session?> login(String email, String password) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    // Fix: AuthResponse now has 'session', return or null if failed
    if (res.session != null) {
      return res.session;
    }
    return null;
  }

  /// Logout current user
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// Returns current logged-in User, or null
  User? getCurrentUser() => _client.auth.currentUser;
}
