import 'package:flutter_test/flutter_test.dart';
import 'package:shipaton_tienda/core/entitlements/entitlement_gates.dart';
import 'package:shipaton_tienda/core/models/models.dart';

void main() {
  group('EntitlementGates', () {
    test('store free cannot use branded template', () {
      const gates = EntitlementGates(
        hasStorePremium: false,
        hasBuyerPremium: false,
      );
      expect(gates.canUseBrandedTemplate(UserRole.store), isFalse);
      expect(gates.postTemplateFor(UserRole.store), 'plain');
    });

    test('store premium unlocks branded template', () {
      const gates = EntitlementGates(
        hasStorePremium: true,
        hasBuyerPremium: false,
      );
      expect(gates.canUseBrandedTemplate(UserRole.store), isTrue);
      expect(gates.postTemplateFor(UserRole.store), 'branded');
      expect(gates.canUseBrandedTemplate(UserRole.buyer), isFalse);
    });

    test('buyer free cannot view exclusive promos', () {
      const gates = EntitlementGates(
        hasStorePremium: false,
        hasBuyerPremium: false,
      );
      expect(gates.canViewExclusivePromos(UserRole.buyer), isFalse);
    });

    test('buyer premium unlocks exclusive promos', () {
      const gates = EntitlementGates(
        hasStorePremium: false,
        hasBuyerPremium: true,
      );
      expect(gates.canViewExclusivePromos(UserRole.buyer), isTrue);
      expect(gates.canViewExclusivePromos(UserRole.store), isFalse);
    });

    test('only a premium store can create promos', () {
      const free = EntitlementGates(
        hasStorePremium: false,
        hasBuyerPremium: false,
      );
      const storePro = EntitlementGates(
        hasStorePremium: true,
        hasBuyerPremium: false,
      );
      expect(free.canCreatePromos(UserRole.store), isFalse);
      expect(storePro.canCreatePromos(UserRole.store), isTrue);
      expect(storePro.canCreatePromos(UserRole.buyer), isFalse);
    });

    test('entitlement ids match role', () {
      const gates = EntitlementGates(
        hasStorePremium: false,
        hasBuyerPremium: false,
      );
      expect(gates.entitlementIdFor(UserRole.store), 'store_premium');
      expect(gates.entitlementIdFor(UserRole.buyer), 'buyer_premium');
    });
  });
}
