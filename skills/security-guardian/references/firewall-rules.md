# Firewall & Network Security Reference

Load this file when auditing CORS policies, webhook configs, API route security, or network architecture.

---

## CORS Policy Rules

### CRITICAL — Never allow in production
```
Access-Control-Allow-Origin: *
```
Combined with:
```
Access-Control-Allow-Credentials: true
```
This combination allows any website to make credentialed cross-origin requests. Always a CRITICAL finding.

### Safe CORS Pattern
```javascript
const allowedOrigins = [
  'https://royalishveda.com',
  'https://www.royalishveda.com',
  // Add staging if needed:
  'https://staging.royalishveda.com'
];

const corsOptions = {
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
};
```

---

## Webhook Security Rules

### QStash Webhook Validation (REQUIRED)
Every route receiving QStash webhooks must verify the signature:

```typescript
import { verifySignatureAppRouter } from "@upstash/qstash/nextjs";

export const POST = verifySignatureAppRouter(async (req: Request) => {
  // Your handler here — only runs if signature is valid
});
```

Flag if:
- A POST route accepts QStash payloads without `verifySignatureAppRouter` or equivalent
- `QSTASH_CURRENT_SIGNING_KEY` or `QSTASH_NEXT_SIGNING_KEY` are not set in env

### Fal.ai Webhook Validation
Fal.ai sends a `X-Fal-Signature` header. Verify it:

```typescript
import crypto from 'crypto';

function verifyFalSignature(payload: string, signature: string, secret: string): boolean {
  const expected = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(`sha256=${expected}`)
  );
}
```

Flag if Fal.ai webhook routes don't implement this check.

---

## Rate Limiting Rules

All public-facing API routes must have rate limiting. Flag missing rate limits on:
- `/api/` routes accessible without auth
- Webhook endpoints (to prevent replay/flood attacks)
- Any route that triggers AI model calls (cost protection)

### Recommended: Upstash Rate Limiting
```typescript
import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, "10 s"), // 10 req/10s
});
```

---

## Authentication & Authorization Rules

| Route Type | Required Auth |
|---|---|
| Public content (GET) | None OK |
| User-specific data | JWT/session verification |
| Admin operations | Admin role check + JWT |
| Webhook receivers | Signature verification |
| Internal Cloud Run routes | Service account or VPC |

Flag any route performing write operations (POST/PUT/PATCH/DELETE) without auth middleware.

---

## HTTP vs HTTPS

Always flag:
- `http://` URLs in any production config
- Mixed content (HTTPS page loading HTTP resources)
- Cookies set without `Secure` flag
- Cookies set without `HttpOnly` flag (for session/auth cookies)

Safe cookie pattern:
```typescript
res.cookie('session', token, {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'strict',
  maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
});
```

---

## Cloud Run / Serverless Security

For RoyalishVeda's Google Cloud Run workers:

- Workers should NOT be publicly accessible without auth (use Cloud Run invoker IAM role)
- Internal worker-to-worker calls should use service account tokens, not hardcoded keys
- Environment variables must be set via Google Secret Manager or Cloud Run env config — never baked into Docker images
- Flag if `Dockerfile` contains `ENV SECRET_KEY=...` with actual values

---

## Next.js Specific Rules

| Rule | Check |
|---|---|
| No secrets in `NEXT_PUBLIC_` vars | Only non-sensitive config allowed |
| Server components for sensitive ops | DB queries, API calls with keys → server only |
| API routes protected | All `/api/` routes check auth where needed |
| No sensitive data in `getStaticProps` | Static generation should not fetch sensitive user data |
| `dangerouslySetInnerHTML` audit | Every use must sanitize input with DOMPurify or similar |
