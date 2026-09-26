import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (!AppConfig.hasSupabase) {
      context.go('/role');
      return;
    }
    final session = ref.read(supabaseProvider).auth.currentSession;
    if (session == null) {
      context.go('/auth');
    } else {
      await ref.read(customerInfoProvider.notifier).logIn(session.user.id);
      final profile = await ref.read(profileProvider.future);
      if (!mounted) return;
      if (profile?.role == null) {
        context.go('/role');
      } else if (profile!.role!.name == 'store') {
        context.go('/store');
      } else {
        context.go('/buyer');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checkroom, size: 72, color: Color(0xFF1B5E20)),
            SizedBox(height: 16),
            Text(
              'Paca GT',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text('Pacas en Guatemala · Shipaton'),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
