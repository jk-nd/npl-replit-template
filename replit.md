# NPL + React Replit Template

## ⚠️ CRITICAL: Agent Instructions

1. **Read NPL docs first**: `docs/NPL_DEVELOPMENT.md` contains all syntax and rules
2. **Install language server**: Run `make lsp` for NPL syntax highlighting and error detection
3. **Delete the demo package**: After successfully building your own NPL code, delete `npl/src/main/npl-1.0/demo/` - it's only an example
4. **Clean before deploy**: Always run `make clean` before deploying to ensure fresh build
5. **Update the app title**: Change the page title in `frontend/index.html` from "NPL + React" to the app name
6. **Do NOT modify this file**: This file contains agent instructions and should not be edited

### Production Reminders
- **Test users exist**: If `make users` was run, test users (alice, bob, etc.) with password `password123456` exist in Keycloak. Remind users to remove these for production.
- **Keycloak realm title**: The login page title shows the realm name (NPL_APP). This can be customized in Keycloak admin console under Realm Settings > Themes.

---

## Read NPL Documentation First

**Before writing ANY code, you MUST read the NPL development guide:**

```
docs/NPL_DEVELOPMENT.md
```

This file contains essential NPL syntax, types, methods, and common mistakes. **Do NOT skip this step.**

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

**Only after the backend is deployed:**

1. **Regenerate the API client**: `make client` (creates types for your new package)
2. **Update the frontend to use your package**:
   - Update `frontend/src/api/client.ts` - change `demo` to your package name
   - Update `frontend/src/api/types.ts` - import from your generated types
   - Update or replace the components in `frontend/src/components/` to match your protocols
3. **Use the `@actions` array** from API responses to show available actions
4. **Test with provisioned users**: `make users` creates test accounts (alice, bob, etc.)

**⚠️ The existing frontend (`IouCard`, `Dashboard`, etc.) is built for the demo IOU protocol. You MUST update it for your own protocols.**

---

## Key Files

| File | Purpose |
|------|---------|
| `docs/NPL_DEVELOPMENT.md` | **NPL syntax, types, and API reference** (READ THIS FIRST) |
| `npl/src/main/migration.yml` | Deployment configuration |
| `npl/src/main/npl-1.0/` | NPL protocol source code |
| `frontend/src/generated/` | Auto-generated TypeScript types from OpenAPI |
| `frontend/src/api/client.ts` | API client for calling NPL Engine |

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

**The file `docs/NPL_DEVELOPMENT.md` contains critical NPL documentation. Do not delete, overwrite, or modify it unless explicitly asked to update NPL syntax or examples.**
