# NPL + React Replit Template

## CRITICAL: Read NPL Documentation First

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
2. **Design your protocols** in `npl/src/main/npl-1.0/{package}/`
3. **Check your code**: `make check`
4. **Deploy to Noumena Cloud**: `make deploy`
5. **Regenerate the TypeScript client**: `make client`

### Step 3: Build the Frontend

**Only after the backend is deployed:**

1. **Check the generated types** in `src/generated/api-types.ts`
2. **Use the `@actions` array** to know what the user can do
3. **Build UI components** that match the protocol's states and permissions
4. **Test with provisioned users**: `make users` creates test accounts

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
| `make run` | Start frontend dev server |

---

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
