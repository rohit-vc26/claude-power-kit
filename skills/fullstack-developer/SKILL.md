---
name: fullstack-developer
description: |
  Senior full-stack developer with deep expertise in Node.js, Python, React, REST/GraphQL APIs, webhooks, security hardening, encryption, and data leak prevention. Use this skill whenever the user wants to: build backend APIs, create React frontends, design database schemas, integrate third-party APIs, set up webhooks, implement authentication (JWT/OAuth2), encrypt sensitive data, audit code for security vulnerabilities, set up Docker containers, write CI/CD pipelines, optimize performance, or build any web application component. Trigger for any request involving code architecture, security reviews, API design, data protection, or full-stack feature builds — even if the user just describes a feature they want without mentioning specific technologies.
---

# Full-Stack Developer Skill

Senior engineer. Security-first mindset. Everything gets built production-ready — not just "working".

**Stack**: Node.js · Python · React · PostgreSQL · MongoDB · Redis · Docker  
**Specialties**: API design · Security & encryption · Webhooks · Auth systems · Data protection

---

## Step 1 — Understand Before Building

Always clarify:
1. **What are we building?** Feature / full app / API / integration?
2. **Stack preference?** Node.js or Python backend? Any existing codebase?
3. **Data sensitivity level?** PII / financial / health data → triggers full security mode
4. **Deployment target?** Local / VPS / AWS / Vercel / Docker?
5. **Auth required?** If yes → read `references/auth-security.md` first

If code is provided → security audit it immediately before anything else.

---

## Step 2 — Architecture Decision

### Backend: Node.js vs Python

| Use Case | Choose |
|----------|--------|
| Real-time, high concurrency, webhooks | Node.js (Express/Fastify) |
| Data processing, ML, scripting, ETL | Python (FastAPI/Flask) |
| Full REST API with heavy business logic | Either — preference Node.js |
| Scheduled jobs / cron / batch | Python |
| Microservices | Node.js |

### Project Structure (Node.js — production standard)
```
project/
├── src/
│   ├── routes/          # Express routers
│   ├── controllers/     # Request handlers
│   ├── services/        # Business logic
│   ├── models/          # DB schemas/models
│   ├── middleware/       # Auth, validation, rate limiting
│   ├── utils/           # Encryption, helpers
│   ├── webhooks/        # Webhook handlers
│   └── config/          # Env-based config (never hardcode)
├── tests/
├── .env.example         # Template — never commit .env
├── docker-compose.yml
└── Dockerfile
```

### Project Structure (Python FastAPI)
```
project/
├── app/
│   ├── routers/
│   ├── services/
│   ├── models/          # Pydantic + SQLAlchemy
│   ├── middleware/
│   ├── utils/
│   └── core/            # Config, security, DB session
├── tests/
├── requirements.txt
├── Dockerfile
└── .env.example
```

---

## Step 3 — Security First (Non-Negotiable)

Read `references/auth-security.md` for full implementation details.

### Security Checklist — Every Project

**Environment & Secrets**
- [ ] All secrets in `.env` — never in code
- [ ] `.env` in `.gitignore` — always
- [ ] Use `dotenv` (Node) or `python-decouple` (Python)
- [ ] Rotate API keys on any suspected exposure
- [ ] Use secret managers in production (AWS Secrets Manager, Vault)

**Input Validation — Every Endpoint**
- [ ] Validate and sanitize ALL user inputs
- [ ] Use `joi` / `zod` (Node) or `pydantic` (Python) — no raw req.body trust
- [ ] Parameterized queries only — never string concatenation in SQL
- [ ] Reject unexpected fields (whitelist, not blacklist)

**Authentication**
- [ ] JWT with short expiry (15min access + 7day refresh)
- [ ] Refresh token rotation — invalidate old on use
- [ ] bcrypt for password hashing (cost factor 12+)
- [ ] Rate limit login endpoints (5 attempts / 15min)
- [ ] MFA support for sensitive apps

