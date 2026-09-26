import '../config/app_config.dart';
import '../models/models.dart';

/// Pure entitlement gates — unit-testable without SDK.
class EntitlementGates {
  const EntitlementGates({
    required this.hasStorePremium,
    required this.hasBuyerPremium,
  });

  final bool hasStorePremium;
  final bool hasBuyerPremium;

  bool canUseBrandedTemplate(UserRole? role) {
    if (role != UserRole.store) return false;
    return hasStorePremium;
  }

  bool canViewExclusivePromos(UserRole? role) {
    if (role != UserRole.buyer) return false;
    return hasBuyerPremium;
  }

  String postTemplateFor(UserRole? role) {
    return canUseBrandedTemplate(role) ? 'branded' : 'plain';
  }

  String entitlementIdFor(UserRole role) {
    switch (role) {
      case UserRole.store:
        return AppConfig.storePremiumEntitlement;
      case UserRole.buyer:
        return AppConfig.buyerPremiumEntitlement;
    }
  }
}
