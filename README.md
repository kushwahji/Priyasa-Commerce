# PRIYASA Core — Laravel Commerce Module

`PriyasaCore` is the authoritative commerce-domain module for PRIYASA. It is designed to sit inside the Laravel API at `api.priyasa.com` while the existing `CommerceAutomation` module remains the integration/automation layer.

## Included

- Catalog: categories, products, variants, SKU/barcode, size/color, pricing/MRP, tax rate, attributes, media, publishing status, collections.
- Inventory: quantity, reservations, atomic row locks, adjustments, sale commit, cancellation/return restock, movement ledger, low-stock threshold.
- Customer: phone-first customer identity, addresses, default address, order history, wishlist and reviews.
- Cart/checkout: server-side pricing, coupon validation, stock validation/reservation, order snapshots, order number generation, idempotency data model.
- Orders: lifecycle state machine, status history, cancellation, payment state, inventory commit/release/restock hooks.
- Payments: gateway contract, Razorpay HTTP adapter, payment records, transaction ledger, capture/refund service hooks.
- Shipping: provider contract and Shiprocket adapter foundation for serviceability/tracking/cancellation.
- Returns/refunds: return request lifecycle, admin transitions, refund/payment transaction data structures.
- Marketing: coupons, redemptions schema, collections, wishlist, product reviews.
- Operations: webhook event inbox, outbox event table, request IDs, health endpoint, reservation cleanup and outbox commands.
- Admin API: catalog, inventory, order status and returns endpoints.
- API versioning: `/api/v1`.
- E2E test suite: Laravel/Pest feature flow from customer/catalog/cart/checkout through inventory settlement, plus module contract smoke test.

## Deliberate boundary

WhatsApp, Meta Ads, WooCommerce, Shopify, custom commerce webhooks, FCM and growth automation already live in the supplied `CommerceAutomation` module. `PriyasaCore` exposes stable commerce contracts so those systems can consume/order/catalog events without owning core business rules.

Provider-specific credentials must never be committed. Configure them through environment variables. Razorpay and Shiprocket calls are real HTTP integrations; run them against sandbox/test credentials before production activation.

## Installation

Copy the module into the Laravel application under `Modules/PriyasaCore`, enable its service provider, install dependencies, run migrations and configure Sanctum. The host application's authenticated customer/admin identity must be mapped to the module's customer/admin authorization strategy.

Typical environment values:

```env
PRIYASA_CURRENCY=INR
PRIYASA_ORDER_PREFIX=PRI
PRIYASA_STOCK_RESERVATION_MINUTES=15
PRIYASA_DEFAULT_TAX_RATE=0
PRIYASA_PAYMENT_PROVIDER=razorpay
RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=
RAZORPAY_WEBHOOK_SECRET=
SHIPROCKET_EMAIL=
SHIPROCKET_PASSWORD=
SHIPROCKET_PICKUP_PINCODE=
```

## Verification

The repository snapshot was validated locally with:

- PHP lint over every PHP file: PASS.
- Module contract smoke test: PASS.
- Laravel/Pest E2E test suite included in `Tests/Feature/CommerceE2ETest.php`.

The full Laravel HTTP/database E2E suite requires a Laravel host application plus Composer-installed Laravel/Sanctum/Pest/Testbench dependencies; those runtime dependencies are not present in the current execution container, so a claim that the Laravel E2E suite itself executed here would be inaccurate.
