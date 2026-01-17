# NPL Development Reference

> **DO NOT DELETE OR OVERWRITE THIS FILE** - This is the comprehensive NPL reference for AI agents.

This document contains everything you need to know about NPL (Noumena Protocol Language) for building backends and frontends.

## What is NPL?

**NPL (Noumena Protocol Language)** is a language for modeling secure-by-design multi-party business processes with:
- Built-in state machines
- Multi-party permissions
- Automatic REST API generation
- Automatic persistence

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         REPLIT                               │
│  ┌──────────────────┐    ┌─────────────────────────────┐    │
│  │  React + Vite    │────│  Generated TypeScript       │    │
│  │  Frontend        │    │  API Client                 │    │
│  └──────────────────┘    └─────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                    │
                    ▼ (HTTPS + JWT)
┌─────────────────────────────────────────────────────────────┐
│                    NOUMENA CLOUD                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Engine   │  │ Keycloak │  │ Readmodel│  │ Connectors│   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
├── .replit              # Replit configuration
├── replit.nix           # System dependencies
├── replit.md            # AI Agent workflow instructions
├── Makefile             # Setup commands
├── docs/
│   ├── NPL_DEVELOPMENT.md         # THIS FILE - NPL reference
│   └── NPL_FRONTEND_DEVELOPMENT.md # Frontend patterns - parties, claims, @actions
├── scripts/
│   ├── setup-env.sh          # Generate .env from tenant/app
│   ├── install-npl-cli.sh    # Install NPL CLI
│   ├── deploy-npl.sh         # Deploy NPL to Noumena Cloud
│   ├── generate-client.sh    # Generate TypeScript API client
│   ├── provision-users.sh    # Create seed users in Keycloak
│   ├── configure-keycloak-client.sh  # Configure Keycloak for Replit
│   ├── deploy-frontend.sh    # Deploy frontend to Noumena Cloud
│   └── preflight-check.sh    # Validate environment setup
├── npl/
│   └── src/
│       └── main/
│           ├── migration.yml  # Deployment entry point
│           └── npl-1.0/
│               └── demo/
│                   └── iou.npl
├── src/
│   ├── main.tsx
│   ├── App.tsx
│   ├── auth/
│   │   └── keycloak.ts
│   ├── api/
│   │   └── npl-client.ts
│   └── generated/       # (Auto-generated from OpenAPI)
└── public/
    └── silent-check-sso.html
```

## Setup Commands

| Command | Description |
|---------|-------------|
| `npl cloud login` | Login to Noumena Cloud (do this first!) |
| `make setup` | Full setup (env, CLI, deps, deploy, client) |
| `make check` | Validate NPL code |
| `make deploy` | Deploy NPL protocols |
| `make client` | Generate TypeScript API client |
| `make users` | Provision test users |
| `make keycloak` | Configure Keycloak for Replit |
| `make run` | Start the frontend |

---

## Secrets Configuration

### 1. Configure Secrets (in Replit Secrets tab)

You only need **two secrets** - all other URLs are derived automatically:

| Secret | Description | Example |
|--------|-------------|---------|
| `NPL_TENANT` | Your Noumena Cloud tenant | `my-company` |
| `NPL_APP` | Your Noumena Cloud app | `my-app` |

**Optional secrets** (auto-derived if not set):
| Secret | Auto-derived Pattern |
|--------|---------------------|
| `NPL_PACKAGE` | Defaults to `demo` |
| `VITE_NPL_ENGINE_URL` | `https://engine-{tenant}-{app}.noumena.cloud` |
| `VITE_KEYCLOAK_URL` | `https://keycloak-{tenant}-{app}.noumena.cloud` |
| `VITE_KEYCLOAK_REALM` | Same as app name |
| `VITE_KEYCLOAK_CLIENT_ID` | Same as app name |

**Find your tenant/app:** Look at the Portal URL: `portal.noumena.cloud/{tenant}/{app}`

### 2. Login to Noumena Cloud

Open the Shell and authenticate:

```bash
npl cloud login
```

This opens a browser to authenticate with your Noumena Cloud account.

### 3. Run Full Setup

```bash
make setup
```

This will:
1. Generate `.env` file with derived URLs
2. Install NPL CLI
3. Install npm dependencies
4. Deploy NPL protocols to Noumena Cloud
5. Generate TypeScript API client

### 4. Provision Users (Optional)

To create seed users for testing, add these **additional secrets**:

