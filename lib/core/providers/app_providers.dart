import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../data/repositories.dart';
import '../entitlements/entitlement_gates.dart';
import '../models/models.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  if (!AppConfig.hasSupabase) {
    throw StateError('Supabase is not configured');
  }
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  if (!AppConfig.hasSupabase) {
    return const Stream<AuthState>.empty();
  }
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  if (!AppConfig.hasSupabase) return null;
  final auth = ref.watch(authStateProvider);
  return auth.maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => ref.watch(supabaseProvider).auth.currentUser,
  );
});

final profileProvider = FutureProvider<Profile?>((ref) async {
  if (!AppConfig.hasSupabase) {
    return DemoStore.instance.profile;
  }
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final client = ref.watch(supabaseProvider);
  final data = await client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();
  if (data == null) return null;
  return Profile.fromJson(Map<String, dynamic>.from(data));
});

final customerInfoProvider =
    StateNotifierProvider<CustomerInfoNotifier, AsyncValue<CustomerInfo?>>(
  (ref) => CustomerInfoNotifier(),
);

class CustomerInfoNotifier extends StateNotifier<AsyncValue<CustomerInfo?>> {
  CustomerInfoNotifier() : super(const AsyncValue.data(null)) {
    _listen();
  }

  void _listen() {
    if (!AppConfig.hasRevenueCat) return;
    Purchases.addCustomerInfoUpdateListener((info) {
      state = AsyncValue.data(info);
    });
  }

  Future<void> refresh() async {
    if (!AppConfig.hasRevenueCat) {
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final info = await Purchases.getCustomerInfo();
      state = AsyncValue.data(info);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logIn(String userId) async {
    if (!AppConfig.hasRevenueCat) return;
    await Purchases.logIn(userId);
    await refresh();
  }

  Future<void> logOut() async {
    if (!AppConfig.hasRevenueCat) return;
    try {
      await Purchases.logOut();
    } catch (_) {
      // Already anonymous.
    }
    state = const AsyncValue.data(null);
  }
}

final demoModeProvider = Provider<bool>((ref) {
  return !AppConfig.hasSupabase;
});

/// Bumps when demo premium toggles so UI rebuilds.
final demoPremiumTickProvider = StateProvider<int>((ref) => 0);

final entitlementGatesProvider = Provider<EntitlementGates>((ref) {
  ref.watch(customerInfoProvider);
  ref.watch(demoPremiumTickProvider);
  final info = ref.watch(customerInfoProvider).valueOrNull;
  final active = info?.entitlements.active ?? {};
  final demoStore = DemoStore.instance.storePremium;
  final demoBuyer = DemoStore.instance.buyerPremium;
  return EntitlementGates(
    hasStorePremium:
        active.containsKey(AppConfig.storePremiumEntitlement) || demoStore,
    hasBuyerPremium:
        active.containsKey(AppConfig.buyerPremiumEntitlement) || demoBuyer,
  );
});