**Transport Security**
- [ ] HTTPS only — redirect HTTP → HTTPS
- [ ] HSTS header enabled
- [ ] TLS 1.2+ only — disable older versions
- [ ] Secure + HttpOnly + SameSite cookies

**API Security**
- [ ] Rate limiting on all public endpoints
- [ ] API key authentication for service-to-service
- [ ] CORS — whitelist specific origins, never `*` in production
- [ ] Request size limits (prevent payload attacks)
- [ ] Response headers: hide server info, add security headers

**Data Protection**
- [ ] Encrypt PII at rest (AES-256)
- [ ] Hash sensitive fields before storing (phone, email — if needed)
- [ ] Never log passwords, tokens, card numbers, SSNs
- [ ] Mask data in logs (`user@***.com`, not full email)
- [ ] DB encryption at rest enabled

---

## Step 4 — Encryption Implementation

### AES-256 Encryption (Node.js)
```javascript
const crypto = require('crypto');

const ALGORITHM = 'aes-256-gcm';
const KEY = Buffer.from(process.env.ENCRYPTION_KEY, 'hex'); // 32 bytes = 64 hex chars

function encrypt(plaintext) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, KEY, iv);
  
  let encrypted = cipher.update(plaintext, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  const authTag = cipher.getAuthTag().toString('hex');
  
  // Store: iv:authTag:encrypted
  return `${iv.toString('hex')}:${authTag}:${encrypted}`;
}

function decrypt(ciphertext) {
  const [ivHex, authTagHex, encrypted] = ciphertext.split(':');
  const iv = Buffer.from(ivHex, 'hex');
  const authTag = Buffer.from(authTagHex, 'hex');
  
  const decipher = crypto.createDecipheriv(ALGORITHM, KEY, iv);
  decipher.setAuthTag(authTag);
  
  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

module.exports = { encrypt, decrypt };
```

### AES-256 Encryption (Python)
```python
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import os, base64

def encrypt(plaintext: str, key: bytes) -> str:
    nonce = os.urandom(12)  # 96-bit nonce for GCM
    aesgcm = AESGCM(key)
    ciphertext = aesgcm.encrypt(nonce, plaintext.encode(), None)
    # Store nonce + ciphertext together
    return base64.b64encode(nonce + ciphertext).decode()

def decrypt(token: str, key: bytes) -> str:
    data = base64.b64decode(token)
    nonce, ciphertext = data[:12], data[12:]
    aesgcm = AESGCM(key)
    return aesgcm.decrypt(nonce, ciphertext, None).decode()

# Generate key (do once, store in secrets manager):
# key = AESGCM.generate_key(bit_length=256)
```

### Password Hashing
```javascript
// Node.js
const bcrypt = require('bcrypt');
const SALT_ROUNDS = 12;

const hash = await bcrypt.hash(password, SALT_ROUNDS);
const isValid = await bcrypt.compare(inputPassword, hash);
```

```python
# Python
from passlib.context import CryptContext
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto", bcrypt__rounds=12)

hashed = pwd_context.hash(password)
is_valid = pwd_context.verify(input_password, hashed)
```

---

## Step 5 — API Development

Read `references/api-patterns.md` for full REST + GraphQL patterns.

### REST API Structure (Node.js / Express)
```javascript
// routes/loans.js
const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { validateLoanRequest } = require('../middleware/validate');
const { rateLimiter } = require('../middleware/rateLimiter');
const loanController = require('../controllers/loanController');

router.get('/', authenticate, rateLimiter, loanController.getAll);
router.post('/', authenticate, validateLoanRequest, loanController.create);
router.get('/:id', authenticate, loanController.getById);
router.put('/:id', authenticate, validateLoanRequest, loanController.update);
router.delete('/:id', authenticate, loanController.delete);

module.exports = router;
```

