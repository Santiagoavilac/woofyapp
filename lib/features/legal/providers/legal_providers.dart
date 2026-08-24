import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/core/services/supabase_service.dart';
import 'package:woofy/features/legal/data/account_deletion_repository.dart';

final accountDeletionRepositoryProvider = Provider<AccountDeletionRepository>(
  (ref) => SupabaseAccountDeletionRepository(ref.watch(supabaseClientProvider)),
);
