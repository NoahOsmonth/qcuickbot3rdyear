import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer';

const String supabaseUrl = 'Url Here';
const String supabaseAnonKey =
    'Key here';

final supabase = Supabase.instance.client;

Future<void> initializeSupabase() async {
  try {
    // Initialize Supabase (PKCE is the default flow on mobile)
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
    );
    log('[Supabase] Initialized successfully');

    // Verify database connection and tables
    try {
      await supabase.from('chat_sessions').select('id').limit(1);
      await supabase.from('chat_messages').select('id').limit(1);
      log('[Supabase] Database tables verified successfully');
    } catch (e) {
      log(
        '[Supabase] Error verifying tables: $e\nMake sure to run the SQL setup script in your Supabase dashboard',
      );
    }
  } catch (e, stackTrace) {
    log('[Supabase] Initialization error: $e');
    log('[Supabase] Stack trace: $stackTrace');
    rethrow;
  }
}
