# PRIYASA Notification + WhatsApp Commerce Contract

## Scope

This contract defines the server-side control plane for Email, Firebase Cloud Messaging (FCM), WhatsApp Business/Meta, order-status notifications, marketing automation, inbound WhatsApp commerce, and Razorpay hand-off.

The browser/Admin UI must never hold provider secrets. Provider credentials, webhook verification, template synchronization, message dispatch, inbound conversation state, and payment creation remain server-side.

## Channels

- Email: transactional and marketing delivery.
- FCM: web/Android transactional and marketing push.
- WhatsApp Cloud API: transactional, template and inbound commerce messaging.
- Order events: one canonical event stream fans out to enabled channel rules.

## Automation rule model

Each rule should contain:

- `name`
- `event_key`
- `enabled`
- `email_enabled`
- `whatsapp_enabled`
- `fcm_enabled`
- channel template keys
- optional delay
- JSON conditions
- audit timestamps

Canonical order events include `order.created`, `order.confirmed`, `order.paid`, `order.processing`, `order.shipped`, `order.out_for_delivery`, `order.delivered`, `order.cancelled`, `order.return_requested`, and `order.refunded`.

Customer/cart events include welcome, abandoned cart, wishlist, and back-in-stock triggers. Marketing events include campaign, coupon, re-engagement, and recommendation triggers.

## WhatsApp provider connection

Use the existing server-side integration boundary. Required capabilities:

1. Meta/WhatsApp Business connection and status.
2. Webhook verification and inbound message ingestion.
3. Outbound message delivery with provider message IDs.
4. Template catalog synchronization from Meta into PriyasaCore.
5. Template status/language/category tracking.
6. Delivery/read/failure webhook reconciliation.
7. Idempotent outbound dispatch and inbound event processing.

No Meta access token, app secret, phone-number ID secret, or webhook secret is returned to the Admin or Store browser.

## WhatsApp 24-hour customer-service window

Maintain a per-customer WhatsApp conversation/session state containing the latest qualifying customer message timestamp.

- Inside the provider's 24-hour customer-service window, permitted session replies can be sent according to WhatsApp policy.
- Outside the window, do not attempt a free-form session reply. Use an approved WhatsApp template where the provider requires it.
- Store `last_customer_message_at`, calculated window state, template/message IDs, and dispatch status for auditability.
- Never bypass Meta/WhatsApp policy by treating an expired window as active.

## Inbound product/cart commerce flow

When a customer sends a product, product URL, product ID, SKU, or cart/share payload to the official WhatsApp number:

1. Verify and persist the inbound webhook event idempotently.
2. Resolve the product/variant against PriyasaCore catalog data.
3. Associate the conversation with the customer by verified WhatsApp/mobile identity when available; otherwise create a pending customer/session.
4. Present product information and available variants using approved message formats.
5. If the customer wants to buy, collect variant/quantity and create/update a server-side commerce cart.
6. Ask for missing delivery details: recipient name, phone, address line, city, state, postal code and pincode.
7. Validate the address and inventory before checkout.
8. Run the same PriyasaCore checkout validation and order-creation rules used by the Store. Do not create a second WhatsApp-only order engine.
9. Create a Razorpay payment order through the existing PriyasaCore payment abstraction.
10. Return a secure payment hand-off/link; never collect card number, CVV, UPI PIN, OTP, or other payment secrets in WhatsApp.
11. Reconcile Razorpay webhook/payment status server-side before marking the order paid.
12. Continue the canonical order lifecycle notifications after payment.

## Cart-share capture

A WhatsApp cart-share payload should be treated as untrusted input. Re-resolve every product/variant, price, promotion, tax and stock value from PriyasaCore. Never trust client-provided totals.

The conversation session may store a temporary cart reference, but final order pricing and inventory reservation must come from PriyasaCore checkout.

## Razorpay boundary

WhatsApp must not directly call Razorpay with secret credentials. PriyasaCore creates the payment order and returns only the public payment hand-off information required by the customer. Payment capture/verification and webhook reconciliation remain server-side.

## Recommended server routes

The final Laravel host should expose authenticated admin controls under `/api/v1/admin/...` and provider webhooks under `/api/v1/webhooks/...`. Exact route names must be added only when implemented in the Laravel host; this document is a contract, not a claim that every route already exists.

Minimum logical operations:

- integration status/connect/disconnect
- automation list/update/toggle
- template list/sync/status
- notification dispatch/test
- WhatsApp inbound webhook
- WhatsApp delivery-status webhook
- conversation/session state
- commerce/cart hand-off
- Razorpay payment create/capture/webhook

## Reliability and safety

- Use idempotency keys for admin mutations and outbound dispatch where supported.
- Persist provider event/message IDs and processing status.
- Queue external sends; do not block order transactions on provider latency.
- Retry transient provider failures with bounded backoff.
- Dead-letter permanently failed jobs for operator review.
- Audit who changed automation/template configuration.
- Enforce customer opt-in/opt-out and marketing consent before marketing sends.
- Separate transactional order notifications from promotional campaigns.
- Apply rate limits and abuse controls to inbound WhatsApp commerce.
- Redact payment secrets and provider credentials from logs.

## Current repository boundary

The public `Priyasa-Commerce` repository currently stores the Commerce Core as an uploaded archive rather than an expanded Laravel source tree. Therefore this contract is intentionally committed separately instead of pretending that a Laravel controller has been wired into source files that are not present in the repository tree.
