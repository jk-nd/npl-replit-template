# NPL + React Replit Template

## ⚠️ CRITICAL: Agent Instructions

1. **Run `make setup` first**: This is the first thing to do. It will:
   - Install NPL CLI, language server, and npm dependencies
   - Open a browser for Noumena Cloud login (user must authenticate)
   - Deploy NPL backend and generate API client
   - Prompt for optional Keycloak and test user configuration
2. **Read NPL docs**: `docs/NPL_DEVELOPMENT.md` contains all NPL syntax and rules
3. **Delete the demo package**: After building your own NPL code, delete `npl/src/main/npl-1.0/demo/`
4. **Clean before deploy**: Run `make clean` before deploying to ensure fresh build
5. **Update the app title**: Change `frontend/index.html` title from "NPL + React" to your app name
6. **Do NOT modify this file**: This file contains agent instructions

### First-Time Setup

**Step 1: Configure your Noumena Cloud app**

Edit `noumena.config` with your tenant and app name:
```
NPL_TENANT=your-tenant
NPL_APP=your-app
```

This file is committed to the repo, so when you copy/fork a project, the config comes with it!

**Step 2: Add secrets (only if using Keycloak admin features)**

In Replit Secrets tab, add:
- `KEYCLOAK_ADMIN_USER` - Only needed for `make users` or `make keycloak`
- `KEYCLOAK_ADMIN_PASSWORD`

**Step 3: Run setup**
```bash
make setup
```
A browser will open for login - the user must complete authentication.

---

## 🚨 NPL Syntax Quick Reference (MUST READ)

These are the **most common mistakes**. Memorize them before writing NPL:

| Rule | Example |
|------|---------|
| **Semicolons after EVERYTHING** | `if (x) { return y; };` ← note semicolon after `}` |
| **Text, not String** | `var name: Text = "hello";` |
| **No null** | Use `Optional<T>` and `getOrElse()` |
| **No ternary operator** | Use `if-else` instead of `? :` |
| **Use `npl check` not LSP** | LSP only shows basic errors; `make check` validates fully |
| **Clear before deploy** | `npl cloud clear` then `make deploy-npl` |
| **Regenerate client** | After NPL changes: `make client` |
| **Use `@actions` for UI** | Don't check emails/roles manually |

**Full reference**: `docs/NPL_DEVELOPMENT.md`

---

## ⚠️ Common Pitfalls

### 1. Production Build: VITE_DEV_MODE must be false
For cloud deployment, `VITE_DEV_MODE` must be `false`. Set it directly in the build command:
```bash
VITE_DEV_MODE=false npm run build
```
Don't rely on `.env` settings for production - inline environment variables take priority.

### 2. React API Client: Use useMemo()
**Always wrap `createApiClient()` with `useMemo()`** to prevent infinite re-render loops:
```typescript
// ❌ BAD - causes infinite re-renders
const client = createApiClient(token);

// ✅ GOOD - stable client reference
const client = useMemo(() => createApiClient(token), [token]);
```

### 3. Clear before deploy (recommended)
**Always clear when changing NPL code** - this applies to:
- Adding new protocols
- Renaming protocols or fields
- Adding/removing fields
- Changing field types

```bash
npl cloud clear --tenant $NPL_TENANT --app $NPL_APP
make deploy-npl
```

**Why?** The NPL Engine caches protocol definitions. Old definitions can conflict with new ones, causing deployment failures or runtime errors. When in doubt, clear first.

### 4. Environment Variable Priority
- `.env` → Used for development
- Inline variables in scripts → Take priority over `.env`
- For production builds, `make build` automatically sets `VITE_DEV_MODE=false`

### 5. Dev Server in Replit Does NOT Work with Production Mode
**The Vite dev server (`make run`) only works with `VITE_DEV_MODE=true`.**

When `VITE_DEV_MODE=false`, the Keycloak library uses iframe-based auth, which Replit's webview blocks with CSP errors:
```
Framing 'http://...' violates Content Security Policy directive: "frame-ancestors 'self'"
```

**Solution:** For testing in Replit's webview:
1. Use `VITE_DEV_MODE=true` during development
2. Run `make build && make deploy-frontend` to deploy to Noumena Cloud for production testing

### Production Reminders
- **Test users exist**: If `make users` was run, test users (alice, bob, etc.) with password `password123456` exist in Keycloak. Remind users to remove these for production.
- **Keycloak realm title**: The login page title shows the realm name (NPL_APP). This can be customized in Keycloak admin console under Realm Settings > Themes.

---

## Read Documentation First

**Before writing ANY code, you MUST read these guides:**

| Document | Purpose |
|----------|---------|
| `docs/NPL_DEVELOPMENT.md` | NPL syntax, types, methods, and common mistakes |
| `docs/NPL_FRONTEND_DEVELOPMENT.md` | **How NPL drives frontend patterns** - parties, claims, @actions |
| `frontend/CUSTOMIZATION_GUIDE.md` | **Step-by-step** template adaptation with code examples |

The frontend guide is **critical** - it explains how to:
- Use `@actions` array to show/hide buttons dynamically
- Specify party claims when creating protocol instances
- Handle multi-party authorization via email claims

---

## Development Workflow

**IMPORTANT: Always follow this order - Backend First, Then Frontend.**

### Step 1: Understand the Requirements

Before writing code, understand what the user wants to build:
- What entities/protocols are needed?
- What parties (roles) are involved?
- What states and transitions exist?
- What permissions do different parties have?

### Step 2: Design and Implement NPL Backend

