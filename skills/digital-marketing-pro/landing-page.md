# Landing Page Templates & Conversion Patterns

## Finance Landing Page — Structure

```
[HEADER: Logo | Phone | Trust badge]

[HERO SECTION]
H1: Get Up to $50,000 — Even With Bad Credit
H2: Check your rate in 2 minutes. No credit impact.
[Loan Amount Slider: $1,000 ←————→ $50,000]
[CTA Button: CHECK MY RATE NOW →]
[Trust row: 🔒 Secure | ⭐ 4.8/5 Rating | ✅ 500+ Lenders]

[3-STEP PROCESS]
Step 1: Fill out a short form (2 min)
Step 2: Get matched with lenders instantly
Step 3: Funds in your account in 24–48 hours

[SOCIAL PROOF / TESTIMONIALS]
Real names, states, loan amounts approved

[FEATURES GRID]
- No prepayment penalty
- Soft credit check only
- All credit types welcome
- Rates from 5.99% APR

[FAQ SECTION] — Schema FAQPage markup
Q: Will applying hurt my credit score?
Q: How fast can I get funded?
Q: What credit score do I need?

[SECONDARY CTA]
[Check Your Rate — Free, No Obligation]

[FOOTER]
Legal disclosure | APR range | Lender network notice
Privacy policy | Terms | Unsubscribe
```

---

## HTML Pattern — Multi-Step Form

```html
<!-- Step 1 -->
<div class="form-step" id="step-1">
  <h3>How much do you need?</h3>
  <input type="range" min="1000" max="50000" step="500" id="loanAmount">
  <div class="amount-display">$<span id="amountValue">5,000</span></div>
  <button onclick="nextStep(2)">Continue →</button>
</div>

<!-- Step 2 -->
<div class="form-step hidden" id="step-2">
  <h3>What's your credit like?</h3>
  <div class="credit-options">
    <button class="option-btn" value="excellent">Excellent (720+)</button>
    <button class="option-btn" value="good">Good (660–719)</button>
    <button class="option-btn" value="fair">Fair (580–659)</button>
    <button class="option-btn" value="poor">Poor (Below 580)</button>
  </div>
</div>

<!-- Step 3 — Contact info -->
<div class="form-step hidden" id="step-3">
  <h3>Where should we send your offers?</h3>
  <input type="text" placeholder="First Name" required>
  <input type="email" placeholder="Email Address" required>
  <input type="tel" placeholder="Phone Number" required>
  <button type="submit">See My Loan Options →</button>
  <p class="trust-note">🔒 Your info is 100% secure</p>
</div>
```

---

## Conversion Rate Benchmarks (Finance)

| Page Type | Average CVR | Good CVR |
|-----------|-------------|----------|
| Personal loan LP | 8–12% | 15%+ |
| Multi-step form | 12–18% | 22%+ |
| Mortgage rate check | 6–10% | 14%+ |
| Nutra product page | 2–4% | 6%+ |
| Email → click | 2–5% | 8%+ |

---

## SEO Meta Templates

### Personal Loans
```
Title: Personal Loans Up to $50,000 | Apply Online — GimmeLoans
Meta: Need fast cash? Apply in 2 minutes and get matched with 500+ lenders. All credit types welcome. Rates from 5.99% APR. No credit impact to check.
```

### Auto Loans
```
Title: Auto Loans for All Credit Types | Rates from 3.99% — GimmeLoans
Meta: Get approved for your next car loan regardless of credit history. Compare offers from top auto lenders. Fast decision, no obligation.
```

### Mortgage
```
Title: Mortgage Rates Today | Compare & Save — GimmeLoans
Meta: Check today's mortgage rates and compare offers from top lenders. First-time buyers welcome. Get pre-qualified in minutes without affecting your credit.
```

### Nutra/Health
```
Title: [Product Name] | Natural [Benefit] Supplement
Meta: [Product] is formulated with [key ingredients] to support [benefit]. Made in USA. GMP certified. 30-day money back guarantee.
```

---

## Schema Markup — Finance Page

```json
{
  "@context": "https://schema.org",
  "@type": "FinancialService",
  "name": "GimmeLoans",
  "description": "Personal loan matching service connecting borrowers with lenders",
  "url": "https://gimmeloans.com",
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.8",
    "reviewCount": "1247"
  }
}
```

---

## A/B Test Ideas (High Priority)

| Element | Version A | Version B |
|---------|-----------|-----------|
| CTA button | "Check My Rate" | "Get My Loan Offers" |
| Headline | Pain-led: "Struggling to get approved?" | Benefit-led: "Up to $50K — Fast Approval" |
| Form position | Left side | Center / full-width |
| Trust badges | Above form | Below CTA button |
| Loan slider | Show it | Hide it — just text field |
