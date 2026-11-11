# /saas code patterns

Condensed from a greenfield API and a retrofit adopter's backend. Open the
source file in your own project before copying; these are shapes, not drop-in code.

## 1. Who vs what (greenfield `middleware/auth.ts`, `middleware/tenant-context.ts`)

```ts
// auth.ts: "who". Mounted globally; does not reject (public routes exist).
export const clerkContext = clerkMiddleware();
export function requireStaffAuth(req, _res, next) {
  const auth = getAuth(req);
  if (!auth.userId) return next(new UnauthenticatedError('Sign-in required.')); // JSON 401, never redirect
  req.clerkPrincipal = { clerkUserId: auth.userId, clerkOrgId: auth.orgId ?? null };
  next();
}

// tenant-context.ts: "what/where". Fails closed at every step.
if (!clerkPrincipal?.clerkOrgId) throw new ForbiddenError('An active organization is required.');
const rawBranchId = req.header('X-Branch-Id')?.trim();
if (rawBranchId && !isUuid(rawBranchId)) throw new ValidationError('Branch selector is invalid.');
const result = await resolveActorContext({ principalId, clerkOrgId, branchId });
// kind: not_found -> 404 | forbidden -> 403 | state_conflict -> 409
req.tenantContext = { tenantId, membershipId, role, permissionCodes /* active branch only */, access };
assertSubscriptionAccess({ method, path, body }, context.access); // central gate, every staff route
```

Owner onboarding additionally requires a **verified primary email** (looked up behind the
adapter); provider failure -> `DependencyUnavailableError` (503).

## 2. Retrofit linking (retrofit adopter `src/modules/auth/authenticate.ts`)

```ts
// Local JWT first (session-revocation check + 15 s cache), then Clerk.
const clerkUserId = await verifyClerkSessionToken(token);      // null on bad token, never throws
let user = byClerkId(clerkUserId) ?? await linkByVerifiedEmail(clerkUserId);

// link: only an unlinked row the owner created, matched on the provider-verified email
UPDATE "user" SET clerk_user_id = $1
 WHERE lower(email) = lower($2) AND clerk_user_id IS NULL      -- rowcount 1 = linked
-- rowcount 0 + row exists with another clerk id -> ACCOUNT_LINKED_ELSEWHERE
-- no row                                         -> NOT_INVITED
audit('auth.clerk_linked')
```

Schema: `clerk_user_id text` + partial unique index `WHERE clerk_user_id IS NOT NULL` + index
on `lower(email)`. `toPublicUser` strips `clerk_user_id`, exposes `clerk_linked: boolean`.

## 3. Derived access (greenfield `modules/billing/access.ts`)

```ts
export function accessOf(sub, now): SubscriptionAccess {
  if (sub.status === 'cancelled') return locked('cancelled', sub.pending_payment);
  const trialing = sub.status === 'trialing';
  const end = trialing ? (sub.trial_ends_at ?? sub.current_period_end) : sub.current_period_end;
  if (now < end) return full(trialing ? 'trial' : 'paid', /* reminder if <= N days */);
  const ext = sub.grace_ends_at;                       // operator "read-only until" extension
  if (ext && ext > now && ext > end) return readOnly('trial_extension', ext);
  if (now < end + READ_ONLY_ACCESS_DAYS) return readOnly(trialing ? 'trial_ended' : 'payment_overdue');
  return locked(trialing ? 'trial_ended' : 'payment_overdue');
}
```

## 4. Central gate (greenfield `modules/billing/access-gate.ts`)

```ts
const ALWAYS_ALLOWED = [
  { method: 'GET',  path: /^\/api\/v1\/actor-context$/ },
  { method: 'GET',  path: /^\/api\/v1\/billing$/ },
  { method: 'GET',  path: /^\/api\/v1\/billing\/payment-methods\/<uuid>\/qr$/i },
  { method: 'POST', path: /^\/api\/v1\/billing\/payments$/ },
  { method: 'POST', path: /^\/api\/v1\/uploads\/<uuid>\/finalize$/i },
];
export function assertSubscriptionAccess(req, access) {
  if (access.level === 'full') return;
  if (ALWAYS_ALLOWED.some(r => r.method === req.method && r.path.test(req.path))) return;
  if (req.method === 'POST' && /^\/api\/v1\/uploads$/.test(req.path) && req.body?.purpose === 'subscription_payment_proof') return;
  if (access.level === 'read_only') {
    if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) return;
    throw new SubscriptionReadOnlyError();   // 403
  }
  throw new SubscriptionLockedError();       // 403
}
```