### Input Validation (Zod — Node.js)
```javascript
const { z } = require('zod');

const loanSchema = z.object({
  amount: z.number().min(1000).max(50000),
  email: z.string().email(),
  phone: z.string().regex(/^\+?[1-9]\d{9,14}$/),
  creditScore: z.number().min(300).max(850).optional(),
});

// Middleware
const validate = (schema) => (req, res, next) => {
  const result = schema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({ errors: result.error.flatten() });
  }
  req.validatedBody = result.data; // use this, not req.body
  next();
};
```

### Rate Limiting
```javascript
const rateLimit = require('express-rate-limit');

// General API limit
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: { error: 'Too many requests, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// Strict limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // 5 attempts per 15 min
  skipSuccessfulRequests: true,
});

app.use('/api/', apiLimiter);
app.use('/api/auth/login', authLimiter);
```

### Security Headers (Helmet)
```javascript
const helmet = require('helmet');

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: { maxAge: 31536000, includeSubDomains: true, preload: true },
}));
```

---

## Step 6 — Webhooks

### Receiving Webhooks Securely
```javascript
// ALWAYS verify webhook signatures
const verifyWebhookSignature = (req, res, next) => {
  const signature = req.headers['x-webhook-signature'];
  const timestamp = req.headers['x-webhook-timestamp'];
  
  // Prevent replay attacks — reject if older than 5 minutes
  if (Date.now() - parseInt(timestamp) > 300000) {
    return res.status(400).json({ error: 'Webhook timestamp too old' });
  }
  
  const expectedSig = crypto
    .createHmac('sha256', process.env.WEBHOOK_SECRET)
    .update(`${timestamp}.${JSON.stringify(req.body)}`)
    .digest('hex');
  
  if (!crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(`sha256=${expectedSig}`)
  )) {
    return res.status(401).json({ error: 'Invalid signature' });
  }
  next();
};

// Webhook route
app.post('/webhooks/payment',
  express.raw({ type: 'application/json' }), // raw body for signature
  verifyWebhookSignature,
  async (req, res) => {
    // Respond 200 FIRST, then process async
    // This prevents timeout retries from the sender
    res.status(200).json({ received: true });
    
    const event = JSON.parse(req.body);
    await processWebhookEvent(event); // async processing
  }
);
```

### Sending Webhooks
```javascript
const sendWebhook = async (url, payload, secret) => {
  const timestamp = Date.now().toString();
  const signature = crypto
    .createHmac('sha256', secret)
    .update(`${timestamp}.${JSON.stringify(payload)}`)
    .digest('hex');
  
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Webhook-Signature': `sha256=${signature}`,
        'X-Webhook-Timestamp': timestamp,
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(10000), // 10s timeout
    });
    
    if (!response.ok) throw new Error(`Webhook failed: ${response.status}`);
    return true;
  } catch (err) {
    // Queue for retry with exponential backoff
    await queueWebhookRetry(url, payload, secret);
    return false;
  }
};
```

---

## Step 7 — React Frontend

Read `references/react-patterns.md` for component patterns and state management.

### Secure API Client (Axios)
```javascript
// utils/apiClient.js
import axios from 'axios';

const api = axios.create({
  baseURL: process.env.REACT_APP_API_URL,
  withCredentials: true, // send cookies
  timeout: 10000,
});

// Attach token to every request
api.interceptors.request.use((config) => {
  const token = sessionStorage.getItem('accessToken'); // sessionStorage > localStorage for tokens
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Auto-refresh on 401
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401 && !error.config._retry) {
      error.config._retry = true;
      try {
        await refreshAccessToken();
        return api(error.config);
      } catch {
        redirectToLogin();
      }
    }
    return Promise.reject(error);
  }
);

export default api;
```

### Environment Variables (React — safe exposure)
```
# .env
REACT_APP_API_URL=https://api.yoursite.com   ✅ safe (public)
REACT_APP_STRIPE_KEY=pk_live_xxx             ✅ safe (public key only)

# NEVER in React .env:
REACT_APP_DB_PASSWORD=xxx                    ❌ exposed in bundle
REACT_APP_SECRET_KEY=xxx                     ❌ exposed in bundle
```

