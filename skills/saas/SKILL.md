---
name: saas
description: Turn a single-business app into a multi-tenant SaaS, or build one from scratch, using the Drezivo approach - Clerk proves identity, the API alone decides membership, role, scope, modules and subscription access; one workspace per business owner; owners invite staff by email/Gmail; staff see only what their role and scope allow; subscription access (full / read_only / locked) is derived at request time and enforced by one central gate; payments are manual proof reviewed by an operator; support uses time-bound grants, never impersonation; Postgres RLS backs the tenant filter. Use when the user says /saas, "make this SaaS", "multi-tenant", "workspace per owner", "subscription / paywall", "invite staff by email", "Clerk login", "tenant isolation", "partner / promo code pricing", or wants an app sold to more than one business.
---

# /saas - multi-tenant SaaS foundation (Drezivo approach)

One sentence governs everything:

> **Clerk proves who someone is. The API decides what they may do, where, and whether the
> workspace is paid up - from its own database, on every request.**

A Clerk user id, org id, session claim, URL slug or header is never authority by itself.
Each one is input that the server resolves against its own rows, and anything missing,
ambiguous, stale or unknown is rejected (fail closed).

Reference implementation: the Drezivo product pack ("Drezivo - Product and Architecture Pack"; its
source is not part of this bundle). The code shapes are summarised in
[references/patterns.md](references/patterns.md); read the real files in your own project when a
detail matters.

This skill sits on top of the user's standing rules (no double-submit, duplicate-safe
endpoints, fail closed, zod at the boundary, server-side authz, no secrets in logs, no
fire-and-forget, company-grade code). It never relaxes them.

## 0. Before touching code: pick the adoption path

Audit first (graph/grep): is there a `user` table with roles? any tenant/company table? how
many tables, and which have no FK path to a tenant root? how does auth work today?

| Path | When | Shape |
|---|---|---|
| **Greenfield** (Drezivo) | New product, no users yet | `tenant` = Clerk Organization (`clerk_org_id` unique), `membership(tenant_id, clerk_user_id, role, status, authz_version)`, `branch_membership(permission_codes)`. Onboarding creates the org + tenant + owner membership in one idempotent flow. |
| **Retrofit** | Live single-business app with its own users/RBAC | Keep the local `user` row as the authority. Add Clerk as a second **door**: `user.clerk_user_id` (partial unique), linked on first sign-in by verified email to a row an owner already created. Password login stays as the IT break-glass. Add `tenant` + `tenant_id` + RLS later as a phased migration. |

Never do both at once. A retrofit that also swaps the identity model and adds tenancy in
one release has no rollback point.

## 1. Identity boundary (one module talks to the provider)

- Exactly one file imports the Clerk SDK on each side (backend `auth/clerk.ts`, frontend
  `ClerkBoundary.tsx`). Everything else sees `{ ok, user } | { ok:false, code }`.
- Inert without keys: no `CLERK_SECRET_KEY` -> Clerk path disabled, app works as before.
- `authorizedParties` (allowed frontend origins) is mandatory. Empty -> Clerk disabled with a
  loud startup error (otherwise tokens minted for any site would be accepted).
- `@clerk/backend` v2 `verifyToken` returns `{ data } | { errors }` and does **not** throw:
  check `errors` explicitly. Declare the package you import (`@clerk/backend`), not a wrapper
  that happens to hoist it.
- One authenticator for REST **and** realtime handshakes, so both doors agree.
- Provider outage -> 503 `IDENTITY_UNAVAILABLE`, never a silent pass and never a 500.

## 2. Invitation-only membership

Nobody self-registers into a workspace. The owner (or onboarding) creates the intent; the
person proves the email.

- Link only a **verified primary email** from the provider, never a client-sent email.
- Link with a conditional UPDATE: `... WHERE lower(email)=lower($1) AND clerk_user_id IS NULL`
  (rowcount checked), audited. Second account with the same email -> `ACCOUNT_LINKED_ELSEWHERE`.
