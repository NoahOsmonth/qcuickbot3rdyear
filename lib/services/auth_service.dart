import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/supabase_client.dart';
import 'dart:developer';

class AuthService {
  final GoTrueClient _auth = supabase.auth;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.onAuthStateChange.map((data) {
    final user = data.session?.user;
    log('[AuthState] Auth state changed - User: ${user?.id}');
    return user;
  });

  // Get current user (synchronous)
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<AuthResponse> signUp(String email, String password) async {
    try {
      final response = await _auth.signUp(email: email, password: password);
      log('[AuthService] User signed up: ${response.user?.id}');
      return response;
    } on AuthException catch (e) {
      log('[AuthService] Sign up error: ${e.message}');
      rethrow;
    } catch (e) {
      log('[AuthService] Unexpected sign up error: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _auth.signInWithPassword(email: email, password: password);
      log('[AuthService] User signed in: ${response.user?.id}');
      return response;
    } on AuthException catch (e) {
      log('[AuthService] Sign in error: ${e.message}');
      rethrow;
    } catch (e) {
      log('[AuthService] Unexpected sign in error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      log('[AuthService] User signed out successfully');
    } on AuthException catch (e) {
      log('[AuthService] Sign out error: ${e.message}');
      rethrow;
    } catch (e) {
      log('[AuthService] Unexpected sign out error: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(email);
      log('[AuthService] Password reset email sent to: $email');
    } on AuthException catch (e) {
      log('[AuthService] Password reset error: ${e.message}');
      rethrow;
    } catch (e) {
      log('[AuthService] Unexpected password reset error: $e');
      rethrow;
    }
  }
}

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
