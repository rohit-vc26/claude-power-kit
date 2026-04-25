# Auth & Security — Deep Implementation Reference

## JWT Authentication — Complete System

### Token Structure
```
Access Token:  15 min expiry  — stored in memory or sessionStorage
Refresh Token: 7 day expiry   — stored in httpOnly cookie ONLY
```

### Node.js Implementation
```javascript
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

// Generate tokens
const generateTokens = (userId, role) => {
  const accessToken = jwt.sign(
    { userId, role, type: 'access' },
    process.env.JWT_ACCESS_SECRET,
    { expiresIn: '15m', issuer: 'yourapp', audience: 'yourapp-client' }
  );

  const refreshToken = jwt.sign(
    { userId, tokenId: crypto.randomUUID(), type: 'refresh' },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: '7d', issuer: 'yourapp', audience: 'yourapp-client' }
  );

  return { accessToken, refreshToken };
};

// Auth middleware
const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const token = authHeader.slice(7);
    const payload = jwt.verify(token, process.env.JWT_ACCESS_SECRET, {
      issuer: 'yourapp',
      audience: 'yourapp-client',
    });

    if (payload.type !== 'access') {
      return res.status(401).json({ error: 'Invalid token type' });
    }

    req.user = payload;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired', code: 'TOKEN_EXPIRED' });
    }
    return res.status(401).json({ error: 'Invalid token' });
  }
};

// Refresh token endpoint
const refreshTokens = async (req, res) => {
  const refreshToken = req.cookies.refreshToken;
  if (!refreshToken) return res.status(401).json({ error: 'No refresh token' });

  try {
    const payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);

    // Check token hasn't been revoked (store in Redis/DB)
    const isRevoked = await redis.get(`revoked:${payload.tokenId}`);
    if (isRevoked) return res.status(401).json({ error: 'Token revoked' });

    // Revoke old refresh token (rotation)
    await redis.setex(`revoked:${payload.tokenId}`, 604800, '1');

    const { accessToken, refreshToken: newRefreshToken } = generateTokens(payload.userId, payload.role);

    res.cookie('refreshToken', newRefreshToken, {
      httpOnly: true,
      secure: true,
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });

    res.json({ accessToken });
  } catch {
    res.status(401).json({ error: 'Invalid refresh token' });
  }
};
```

---

## OAuth2 Integration

```javascript
// passport.js config
const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;

passport.use(new GoogleStrategy({
  clientID: process.env.GOOGLE_CLIENT_ID,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET,
  callbackURL: `${process.env.APP_URL}/auth/google/callback`,
}, async (accessToken, refreshToken, profile, done) => {
  try {
    let user = await User.findOne({ googleId: profile.id });
    if (!user) {
      user = await User.create({
        googleId: profile.id,
        email: profile.emails[0].value,
        name: profile.displayName,
      });
    }
    done(null, user);
  } catch (err) {
    done(err);
  }
}));

// Routes
app.get('/auth/google', passport.authenticate('google', { scope: ['profile', 'email'] }));
app.get('/auth/google/callback',
  passport.authenticate('google', { session: false }),
  (req, res) => {
    const { accessToken, refreshToken } = generateTokens(req.user.id, req.user.role);
    res.cookie('refreshToken', refreshToken, { httpOnly: true, secure: true, sameSite: 'strict' });
    res.redirect(`${process.env.FRONTEND_URL}/auth/callback?token=${accessToken}`);
  }
);
```

---

## RBAC (Role-Based Access Control)

```javascript
const ROLES = {
  ADMIN: 'admin',
  USER: 'user',
  VIEWER: 'viewer',
};

const PERMISSIONS = {
  admin: ['read', 'write', 'delete', 'manage_users'],
  user: ['read', 'write'],
  viewer: ['read'],
};

const authorize = (...requiredPermissions) => (req, res, next) => {
  const userPermissions = PERMISSIONS[req.user.role] || [];
  const hasPermission = requiredPermissions.every(p => userPermissions.includes(p));

  if (!hasPermission) {
    return res.status(403).json({ error: 'Insufficient permissions' });
  }
  next();
};

// Usage
router.delete('/users/:id', authenticate, authorize('delete', 'manage_users'), deleteUser);
```

---

## SQL Injection Prevention

```javascript
// ✅ Always use parameterized queries (pg)
const getUser = async (email) => {
  const { rows } = await pool.query(
    'SELECT id, name, email FROM users WHERE email = $1',
    [email]
  );
  return rows[0];
};

// ✅ ORM (Sequelize/Prisma) — also safe
const user = await prisma.user.findUnique({ where: { email } });

// ❌ NEVER do this
const getUser = async (email) => {
  // SQL INJECTION VULNERABILITY
  return pool.query(`SELECT * FROM users WHERE email = '${email}'`);
};
```

---

## XSS Prevention

```javascript
// React — safe by default (JSX escapes)
const UserName = ({ name }) => <div>{name}</div>; // ✅ safe

// Dangerous — only use if you trust the content 100%
<div dangerouslySetInnerHTML={{ __html: userContent }} /> // ❌ avoid

// Sanitize if HTML input is required
const DOMPurify = require('dompurify');
const clean = DOMPurify.sanitize(dirtyHTML);
```

---

## CSRF Protection

```javascript
const csurf = require('csurf');
const csrfProtection = csurf({ cookie: { httpOnly: true, secure: true } });

app.use(csrfProtection);

// Send token to frontend
app.get('/csrf-token', (req, res) => {
  res.json({ csrfToken: req.csrfToken() });
});

// Frontend — attach to every mutating request header
axios.defaults.headers.common['X-CSRF-Token'] = csrfToken;
```

---

## Secrets Management

### Local Development (.env)
```bash
# Generate encryption key
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# .env.example (commit this)
DB_URL=postgresql://user:password@localhost:5432/dbname
JWT_ACCESS_SECRET=your_secret_here
ENCRYPTION_KEY=32_byte_hex_key_here
WEBHOOK_SECRET=your_webhook_secret
```

### Production (AWS Secrets Manager)
```javascript
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

const client = new SecretsManagerClient({ region: 'us-east-1' });

const getSecret = async (secretName) => {
  const command = new GetSecretValueCommand({ SecretId: secretName });
  const response = await client.send(command);
  return JSON.parse(response.SecretString);
};

// At startup
const secrets = await getSecret('prod/myapp/db');
process.env.DB_PASSWORD = secrets.DB_PASSWORD;
```

---

## Security Headers Reference

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

---

## Common Vulnerabilities — Quick Reference

| Vulnerability | Risk | Fix |
|---------------|------|-----|
| SQL Injection | Critical | Parameterized queries always |
| XSS | High | Sanitize output, CSP headers |
| CSRF | High | CSRF tokens + SameSite cookies |
| Broken Auth | Critical | JWT + refresh rotation + rate limit |
| Sensitive Data Exposure | Critical | Encrypt at rest, HTTPS, mask logs |
| Security Misconfiguration | High | Helmet, disable debug in prod |
| Insecure Deserialization | High | Validate + sanitize all JSON input |
| Hardcoded Secrets | Critical | .env + secrets manager always |
| Missing Rate Limiting | Medium | express-rate-limit on all endpoints |
| Verbose Error Messages | Medium | Generic errors in prod, detailed in logs only |
