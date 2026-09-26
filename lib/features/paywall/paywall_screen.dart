import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _loading = false;
  String? _error;
  Offerings? _offerings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AppConfig.hasRevenueCat) return;
    setState(() => _loading = true);
    try {
      _offerings = await Purchases.getOfferings();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _entitlement => widget.role == UserRole.store
      ? AppConfig.storePremiumEntitlement
      : AppConfig.buyerPremiumEntitlement;

  String get _headline =>
      widget.role == UserRole.store ? 'Tienda Pro' : 'Comprador Pro';

  String get _body => widget.role == UserRole.store
      ? 'Publica en tus redes con branding (logo, color y plantillas bonitas). En free solo fondo blanco.'
      : 'Desbloquea promociones exclusivas de ropa de tiendas en Guatemala.';

  Future<void> _purchase(Package package) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      await ref.read(customerInfoProvider.notifier).refresh();
      final active =
          customerInfo.entitlements.active.containsKey(_entitlement);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              active
                  ? '¡Premium activado!'
                  : 'Compra registrada. Revisa entitlements en RevenueCat.',
            ),
          ),
        );
        if (active) Navigator.of(context).pop(true);
      }
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        setState(() => _error = e.message ?? e.toString());
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    try {
      await Purchases.restorePurchases();
      await ref.read(customerInfoProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compras restauradas')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final packages = _offerings?.current?.availablePackages ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(_headline)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(_body, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            'Entitlement: $_entitlement',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (!AppConfig.hasRevenueCat) ...[
            const Text(
              'RevenueCat no configurado. Usa el toggle demo en Pro / Perfil, '
              'o pasa --dart-define=REVENUECAT_GOOGLE_API_KEY=...',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (widget.role == UserRole.store) {
                  DemoStore.instance.storePremium = true;
                } else {
                  DemoStore.instance.buyerPremium = true;
                }
                ref.read(demoPremiumTickProvider.notifier).state++;
                Navigator.of(context).pop(true);
              },
              child: const Text('Activar premium (demo local)'),
            ),
          ] else if (packages.isEmpty && !_loading) ...[
            const Text('No hay offerings configurados en RevenueCat todavía.'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _restore,
              child: const Text('Restaurar compras'),
            ),
          ] else
            ...packages.map(
              (pkg) => Card(
                child: ListTile(
                  title: Text(pkg.storeProduct.title),
                  subtitle: Text(pkg.storeProduct.description),
                  trailing: Text(
                    pkg.storeProduct.priceString,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: _loading ? null : () => _purchase(pkg),
                ),
              ),
            ),
          if (AppConfig.hasRevenueCat) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loading ? null : _restore,
              child: const Text('Restaurar compras'),
            ),
          ],
        ],
      ),
    );
  }
}
