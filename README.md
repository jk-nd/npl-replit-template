# NPL + React Replit Template

Build React frontends on Replit that connect to NPL backends running on [Noumena Cloud](https://noumena.cloud).

![NPL + React](https://img.shields.io/badge/NPL-Noumena%20Cloud-6366f1)
![React](https://img.shields.io/badge/React-19-61dafb)
![TypeScript](https://img.shields.io/badge/TypeScript-5.7-3178c6)

## 📥 Use This Template

### Option 1: From GitHub (Recommended)

1. Go to [Replit](https://replit.com)
2. Click **Create Repl** → **Import from GitHub**
3. Paste this URL: `https://github.com/jk-nd/npl-replit-template`
4. Click **Import from GitHub**

### Option 2: Fork on GitHub First

1. Fork this repository on GitHub
2. In Replit, click **Create Repl** → **Import from GitHub**
3. Select your forked repository

### Option 3: Use as Replit Template

If this is published as a Replit template, simply click **Use Template**.

---

## 🚀 Quick Start

### 1. Configure Your Project

Edit the `noumena.config` file in the project root:

```
NPL_TENANT=my-company
NPL_APP=my-app
```

**Find these values at:** `portal.noumena.cloud/{tenant}/{app}`

All other URLs (NPL Engine, Keycloak) are **automatically derived** from these!

> **Note:** These are not secrets — they're visible in URLs. Alternatively, you can use Replit's **Configurations** tab instead of the config file.

**Add Keycloak Secrets**

To configure Keycloak and create test users, add these in Replit's **Secrets** tab (🔒):

| Secret | Description |
|--------|-------------|
| `KEYCLOAK_ADMIN_USER` | Keycloak admin username |
| `KEYCLOAK_ADMIN_PASSWORD` | Keycloak admin password |

These enable the optional Keycloak configuration steps during setup.

### 2. Run Full Setup (Interactive)

**Option 1: Using Workflows (Recommended)**

Use the **🚀 Full Setup** workflow from Replit's Tools panel.

**Option 2: Using Make Command**

```bash
make setup
```

This **interactive** setup will:
1. Generate `.env` file with derived URLs
2. Install the NPL CLI and npm dependencies
3. **Prompt you to login** to Noumena Cloud (opens browser)
4. Deploy your NPL code to Noumena Cloud
5. Generate TypeScript API client
6. **Ask if you want to configure Keycloak** (enables dev mode login)
7. **Ask if you want to provision test users** (alice, bob, etc.)

> **Already logged in?** Use `make setup-quick` to skip the login prompt.

### 3. Start Developing

Click the **Run** button or use the **▶️ Start Dev Server** workflow!

### Optional: Manual Configuration

If you skipped the optional steps during setup, you can run them later:

**Configure Keycloak for Replit** (required for dev mode login):
```bash
make keycloak
```
Requires `KEYCLOAK_ADMIN_USER` and `KEYCLOAK_ADMIN_PASSWORD` secrets.

**Provision Test Users** (creates alice, bob, etc.):
```bash
make users
```

**Check Environment Setup**:
```bash
make preflight
```

## 📁 Project Structure

```
├── .replit              # Replit configuration
├── replit.nix           # System dependencies
├── replit.md            # AI Agent workflow instructions
├── Makefile             # Setup commands
│
├── docs/
│   ├── NPL_DEVELOPMENT.md         # Complete NPL reference (for AI Agent)
│   └── NPL_FRONTEND_DEVELOPMENT.md # Frontend patterns - parties, claims, @actions
│
├── scripts/
│   ├── setup-env.sh          # Generate .env from tenant/app
│   ├── install-npl-cli.sh    # Install NPL CLI
│   ├── deploy-npl.sh         # Deploy NPL to Noumena Cloud
│   ├── generate-client.sh    # Generate TypeScript client
│   ├── provision-users.sh    # Create seed users in Keycloak
│   ├── configure-keycloak-client.sh  # Configure Keycloak settings
│   └── deploy-frontend.sh    # Deploy frontend to Cloud
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
└── frontend/
    ├── package.json          # Frontend dependencies
    ├── tsconfig.json         # TypeScript config
    ├── vite.config.ts        # Vite build config
    ├── index.html            # HTML entry point
    ├── src/
    │   ├── main.tsx          # Entry with Keycloak auth
    │   ├── App.tsx           # Main dashboard
    │   ├── auth/
    │   │   └── keycloak.ts   # Keycloak configuration
    │   ├── api/
    │   │   └── npl-client.ts # NPL API client
    │   └── generated/        # (Auto-generated from OpenAPI)
    └── public/
        └── silent-check-sso.html
```

## 🔧 Workflows & Commands

### Replit Workflows (Recommended)

Use the workflows in Replit's **Tools** panel for a guided experience:

- **⚙️ Full Setup** - Complete setup (env, CLI, deps, deploy, client)
- **🚀 Cloud Login** - Login to Noumena Cloud
- **📦 Deploy NPL** - Deploy NPL protocols only
- **🌐 Deploy Frontend** - Deploy frontend only
- **🚀 Full Deploy** - Deploy both NPL and frontend
- **🔄 Generate Client** - Generate TypeScript API client
- **👥 Provision Users** - Create test users in Keycloak
- **🔑 Configure Keycloak** - Configure Keycloak for Replit
- **✅ Check NPL** - Validate NPL code
- **🧪 Test NPL** - Run NPL tests
- **▶️ Start Dev Server** - Start the frontend dev server
- **🏗️ Build Frontend** - Build frontend for production

### Make Commands (Alternative)

| Command | Description |
|---------|-------------|
| `make setup` | **Interactive** full setup with login and optional steps |
| `make setup-quick` | Non-interactive setup (use if already logged in) |
| `make preflight` | Check if environment is correctly configured |
| `make login` | Login to Noumena Cloud |
| `make deploy` | Deploy both NPL and frontend |
| `make deploy-npl` | Deploy NPL protocols only |
| `make deploy-frontend` | Deploy frontend only |
| `make client` | Generate TypeScript API client |
| `make users` | Provision test users in Keycloak |
| `make keycloak` | Configure Keycloak for Replit (enables dev mode) |
| `make add-redirect URL=<url>` | Add redirect URI for external hosting |
| `make check` | Validate NPL code |
| `make test` | Run NPL tests |
| `make run` | Start the frontend dev server |
| `make build` | Build frontend for production |

## 🔄 Development Workflow

### Development Stages

This template supports different development modes based on environment variables:

#### 1. **Local Development** (Recommended for UI Development)
```bash
# .env configuration
VITE_DEV_MODE=true      # Use custom login form with direct OIDC calls
VITE_USE_PROXY=true     # Use Vite proxy to avoid CORS issues
```
- Custom login form instead of Keycloak redirect
- Direct HTTP calls to OIDC endpoints (no Keycloak library)
- Proxy endpoints (`/auth`, `/npl`) to avoid CORS
- Faster iteration for UI changes
- **Run:** Use **▶️ Start Dev Server** workflow or `make run`

#### 2. **Cloud Testing** (Test Against Real Services)
```bash
# .env configuration
VITE_DEV_MODE=true      # Use custom login form
VITE_USE_PROXY=false    # Direct calls to cloud URLs
```
- Custom login form with direct OIDC calls
- Direct calls to Keycloak and NPL Engine on Noumena Cloud
- Tests real authentication and API integration
- **Run:** Use **▶️ Start Dev Server** workflow or `make run`

#### 3. **Production Mode** (Standard Keycloak Flow)
```bash
# .env configuration
VITE_DEV_MODE=false     # Use Keycloak library
VITE_USE_PROXY=false    # Direct calls to cloud URLs
```
- Standard Keycloak redirect flow
- Uses `keycloak-js` library
- Full OAuth2/OIDC authorization code flow
- **Build:** `make build`
- **Deploy:** `make deploy-frontend`

### Deployment Workflow

#### Full Deployment (NPL + Frontend)

**Using Workflow (Recommended):** Use **🚀 Full Deploy** workflow

**Using Make:**
```bash
make deploy
```
This runs in sequence:
1. `make deploy-npl` - Deploys NPL protocols to Noumena Cloud
2. `make build` - Builds frontend for production
3. `make deploy-frontend` - Deploys frontend dist/ to Noumena Cloud

#### Deploy NPL Only (Backend Changes)

**Using Workflow (Recommended):** Use **📦 Deploy NPL** workflow

**Using Make:**
```bash
make deploy-npl
```
When you've made changes to:
- NPL protocol definitions (`*.npl` files)
- Protocol logic, permissions, or states
- No frontend changes needed

After deployment, regenerate the API client:

**Using Workflow:** Use **🔄 Generate Client** workflow

**Using Make:**
```bash
make client
```

#### Deploy Frontend Only (UI Changes)

**Using Workflow (Recommended):** Use **🌐 Deploy Frontend** workflow

**Using Make:**
```bash
make build
make deploy-frontend
```
When you've made changes to:
- React components
- UI/UX updates
- Frontend logic
- No NPL protocol changes

### Environment Variables Reference

| Variable | Values | Description |
|----------|--------|-------------|
| `VITE_DEV_MODE` | `true`/`false` | Use custom login (`true`) or Keycloak library (`false`) |
| `VITE_USE_PROXY` | `true`/`false` | Use Vite proxy (`true`) or direct URLs (`false`) |
| `VITE_NPL_ENGINE_URL` | URL | NPL Engine endpoint (auto-generated) |
| `VITE_KEYCLOAK_URL` | URL | Keycloak endpoint (auto-generated) |
| `VITE_KEYCLOAK_REALM` | realm | Keycloak realm name (auto-generated) |
| `VITE_KEYCLOAK_CLIENT_ID` | client ID | Keycloak client ID (auto-generated) |

**Note:** After changing environment variables, restart the dev server for changes to take effect.

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

## 🤖 For AI Agents (Replit Agent)

This template is designed to work with Replit Agent. The agent should:

1. **Read `docs/NPL_DEVELOPMENT.md` first** - Contains complete NPL syntax, types, and API reference
2. **Read `docs/NPL_FRONTEND_DEVELOPMENT.md`** - Explains how NPL drives frontend patterns (parties, claims, @actions)
3. **Use `frontend/CUSTOMIZATION_GUIDE.md`** - Step-by-step guide for adapting the template
4. **Design backend (NPL) before frontend** - The frontend depends on the generated API

The `replit.md` file contains workflow instructions. Documentation is split to prevent accidental overwriting:
- `docs/NPL_DEVELOPMENT.md` - Backend NPL syntax
- `docs/NPL_FRONTEND_DEVELOPMENT.md` - Frontend integration patterns
- `frontend/CUSTOMIZATION_GUIDE.md` - Practical template adaptation

## 🚀 Deployment Options

### Option 1: Deploy to Noumena Cloud ⭐ Recommended

**This is the easiest and recommended approach.** Deploy your frontend alongside your NPL backend on Noumena Cloud:

```bash
make deploy
```

**Why choose Noumena Cloud?**
- ✅ **Zero configuration** - No Keycloak changes needed (same domain)
- ✅ **Production-ready** - Uses standard OAuth2 redirect flow
- ✅ **Single command** - Deploys both NPL and frontend together
- ✅ **Integrated** - View everything in the Noumena Cloud Portal

After deployment, your app is available at:
```
https://app-{tenant}-{app}.noumena.cloud
```

### Option 2: Publish on Replit

If you prefer to host your frontend on Replit (e.g., for demo purposes or custom domain), additional configuration is required:

1. **Build for production:**
   ```bash
   make build
   ```

2. **Publish your Replit app** and get the URL (e.g., `https://my-app--username.replit.app`)

3. **Add the redirect URI to Keycloak:**
   ```bash
   make add-redirect URL=https://my-app--username.replit.app
   ```

4. **Create production environment:**
   - Copy `env.production.template` to `.env.production` in the root directory
   - Update with your actual tenant/app values
   - Set `VITE_DEV_MODE=false`

> **⚠️ Note:** Each Replit published URL must be added explicitly. Keycloak wildcards only work for paths, not hostnames.

### Environment Modes

| Mode | `VITE_DEV_MODE` | Use Case |
|------|-----------------|----------|
| Development | `true` | Replit preview (iframe restrictions require direct OIDC) |
| Production | `false` | Noumena Cloud or published Replit app |

## 🔧 Troubleshooting

### "Connecting to Noumena Cloud..." hangs forever
**Cause:** Keycloak CSP blocking iframe embedding  
**Solution:** Run `make keycloak` to update CSP settings, then restart the dev server.

### Infinite re-renders in React components
**Cause:** API client recreated on every render  
**Solution:** Wrap `createApiClient()` with `useMemo()`:
```typescript
const client = useMemo(() => createApiClient(token), [token]);
```

### Protocol changes not reflecting after deploy
**Cause:** Old protocol definitions cached in the NPL Engine  
**Applies to:** Adding new protocols, renaming, adding/removing fields, changing types  
**Solution:** Clear and redeploy:
```bash
npl cloud clear --tenant $NPL_TENANT --app $NPL_APP
make deploy-npl
```
**Tip:** When in doubt, always clear before deploying NPL changes.

### Production build still uses dev mode auth
**Cause:** `.env` settings not overriding in production  
**Solution:** Set `VITE_DEV_MODE=false` directly in build command:
```bash
VITE_DEV_MODE=false npm run build
```

### "Please login again" error during deploy
**Cause:** NPL CLI session expired  
**Solution:** Run `make login` or `npl cloud login`

### "Not logged in" error when running make setup
**Cause:** The interactive setup will prompt you to login - just follow the prompts.  
**Alternative:** Run `make install` first, then `make login`, then `make setup-quick`.

### Actions not showing on protocol cards
**Cause:** User doesn't have permission for those actions  
**Solution:** Check your NPL protocol permissions match the logged-in user's party claims.

### Login form shows but authentication fails
**Cause:** Direct Access Grants not enabled on Keycloak client  
**Solution:** Run `make keycloak` to enable Direct Access Grants for dev mode.

## 📚 Resources

- [NPL Documentation](https://documentation.noumenadigital.com)
- [Noumena Cloud Portal](https://portal.noumena.cloud)
- [NPL CLI Reference](https://documentation.noumenadigital.com/runtime/tools/build-tools/cli/)

## 📄 License

MIT License - feel free to use this template for your projects!
