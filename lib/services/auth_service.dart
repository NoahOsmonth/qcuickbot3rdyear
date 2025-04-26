import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/supabase_client.dart';
import 'dart:developer';
import './messaging_service.dart'; // Import MessagingService

class AuthService {
  final GoTrueClient _auth = supabase.auth;
  final MessagingService _messagingService = MessagingService(); // Instantiate MessagingService

  AuthService() { // Add a constructor to listen to auth changes
    _listenToAuthChanges();
  }

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.onAuthStateChange.map((data) {
    final user = data.session?.user;
    log('[AuthState] Auth state changed - User: ${user?.id}');
    // Don't register token here directly, use the dedicated listener
    return user;
  });

  // Listen to auth state changes to register/unregister token
  void _listenToAuthChanges() {
    _auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user != null) {
        // User logged in or session restored
        await _registerDeviceToken(user.id);
      } else {
        // User logged out - potentially remove token if needed (optional)
        // await _unregisterDeviceToken(); // Implement if needed
        log('[AuthService] User logged out, device token not unregistered (optional feature).');
      }
    });
  }

  // Helper method to get and save FCM token
  Future<void> _registerDeviceToken(String userId) async {
    try {
      final token = await _messagingService.getToken();
      if (token != null) {
        log('[AuthService] Got FCM token: ...${token.substring(token.length - 10)}'); // Log last 10 chars
        // Upsert the token: inserts if new, updates if user_id exists
        await supabase.from('user_devices').upsert({
          'user_id': userId,
          'fcm_token': token,
          'created_at': DateTime.now().toIso8601String(), // Track last update
        });
        log('[AuthService] Successfully registered/updated FCM token for user $userId');
      } else {
        log('[AuthService] Failed to get FCM token.');
      }
    } catch (e) {
      log('[AuthService] Error registering FCM token: $e');
      // Consider more robust error handling/retry logic if needed
    }
  }

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
      // No need to explicitly call _registerDeviceToken here,
      // the onAuthStateChange listener will handle it.
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
      // Optional: Consider removing the token before signing out
      // final userId = currentUser?.id;
      // if (userId != null) {
      //   await _unregisterDeviceToken(userId); // You'd need to implement this
      // }
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

  // Get current user (synchronous)
  User? get currentUser => _auth.currentUser;
}

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
