# Secret & Credential Pattern Reference

This file contains regex patterns and heuristics for detecting exposed secrets.
Load this file when performing deep credential scanning.

---

## API Key Patterns (CRITICAL)

| Service | Pattern | Example prefix |
|---|---|---|
| Anthropic | `sk-ant-[a-zA-Z0-9\-]{40,}` | `sk-ant-api03-...` |
| OpenAI | `sk-[a-zA-Z0-9]{48}` | `sk-abc123...` |
| Google/Firebase | `AIza[0-9A-Za-z\-_]{35}` | `AIzaSy...` |
| AWS Access Key | `AKIA[0-9A-Z]{16}` | `AKIAIOSFODNN7...` |
| AWS Secret | `[0-9a-zA-Z/+]{40}` (near "aws_secret") | — |
| Fal.ai | `fal_[a-zA-Z0-9\-_]{30,}` | `fal_...` |
| Supabase anon | `eyJ[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+` | JWT format |
| Supabase service | Same as above but labeled `service_role` | — |
| Stripe | `sk_live_[a-zA-Z0-9]{24,}` or `sk_test_...` | — |
| GitHub token | `ghp_[a-zA-Z0-9]{36}` | — |
| Ayrshare | Check for `apiKey` or `Authorization` header values in server code | — |
| QStash | `qstash_[a-zA-Z0-9\-_]{30,}` or env `QSTASH_TOKEN` | — |

---

## Connection String Patterns (CRITICAL)

```
postgresql://[user]:[password]@[host]:[port]/[db]
mysql://[user]:[password]@[host]/[db]
mongodb+srv://[user]:[password]@[cluster]/[db]
redis://:[password]@[host]:[port]
```

Flag any connection string where a literal password appears (not `${process.env.X}`).

---

## Private Key Blocks (CRITICAL)

```
-----BEGIN RSA PRIVATE KEY-----
-----BEGIN PRIVATE KEY-----
-----BEGIN EC PRIVATE KEY-----
-----BEGIN OPENSSH PRIVATE KEY-----
-----BEGIN PGP PRIVATE KEY BLOCK-----
```

---

## Dangerous Environment Variable Names (HIGH when in client code)

Flag if these appear in:
- React components (client-side)
- HTML/JS artifacts served to browser
- `console.log()` output
- URL parameters

```
*_SECRET*
*_KEY*
*_TOKEN*
*_PASSWORD*
*_PRIVATE*
*_AUTH*
*_CREDENTIAL*
DATABASE_URL
REDIS_URL
SMTP_PASSWORD
WEBHOOK_SECRET
SIGNING_KEY
ENCRYPTION_KEY
```

---

## Safe Patterns (Do NOT flag these)

```javascript
// These are safe — secrets loaded from environment
process.env.SUPABASE_SERVICE_KEY
process.env.FAL_API_KEY
os.environ.get("SECRET_KEY")
import.meta.env.VITE_SUPABASE_ANON_KEY  // OK only if Supabase RLS is enabled
```

Flag only when the actual secret VALUE is present, not the reference.

---

## Contextual Rules

### Frontend vs Backend Context

| Location | Rule |
|---|---|
| `app/` or `pages/` (Next.js client) | No secrets at all — only `NEXT_PUBLIC_` vars allowed, and only non-sensitive ones |
| `app/api/` or server components | `process.env` references OK |
| Cloud Run worker files | `process.env` references OK |
| SKILL.md files | Zero secrets — reference env var names only |
| Artifacts / HTML output | Zero secrets — must use server proxy pattern |

### Supabase RLS Check

When Supabase anon key appears in frontend code, verify:
1. Is RLS enabled on ALL tables the frontend queries?
2. Are RLS policies defined for SELECT, INSERT, UPDATE, DELETE separately?
3. Is the service role key absent from frontend?

If any of these fail → escalate anon key finding from LOW to HIGH.