**Do the backend FIRST. The frontend depends on it.**

1. **Read the NPL reference**: `docs/NPL_DEVELOPMENT.md`
2. **Create a new package** in `npl/src/main/npl-1.0/{your_package}/`
3. **Design your protocols** in your new package
4. **Validate your code**: `make check`
5. **Run tests** (if any): `make test`
6. **Delete the demo package**: After your code builds successfully, delete `npl/src/main/npl-1.0/demo/` (contains example IOU protocol)
7. **Clean and deploy**: `make clean && make deploy-npl`
8. **Regenerate the TypeScript client**: `make client`

**⚠️ IMPORTANT:** Always delete the demo IOU protocol (`npl/src/main/npl-1.0/demo/`) before deploying your own application. It's only there as a reference example.

### Step 3: Build the Frontend

**Only after the backend is deployed. Read `docs/NPL_FRONTEND_DEVELOPMENT.md` first!**

1. **Regenerate the API client**: `make client` (creates types for your new package)
2. **Update the frontend to use your package**:
   - Update `frontend/src/api/client.ts` - change `demo` to your package name
   - Update `frontend/src/api/types.ts` - import from your generated types
   - Update party role names to match your protocol (e.g., `buyer`/`seller` instead of `issuer`/`payee`)
   - Update or replace the components in `frontend/src/components/` to match your protocols
3. **Use the `@actions` array** from API responses to show available actions dynamically
4. **When creating protocol instances**, always include `@parties` with email claims for ALL party roles
5. **Test with provisioned users**: `make users` creates test accounts (alice, bob, etc.) with email claims

**⚠️ The existing frontend (`IouCard`, `Dashboard`, etc.) is built for the demo IOU protocol. You MUST update it for your own protocols.**

**⚠️ Party Authorization**: Users are authorized via JWT claims matching party claims. Use `partyFromEmail(email)` helper to create party objects.

---

## Key Files

| File | Purpose |
|------|---------|
| `docs/NPL_DEVELOPMENT.md` | **NPL syntax, types, and API reference** (READ FIRST) |
| `docs/NPL_FRONTEND_DEVELOPMENT.md` | **Frontend patterns** - parties, claims, @actions (READ SECOND) |
| `npl/src/main/migration.yml` | Deployment configuration |
| `npl/src/main/npl-1.0/` | NPL protocol source code |
| `frontend/src/generated/` | Auto-generated TypeScript types from OpenAPI |
| `frontend/src/api/client.ts` | API client for calling NPL Engine |
| `frontend/src/api/types.ts` | Party helper functions and type exports |

---

## Quick Reference

### NPL Critical Rules

- Use `Text`, not `String`
- Use `Optional<T>`, not `null`
- Semicolons after ALL statements including `if` blocks: `if (x) { y; };`
- No ternary operators - use `if/else`
- Package declaration must be first line (no comments before it)
- Struct fields use commas, not semicolons

### Party Structure

```typescript
// Parties are identified by claims
const party = { claims: { email: ["user@example.com"] } };
```

### Available Actions

The API response includes `@actions` - an array of actions the current user can perform:

```typescript
const instance = await fetchProtocol(id);
if (instance["@actions"].includes("approve")) {
  // Show approve button
}
```

---

## Commands

| Command | Description |
|---------|-------------|
| `make setup` | **Interactive** full setup (installs, prompts for login, deploys, offers optional steps) |
| `make setup-quick` | Non-interactive setup (use if already logged in) |
| `make preflight` | Check if environment is correctly configured |
| `make login` | Login to Noumena Cloud |
| `make check` | Validate NPL code |
| `make deploy` | Deploy both NPL and frontend |
| `make deploy-npl` | Deploy only NPL protocols |
| `make client` | Generate TypeScript client |
| `make users` | Create test users (alice, bob, etc.) |
| `make keycloak` | Configure Keycloak for Replit (enables dev mode) |
| `make add-redirect URL=<url>` | Add redirect URI for external hosting |
| `make lsp` | Install NPL Language Server (syntax highlighting) |
| `make run` | Start frontend dev server |

---

## Deployment

### Recommended: Deploy to Noumena Cloud

```bash
make deploy
```

This deploys both NPL and frontend to Noumena Cloud. **No extra configuration needed.**

Your app will be at: `https://app-{tenant}-{app}.noumena.cloud`

**Before production deployment:**
- Update `frontend/index.html` title to your app name
- As user whether user wants to remove test users from Keycloak if `make users` was run (alice, bob, etc. have weak passwords)

### Alternative: Publish on Replit

If you want to use Replit's publishing instead:

1. `make build`
2. Publish and get the URL
3. `make add-redirect URL=https://your-app.replit.app`
4. Create `.env.production` with `VITE_DEV_MODE=false`

---

## NPL CLI MCP Support

The NPL CLI supports the Model Context Protocol (MCP). Run `npl mcp` to start an MCP server with these tools:

- `check` - Validate NPL code
- `test` - Run NPL tests
- `openapi` - Generate OpenAPI spec
- `cloud_deploy_npl` - Deploy to Noumena Cloud
- `cloud_deploy_frontend` - Deploy frontend

See `docs/NPL_DEVELOPMENT.md` for MCP configuration details.

---

## DO NOT DELETE OR OVERWRITE

**These files contain critical documentation. Do not delete, overwrite, or modify them unless explicitly asked:**

- `docs/NPL_DEVELOPMENT.md` - NPL syntax and backend development
- `docs/NPL_FRONTEND_DEVELOPMENT.md` - Frontend patterns and party authorization
