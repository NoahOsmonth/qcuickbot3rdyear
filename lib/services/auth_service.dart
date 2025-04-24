import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/supabase_client.dart';

class AuthService {
  final GoTrueClient _auth = supabase.auth;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.onAuthStateChange.map((data) {
    final user = data.session?.user;
    print('[AuthState] session: \\${data.session}, user: \\${user}');
    return user;
  });

  // Get current user (synchronous)
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<AuthResponse> signUp(String email, String password) async {
    try {
      final response = await _auth.signUp(email: email, password: password);
      return response;
    } on AuthException catch (e) {
      print('Supabase Auth Error (SignUp): ${e.message}');
      rethrow; // Rethrow to handle in UI
    } catch (e) {
      print('Unexpected Error (SignUp): $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _auth.signInWithPassword(email: email, password: password);
      return response;
    } on AuthException catch (e) {
      print('Supabase Auth Error (SignIn): ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Error (SignIn): $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException catch (e) {
      print('Supabase Auth Error (SignOut): ${e.message}');
      // Handle error appropriately, maybe show a snackbar
    } catch (e) {
      print('Unexpected Error (SignOut): $e');
    }
  }

  /// Send magic link / reset‑password email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      print('Supabase Auth Error (ResetPassword): ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Error (ResetPassword): $e');
      rethrow;
    }
  }
}

final authServiceProvider = Provider((ref) => AuthService());

// Stream provider for authentication state
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);
