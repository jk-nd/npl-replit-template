# NPL Frontend Development Guide

> **For AI Agents**: This guide explains how NPL backend patterns directly inform frontend architecture. Read this BEFORE building any frontend components.

## Core Concept: The Backend Drives the Frontend

Unlike traditional REST APIs, NPL backends provide **rich metadata** with every response that tells your frontend:
- **What actions are available** (`@actions` array)
- **Who can perform them** (party/role matching via claims)
- **What state the protocol is in** (`@state`)

**Your frontend should NEVER hardcode visibility logic.** Instead, read this metadata from the API.

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| `frontend/CUSTOMIZATION_GUIDE.md` | **Practical step-by-step** guide for adapting the template to your protocol |
| This document | **Conceptual guide** for understanding NPL-frontend patterns |

Read this document first to understand the concepts, then use the Customization Guide for hands-on adaptation.

---

## 1. Understanding Parties and Authorization

This is **fundamental to NPL**. Authorization is based on **party claims**, not traditional roles.

### How It Works

1. **Users authenticate** via Keycloak → receive a JWT token
2. **JWT contains claims** like `{ "email": "alice@example.com" }`
3. **Protocols define party roles** like `protocol[issuer, payee]`
4. **Party roles are filled with claims** when creating instances
5. **NPL Engine checks** if user's JWT claims match a party's claims

### Party Structure

```typescript
// A Party is identified by claims (key-value pairs from JWT)
interface Party {
  claims: {
    [key: string]: string[];  // Each claim key can have multiple values
  }
}

// Example: Party identified by email
const alice: Party = {
  claims: {
    email: ["alice@example.com"]
  }
};
```

### Claim Matching Rule

A user **represents** a party if their JWT claims are a **superset** of the party's claims:

```
Party claims:    { email: ["alice@example.com"] }
User JWT claims: { email: ["alice@example.com"], groups: ["users"] }
Result: ✅ User can represent this party (user has all required claims)
```

### Helper Function for Email-Based Parties

```typescript
// Utility to create a party from an email
export function partyFromEmail(email: string): Party {
  return { 
    claims: { 
      email: [email] 
    } 
  };
}
```

---

## 2. Creating Protocol Instances - Specifying All Parties

When creating a protocol instance, you must provide claims for **every party role** defined in the protocol.

### Example: Two-Party Protocol

```npl
// NPL Backend: protocol[issuer, payee] Iou(var forAmount: Number)
```

```typescript
// Frontend: Creating an IOU
// - Current user (alice@example.com) will be the issuer
// - Someone else (bob@example.com) will be the payee

async function createIou(payeeEmail: string, amount: number) {
  const currentUserEmail = keycloak.tokenParsed?.email;
  
  const response = await client.POST('/npl/demo/Iou/', {
    body: {
      "@parties": {
        // Issuer: the current logged-in user
        issuer: partyFromEmail(currentUserEmail),
        // Payee: another user (from form input)
        payee: partyFromEmail(payeeEmail)
      },
      forAmount: amount
    }
  });
  
  return response.data;
}
```

### ❌ Common Mistake: Forgetting @parties

```typescript
// ❌ WRONG: Missing @parties - will fail!
await client.POST('/npl/demo/Iou/', {
  body: { forAmount: 100 }
});

// ✅ CORRECT: Always include @parties
await client.POST('/npl/demo/Iou/', {
  body: {
    "@parties": {
      issuer: partyFromEmail(currentUser),
      payee: partyFromEmail(otherUser)
    },
    forAmount: 100
  }
});
```

---

## 3. The `@actions` Array - Your UI Control Center

Every protocol instance response includes an `@actions` array listing **exactly which permissions the current user can invoke**.

### How It Works

```typescript
// API Response for an IOU when alice@example.com is logged in
{
  "@id": "abc-123",
  "@state": "unpaid",
  "@parties": {
    "issuer": { "claims": { "email": ["alice@example.com"] } },
    "payee": { "claims": { "email": ["bob@example.com"] } }
  },
  "@actions": ["pay", "getAmountOwed"],  // ⭐ Alice can do these
  "forAmount": 100
}
```

The `@actions` array is computed by the NPL Engine based on:
1. **Current protocol state** - permissions have state constraints (e.g., `| unpaid`)
2. **User's JWT claims** - determines which party they represent
3. **Permission definitions** - who can invoke what

### Different Users See Different Actions

```typescript
// Same IOU, but bob@example.com is logged in (the payee)
{
  "@id": "abc-123",
  "@state": "unpaid",
  "@actions": ["forgive", "getAmountOwed"],  // Bob sees different actions!
  // ...
}

// Same IOU in final state - no actions for anyone
{
  "@id": "abc-123",
  "@state": "paid",
  "@actions": [],  // No actions in final state
  // ...
}
```

### Frontend Pattern: Action-Based Button Visibility

