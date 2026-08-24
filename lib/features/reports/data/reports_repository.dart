import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/errors/error_mapper.dart';
import 'package:woofy/features/reports/data/report_models.dart';

abstract interface class ReportsRepository {
  Future<void> submit(ReportDraft draft);
}

abstract interface class ReportsDataSource {
  String? get currentUserId;

  Future<int> countRecentReports(String reporterId, DateTime since);

  Future<void> insertReport(Map<String, dynamic> values);
}

class SupabaseReportsDataSource implements ReportsDataSource {
  SupabaseReportsDataSource(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<int> countRecentReports(String reporterId, DateTime since) async {
    final rows = await _client
        .from('reports')
        .select('id')
        .eq('reporter_id', reporterId)
        .gte('created_at', since.toIso8601String());
    return rows.length;
  }

  @override
  Future<void> insertReport(Map<String, dynamic> values) async {
    await _client.from('reports').insert(values);
  }
}

class SupabaseReportsRepository implements ReportsRepository {
  SupabaseReportsRepository(SupabaseClient client)
    : _source = SupabaseReportsDataSource(client);

  SupabaseReportsRepository.withDataSource(this._source);

  /// Mismo límite que aplica la web en `createReport()`. Sin esto, denunciar
  /// en masa sería una forma de acoso en sí misma.
  static const maxReportsPerHour = 10;

  final ReportsDataSource _source;

  @override
  Future<void> submit(ReportDraft draft) async {
    try {
      final reporterId = _source.currentUserId;
      if (reporterId == null) {
        throw const AppException(
          code: 'report_requires_session',
          message: 'Iniciá sesión para poder denunciar.',
        );
      }

      final since = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      final recent = await _source.countRecentReports(reporterId, since);
      if (recent >= maxReportsPerHour) {
        throw const AppException(
          code: 'report_rate_limited',
          message: 'Alcanzaste el límite de denuncias por hora.',
        );
      }

      await _source.insertReport(draft.toJson(reporterId));
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }
}