## 5. Tenant transaction (greenfield `db/client.ts`)

```ts
export async function withTenantTransaction(tenantId, principalId, work) {
  // BEGIN ...
  await client.query('SELECT set_config($1, $2, true)', ['app.tenant_id', tenantId]);
  await client.query('SELECT set_config($1, $2, true)', ['app.principal_id', principalId]);
  return work(client); // COMMIT / ROLLBACK
}
```

Variants: `withSystemTenantTransaction` (`app.actor_kind='system'`), `withGlobalTransaction`
(`app.tenant_id=''` for global tables), resolution transactions that set the tenant only after
it is found. Never a session-level `SET`.

## 6. RLS policy loop (greenfield `db/migrations/0008_rls_policies.sql`)

```sql
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['branch','membership', /* every tenant-owned table */] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY tenant_isolation ON %I
      USING (tenant_id = (select current_setting(''app.tenant_id'', true))::uuid)
      WITH CHECK (tenant_id = (select current_setting(''app.tenant_id'', true))::uuid)', t);
  END LOOP; END $$;
-- worker role: second permissive policy ONLY on outbox_event / notification_delivery
-- financial postings: REVOKE UPDATE, DELETE from the runtime role (immutable at the DB)
```

## 7. Clerk webhook inbox (greenfield `modules/webhooks/*`)

```ts
const event = await verifyWebhook(req, { signingSecret });  // '@clerk/express/webhooks', raw body
insertClerkWebhookInbox({
  providerEventId: req.get('svix-id'),                       // dedup key
  eventType: z.enum(['organization.created', 'organization_membership.created', /* ... */]),
  payloadDigest: sha256hex, safePayload,
});  // INSERT ... ON CONFLICT DO NOTHING; rowcount decides new vs retry; HTTP path never SELECTs
// reconciliation runs in the worker, idempotent via provider ids + local unique constraints
```

## 8. Durable job (greenfield `clerk_organization_cleanup_job`)

Columns: `status`, `lease_token uuid`, `lease_until`, `attempts`, `max_attempts (8)`,
`available_at`, `completed_at`, `safe_last_error`, unique per business key. Claim:
`UPDATE ... SET lease_token=$new, lease_until=now()+interval WHERE id=$1 AND (lease_until IS NULL OR lease_until < now()) AND status='pending'`.

## 9. Business modules (retrofit adopter `src/modules/business-modules/`)

```ts
// catalog.ts: code owns key -> pages; core pages are absent so they can never be disabled
export const BUSINESS_MODULES = [{ key: 'purchasing', label, description, pages: ['/purchasing', '/master-data'] }, ...];
// routes.ts: PUT /business-modules/:key  OWNER only, z.object({ enabled: z.boolean() }).strict()
db.insert(businessModules).values({ key, enabled, updatedBy }).onConflictDoUpdate({ target: key, set: { enabled, ... } });
// me/routes.ts: pages = allowedForRole - disabledPages(db), for every role incl. OWNER
```

## 10. Frontend boundary (retrofit adopter `frontend/src/auth/`)

```tsx
// ClerkAuthAdapter.tsx: SDK is a lazy chunk; password-only builds never download it
const ClerkBoundary = CLERK_PUBLISHABLE_KEY ? lazy(() => import('./ClerkBoundary')) : null;
export function AppAuthProvider({ children }) {
  if (!ClerkBoundary) return <AuthProvider>{children}</AuthProvider>;
  return <Suspense fallback={null}><ClerkBoundary>{children}</ClerkBoundary></Suspense>;
}
// lib/authToken.ts: currentBearerToken() = local break-glass token ?? await clerkGetToken()
// vite.config.ts: decode pk_ -> Frontend API host -> add to script-src/connect-src/frame-src
```