```typescript
function IouCard({ iou }: { iou: Iou }) {
  // ✅ CORRECT: Use @actions to determine what to show
  const canPay = iou["@actions"].includes("pay");
  const canForgive = iou["@actions"].includes("forgive");
  
  return (
    <div className="iou-card">
      <p>Amount: ${iou.forAmount}</p>
      <p>State: {iou["@state"]}</p>
      
      {/* Only render buttons for available actions */}
      {canPay && (
        <button onClick={() => handlePay(iou["@id"])}>
          Pay
        </button>
      )}
      {canForgive && (
        <button onClick={() => handleForgive(iou["@id"])}>
          Forgive
        </button>
      )}
      
      {/* Show message when no actions available */}
      {iou["@actions"].length === 0 && (
        <p className="no-actions">No actions available</p>
      )}
    </div>
  );
}
```

### ❌ Anti-Pattern: Hardcoded State/Role Checks

```typescript
// ❌ WRONG: Don't hardcode visibility logic
function IouCard({ iou, currentUser }) {
  // Don't do this! The backend already computed this for you
  const isIssuer = iou["@parties"].issuer.claims.email[0] === currentUser;
  const isUnpaid = iou["@state"] === "unpaid";
  const canPay = isIssuer && isUnpaid;  // ❌ Duplicating backend logic
}

// ✅ CORRECT: Trust @actions
function IouCard({ iou }) {
  const canPay = iou["@actions"].includes("pay");  // ✅ Backend already checked
}
```

---

## 4. Test Users and Their Claims

The provisioned test users (via `make users`) have these claims in their JWT tokens:

| User | Email Claim | Use For |
|------|-------------|---------|
| alice | alice@example.com | First party in protocols |
| bob | bob@example.com | Second party in protocols |
| eve | eve@example.org | Third party / observer |
| carol | carol@example.com | Additional test user |
| ... | ... | ... |

**Password for all**: `password123456`

### How Claims Flow

```
1. User logs in as "alice"
   ↓
2. Keycloak returns JWT with claims:
   { "email": "alice@example.com", "preferred_username": "alice", ... }
   ↓
3. Frontend stores token and sends with API requests
   ↓
4. NPL Engine checks: Does alice's email match any party in this protocol?
   ↓
5. If match: Include available actions in @actions array
```

---

## 5. API Client Best Practices

### ⚠️ Critical: Use useMemo for API Client

Creating the API client inside a component body causes infinite re-renders:

```typescript
// ❌ BAD: Creates new client on every render → infinite loop
function Dashboard({ keycloak }) {
  const client = createApiClient({
    engineUrl,
    getToken: async () => keycloak.token!
  });
  
  useEffect(() => {
    loadData();
  }, [client]);  // client changes every render!
}

// ✅ GOOD: Memoize the client
function Dashboard({ keycloak }) {
  const client = useMemo(() => createApiClient({
    engineUrl,
    getToken: async () => keycloak.token!
  }), [engineUrl]);  // Stable reference
  
  useEffect(() => {
    loadData();
  }, [client]);
}
```

### API Client with Auth Middleware

```typescript
import createClient from 'openapi-fetch';
import type { paths } from '../generated/demo/api-types';

export function createApiClient(config: {
  engineUrl: string;
  getToken: () => Promise<string>;
}) {
  const client = createClient<paths>({
    baseUrl: `${config.engineUrl}/npl/demo`,
  });

  // Add auth middleware - runs before every request
  client.use({
    async onRequest({ request }) {
      const token = await config.getToken();
      request.headers.set('Authorization', `Bearer ${token}`);
      return request;
    },
  });

  return client;
}
```

---

## 6. Complete Component Patterns

### Pattern 1: Protocol List

```typescript
function IouList() {
  const [ious, setIous] = useState<Iou[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  const loadIous = useCallback(async () => {
    try {
      setLoading(true);
      const { data, error } = await client.GET('/npl/demo/Iou/');
      if (error) throw new Error(error.message);
      setIous(data?.items || []);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [client]);
  
  useEffect(() => {
    loadIous();
  }, [loadIous]);
  
  if (loading) return <LoadingSpinner />;
  if (error) return <ErrorMessage message={error} />;
  if (ious.length === 0) return <EmptyState message="No IOUs found" />;
  
  return (
    <div className="iou-list">
      {ious.map(iou => (
        <IouCard key={iou["@id"]} iou={iou} onUpdate={loadIous} />
      ))}
    </div>
  );
}
```

### Pattern 2: Protocol Card with Dynamic Actions

