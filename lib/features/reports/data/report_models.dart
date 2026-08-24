/// Qué se está reportando. Los valores serializados coinciden con el enum
/// `report_target_type` de Postgres: `dog | shelter | conversation | message`.
enum ReportTargetType {
  dog('dog'),
  shelter('shelter'),
  conversation('conversation'),
  message('message');

  const ReportTargetType(this.value);

  final String value;
}

/// Motivos de denuncia. Son exactamente los mismos que ofrece la web en
/// `ReportButton.tsx`: la columna `reason` es texto libre, así que si acá
/// divergieran, la cola de moderación quedaría con etiquetas inconsistentes
/// según desde dónde se denunció.
enum ReportReason {
  falseInformation('Información falsa'),
  disguisedSale('Venta disfrazada'),
  inappropriateContent('Contenido inapropiado'),
  unresponsive('No responde'),
  other('Otro');

  const ReportReason(this.label);

  final String label;
}

class ReportDraft {
  const ReportDraft({
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.details,
  });

  final ReportTargetType targetType;
  final String targetId;
  final ReportReason reason;
  final String? details;

  Map<String, dynamic> toJson(String reporterId) => {
    'reporter_id': reporterId,
    'target_type': targetType.value,
    'target_id': targetId,
    'reason': reason.label,
    'details': ?_optional(details),
  };

  static String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
