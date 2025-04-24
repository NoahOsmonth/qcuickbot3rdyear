import 'package:supabase_flutter/supabase_flutter.dart';

// TODO: Replace with your actual Supabase URL and Anon Key
const String supabaseUrl = 'https://jgvaqwmxwtherxrdplmv.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpndmFxd214d3RoZXJ4cmRwbG12Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU0NjM1ODAsImV4cCI6MjA2MTAzOTU4MH0.KE2nWmujF5pVsBsf10fqnQlIlZ52Mvz7pkwj6_mttRg';

final supabase = Supabase.instance.client;

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  print('Supabase Initialized!'); // Optional: for debugging
}