```typescript
function IouCard({ iou, onUpdate }: { iou: Iou; onUpdate: () => void }) {
  const [loading, setLoading] = useState(false);
  
  async function handleAction(action: string, params?: object) {
    setLoading(true);
    try {
      const { error } = await client.POST(`/npl/demo/Iou/{id}/${action}`, {
        params: { path: { id: iou["@id"] } },
        body: params
      });
      if (error) throw new Error(error.message);
      onUpdate();  // Refresh the list after action
    } catch (err) {
      console.error(`Failed to ${action}:`, err);
    } finally {
      setLoading(false);
    }
  }
  
  return (
    <div className="iou-card">
      <div className="iou-header">
        <span className={`state-badge state-${iou["@state"]}`}>
          {iou["@state"]}
        </span>
        <span className="amount">${iou.forAmount}</span>
      </div>
      
      {/* Dynamic action buttons based on @actions */}
      <div className="iou-actions">
        {iou["@actions"].includes("pay") && (
          <button 
            onClick={() => handleAction("pay", { amount: 10 })}
            disabled={loading}
          >
            Pay $10
          </button>
        )}
        {iou["@actions"].includes("forgive") && (
          <button 
            onClick={() => handleAction("forgive")}
            disabled={loading}
          >
            Forgive
          </button>
        )}
      </div>
    </div>
  );
}
```

### Pattern 3: Create Protocol Form

```typescript
function CreateIouForm({ onSuccess }: { onSuccess: () => void }) {
  const [payeeEmail, setPayeeEmail] = useState('');
  const [amount, setAmount] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  
  // Get current user's email from Keycloak
  const currentUserEmail = keycloak.tokenParsed?.email;
  
  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    
    try {
      const { error: apiError } = await client.POST('/npl/demo/Iou/', {
        body: {
          // ⭐ CRITICAL: Specify claims for ALL parties
          "@parties": {
            issuer: partyFromEmail(currentUserEmail),
            payee: partyFromEmail(payeeEmail)
          },
          forAmount: amount
        }
      });
      
      if (apiError) throw new Error(apiError.message);
      onSuccess();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }
  
  return (
    <form onSubmit={handleSubmit}>
      <div className="form-group">
        <label>Your Email (Issuer)</label>
        <input type="email" value={currentUserEmail} disabled />
      </div>
      
      <div className="form-group">
        <label>Payee Email</label>
        <input 
          type="email" 
          value={payeeEmail} 
          onChange={e => setPayeeEmail(e.target.value)}
          placeholder="bob@example.com"
          required 
        />
      </div>
      
      <div className="form-group">
        <label>Amount</label>
        <input 
          type="number" 
          value={amount} 
          onChange={e => setAmount(Number(e.target.value))}
          min="1"
          required 
        />
      </div>
      
      {error && <p className="error">{error}</p>}
      
      <button type="submit" disabled={loading}>
        {loading ? 'Creating...' : 'Create IOU'}
      </button>
    </form>
  );
}
```

---

## 7. Common Mistakes to Avoid

| Mistake | Problem | Solution |
|---------|---------|----------|
| Hardcoding action visibility | Duplicates backend logic, goes stale | Use `@actions.includes("actionName")` |
| Forgetting `@parties` when creating | API returns 400 error | Always include `@parties` with claims for all roles |
| Recreating API client every render | Infinite re-render loop | Use `useMemo()` |
| Not refreshing after actions | UI shows stale data | Call refresh function after mutations |
| Assuming specific claims exist | Breaks with different users | Check claims exist before accessing |

---

## 8. Updating Frontend for New Protocols

When you create a new NPL package (replacing `demo`):

### Step 1: Deploy and Generate

```bash
make deploy-npl
make client
```

### Step 2: Update API Client Imports

```typescript
// Before (demo package)
import type { paths } from '../generated/demo/api-types';
const baseUrl = `${engineUrl}/npl/demo`;

// After (your package, e.g., "bikeshop")
import type { paths } from '../generated/bikeshop/api-types';
const baseUrl = `${engineUrl}/npl/bikeshop`;
```

### Step 3: Update Party Role Names

Match your protocol's party names:

```typescript
// If your protocol is: protocol[buyer, seller] Order(...)
"@parties": {
  buyer: partyFromEmail(currentUserEmail),
  seller: partyFromEmail(sellerEmail)
}
```

### Step 4: Update Action Names

Match your protocol's permission names:

```typescript
// If your protocol has: permission[buyer] confirmOrder()
{order["@actions"].includes("confirmOrder") && (
  <button onClick={() => handleAction("confirmOrder")}>
    Confirm Order
  </button>
)}
```

---

## Quick Reference

| NPL Backend | Frontend Equivalent |
|-------------|---------------------|
| `protocol[partyA, partyB]` | Form inputs for both party emails |
| `permission[partyA] doSomething()` | Button visible when `@actions.includes("doSomething")` |
| `state pending` | Badge/chip showing state name |
| `@actions: ["approve", "reject"]` | Render Approve and Reject buttons |
| `@parties.partyA.claims.email` | Display party info in UI |
| `@state` | Style cards differently per state |

---

## Summary

1. **Authorization = Party Claims** - Users are matched to parties via JWT claims (email)
2. **Read `@actions`** - Don't hardcode visibility; use what the backend tells you
3. **Specify all parties** - When creating, provide claims for every role in the protocol
4. **Memoize API client** - Avoid infinite re-render loops
5. **Refresh after mutations** - Reload data after any action
6. **Update imports** - When changing packages, update all path references
