# API Patterns & React Patterns

## REST API Design Standards

### Endpoint Naming
```
GET    /api/v1/users          → list users
GET    /api/v1/users/:id      → get one user
POST   /api/v1/users          → create user
PUT    /api/v1/users/:id      → replace user
PATCH  /api/v1/users/:id      → partial update
DELETE /api/v1/users/:id      → delete user

Nested resources:
GET    /api/v1/users/:id/loans → user's loans
POST   /api/v1/users/:id/loans → create loan for user
```

### Standard Response Format
```javascript
// Success
{
  "success": true,
  "data": { ... },
  "meta": { "page": 1, "total": 100, "perPage": 20 }
}

// Error
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is required",
    "details": [{ "field": "email", "message": "Required" }]
  }
}
```

### Error Handler (Express)
```javascript
// middleware/errorHandler.js
const errorHandler = (err, req, res, next) => {
  // Log full error internally
  console.error({
    error: err.message,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
    url: req.url,
    method: req.method,
    userId: req.user?.userId,
  });

  // Never expose stack traces in production
  const statusCode = err.statusCode || 500;
  const message = process.env.NODE_ENV === 'production' && statusCode === 500
    ? 'An internal error occurred'
    : err.message;

  res.status(statusCode).json({
    success: false,
    error: {
      code: err.code || 'INTERNAL_ERROR',
      message,
    },
  });
};
```

---

## Third-Party API Integration Pattern

```javascript
// services/stripeService.js
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

class StripeService {
  async createPaymentIntent(amount, currency = 'usd', metadata = {}) {
    try {
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100), // Stripe uses cents
        currency,
        metadata,
        automatic_payment_methods: { enabled: true },
      });
      return { success: true, clientSecret: paymentIntent.client_secret };
    } catch (err) {
      if (err.type === 'StripeCardError') {
        return { success: false, error: err.message };
      }
      throw err; // Re-throw unexpected errors
    }
  }
}

module.exports = new StripeService();
```

### Retry Logic for External APIs
```javascript
const fetchWithRetry = async (url, options, maxRetries = 3) => {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      const response = await fetch(url, {
        ...options,
        signal: AbortSignal.timeout(10000),
      });

      if (!response.ok && response.status >= 500 && attempt < maxRetries) {
        const delay = Math.pow(2, attempt) * 1000; // exponential backoff
        await new Promise(r => setTimeout(r, delay));
        continue;
      }

      return response;
    } catch (err) {
      if (attempt === maxRetries) throw err;
      const delay = Math.pow(2, attempt) * 1000;
      await new Promise(r => setTimeout(r, delay));
    }
  }
};
```

---

## React Component Patterns

### Protected Route
```jsx
// components/ProtectedRoute.jsx
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

const ProtectedRoute = ({ children, requiredRole }) => {
  const { user, isLoading } = useAuth();
  const location = useLocation();

  if (isLoading) return <LoadingSpinner />;

  if (!user) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (requiredRole && user.role !== requiredRole) {
    return <Navigate to="/unauthorized" replace />;
  }

  return children;
};

// Usage
<Route path="/admin" element={
  <ProtectedRoute requiredRole="admin">
    <AdminDashboard />
  </ProtectedRoute>
} />
```

### Custom API Hook
```jsx
// hooks/useApi.js
import { useState, useCallback } from 'react';
import api from '../utils/apiClient';

export const useApi = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const request = useCallback(async (method, url, data = null) => {
    setLoading(true);
    setError(null);
    try {
      const response = await api[method](url, data);
      return response.data;
    } catch (err) {
      const message = err.response?.data?.error?.message || 'Something went wrong';
      setError(message);
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  return { loading, error, request };
};
```

### Form with Validation
```jsx
// Using React Hook Form + Zod
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const schema = z.object({
  email: z.string().email('Invalid email'),
  amount: z.number().min(1000, 'Minimum $1,000').max(50000, 'Maximum $50,000'),
  phone: z.string().regex(/^\d{10}$/, 'Enter 10-digit phone number'),
});

const LoanForm = () => {
  const { register, handleSubmit, formState: { errors } } = useForm({
    resolver: zodResolver(schema),
  });

  const onSubmit = async (data) => {
    // data is validated and typed
    await submitLoanApplication(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} type="email" />
      {errors.email && <span>{errors.email.message}</span>}
      <button type="submit">Apply Now</button>
    </form>
  );
};
```

---

## Redis Usage Patterns

```javascript
const redis = require('redis');
const client = redis.createClient({
  url: process.env.REDIS_URL,
  password: process.env.REDIS_PASSWORD,
});

// Cache API response
const getCachedOrFetch = async (key, fetchFn, ttlSeconds = 300) => {
  const cached = await client.get(key);
  if (cached) return JSON.parse(cached);

  const data = await fetchFn();
  await client.setEx(key, ttlSeconds, JSON.stringify(data));
  return data;
};

// Session store
const setSession = async (sessionId, data) => {
  await client.setEx(`session:${sessionId}`, 3600, JSON.stringify(data));
};

// Rate limiting with Redis (sliding window)
const checkRateLimit = async (key, limit, windowMs) => {
  const now = Date.now();
  const windowStart = now - windowMs;

  await client.zRemRangeByScore(key, 0, windowStart);
  const count = await client.zCard(key);

  if (count >= limit) return { allowed: false, count };

  await client.zAdd(key, { score: now, value: now.toString() });
  await client.expire(key, Math.ceil(windowMs / 1000));
  return { allowed: true, count: count + 1 };
};
```

---

## Performance Optimization Checklist

**Backend**
- [ ] Database indexes on all columns used in WHERE clauses
- [ ] N+1 query detection — use query logging in dev
- [ ] Redis caching for repeated reads (user data, config, rates)
- [ ] Connection pooling (pg-pool, mongoose poolSize)
- [ ] Pagination on all list endpoints (never return unbounded results)
- [ ] Async/await everywhere — no blocking operations
- [ ] Compression middleware (gzip)

**Frontend**
- [ ] Code splitting — lazy load routes
- [ ] Memoize expensive components (React.memo, useMemo, useCallback)
- [ ] Images: WebP format, lazy loading, proper dimensions
- [ ] Bundle analysis (webpack-bundle-analyzer)
- [ ] Debounce search/filter inputs
- [ ] Virtual scrolling for long lists (react-virtualized)

**API**
- [ ] Response compression
- [ ] Field selection (only return needed fields)
- [ ] ETags for caching (304 Not Modified)
- [ ] CDN for static assets
