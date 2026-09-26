# Paca GT — Marketplace + RevenueCat (Shipaton Students)

## Summary

Flutter marketplace for clothing *pacas* in Guatemala. One app, two navigation trees after role pick (`StoreApp` / `BuyerApp`). Stores generate social posts and share via system share sheet (no Meta APIs). RevenueCat gates store branding templates and buyer-only promotions. Backend: Supabase. Primary demo platform: Android.

## Decisions locked

| Topic | Choice |
|--------|--------|
| Product shape | Marketplace: buyers + stores in one app |
| Architecture | Shell + separate `StoreApp` / `BuyerApp` nav trees |
| Social automation | Generate image+copy → share sheet (WhatsApp/Facebook) |
| Backend | Supabase (Auth, Postgres, Storage) |
| Monetization | Entitlements `store_premium` + `buyer_premium` |
| Platform priority | Android first |
| Hackathon track | Students / Shipaton + RevenueCat SDK |

## Architecture

```text
Launch → Supabase Auth → Role pick (once) → StoreApp | BuyerApp
                              ↓
                     RevenueCat (appUserID = uid)
```

- **Shell:** auth, session, RevenueCat init, theme, role picker, shared paywall.
- **StoreApp:** paca CRUD, brand settings, post preview/share, store paywall.
- **BuyerApp:** explore feed, promo tab (gated), buyer paywall, profile.

## Data model (Supabase)

### `profiles`
- `id` (FK auth.users), `role` (`store` | `buyer`), `display_name`, `department`, `phone_whatsapp`, `logo_url`, `brand_color`

### `pacas`
- `id`, `store_id`, `title`, `description`, `price_gtq`, `category`, `size_mix`, `photo_urls[]`, `status` (`draft` | `active` | `sold`), `created_at`

### `promotions`
- `id`, `store_id`, `paca_id` (nullable), `title`, `discount_label`, `starts_at`, `ends_at`, `premium_only` (bool)

### `share_logs`
- `id`, `store_id`, `paca_id`, `template` (`plain` | `branded`), `created_at`

### Storage
- Buckets: `paca-photos`, `store-logos`
- RLS: stores manage own rows; buyers read active pacas; promo visibility enforced in app via `buyer_premium` (and RLS where practical)

## RevenueCat

- Products (Play sandbox): `store_premium_monthly`, `buyer_premium_monthly`
- Entitlements: `store_premium`, `buyer_premium`
- App User ID: Supabase `auth.uid`
- Gates:
  - Store free → white-background plain post template; single share action
  - Store premium → branded templates (logo, color, typography); richer multi-target share UX
  - Buyer free → explore feed only
  - Buyer premium → exclusive promotions section

## MVP screens

### Shell
Splash, Auth, Role pick, shared Paywall

### StoreApp tabs
1. Mis pacas (list + create/edit)
2. Publicar (select paca → preview → share)
3. Marca (logo/color/name; premium unlocks branded output)
4. Pro (store paywall)

### BuyerApp tabs
1. Explorar (feed, department/category filters, GTQ)
2. Promos (gated / teaser + paywall)
3. Perfil

### Publish flow
1. Select paca → 2. Render template (`plain` | `branded`) → 3. Capture widget → 4. `share_plus` → 5. Log `share_logs`

## Out of scope (MVP)

In-app chat, merchandise checkout, Meta/WhatsApp Business APIs, iOS shipping, multi-role accounts beyond profile role switch for demo.

## Flutter stack

- Existing: Flutter app `shipaton_tienda`
- Add: `supabase_flutter`, `purchases_flutter`, `go_router`, `flutter_riverpod`, `share_plus`, `image_picker`, `cached_network_image`
- Post export: `RepaintBoundary` → image bytes → share

## Errors & edge cases

- Offline messaging + retry
- Purchase cancel / `restorePurchases` on paywall
- Persist role; allow change only from profile (demo)
- Expired entitlement → plain template / hide exclusive promos
- Block publish without ≥1 photo

## Testing (Shipaton)

- Unit: entitlement gates for templates and promos
- Widget: role picker + paywall smoke
- Manual: Play billing sandbox + RevenueCat + WhatsApp share

## Success criteria for demo

1. Store creates a paca and shares a plain post from the phone.
2. With `store_premium`, same flow shows branded creatives.
3. Buyer browses pacas; with `buyer_premium`, sees exclusive promos.
4. Pitch clearly ties RevenueCat entitlements to automation away from manual Facebook/WhatsApp design work.
