import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/reports/data/report_models.dart';
import 'package:woofy/features/reports/data/reports_repository.dart';

void main() {
  const draft = ReportDraft(
    targetType: ReportTargetType.dog,
    targetId: 'dog-1',
    reason: ReportReason.inappropriateContent,
  );

  test('each target type serializes to its Postgres enum value', () {
    expect(ReportTargetType.dog.value, 'dog');
    expect(ReportTargetType.shelter.value, 'shelter');
    expect(ReportTargetType.conversation.value, 'conversation');
    expect(ReportTargetType.message.value, 'message');
  });

  test('the reasons match the ones the web already stores', () {
    // La columna `reason` es texto libre; si divergieran, la cola de
    // moderación quedaría con etiquetas distintas según el origen.
    expect(ReportReason.values.map((reason) => reason.label), [
      'Información falsa',
      'Venta disfrazada',
      'Contenido inapropiado',
      'No responde',
      'Otro',
    ]);
  });

  test('a report carries the reporter, the target and the reason', () async {
    final source = _FakeReportsDataSource();
    final repository = SupabaseReportsRepository.withDataSource(source);

    await repository.submit(draft);

    expect(source.inserted.single, {
      'reporter_id': 'user-1',
      'target_type': 'dog',
      'target_id': 'dog-1',
      'reason': 'Contenido inapropiado',
    });
  });

  test('blank details are dropped instead of stored empty', () async {
    final source = _FakeReportsDataSource();
    final repository = SupabaseReportsRepository.withDataSource(source);

    await repository.submit(
      const ReportDraft(
        targetType: ReportTargetType.message,
        targetId: 'msg-1',
        reason: ReportReason.other,
        details: '   ',
      ),
    );

    expect(source.inserted.single.containsKey('details'), isFalse);
  });

  test('details are kept and trimmed when present', () async {
    final source = _FakeReportsDataSource();
    final repository = SupabaseReportsRepository.withDataSource(source);

    await repository.submit(
      const ReportDraft(
        targetType: ReportTargetType.conversation,
        targetId: 'thread-1',
        reason: ReportReason.disguisedSale,
        details: '  Me pidió dinero  ',
      ),
    );

    expect(source.inserted.single['details'], 'Me pidió dinero');
  });

  test('reporting without a session fails before inserting', () async {
    final source = _FakeReportsDataSource(userId: null);
    final repository = SupabaseReportsRepository.withDataSource(source);

    await expectLater(
      repository.submit(draft),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          'report_requires_session',
        ),
      ),
    );
    expect(source.inserted, isEmpty);
  });

  test('the hourly limit stops report flooding', () async {
    // Denunciar en masa es en sí mismo una forma de acoso, y es el mismo
    // límite que ya aplica la web.
    final source = _FakeReportsDataSource(recentCount: 10);
    final repository = SupabaseReportsRepository.withDataSource(source);

    await expectLater(
      repository.submit(draft),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          'report_rate_limited',
        ),
      ),
    );
    expect(source.inserted, isEmpty);
  });

  test('just under the limit still goes through', () async {
    final source = _FakeReportsDataSource(recentCount: 9);
    final repository = SupabaseReportsRepository.withDataSource(source);

    await repository.submit(draft);

    expect(source.inserted, hasLength(1));
  });
}

class _FakeReportsDataSource implements ReportsDataSource {
  _FakeReportsDataSource({this.userId = 'user-1', this.recentCount = 0});

  final String? userId;
  final int recentCount;
  final List<Map<String, dynamic>> inserted = [];

  @override
  String? get currentUserId => userId;

  @override
  Future<int> countRecentReports(String reporterId, DateTime since) async =>
      recentCount;

  @override
  Future<void> insertReport(Map<String, dynamic> values) async {
    inserted.add(values);
  }
}