- Error vocabulary (generic, no enumeration beyond what the signed-in user already knows):
  `NOT_INVITED`, `EMAIL_NOT_VERIFIED`, `ACCOUNT_LINKED_ELSEWHERE`, `ACCOUNT_BLOCKED`,
  `ROLE_RETIRED`, `IDENTITY_UNAVAILABLE`.
- Invitation send is `ignoreExisting: true` (idempotent) and returns
  `sent | failed | not_configured` so the UI can tell the owner the truth. Resend is a
  separate guarded endpoint. Greenfield: store invitation intent (`membership_invitation`,
  email digest + ciphertext, business key) and dispatch via the outbox.
- Mandatory test: an attacker's Clerk account with an unverified or different email cannot
  take over an invited row. Mutation-check it (remove the guard, watch the test fail).

## 3. Roles = WHAT, scope = WHERE

- Role is a closed enum checked server-side per route (`requireRole`), never read from the
  token alone. Re-read current role/status from the DB (cache <= 15 s, keyed by user, and
  **dropped immediately** on role/scope/block change).
- Scope (branches/outlets) is a separate grant table. A selector header (`X-...-Branch-Id`)
  is validated (uuid) and membership-checked; other branches' grants never authorize.
- Page/feature permissions: server returns the allowed page list (`/me/permissions`);
  per-page merge `persisted ?? default(role, page)` so pages added later are not denied.
- Owners manage their own staff; the platform team is not a tenant member by default.

## 4. Modules (owner switches) and plan entitlements

- Code owns the catalog (`key -> pages`); the table stores only the owner's choice; no row =
  ON. Core pages are not in the catalog, so they cannot be switched off.
- Disabled pages are removed from `/me/permissions` for **every** role, owner included, and
  direct URLs redirect away. Switching off a module must also lift any gate it implies.
- PUT is an absolute-state upsert (`{enabled}`), so double clicks are no-ops by construction.
- Plan entitlements (seats, outlets, brands) are server-side rows (versioned plan), never
  browser copy. Enforce at the mutation that would exceed them.

## 5. Subscription access: derived, never scheduled

`accessOf(subscription, now)` is a pure function; no cron moves state, so a stopped worker
cannot leave a shop wrongly locked or unlocked.

```
now < end                      full       (last N days carry a renewal reminder)
operator extension > now       read_only  (dated, audited extension)
end <= now < end + 30 days     read_only  (reads + paying only)
end + 30 days <= now           locked     (only actor-context, billing reads, paying)
cancelled                      locked
```

- One gate, applied right after tenant context resolves, for every staff route, with an
  explicit `ALWAYS_ALLOWED` list (actor context, billing read, payment-method QR, submit
  payment, finalize proof upload). `read_only` allows `GET/HEAD/OPTIONS`. Errors: 403 with
  distinct codes `SUBSCRIPTION_READ_ONLY` / `SUBSCRIPTION_LOCKED`.
- Operational exception to decide per product: a kitchen/POS mid-service must not lose
  in-flight work at the instant of expiry. Prefer read_only (finish, no new) over locked,
  and show the countdown days before.

## 6. Pricing, codes, payments

- Prices live in versioned plan rows (money as integer minor units). A price change = new
  version; existing subscribers keep theirs. Annual = a separate plan row, not client math.
- Partner / promo codes: server-validated, single-use or capped, bound to a plan version;
  a "lifetime" rate is a locked `plan_version` on the subscription, honoured on renewal.
- Manual payment first (PH reality: GCash/Maya/bank QR): owner submits reference + receipt
  image (private storage); an operator verifies; approval starts the paid period. Verification
  is an immutable row with a business key (duplicate-safe). No card storage.

## 7. Operators and support

- Separate operator console + role; never a tenant member by default.
- Support access = `support_grant`: tenant-scoped, time-bound, reason-coded,
  permission-specific, revocable, every issue/use/deny/expiry audited. No impersonation.
- Retry/replay = a named, audited command on one durable job; never a blind replay.

## 8. Tenancy in the database (RLS backs the filter, it does not replace it)