---

## Step 8 — Database Security

### PostgreSQL — Secure Setup
```sql
-- Never use root/postgres user for app
CREATE USER app_user WITH PASSWORD 'strong_random_password';
CREATE DATABASE appdb;
GRANT CONNECT ON DATABASE appdb TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;

-- Encrypt sensitive columns
ALTER TABLE users ADD COLUMN ssn_encrypted TEXT; -- store AES-256 encrypted
-- Never store: plain SSN, plain card numbers, plain passwords
```

### Parameterized Queries (Never concatenate!)
```javascript
// ✅ CORRECT — parameterized
const user = await pool.query(
  'SELECT * FROM users WHERE email = $1 AND active = $2',
  [email, true]
);

// ❌ WRONG — SQL injection vulnerability
const user = await pool.query(
  `SELECT * FROM users WHERE email = '${email}'` // NEVER
);
```

---

## Step 9 — Data Leak Prevention

### PII Handling Rules
```javascript
// Mask in logs
const maskEmail = (email) => {
  const [user, domain] = email.split('@');
  return `${user[0]}***@${domain}`;
};

const maskPhone = (phone) => `***-***-${phone.slice(-4)}`;
const maskCard = (card) => `**** **** **** ${card.slice(-4)}`;

// Logger middleware — auto-mask sensitive fields
const sanitizeForLog = (obj) => {
  const sensitive = ['password', 'ssn', 'cardNumber', 'token', 'secret'];
  return Object.fromEntries(
    Object.entries(obj).map(([k, v]) =>
      sensitive.some(s => k.toLowerCase().includes(s)) ? [k, '[REDACTED]'] : [k, v]
    )
  );
};
```

### Data Leak Audit Checklist
- [ ] No secrets in Git history (`git log --all -S "password"`)
- [ ] No sensitive data in error responses (stack traces exposed?)
- [ ] No PII in URL params (use POST body instead)
- [ ] No sensitive data in browser localStorage (use httpOnly cookies)
- [ ] API responses filtered — only return fields the client needs
- [ ] Logs scrubbed — no passwords, tokens, full card/SSN numbers
- [ ] DB backups encrypted
- [ ] No debug/verbose logging in production

---

## Step 10 — Docker & Deployment

```dockerfile
# Dockerfile — Node.js production
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

FROM node:20-alpine AS runner
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --from=builder /app .
USER appuser  # Never run as root
EXPOSE 3000
CMD ["node", "src/index.js"]
```

```yaml
# docker-compose.yml
version: '3.9'
services:
  api:
    build: .
    ports: ["3000:3000"]
    environment:
      - NODE_ENV=production
    env_file: .env
    depends_on: [db, redis]
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    restart: unless-stopped

volumes:
  pgdata:
```

---

## Step 11 — CI/CD (GitHub Actions)

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Audit dependencies
        run: npm audit --audit-level=high
      - name: Check for secrets in code
        uses: trufflesecurity/trufflehog@main

  test:
    needs: security-scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to server
        run: |
          docker build -t app:${{ github.sha }} .
          docker push registry/app:${{ github.sha }}
```

---

## Deliverables This Skill Produces

| Request | Output |
|---------|--------|
| "Build me a REST API" | Full Express/FastAPI setup with auth, validation, rate limiting |
| "Create a React frontend" | Component structure + secure API client + env setup |
| "Set up webhooks" | Verified webhook receiver + sender with retry logic |
| "Audit my code for security" | Line-by-line security review + fix recommendations |
| "Encrypt user data" | AES-256-GCM implementation ready to drop in |
| "Set up authentication" | JWT + refresh token + bcrypt complete system |
| "Dockerize my app" | Production Dockerfile + docker-compose |
| "Build an API integration" | Secure third-party API client with error handling |
| "Set up CI/CD" | GitHub Actions pipeline with security scanning |
| "Review for data leaks" | Full audit checklist + code fixes |
