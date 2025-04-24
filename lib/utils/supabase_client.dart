import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer';

const String supabaseUrl = 'https://jgvaqwmxwtherxrdplmv.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpndmFxd214d3RoZXJ4cmRwbG12Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU0NjM1ODAsImV4cCI6MjA2MTAzOTU4MH0.KE2nWmujF5pVsBsf10fqnQlIlZ52Mvz7pkwj6_mttRg';

final supabase = Supabase.instance.client;

Future<void> initializeSupabase() async {
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true
    );
    log('[Supabase] Initialized successfully');
    
    // Verify database connection and tables
    try {
      await supabase.from('chat_sessions').select('id').limit(1);
      await supabase.from('chat_messages').select('id').limit(1);
      log('[Supabase] Database tables verified successfully');
    } catch (e) {
      log('[Supabase] Error verifying tables: $e\nMake sure to run the SQL setup script in your Supabase dashboard');
    }
  } catch (e, stackTrace) {
    log('[Supabase] Initialization error: $e');
    log('[Supabase] Stack trace: $stackTrace');
    rethrow;
  }
}
