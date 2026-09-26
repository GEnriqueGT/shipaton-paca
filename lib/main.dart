import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/config/app_config.dart';
import 'core/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  if (AppConfig.hasRevenueCat) {
    await Purchases.setLogLevel(LogLevel.info);
    final configuration =
        PurchasesConfiguration(AppConfig.revenueCatGoogleApiKey);
    await Purchases.configure(configuration);
  }

  runApp(const ProviderScope(child: PacaGtApp()));
}

class PacaGtApp extends ConsumerWidget {
  const PacaGtApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    ref.listen(currentUserProvider, (prev, next) async {
      if (next != null && AppConfig.hasRevenueCat) {
        await ref.read(customerInfoProvider.notifier).logIn(next.id);
      }
    });

    return MaterialApp.router(
      title: 'Paca GT',
      theme: buildPacaTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
