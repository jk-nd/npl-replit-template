# NPL + React Replit Template

## Project Overview

This is a **Noumena NPL + React** template for building frontends that connect to NPL backends running on Noumena Cloud.

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
├── .replit              # Replit config + workflow buttons
├── replit.nix           # System dependencies
├── package.json         # Frontend dependencies
├── vite.config.ts       # Vite configuration
├── scripts/
│   ├── setup-env.sh          # Generate .env from tenant/app
│   ├── install-npl-cli.sh    # Install NPL CLI
│   ├── deploy-to-cloud.sh    # Deploy NPL to Noumena Cloud
│   ├── generate-client.sh    # Generate TypeScript API client
│   ├── provision-users.sh    # Create seed users in Keycloak
│   ├── deploy-frontend.sh    # Deploy frontend to Noumena Cloud
│   └── full-setup.sh         # Run complete setup
├── npl/
│   └── src/
│       └── main/
│           ├── migration.yml
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

## Getting Started

### 1. Configure Secrets (in Replit Secrets tab)

You only need **two secrets** - all other URLs are derived automatically:

| Secret | Description | Example |
|--------|-------------|---------|
| `NPL_TENANT` | Your Noumena Cloud tenant | `tim` |
| `NPL_APP_NAME` | Your Noumena Cloud app | `test` |

**Optional secrets** (auto-derived if not set):
| Secret | Auto-derived Pattern |
|--------|---------------------|
| `NPL_PACKAGE` | Defaults to `demo` |
| `VITE_NPL_ENGINE_URL` | `https://engine-{tenant}-{app}.noumena.cloud` |
| `VITE_KEYCLOAK_URL` | `https://keycloak-{tenant}-{app}.noumena.cloud` |
| `VITE_KEYCLOAK_REALM` | Same as app name |
| `VITE_KEYCLOAK_CLIENT_ID` | Same as app name |

**Find your tenant/app:** Look at the Portal URL: `portal.noumena.cloud/{tenant}/{app}`

### 2. Run Full Setup

Click the **"⚡ Full Setup"** workflow button. This will:
1. Generate `.env` file with derived URLs
2. Install NPL CLI
3. Install npm dependencies
4. Deploy NPL protocols to Noumena Cloud
5. Generate TypeScript API client

### 3. Provision Users (Optional)

To create seed users for testing, add these **additional secrets**:

| Secret | Description | Where to Find |
|--------|-------------|---------------|
| `KEYCLOAK_ADMIN_USER` | Keycloak admin username | Portal > Services > Keycloak |
| `KEYCLOAK_ADMIN_PASSWORD` | Keycloak admin password | Portal > Services > Keycloak |

Then click **"👥 Provision Dev Users"** to create these test users:

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

### 4. Click Run

Start your React frontend connected to Noumena Cloud!

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

- **No redundant getters**: Do NOT create permissions or functions that simply return a public protocol field (e.g.,
  `getAmount()`). All non-private top-level variables are already queryable via the API.

- **Unwrap activeState() before comparing**: `activeState()` returns an `Optional<State>`. Use `getOrFail()` (or another
  optional-handling method) before comparison, and reference the state constant via the `States` enum:

  ```npl
  activeState().getOrFail() == States.stateName; // Correct
  ```

- **Boolean operators**: Use `&&` and `||` for logical AND/OR. Keywords `and` and `or` are not valid in NPL.

- **Permission syntax order**: Always use this exact order in permission declarations:

  ```npl
  // CORRECT ORDER
  permission[party] foo(parameters) returns ReturnType | stateName { ... };

  // INCORRECT - state constraint after return type
  permission[party] foo(parameters) | stateName returns ReturnType { ... };
  ```

- **Always initialize variables**: ALL variables MUST be initialized when declared.

  ```npl
  // INCORRECT - uninitialized variable
  private var bookingTime: DateTime;

  // CORRECT - variable with initialization
  private var bookingTime: DateTime = now();
  ```

- **No comments before package declaration**: NOTHING should appear before the package statement. The package declaration must be the very first line of any NPL file.

## Key Guidelines

- All NPL files have the `.npl` extension and must start with a package declaration.
- NPL is strongly typed - respect the type system when writing code.
- Protocols, permissions, and states are fundamental concepts.
- All variables must be initialized when declared.
- **Document Everything**: Use Javadoc-style comments (`/** ... */`) for all declarations.
- **Initialization**: Use `init` block for initialization behavior.
- **End if statements with semicolons**: `if (amount > 0) { return true; };`
- **Use toText(), not toString()** for string conversion.
- **Only use for-in loops** - there are no while loops in NPL.
- **Multiple parties in single permission**: Use `permission[buyer | seller]` not multiple declarations.
- **Use length() for Text, not size()**.
- **List.without() removes elements, not indices**.
- **Invoke permissions with this. and party**: `this.startProcessing[provider]();`
- **DateTime methods require inclusive parameter**: `if (deadline.isBefore(now(), false)) { ... };`
- **Don't hallucinate methods**: Only use methods explicitly listed in this document.
- **Immutable collections**: `with()` and `without()` create new collections.

