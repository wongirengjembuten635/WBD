import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient client = Supabase.instance.client;

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw Exception('Sign up failed');
      }
    } catch (e) {
      throw Exception('Sign up error: $e');
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        // additional check: check for error response
        throw Exception('Sign in failed');
      }
    } catch (e) {
      throw Exception('Sign in error: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out error: $e');
    }
  }

  User? get currentUser => client.auth.currentUser;
}

class ProfileService {
  Future<void> create({required String role}) async {}
}