Five rules (all must hold or RLS is a no-op):
1. Runtime role is **not** the table owner and has **no BYPASSRLS**.
2. `ENABLE` **and** `FORCE ROW LEVEL SECURITY` on every tenant-owned table.
3. Context only via `SELECT set_config('app.tenant_id', $1, true)` inside a transaction
   (transaction-local; poolers are transaction-scoped; parameterized, not string-built).
4. Policies fail closed: `tenant_id = (select current_setting('app.tenant_id', true))::uuid`
   in `USING` and `WITH CHECK`; unset context = zero rows.
5. Wrap `current_setting` in a sub-select so it is evaluated once per statement.

Plus: a narrow worker role with a second permissive policy only on queue tables; global
tables (webhook inbox, tenant root) get explicit grants instead; every unique constraint
becomes `(tenant_id, ...)`; document numbers are per tenant.

Test-harness trap: embedded/superuser test DBs (PGlite, `postgres` user) bypass RLS. Prove
isolation with a non-owner role in at least one test, or the green suite proves nothing.

Tenant URLs by path: `/t/<workspace-slug>/...`. The `/t/` prefix keeps tenant slugs out of
the app's own routes (`/login`, `/api`, `/operator`, ...), so no reserved-word list can go
stale. The slug resolves server-side to a tenant, then membership is checked; a slug the user
is not a member of returns a concealed 404. The slug is never authority on its own.

## 9. Webhooks and outbox

- Clerk webhooks: `verifyWebhook` (Svix) over the **raw** body; dedup on `svix-id` with an
  insert-only inbox (`ON CONFLICT DO NOTHING`, rowcount decides new vs retry); allowlisted
  event types (`z.enum`), unknown = reject; reconcile in the worker, not the HTTP handler.
- Anything that must survive a crash (invitation dispatch, org cleanup, emails) = outbox row
  in the same transaction, lease-claimed by a conditional UPDATE, bounded retries, terminal
  `succeeded` / `dead`.

## 10. Frontend

- Publishable key optional at build time; without it the bundle must not even download the
  Clerk SDK (lazy chunk). CSP gains the Clerk Frontend API host (decoded from `pk_`) and
  Cloudflare challenges only when a key is set.
- Token precedence: local break-glass token first, else `getToken()` from Clerk; logout ends
  both. Never store Clerk tokens yourself.
- Sign-in page: `SignUp` when the URL carries `__clerk_ticket` (invitation), else `SignIn`;
  a not-invited result shows a clear panel with "use a different account".
- Every mutating control follows the submit-guard rule (disabled + pending + ref guard,
  idempotency key once per intent).

## 11. Clerk dashboard settings (hand these to the user)

- Sign-in: Google + email code/link. Restrict sign-ups (invitation/allowlist only).
- MFA required for owners, admins, finance and support; offered to everyone.
- Sessions: 30 min inactive, 12 h max for staff (tune after real usage).
- Allowed redirect origins = the real frontend origins only.
- Production instance keys (`sk_live_`, `pk_live_`) in env only; `CLERK_JWT_KEY` (PEM) for
  networkless verification. Webhook signing secret per endpoint.

## Definition of done (per layer, tested, output quoted)

- [ ] Unknown / unverified / unlinked identity -> specific 401/403 code, no session.
- [ ] Takeover test (different or unverified email) fails when the guard is removed.
- [ ] Role/scope/block change takes effect within one request (cache dropped).
- [ ] Cross-tenant read returns zero rows / 404 **under a non-owner DB role**.
- [ ] Disabled module: absent from permissions for every role; direct URL redirects.
- [ ] Gate: read_only allows GET, blocks POST; locked allows only the always-allowed list.
- [ ] Every new mutating endpoint: sequential + concurrent double-fire -> one effect.
- [ ] Webhook replay (same `svix-id`) -> one inbox row, one effect.
- [ ] No secrets/tokens/PII in responses, logs, fixtures, or committed env files.
- [ ] Setup checklist for the human (keys, dashboard settings, deploy order) delivered.

## Deploy order (always)

Additive migrations first, code second: run the migrations that add columns/tables
**before** the new code starts, or login/permissions queries fail on a missing column.
Keep the provider off (no secret key) for one deploy, verify password login, then turn the
provider on with the frontend publishable key in the same window.
