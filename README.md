# Paca GT (Shipaton)

Marketplace Flutter de **pacas** en Guatemala. Una app, dos árboles de navegación (`StoreApp` / `BuyerApp`), backend **Supabase**, suscripciones con **RevenueCat**.

Track: estudiantes · plataforma demo: **Android**.

## Qué resuelve

- Las tiendas dejan de diseñar posts a mano en Facebook/WhatsApp.
- Free: plantilla de post fondo blanco + share sheet.
- `store_premium`: plantillas branded (logo, color).
- `buyer_premium`: promociones exclusivas de ropa.

## Stack

- Flutter + Riverpod + go_router
- `supabase_flutter`
- `purchases_flutter` (RevenueCat)
- `share_plus` (compartir imagen generada)

## Setup rápido (demo local sin backend)

```bash
flutter pub get
flutter run
```

Sin `--dart-define`, la app entra en **modo demo** (datos en memoria). Elige rol Tienda o Comprador y usa los toggles Pro para simular entitlements.

## Setup completo Shipaton

### 1. Supabase

1. Crea un proyecto.
2. Ejecuta el SQL en [`supabase/migrations/0001_init.sql`](supabase/migrations/0001_init.sql).
3. Activa Email auth.

### 2. RevenueCat + Play Console

| Tipo | ID |
|------|-----|
| Entitlement tienda | `store_premium` |
| Entitlement comprador | `buyer_premium` |
| Producto sugerido | `store_premium_monthly` |
| Producto sugerido | `buyer_premium_monthly` |

1. Crea productos de suscripción en Google Play (licencias de prueba).
2. Conéctalos en RevenueCat a los entitlements de arriba.
3. Crea un Offering con ambos packages.
4. Copia la **Google API Key** pública de RevenueCat.

### 3. Run Android

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY --dart-define=REVENUECAT_GOOGLE_API_KEY=goog_xxx
```

`Purchases.logIn` usa el `auth.uid` de Supabase como App User ID.

## Flujos demo (checklist)

### Tienda

1. Rol **Soy tienda** → crear paca (foto + precio GTQ) → estado `active`.
2. **Publicar** → preview fondo blanco → Compartir (share sheet → WhatsApp/Facebook).
3. Activar `store_premium` (compra real o toggle demo) → plantilla branded.
4. Tab **Marca**: logo, color, WhatsApp, departamento.

### Comprador

1. Rol **Soy comprador** → **Explorar** pacas → detalle → WhatsApp.
2. Tab **Promos** bloqueado → paywall `buyer_premium` → ver promos `premium_only`.

## Tests

```bash
flutter test test/entitlement_gates_test.dart test/role_picker_test.dart
```

## Estructura

```
lib/
  app/           # theme, router
  core/          # config, models, providers, entitlements, data
  features/
    auth/        # splash, login, role pick
    store/       # pacas, publish, brand, pro
    buyer/       # explore, promos, profile
    paywall/     # RevenueCat offerings
    share/       # plain/branded templates + capture
supabase/migrations/
docs/superpowers/specs/2026-09-26-paca-marketplace-design.md
```

## Fuera de MVP

Chat in-app, checkout de mercancía, Meta Graph / WhatsApp Business API, release iOS.
