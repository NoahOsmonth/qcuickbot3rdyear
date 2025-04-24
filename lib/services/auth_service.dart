import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_client.dart'; // Your Supabase client instance

class AuthService {
  final GoTrueClient _auth = supabase.auth;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.onAuthStateChange.map((data) => data.session?.user);

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
}

// Provider for the AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// StreamProvider for auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});
