import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/core/errors/error_mapper.dart';
import 'package:woofy/core/services/supabase_service.dart';
import 'package:woofy/features/reports/data/report_models.dart';
import 'package:woofy/features/reports/data/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => SupabaseReportsRepository(ref.watch(supabaseClientProvider)),
);

final reportControllerProvider = AsyncNotifierProvider<ReportController, void>(
  ReportController.new,
);

class ReportController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit(ReportDraft draft) async {
    state = const AsyncLoading();
    try {
      await ref.read(reportsRepositoryProvider).submit(draft);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(ErrorMapper.map(error, stackTrace), stackTrace);
      rethrow;
    }
  }
}
