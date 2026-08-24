import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/core/config/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => SupabaseService.client,
);
