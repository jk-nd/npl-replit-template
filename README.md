# NPL + React Replit Template

Build React frontends on Replit that connect to NPL backends running on [Noumena Cloud](https://noumena.cloud).

![NPL + React](https://img.shields.io/badge/NPL-Noumena%20Cloud-6366f1)
![React](https://img.shields.io/badge/React-19-61dafb)
![TypeScript](https://img.shields.io/badge/TypeScript-5.7-3178c6)

## 🚀 Quick Start

### 1. Configure Secrets

In Replit's **Secrets** tab (🔒), add only **two required secrets**:

| Secret | Description | Example |
|--------|-------------|---------|
| `NPL_TENANT` | Your Noumena Cloud tenant | `my-company` |
| `NPL_APP_NAME` | Your Noumena Cloud app | `my-app` |

**Find these at:** `portal.noumena.cloud/{tenant}/{app}`

All other URLs (NPL Engine, Keycloak) are **automatically derived** from these!

### 2. Login to Noumena Cloud

Open the Shell and run:

```bash
npl cloud login
```

This opens a browser to authenticate with your Noumena Cloud account.

### 3. Run Full Setup

```bash
make setup
```

This will:
- Generate `.env` file with derived URLs
- Install the NPL CLI
- Install npm dependencies  
- Deploy your NPL code to Noumena Cloud
- Generate TypeScript API client

### 4. Provision Test Users (Optional)

Add these additional secrets for user provisioning:

| Secret | Description | Where to Find |
|--------|-------------|---------------|
| `KEYCLOAK_ADMIN_USER` | Keycloak admin username | Portal > Services > Keycloak |
| `KEYCLOAK_ADMIN_PASSWORD` | Keycloak admin password | Portal > Services > Keycloak |

Then run:

```bash
make users
```

This creates seed users (alice, bob, eve, etc.) with password `password123456`.

### 5. Configure Keycloak for Replit

```bash
make keycloak
```

This configures Keycloak to:
- Allow redirect URIs from Replit domains
- Enable iframe embedding for the Replit preview

### 6. Start Developing

Click **Run** to start the React dev server!

## 📁 Project Structure

```
├── .replit              # Replit configuration
├── replit.nix           # System dependencies
├── replit.md            # AI Agent context (NPL documentation)
├── Makefile             # Setup commands
├── package.json         # Frontend dependencies
│
├── scripts/
│   ├── setup-env.sh          # Generate .env from tenant/app
│   ├── install-npl-cli.sh    # Install NPL CLI
│   ├── deploy-to-cloud.sh    # Deploy NPL to Noumena Cloud
│   ├── generate-client.sh    # Generate TypeScript client
│   ├── provision-users.sh    # Create seed users in Keycloak
│   ├── configure-keycloak-client.sh  # Configure Keycloak settings
│   ├── deploy-frontend.sh    # Deploy frontend to Cloud
│   └── full-setup.sh         # Complete setup orchestration
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
│   ├── main.tsx              # Entry with Keycloak auth
│   ├── App.tsx               # Main dashboard
│   ├── auth/
│   │   └── keycloak.ts       # Keycloak configuration
│   ├── api/
│   │   └── npl-client.ts     # NPL API client
│   └── generated/            # (Auto-generated from OpenAPI)
│
└── public/
    └── silent-check-sso.html
```

## 🔧 Make Commands

| Command | Description |
|---------|-------------|
| `make setup` | Full setup (env, CLI, deps, deploy, client) |
| `make login` | Login to Noumena Cloud |
| `make deploy` | Deploy NPL protocols |
| `make client` | Generate TypeScript API client |
| `make users` | Provision test users in Keycloak |
| `make keycloak` | Configure Keycloak for Replit |
| `make check` | Validate NPL code |
| `make test` | Run NPL tests |
| `make run` | Start the frontend dev server |

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
npl cloud deploy npl --tenant $NPL_TENANT --app $NPL_APP_NAME --migration ./npl/src/main/migration.yml
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
        require(amount > 0, "Amount must be positive");
        require(amount <= forAmount, "Cannot overpay");
        forAmount = forAmount - amount;
        if (forAmount == 0) {
            become paid;
        };
    };
}
```

## 🔐 Authentication

This template uses Keycloak for authentication via the `@react-keycloak/web` library.

The frontend automatically redirects to Keycloak login when accessed. After login, the JWT token is included in all API requests to NPL Engine.

### Test Users

After running `make users`, you can login with:

| Username | Password |
|----------|----------|
| alice | password123456 |
| bob | password123456 |
| eve | password123456 |
| carol | password123456 |
| ... | password123456 |

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
- [Noumena Cloud Portal](https://portal.noumena.cloud)
- [NPL CLI Reference](https://documentation.noumenadigital.com/runtime/tools/build-tools/cli/)

## 📄 License

MIT License - feel free to use this template for your projects!
