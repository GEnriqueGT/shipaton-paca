import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/models.dart';
import '../core/providers/app_providers.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/role_picker_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/buyer/buyer_shell.dart';
import '../features/buyer/paca_detail_screen.dart';
import '../features/paywall/paywall_screen.dart';
import '../features/store/paca_form_screen.dart';
import '../features/store/publish_screen.dart';
import '../features/store/store_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final demo = ref.watch(demoModeProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: demo ? null : _RouterRefresh(ref),
    redirect: (context, state) {
      final loc = state.matchedLocation;

      if (demo) {
        if (loc == '/splash' || loc == '/auth') return '/role';
        return null;
      }

      final session = ref.read(supabaseProvider).auth.currentSession;
      final loggedIn = session != null;
      final loggingIn = loc == '/auth' || loc == '/splash';

      if (!loggedIn) {
        return loggingIn ? null : '/auth';
      }

      if (loc == '/auth' || loc == '/splash') {
        final profile = ref.read(profileProvider).valueOrNull;
        if (profile?.role == null) return '/role';
        return profile!.role == UserRole.store ? '/store' : '/buyer';
      }

      if (loc == '/role') {
        final profile = ref.read(profileProvider).valueOrNull;
        if (profile?.role == UserRole.store) return '/store';
        if (profile?.role == UserRole.buyer) return '/buyer';
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/role',
        builder: (context, state) => const RolePickerScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) {
          final roleParam = state.uri.queryParameters['role'];
          final role = UserRole.tryParse(roleParam) ?? UserRole.store;
          return PaywallScreen(role: role);
        },
      ),
      GoRoute(
        path: '/store',
        builder: (context, state) => const StoreShell(),
        routes: [
          GoRoute(
            path: 'paca/new',
            builder: (context, state) => const PacaFormScreen(),
          ),
          GoRoute(
            path: 'paca/:id',
            builder: (context, state) =>
                PacaFormScreen(pacaId: state.pathParameters['id']),
          ),
          GoRoute(
            path: 'publish/:id',
            builder: (context, state) =>
                PublishScreen(pacaId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/buyer',
        builder: (context, state) => const BuyerShell(),
        routes: [
          GoRoute(
            path: 'paca/:id',
            builder: (context, state) =>
                PacaDetailScreen(pacaId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(profileProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
