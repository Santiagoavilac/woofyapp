import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/core/services/supabase_service.dart';
import 'package:woofy/features/banners/data/banner_models.dart';
import 'package:woofy/features/banners/data/banner_repository.dart';

final bannerRepositoryProvider = Provider<BannerRepository>(
  (ref) => SupabaseBannerRepository(ref.watch(supabaseClientProvider)),
);

final bannersProvider = FutureProvider.family<List<PromoBanner>, BannerSlot>(
  (ref, slot) => ref.watch(bannerRepositoryProvider).fetchBanners(slot),
);