## Folder Structure Guidelines

- **Entry Point**: The project entry point is always a `migration.yml` file that defines migration changesets.
- **Source Files**: NPL source files are organized in versioned directories (e.g., `npl-1.0/`) as specified in the migration.yml file.
- **Test Files**: Test files should be placed in `src/test/npl/` mirroring the source structure.

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

- **Logging**: `debug()`, `info()`, `error()`
- **Constructors**: `listOf()`, `setOf()`, `mapOf()`, `optionalOf()`, `dateTimeOf()`, `localDateOf()`
- **Time and Duration**: `now()`, `millis()`, `seconds()`, `minutes()`, `hours()`, `days()`, `weeks()`, `months()`, `years()`

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

- **Boolean Methods**: `not()`

- **DateTime Methods**:
  - `day()`, `month()`, `year()`, `nano()`, `second()`, `minute()`, `hour()`, `zoneId()`
  - `firstDayOfYear()`, `lastDayOfYear()`, `firstDayOfMonth()`, `lastDayOfMonth()`, `startOfDay()`
  - `durationUntil()`, `isAfter()`, `isBefore()`, `isBetween()`, `withZoneSameLocal()`, `withZoneSameInstant()`
  - `plus()`, `minus()`, `toLocalDate()`, `dayOfWeek()`

- **Duration Methods**: `toSeconds()`, `plus()`, `minus()`, `multiplyBy()`

- **LocalDate Methods**:
  - `day()`, `month()`, `year()`, `firstDayOfYear()`, `lastDayOfYear()`, `firstDayOfMonth()`, `lastDayOfMonth()`
  - `isAfter()`, `isBefore()`, `isBetween()`, `plus()`, `minus()`, `periodUntil()`, `atStartOfDay()`, `dayOfWeek()`

- **Period Methods**: `plus()`, `minus()`, `multiplyBy()`

- **Optional Methods**: `isPresent()`, `getOrElse()`, `getOrFail()`, `computeIfAbsent()`

- **Party Methods**: `isRepresentableBy()`, `mayRepresent()`, `claims()`

- **Protocol Methods**: `parties()`, `activeState()`, `initialState()`, `finalStates()`

- **Blob Methods**: `filename()`, `mimeType()`

- **Symbol Methods**:
  - `toNumber()`, `unit()`, `plus()`, `minus()`, `multiplyBy()`, `divideBy()`, `remainder()`, `negative()`
  - `lessThan()`, `greaterThan()`, `lessThanOrEqual()`, `greaterThanOrEqual()`

- **General Methods**: All types have `toText()` for string conversion.

---

# NPL Frontend Development

## OpenAPI Integration

- All backend API endpoints are defined in the OpenAPI specification. Do not invent or hallucinate endpoints.
- Only use the functions provided in the generated OpenAPI client (typically found in `src/generated/`).
- Ensure all API payloads and return types strictly match the OpenAPI specification.

## Party Representation

Party objects identify users and must use the following structure: `{ "claims": { "key": ["value"] } }`
- For individuals, use the email key: `{ "claims": { "email": ["user@example.com"] } }`
- For groups, use the relevant identifying attribute as the key.
- Leave claims empty for parties accessible by all users.

## Frontend Development Rules

- Use React with TypeScript and functional components.
- Use React Hooks for state and effect management.
- Use React Hook Form for form handling.
- Implement proper TypeScript types and interfaces throughout.
- Create reusable UI components and follow component composition best practices.
- Implement responsive design and maintain consistent spacing and typography.

## Authorization

- Use OIDC (OpenID Connect) standard flow for authentication and authorization.
- Keycloak is provided by Noumena Cloud and configured in `src/auth/keycloak.ts`.

## Build and Deployment

- Run `npm run build` to generate the production-ready `dist` directory.
- Use "🌐 Deploy Frontend" workflow button to deploy to Noumena Cloud.

---

## NPL CLI Commands

- `npl check --source ./npl` - Validate NPL code
- `npl test --test-source-dir ./npl` - Run NPL tests
- `npl cloud login` - Authenticate to Noumena Cloud
- `npl cloud deploy npl` - Deploy NPL protocols to cloud
- `npl cloud deploy frontend` - Deploy frontend to cloud

## Tech Stack

- **Frontend**: React 19, TypeScript, Vite
- **Auth**: Keycloak JS, @react-keycloak/web
- **API**: OpenAPI-generated TypeScript client
- **Backend**: Noumena Cloud (NPL Engine)