| Secret | Description | Where to Find |
|--------|-------------|---------------|
| `KEYCLOAK_ADMIN_USER` | Keycloak admin username | Portal > Services > Keycloak |
| `KEYCLOAK_ADMIN_PASSWORD` | Keycloak admin password | Portal > Services > Keycloak |

Then run:

```bash
make users
```

This creates these test users:

| Username | Email | Password |
|----------|-------|----------|
| alice | alice@example.com | password123456 |
| bob | bob@example.com | password123456 |
| eve | eve@example.org | password123456 |
| carol | carol@example.com | password123456 |
| ivan | ivan@example.com | password123456 |
| dave | dave@example.com | password123456 |
| frank | frank@example.com | password123456 |
| peggy | peggy@example.com | password123456 |
| grace | grace@example.com | password123456 |
| heidi | heidi@example.com | password123456 |

These match the [NPL Development Mode seed users](https://documentation.noumenadigital.com/runtime/deployment/configuration/Engine-Dev-Mode/).

### 5. Configure Keycloak for Replit

```bash
make keycloak
```

This configures Keycloak to:
- Allow redirect URIs from Replit domains
- Enable iframe embedding for the Replit preview

### 6. Click Run

Start your React frontend connected to Noumena Cloud!
| `make check` | Validate NPL code |
| `make test` | Run NPL tests |
| `make run` | Start the frontend dev server |

---

# NPL Development Reference

NPL (NOUMENA Protocol Language) has unique syntax for defining protocol types and operations, strong typing, and a
distinct approach to modeling permissions and state transitions.

## Simple Example: Payment Protocol

```npl
package iou

/**
 * Struct to represent a timestamped amount
 * @param amount The amount of the payment
 * @param timestamp The time at which the payment was made
 */
struct TimestampedAmount {
    amount: Number,
    timestamp: DateTime
};

/**
 * Function to calculate the total of a list of timestamped amounts
 * @param entries The list of timestamped amounts
 * @return The total amount
 */
function total(entries: List<TimestampedAmount>) -> entries.map(function(p: TimestampedAmount) -> p.amount).sum();

/**
 * Simple IOU protocol
 * @param issuer The party issuing the IOU
 * @param payee The party receiving the IOU
 * @param forAmount The initial amount of the IOU
 */
@api
protocol[issuer, payee] Iou(var forAmount: Number) {
    require(forAmount > 0, "Initial amount must be strictly positive");

    initial state unpaid;
    final state paid;
    final state forgiven;

    private var payments = listOf<TimestampedAmount>();

    /**
     * Function to calculate the amount owed
     * @return The amount owed
     */
    function amountOwed() returns Number -> forAmount - total(payments);

    /**
     * Function to pay a certain amount towards the IOU, invoked by the issuer
     * @param amount The amount to pay
     */
    @api
    permission[issuer] pay(amount: Number) | unpaid {
        require(amount > 0, "Amount must be strictly positive");
        require(amount <= amountOwed(), "Amount may not exceed amount owed");

        var p = TimestampedAmount(amount = amount, timestamp = now());

        payments = payments.with(p);

        if (amountOwed() == 0) {
            become paid;
        };
    };

    /**
     * Function to forgive the IOU, invoked by the payee
     */
    @api
    permission[payee] forgive() | unpaid {
        become forgiven;
    };

    /**
     * Function to get the amount owed, invoked by either party
     * @return The amount owed
     */
    @api
    permission[issuer | payee] getAmountOwed() returns Number | unpaid {
        return amountOwed();
    };
}
```

## NPL Tests

Tests should be placed in a DIFFERENT file, but part of the same package:

```npl
@test
function test_amount_owed_after_pay(test: Test) -> {
    var iou = Iou['issuer', 'payee'](100);
    iou.pay['issuer'](50);

    test.assertEquals(50, iou.getAmountOwed['issuer'](), "Amount owed should reflect payment");
};

@test
function test_pay_negative_amount(test: Test) -> {
    var iou = Iou['issuer', 'payee'](100);

    test.assertFails(function() -> iou.pay['issuer'](-10), "Paying negative amounts should fail");
};
```

Do NOT generate tests unless explicitly asked to.

## Common mistakes to avoid

These are critical errors to avoid when working with NPL:

- **Text, not String**: NPL uses `Text` type, not `String`.
- **No null values**: NPL doesn't have `null` or nullable types. Use `Optional<T>` instead.
- **Optional handling**: Access optional values with `getOrElse()`, `getOrFail()`, or `computeIfAbsent()`.
- **Party limitations**: NEVER store or persist values of the `Party` type in protocol-level variables, collections, or
  data structures.
- **Always use semicolons**: Semicolons are MANDATORY at the end of ALL statements. This includes:

  - Return statements inside blocks: `return value;`
  - Statement blocks inside control structures: `if (condition) { doSomething(); };`
  - Statements inside functions: `var x = 5;`

  ```npl
  // CORRECT - note semicolons after each return and after the entire if-else block
  var f = function() returns Text -> if (true) { return "foo"; } else { return "bar"; };

  // INCORRECT - missing semicolons after return statements and if-else block
  var f = function() returns Text -> if (true) { return "foo" } else { return "bar" }
  ```

- **No ternary operators**: Always use if-else statements instead of `?:` syntax.
- **Otherwise clauses**: In obligations, the `otherwise` clause MUST ONLY contain a state transition.
- **Method hallucinations**: Only use the standard library methods explicitly documented below.
- **No imports or mocks**: Define everything you need in the current file.
- **Keep implementations simple**: Prefer small applications with less than 200 lines of code.
- **Type definitions outside protocols**: Always define types (structs, enums, unions, etc.) at the top level of the
  file, NEVER inside protocols.
- **Struct field syntax**: Struct fields use commas, not semicolons, and don't use `var`:

  ```npl
  // INCORRECT
  struct Item {
    var id: Text;
    var price: Number;
  };

  // CORRECT
  struct Item {
    id: Text,
    price: Number
  };
  ```

- **Avoid reserved keywords**: Never use these reserved keywords as variable names, parameter names, or identifiers:
  `after`, `and`, `become`, `before`, `between`, `const`, `enum`, `else`, `final`, `for`, `function`, `guard`, `in`,
  `init`, `initial`, `if`, `is`, `match`, `native`, `notification`, `notify`, `identifier`, `obligation`, `optional`,
  `otherwise`, `package`, `permission`, `private`, `protocol`, `require`, `resume`, `return`, `returns`, `state`,
  `struct`, `symbol`, `this`, `union`, `use`, `var`, `vararg`, `with`, `copy`

  **CRITICAL WARNING:** Be especially careful not to use `state` or `symbol` as variable names. These are two of the
  most commonly misused reserved keywords. Other frequently misused keywords include `return`, `final`, and `initial`.
  Reserved keywords should only be used for their intended purpose (e.g., `state` for state declarations:
  `initial state unpaid;`; `symbol` for declaring new symbol types: `symbol chf;`).

- **No redundant getters**: Do NOT create permissions or functions that simply return a public protocol field (e.g.,
  `getAmount()`). All non-private top-level variables are already queryable via the API. Only introduce a separate
  accessor when additional logic is required.

- **Unwrap activeState() before comparing**: `activeState()` returns an `Optional<State>`. Use `getOrFail()` (or another
  optional-handling method) before comparison, and reference the state constant via the `States` enum:

  ```npl
  activeState().getOrFail() == States.stateName; // Correct
  ```

  Direct comparisons like `activeState() == stateName` are invalid.

- **Boolean operators**: Use `&&` and `||` for logical AND/OR. Keywords `and` and `or` are not valid in NPL.

- **Permission syntax order**: Always use this exact order in permission declarations:

  ```npl
  // CORRECT ORDER
  permission[party] foo(parameters) returns ReturnType | stateName { ... };

  // INCORRECT - state constraint after return type
  permission[party] foo(parameters) | stateName returns ReturnType { ... };
  ```

  The return type (`returns Type`) must always come before the state constraint (`| stateName`).

- **Always initialize variables**: ALL variables MUST be initialized when declared. Uninitialized variables are not
  allowed in NPL.

  ```npl
  // INCORRECT - uninitialized variable
  private var bookingTime: DateTime;

  // CORRECT - variable with initialization
  private var bookingTime: DateTime = now();
  ```

- **No comments before package declaration**: NOTHING should appear before the package statement. No comments, no
  docstrings, no whitespace. The package declaration must be the very first line of any NPL file.

  ```npl
  // INCORRECT - comment before package
  /** File documentation */
  package mypackage

  // CORRECT - package is first
  package mypackage
  ```

## Key Guidelines

- All NPL files have the `.npl` extension and must start with a package declaration.
- NPL is strongly typed - respect the type system when writing code.
- Follow existing code style in the project.
- Protocols, permissions, and states are fundamental concepts.
- All variables must be initialized when declared.
- **Document Everything**: Use Javadoc-style comments (`/** ... */`) for all declarations. Include `@param` and
  `@return` tags where applicable. Do NOT add Javadoc to variables or `init` blocks. Place docstrings directly above the
  element they document (protocols, functions, structs, etc.), never at the top of the file.
- **Initialization**: Use `init` block for initialization behavior.
- **End if statements with semicolons**:
  ```npl
  if (amount > 0) { return true; }; // Semicolon required
  ```
- **Use toText(), not toString()** for string conversion.
- **Only use for-in loops** - there are no while loops (or other kinds of loops) in NPL:
  ```npl
  for (item in items) { process(item); }; // Correct
  ```
- **Multiple parties in single permission**: Use `permission[buyer | seller]` not multiple declarations.
- **Use length() for Text, not size()**:
  ```npl
  var nameCount = name.length(); // Correct
  ```
- **List.without() removes elements, not indices**:
  ```npl
  var itemToRemove = items.get(index);
  items = items.without(itemToRemove); // Correct
  ```
- **Invoke permissions with this. and party**:
  ```npl
  this.startProcessing[provider](); // Correct
  ```
- **DateTime methods require inclusive parameter**:
  ```npl
  if (deadline.isBefore(now(), false)) { /* Strictly before */ };
  ```
- **Don't hallucinate methods**: Only use methods explicitly listed in this document's "Allowed Methods by Type" section.
- **Immutable collections**: `with()` and `without()` create new collections.
- **No advanced functional operations**: No streams, reduce, unless documented above.
- **No `Any` type**: Always use the most specific type for a variable.

## Folder Structure Guidelines

When organizing your NPL project, adhere to the following folder structure:

- **Entry Point**:

  - The project entry point is always a `migration.yml` file that defines migration changesets.
  - This file is often located at `*/src/main/migration.yml` and references the source directories.

- **Source Files**:

  - NPL source files are organized in versioned directories (e.g., `npl-1.0.0/`) as specified in the migration.yml file.
  - New NPL files and packages should be created within the appropriate versioned directory (e.g.,
    `src/main/npl-1.0.0/my_package/`).
  - Always create a new package (a new sub-directory) within the versioned directory when implementing new, distinct
    functionality.

- **Test Files**:

  - Test files should be placed in a separate `test` directory, usually found at `src/test/npl/`. The package structure
    within the `test` directory should mirror the structure of the source files they are testing. For example, tests for
    `src/main/npl-1.0.0/my_package/MyProtocol.npl` would be located in `src/test/npl/my_package/MyProtocolTests.npl`.

Don't generate tests unless explicitly asked to.

## Protocol Syntax

### Protocol Declaration

```npl
/**
 * Basic protocol structure.
 * @param initialValue Initial numeric value.
 * @param textParameter Text parameter.
 */
@api  // Required for API instantiation
protocol[party1, party2] ProtocolName(
  // The var keyword makes the variable accessible to the protocol body
  var initialValue: Number,
  var textParameter: Text
) {
    init {
        // Initialization
    };
    // Protocol body
};
```

### Protocol Instantiation

```npl
var instance = ProtocolName[alice, bob](42, "example");

// With named arguments
var namedInstance = ProtocolName[party1 = alice, party2 = bob](
  initialValue = 42, textParameter = "example"
);
```

## Permissions and States

```npl
@api
protocol[issuer, recipient] Transfer() {
  // States
  initial state created;
  state pending;
  final state completed;

  /**
   * Allows the issuer to send money.
   * @param amount Amount to send.
   * @return Success status.
   */
  permission[issuer] sendMoney(amount: Number) | created, pending returns Boolean {
    require(amount > 0, "Amount must be positive");
    become completed;
    return true;
  };

  /**
   * Obligation with deadline.
   */
  obligation[issuer] makePayment() before deadline | created {
    // Action logic
  } otherwise become expired; // ONLY state transition allowed in otherwise
};
```

## Standard Library and Type System

NPL has a defined standard library. **Never invent or assume the existence of methods that aren't documented.**

### Available Types

- **Basic Types**: `Boolean`, `Number`, `Text`, `DateTime`, `LocalDate`, `Duration`, `Period`, `Blob`, `Unit`
- **Collection Types**: `List<T>`, `Set<T>`, `Map<K, V>`
- **Complex Types**: `Optional<T>`, `Pair<A, B>`, `Party`, `Test`
- **User-Defined Types**: `Enum`, `Struct`, `Union`, `Identifier`, `Symbol`, `Protocol`

### Standard Library Functions

> **Note**: The functions listed below are top-level helpers, invoked _directly_ (e.g., `var t = now()`). They are
> **not** receiver methods—expressions such as `now().millis()` or `someDate.millis()` are invalid.

- **Logging**: `debug()`, `info()`, `error()`
- **Constructors**: `listOf()`, `setOf()`, `mapOf()`, `optionalOf()`, `dateTimeOf()`, `localDateOf()`
- **Time and Duration**: `now()`, `millis()`, `seconds()`, `minutes()`, `hours()`, `days()`, `weeks()`, `months()`,
  `years()`

### Type Usage Examples

```npl
// Basic types
var amount = 100;
var name = "John";
var isValid = true;

// Collections
var numbers = listOf(1, 2, 3);
var uniqueNumbers = setOf(1, 2, 3);
var userScores = mapOf(Pair("alice", 95), Pair("bob", 87));

// Optionals
var presentValue = optionalOf(42);
var emptyValue = optionalOf<Number>();
var value = presentValue.getOrElse(0);

// Control Flow
if (amount > 100) {
  return "High value";
} else if (amount > 50) {
  return "Medium value";
} else {
  return "Low value";
};

// Match expressions
var result = match(paymentStatus) {
  Pending -> "Please wait"
  Completed -> "Thank you"
  Failed -> "Please try again"
};

// Functions
function calculateTax(amount: Number) returns Number -> {
  return amount * 0.2;
};
```

### Allowed Methods by Type

Use ONLY these methods - do not hallucinate or invent others:

- **Collection Methods (all collections)**:

  - `allMatch()`, `anyMatch()`, `contains()`, `flatMap()`, `fold()`, `forEach()`, `isEmpty()`, `isNotEmpty()`
  - `map()`, `noneMatch()`, `size()`, `asList()`
  - Collections of `Number`: `sum()`

- **List Methods**:

  - `filter()`, `findFirstOrNone()`, `firstOrNone()`, `get()`, `head()`, `indexOfOrNone()`, `lastOrNone()`, `plus()`
  - `reverse()`, `sort()`, `sortBy()`, `tail()`, `toSet()`, `with()`, `withAt()`, `without()`, `withoutAt()`
  - `withIndex()`, `zipOrFail()`, `takeFirst()`, `takeLast()`, `toMap()`

- **Map Methods**:

  - `filter()`, `forEach()`, `getOrNone()`, `isEmpty()`, `isNotEmpty()`, `keys()`, `plus()`, `size()`
  - `mapValues()`, `values()`, `with()`, `without()`, `toList()`

- **Set Methods**:

  - `filter()`, `plus()`, `toList()`, `with()`, `without()`, `takeFirst()`, `takeLast()`

- **Text Methods**:

  - `plus()`, `lessThan()`, `greaterThan()`, `lessThanOrEqual()`, `greaterThanOrEqual()`, `length()`

- **Number Methods**:

  - `isInteger()`, `roundTo()`, `negative()`, `plus()`, `minus()`, `multiplyBy()`, `divideBy()`, `remainder()`
  - `lessThan()`, `greaterThan()`, `lessThanOrEqual()`, `greaterThanOrEqual()`

- **Boolean Methods**:

  - `not()`

- **DateTime Methods**:

  - `day()`, `month()`, `year()`, `nano()`, `second()`, `minute()`, `hour()`, `zoneId()`
  - `firstDayOfYear()`, `lastDayOfYear()`, `firstDayOfMonth()`, `lastDayOfMonth()`, `startOfDay()`
  - `durationUntil()`, `isAfter()`, `isBefore()`, `isBetween()`, `withZoneSameLocal()`, `withZoneSameInstant()`
  - `plus()`, `minus()`, `toLocalDate()`, `dayOfWeek()`

- **Duration Methods**:

  - `toSeconds()`, `plus()`, `minus()`, `multiplyBy()`

- **LocalDate Methods**:

  - `day()`, `month()`, `year()`, `firstDayOfYear()`, `lastDayOfYear()`, `firstDayOfMonth()`, `lastDayOfMonth()`
  - `isAfter()`, `isBefore()`, `isBetween()`, `plus()`, `minus()`, `periodUntil()`, `atStartOfDay()`, `dayOfWeek()`

- **Period Methods**:

  - `plus()`, `minus()`, `multiplyBy()`

- **Optional Methods**:

  - `isPresent()`, `getOrElse()`, `getOrFail()`, `computeIfAbsent()`

- **Party Methods**:

  - `isRepresentableBy()`, `mayRepresent()`, `claims()`

- **Protocol Methods**:

  - `parties()`, `activeState()`, `initialState()`, `finalStates()`

- **Blob Methods**:

  - `filename()`, `mimeType()`

- **Symbol Methods**:

  - `toNumber()`, `unit()`, `plus()`, `minus()`, `multiplyBy()`, `divideBy()`, `remainder()`, `negative()`
  - `lessThan()`, `greaterThan()`, `lessThanOrEqual()`, `greaterThanOrEqual()`

- **General Methods**:
  - All types: `toText()` - converts value to Text representation

---

# NPL Frontend Development

## Understanding Parties and Claims

**This is fundamental to NPL.** Parties represent identities in multi-party protocols. Unlike traditional apps where you just have "users", NPL protocols define **roles** (like `issuer`, `payee`, `buyer`, `seller`) that are filled by parties.

### How Parties Work

A **Party** is identified by **claims** - key-value pairs that come from the user's JWT token (from Keycloak).

```typescript
// Party structure
interface Party {
  claims: {
    [key: string]: string[];  // Each claim key can have multiple values
  }
}

// Example: A party identified by email
const alice: Party = {
  claims: {
    email: ["alice@example.com"]
  }
};

// Example: A party identified by group membership
const admins: Party = {
  claims: {
    groups: ["admin", "superuser"]
  }
};
```

### Creating Parties in Frontend Code

```typescript
// Helper function to create a party from email
function partyFromEmail(email: string): Party {
  return { claims: { email: [email] } };
}

// Creating a protocol instance with parties
const response = await fetch(`${engineUrl}/npl/demo/Iou`, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    "@parties": {
      issuer: partyFromEmail("alice@example.com"),
      payee: partyFromEmail("bob@example.com")
    },
    forAmount: 100
  })
});
```

### Party Matching

When a user makes an API request, the NPL Engine checks if the user's JWT claims **match** any party in the protocol. A user "represents" a party if their claims are a **superset** of the party's claims.

Example:
- Protocol party: `{ claims: { email: ["alice@example.com"] } }`
- User's JWT claims: `{ email: ["alice@example.com"], groups: ["users"] }`
- **Result**: User can represent this party (user's claims contain all party's claims)

### Empty Claims (Public Parties)

A party with empty claims can be represented by **anyone**:

```typescript
// Anyone can represent this party
const publicParty: Party = { claims: {} };
```

## API Response Structure and Available Actions

**This is critical for building frontends.** When you fetch a protocol instance, the API returns not just the data but also **which actions the current user can perform**.

### Protocol Instance Response

```typescript
// GET /npl/{package}/{Protocol}/{id}
interface ProtocolInstance {
  "@id": string;                    // Unique instance ID
  "@state": string;                 // Current state (e.g., "unpaid", "paid")
  "@parties": {                     // Parties in this instance
    [role: string]: Party;
  };
  "@actions": string[];             // ⭐ ACTIONS THE CURRENT USER CAN PERFORM
  
  // Protocol-specific fields (from your NPL code)
  forAmount: number;
  // ... other fields
}
```

### The `@actions` Array - Key for Frontend Development

The `@actions` array tells you **exactly which permissions the current user can invoke** based on:
1. The current **state** of the protocol
2. The user's **claims** (which parties they can represent)

**Example**: For an IOU in state `unpaid`:

```typescript
// If logged in as alice@example.com (the issuer)
{
  "@id": "abc123",
  "@state": "unpaid",
  "@parties": {
    "issuer": { "claims": { "email": ["alice@example.com"] } },
    "payee": { "claims": { "email": ["bob@example.com"] } }
  },
  "@actions": ["pay", "getAmountOwed"],  // Alice can pay or check amount
  "forAmount": 100
}

// If logged in as bob@example.com (the payee)
{
  "@id": "abc123",
  "@state": "unpaid",
  "@actions": ["forgive", "getAmountOwed"],  // Bob can forgive or check amount
  // ...
}

// If the IOU is already paid (final state)
{
  "@id": "abc123",
  "@state": "paid",
  "@actions": [],  // No actions available in final state
  // ...
}
```

### Using `@actions` in Your UI

```typescript
function IouCard({ iou }: { iou: ProtocolInstance }) {
  const canPay = iou["@actions"].includes("pay");
  const canForgive = iou["@actions"].includes("forgive");
  
  return (
    <div>
      <p>Amount: {iou.forAmount}</p>
      <p>State: {iou["@state"]}</p>
      
      {/* Only show buttons for actions the user can perform */}
      {canPay && <button onClick={() => handlePay(iou)}>Pay</button>}
      {canForgive && <button onClick={() => handleForgive(iou)}>Forgive</button>}
      
      {iou["@actions"].length === 0 && <p>No actions available</p>}
    </div>
  );
}
```

## API Endpoints

The NPL Engine provides a REST API based on the OpenAPI spec generated from your NPL code.

### List Protocol Instances

```
GET /npl/{package}/{Protocol}/
```

Returns all instances of a protocol type that the current user can see. You can filter by state:

```
GET /npl/{package}/{Protocol}/?state=unpaid
```

### Get Single Instance

```
GET /npl/{package}/{Protocol}/{id}
```

### Create Instance

```
POST /npl/{package}/{Protocol}
Content-Type: application/json

{
  "@parties": {
    "issuer": { "claims": { "email": ["alice@example.com"] } },
    "payee": { "claims": { "email": ["bob@example.com"] } }
  },
  "forAmount": 100
}
```

### Invoke Action (Permission)

```
POST /npl/{package}/{Protocol}/{id}/{action}
Content-Type: application/json

{
  "amount": 50
}
```

## OpenAPI Integration

- All backend API endpoints are defined in the OpenAPI specification at `/npl/{package}/-/openapi.json`
- After running `make client`, TypeScript types are generated in `src/generated/api-types.ts`
- Do not invent or hallucinate endpoints - only use what's in the OpenAPI spec
- Ensure all API payloads and return types strictly match the OpenAPI specification

## Frontend Development Rules

- Use React with TypeScript and functional components.
- Use React Hooks for state and effect management.
- Use React Hook Form for form handling.
- Implement proper TypeScript types and interfaces throughout.
- Implement error boundaries for robust error handling.
- Create reusable UI components and follow component composition best practices.
- Separate logic, presentation, and data concerns.
- Organize components in logical folders, separating utilities, types, and services.
- Use index files for clean imports and follow naming conventions (PascalCase for components, camelCase for functions).
- Implement responsive design and maintain consistent spacing and typography.

## Authorization

- Use OIDC (OpenID Connect) standard flow for authentication and authorization.
- Keycloak is provided by Noumena Cloud and configured in `src/auth/keycloak.ts`.
- The JWT token from Keycloak contains the user's claims that determine which parties they can represent.

## Build and Deployment

- After implementing or updating the frontend, always run `npm run build` to generate the production-ready `dist` directory.
- Use `make deploy-frontend` or the "🌐 Deploy Frontend" command to deploy to Noumena Cloud.

## Further Reading

**For detailed frontend patterns, see: `docs/NPL_FRONTEND_DEVELOPMENT.md`**

This guide covers:
- Using `@actions` array to show/hide buttons dynamically
- Specifying party claims when creating protocol instances
- API client best practices (useMemo, auth middleware)
- Common mistakes and how to avoid them

---

# NPL Deployment and Migrations

## Understanding Migrations

NPL uses a **migration-based deployment model**. Instead of just deploying code, you deploy **changesets** that describe how your protocols evolve over time. This ensures:

1. **Versioned deployments** - Track what code is deployed
2. **Safe upgrades** - Migrate existing protocol instances to new versions
3. **Rollback capability** - Understand what changed between versions

## The migration.yml File

The `migration.yml` file is the **entry point** for NPL deployment. It defines which NPL source directories to deploy and in what order.

### Basic Structure

```yaml
$schema: https://documentation.noumenadigital.com/schemas/migration-schema-v2.yml

changesets:
  - name: 1.0
    changes:
      - migrate:
          sources:
            - npl-1.0
```

### Key Concepts

| Field | Description |
|-------|-------------|
| `$schema` | Required. Points to the migration schema for validation. |
| `changesets` | List of versioned changes to apply. |
| `name` | Version identifier (e.g., "1.0", "1.1", "2.0"). |
| `changes` | List of change operations to apply. |
| `migrate` | Deploy NPL source code from specified directories. |
| `sources` | List of directories containing NPL code (relative to migration.yml). |

### Adding New Versions

When you update your protocols, add a new changeset:

```yaml
$schema: https://documentation.noumenadigital.com/schemas/migration-schema-v2.yml

changesets:
  - name: 1.0
    changes:
      - migrate:
          sources:
            - npl-1.0
  
  - name: 1.1
    changes:
      - migrate:
          sources:
            - npl-1.1
```

### Directory Structure

```
npl/
└── src/
    └── main/
        ├── migration.yml      # Deployment entry point
        ├── npl-1.0/           # Version 1.0 source code
        │   └── demo/
        │       └── iou.npl
        └── npl-1.1/           # Version 1.1 source code (future)
            └── demo/
                └── iou.npl
```

## Deployment Process

### 1. Check Your Code First

Always validate your NPL code before deploying:

```bash
npl check --source-dir ./npl/src/main
```

This catches syntax errors, type mismatches, and other issues.

### 2. Run Tests

If you have tests, run them:

```bash
npl test --test-source-dir ./npl/src
```

### 3. Deploy to Noumena Cloud

Deploy using the migration file:

```bash
npl cloud deploy npl \
  --tenant $NPL_TENANT \
  --app $NPL_APP \
  --migration ./npl/src/main/migration.yml
```

Or simply:

```bash
make deploy
```

### 4. Generate Updated Client

After deploying new protocols, regenerate your TypeScript client:

```bash
make client
```

This fetches the new OpenAPI spec and generates updated types.

## What Happens During Deployment

1. **Code Compilation**: NPL source files are compiled and validated
2. **Schema Generation**: OpenAPI spec is generated from `@api` annotated protocols
3. **Database Migration**: Protocol definitions are stored in the backend
4. **Instance Migration**: Existing protocol instances can be migrated to new versions (if configured)

## Deployment Best Practices

- **Always check before deploy**: Run `npl check` to catch errors early
- **Version your changesets**: Use meaningful version numbers (1.0, 1.1, 2.0)
- **Keep migrations additive**: Add new changesets rather than modifying old ones
- **Regenerate client after deploy**: The OpenAPI spec may have changed
- **Test in development first**: Use a dev app before deploying to production

## Common Deployment Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "required property 'name' not found" | Missing changeset name | Add `name: X.X` to each changeset |
| "No refresh token found" | Not logged in | Run `npl cloud login` first |
| "NPL check failed" | Syntax/type errors in code | Fix errors shown by `npl check` |
| "Migration failed" | Breaking changes to existing protocols | Review migration strategy |

---

## NPL CLI Commands

- `npl check --source ./npl` - Validate NPL code
- `npl test --test-source-dir ./npl` - Run NPL tests
- `npl cloud login` - Authenticate to Noumena Cloud
- `npl cloud deploy npl` - Deploy NPL protocols to cloud
- `npl cloud deploy frontend` - Deploy frontend to cloud

---

## NPL CLI MCP Integration

The NPL CLI supports the **Model Context Protocol (MCP)**, allowing AI agents to interact directly with NPL tools.

### Starting the MCP Server

```bash
npl mcp
```

This starts an MCP server exposing the following tools:

| MCP Tool | Description |
|----------|-------------|
| `check` | Validate NPL source code |
| `test` | Run NPL tests |
| `openapi` | Generate OpenAPI specification |
| `puml` | Generate PlantUML diagrams |
| `deploy` | Deploy locally |
| `cloud_login` | Login to Noumena Cloud |
| `cloud_logout` | Logout from Noumena Cloud |
| `cloud_clear` | Clear cloud deployment |
| `cloud_deploy_npl` | Deploy NPL protocols to cloud |
| `cloud_deploy_frontend` | Deploy frontend to cloud |

### Configuring MCP for AI Editors

#### Cursor IDE

Create `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "npl": {
      "command": "npl",
      "args": ["mcp"]
    }
  }
}
```

#### Claude Desktop

Add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "npl": {
      "command": "npl",
      "args": ["mcp"]
    }
  }
}
```

### Benefits of MCP

- **Direct tool access**: AI agents can validate code, run tests, and deploy without shell commands
- **Structured responses**: Better error handling and result parsing
- **Integrated workflow**: Seamless development experience

---

## Tech Stack

- **Frontend**: React 19, TypeScript, Vite
- **Auth**: Keycloak JS, @react-keycloak/web
- **API**: OpenAPI-generated TypeScript client
- **Backend**: Noumena Cloud (NPL Engine)
