import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_app/app/app.dart';
import 'package:mi_app/app/bootstrap_error_app.dart';
import 'package:mi_app/core/config/env.dart';
import 'package:mi_app/core/errors/error_mapper.dart';
import 'package:mi_app/core/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Env.load();
    await initializeDateFormatting('es');
    await SupabaseService.initialize();
    runApp(const ProviderScope(child: WoofyApp()));
  } catch (error, stackTrace) {
    runApp(BootstrapErrorApp(exception: ErrorMapper.map(error, stackTrace)));
  }
}
