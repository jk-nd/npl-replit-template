# NPL + React Replit Template

Build React frontends on Replit that connect to NPL backends running on [Noumena Cloud](https://cloud.noumena.digital).

![NPL + React](https://img.shields.io/badge/NPL-Noumena%20Cloud-6366f1)
![React](https://img.shields.io/badge/React-19-61dafb)
![TypeScript](https://img.shields.io/badge/TypeScript-5.7-3178c6)

## 🚀 Quick Start

### 1. Configure Secrets

In Replit's **Secrets** tab (🔒), add:

| Secret | Description | Example |
|--------|-------------|---------|
| `NPL_TENANT` | Your Noumena Cloud tenant | `my-company` |
| `NPL_APP` | Your app name | `iou-demo` |
| `VITE_NPL_ENGINE_URL` | NPL Engine URL | `https://my-app.noumena.cloud` |
| `VITE_KEYCLOAK_URL` | Keycloak URL | `https://auth.noumena.cloud` |
| `VITE_KEYCLOAK_REALM` | Keycloak realm | `my-realm` |
| `VITE_KEYCLOAK_CLIENT_ID` | Frontend client ID | `frontend` |

### 2. Run Full Setup

Click the **⚡ Full Setup** workflow button, or run:

```bash
./scripts/full-setup.sh
```

This will:
- Install the NPL CLI
- Install npm dependencies
- Deploy your NPL code to Noumena Cloud
- Generate TypeScript API client

### 3. Start Developing

Click **Run** to start the React dev server!

## 📁 Project Structure

```
├── .replit              # Replit config + workflow buttons
├── replit.nix           # System dependencies
├── package.json         # Frontend dependencies
│
├── scripts/
│   ├── install-npl-cli.sh    # Install NPL CLI
│   ├── deploy-to-cloud.sh    # Deploy NPL to Noumena Cloud
│   ├── generate-client.sh    # Generate TypeScript client
│   ├── deploy-frontend.sh    # Deploy frontend to Cloud
│   └── full-setup.sh         # Complete setup
│
├── npl/
│   └── src/
│       ├── main/
│       │   ├── migration.yml
│       │   └── npl-1.0/demo/
│       │       └── iou.npl   # Example IOU protocol
│       └── test/
│           └── npl/demo/
│               └── test_iou.npl
│
├── src/
│   ├── main.tsx              # Entry with Keycloak
│   ├── App.tsx               # Main dashboard
│   ├── auth/
│   │   └── keycloak.ts       # Keycloak config
│   ├── api/
│   │   └── npl-client.ts     # NPL API client
│   └── generated/            # (Auto-generated)
│
└── public/
    └── silent-check-sso.html
```

## 🔧 Workflow Buttons

| Button | Action |
|--------|--------|
| 📦 Install NPL CLI | Install the Noumena CLI |
| 🔐 Login to Noumena Cloud | Authenticate to your cloud account |
| ✅ Check NPL Code | Validate NPL syntax and types |
| 🧪 Run NPL Tests | Execute NPL unit tests |
| 🚀 Deploy to Noumena Cloud | Deploy NPL protocols |
| 🔧 Generate API Client | Generate TypeScript types from OpenAPI |
| ⚡ Full Setup | Complete setup (all of the above) |
| 🌐 Deploy Frontend | Deploy built frontend to Noumena Cloud |

## 📖 NPL Development

### Key Commands

```bash
# Validate NPL code
npl check --source-dir ./npl/src/main

# Run tests
npl test --test-source-dir ./npl/src

# Generate OpenAPI spec locally
npl openapi --source-dir ./npl/src/main

# Login to Noumena Cloud
npl cloud login

# Deploy to cloud
npl cloud deploy npl --tenant $NPL_TENANT --app $NPL_APP --migration ./npl/src/main/migration.yml
```

### NPL Code Style

- All files use `.npl` extension
- Package declaration is the first line
- Use Javadoc comments (`/** ... */`) for documentation
- Semicolons are mandatory after all statements
- Use `Text` not `String`, `Optional<T>` not `null`

### Example Protocol

```npl
package demo

@api
protocol[issuer, payee] Iou(var forAmount: Number) {
    require(forAmount > 0, "Amount must be positive");
    
    initial state unpaid;
    final state paid;
    
    @api
    permission[issuer] pay(amount: Number) | unpaid {
        // Payment logic...
    };
}
```

## 🔐 Authentication

This template uses Keycloak for authentication via the `@react-keycloak/web` library.

The frontend will automatically redirect to Keycloak login when accessed. After login, the JWT token is included in all API requests to NPL Engine.

### Party Representation

In NPL, parties are identified by claims:

```typescript
// Create a party from email
const alice = { claims: { email: ['alice@example.com'] } };

// Create an IOU with parties
await client.create('Iou', {
  '@parties': {
    issuer: alice,
    payee: bob
  },
  forAmount: 100
});
```

## 🌐 API Client Usage

```typescript
import { NPLClient, partyFromEmail } from './api/npl-client';

const client = new NPLClient({
  engineUrl: import.meta.env.VITE_NPL_ENGINE_URL,
  getToken: async () => keycloak.token!,
  packageName: 'demo'
});

// Create protocol instance
const iou = await client.create('Iou', {
  '@parties': {
    issuer: partyFromEmail('alice@example.com'),
    payee: partyFromEmail('bob@example.com')
  },
  forAmount: 100
});

// Execute action
await client.action('Iou', iou['@id'], 'pay', { amount: 50 });

// List instances
const ious = await client.list('Iou', { state: 'unpaid' });
```

## 📚 Resources

- [NPL Documentation](https://documentation.noumenadigital.com)
- [Noumena Cloud Portal](https://cloud.noumena.digital)
- [NPL CLI Reference](https://documentation.noumenadigital.com/runtime/tools/build-tools/cli/)

## 📄 License

MIT License - feel free to use this template for your projects!
