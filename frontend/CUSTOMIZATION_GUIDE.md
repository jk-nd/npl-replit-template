# Frontend Customization Guide for AI Agents

This guide helps AI agents adapt this NPL frontend template to different protocol use cases.

> **Prerequisites**: Read `docs/NPL_FRONTEND_DEVELOPMENT.md` first to understand NPL concepts like parties, claims, and the `@actions` array.

## Current Implementation

This frontend is configured for an **IOU (I Owe You)** protocol with the following entities:
- **Protocol**: `Iou`
- **Parties**: `issuer`, `payee`
- **States**: `unpaid`, `paid`, `forgiven`
- **Actions**: `pay(amount)`, `forgive()`, `getAmountOwed()`
- **Fields**: `forAmount` (Number)

## Files That Need Customization

### 1. API Layer (`src/api/`)

#### `src/api/types.ts`
**Purpose**: Type exports and helper functions for your protocol.

**What to change**:
```typescript
// Current IOU-specific exports:
export type Iou = components['schemas']['Iou']
export type IouList = components['schemas']['Iou_List']
export type IouCreate = components['schemas']['Iou_Create']
export type IouStates = components['schemas']['Iou_States']
export type IouPayCommand = components['schemas']['Iou_Pay_Command']

// Replace with your protocol (e.g., for a Booking protocol):
export type Booking = components['schemas']['Booking']
export type BookingList = components['schemas']['Booking_List']
export type BookingCreate = components['schemas']['Booking_Create']
export type BookingStates = components['schemas']['Booking_States']
export type BookingConfirmCommand = components['schemas']['Booking_Confirm_Command']
```

**Party helpers** (keep these, they're reusable):
```typescript
export function partyFromEmail(email: string): Party { ... }
export function getPartyEmail(party: Party): string { ... }
```

### 2. Dashboard Component (`src/components/dashboard/Dashboard.tsx`)

**Purpose**: Main business logic and data management.

**Key areas to customize**:

#### State management
```typescript
// Current:
const [ious, setIous] = useState<Iou[]>([])

// Change to:
const [bookings, setBookings] = useState<Booking[]>([])
```

#### API calls
```typescript
// Current GET list:
const { data, error: apiError } = await client.GET('/npl/demo/Iou/')

// Change to:
const { data, error: apiError } = await client.GET('/npl/demo/Booking/')
```

#### Create action
```typescript
// Current:
const { error: apiError } = await client.POST('/npl/demo/Iou/', {
  body: {
    '@parties': {
      issuer: partyFromEmail(userEmail),
      payee: partyFromEmail(payeeEmail)
    },
    forAmount: amount
  }
})

// Example for Booking:
const { error: apiError } = await client.POST('/npl/demo/Booking/', {
  body: {
    '@parties': {
      host: partyFromEmail(userEmail),
      guest: partyFromEmail(guestEmail)
    },
    roomNumber: roomNum,
    checkIn: checkInDate,
    checkOut: checkOutDate
  }
})
```

#### Protocol-specific actions
```typescript
// Current IOU actions:
const handlePay = async (iouId: string, amount: number) => { ... }
const handleForgive = async (iouId: string) => { ... }

// Example Booking actions:
const handleConfirm = async (bookingId: string) => {
  const { error: apiError } = await client.POST('/npl/demo/Booking/{id}/confirm', {
    params: { path: { id: bookingId } }
  })
}

const handleCancel = async (bookingId: string, reason: string) => {
  const { error: apiError } = await client.POST('/npl/demo/Booking/{id}/cancel', {
    params: { path: { id: bookingId } },
    body: { reason }
  })
}
```

#### JSX rendering
Update the component name in the map:
```typescript
// Current:
{ious.map((iou) => (
  <IouCard key={iou['@id']} iou={iou} ... />
))}

// Change to:
{bookings.map((booking) => (
  <BookingCard key={booking['@id']} booking={booking} ... />
))}
```

### 3. Card Component (`src/components/iou/IouCard.tsx`)

**Purpose**: Display individual protocol instance with available actions.

**Steps to customize**:

1. **Rename the file**: `src/components/booking/BookingCard.tsx`

2. **Update types and props**:
```typescript
// Current:
interface IouCardProps {
  iou: Iou
  currentUser: string
  onPay: (id: string, amount: number) => void
  onForgive: (id: string) => void
}

// Change to match your protocol:
interface BookingCardProps {
  booking: Booking
  currentUser: string
  onConfirm: (id: string) => void
  onCancel: (id: string, reason: string) => void
}
```

3. **Extract protocol-specific data**:
```typescript
// Current IOU:
const issuerEmail = getPartyEmail(iou['@parties'].issuer)
const payeeEmail = getPartyEmail(iou['@parties'].payee)
const forAmount = iou.forAmount
const state = iou['@state']

// Example Booking:
const hostEmail = getPartyEmail(booking['@parties'].host)
const guestEmail = getPartyEmail(booking['@parties'].guest)
const roomNumber = booking.roomNumber
const checkIn = booking.checkIn
const checkOut = booking.checkOut
const state = booking['@state']
```

4. **Update role-based logic**:
```typescript
// Current:
const isIssuer = issuerEmail === currentUser
const isPayee = payeeEmail === currentUser

// Example:
const isHost = hostEmail === currentUser
const isGuest = guestEmail === currentUser
```

5. **Update state checks**:
```typescript
// Current:
const isPaid = state === 'paid'
const isForgiven = state === 'forgiven'
const isActive = !isPaid && !isForgiven

// Example:
const isConfirmed = state === 'confirmed'
const isCancelled = state === 'cancelled'
const isPending = state === 'pending'
```

6. **Customize the UI**:
```typescript
// Display protocol-specific information
<div className="booking-details">
  <div className="detail">
    <span className="label">Room</span>
    <span className="value">{roomNumber}</span>
  </div>
  <div className="detail">
    <span className="label">Check In</span>
    <span className="value">{new Date(checkIn).toLocaleDateString()}</span>
  </div>
  <div className="detail">
    <span className="label">Check Out</span>
    <span className="value">{new Date(checkOut).toLocaleDateString()}</span>
  </div>
</div>
```

7. **Update action buttons**:
```typescript
// Replace IOU-specific actions with your protocol's actions
{isHost && isPending && (
  <button onClick={() => onConfirm(booking['@id'])}>
    Confirm Booking
  </button>
)}

{(isHost || isGuest) && !isCancelled && (
  <button onClick={() => handleCancelClick(booking['@id'])}>
    Cancel
  </button>
)}
```

### 4. Create Modal (`src/components/iou/CreateIouModal.tsx`)

**Purpose**: Form for creating new protocol instances.

**Steps to customize**:

1. **Rename file**: `src/components/booking/CreateBookingModal.tsx`

2. **Update component and props**:
```typescript
// Current:
interface CreateIouModalProps {
  onSubmit: (payeeEmail: string, amount: number) => void
  onClose: () => void
}

// Change to:
interface CreateBookingModalProps {
  onSubmit: (guestEmail: string, roomNumber: string, checkIn: string, checkOut: string) => void
  onClose: () => void
}
```

3. **Update form state**:
```typescript
// Current:
const [payeeEmail, setPayeeEmail] = useState('')
const [amount, setAmount] = useState('')

// Change to:
const [guestEmail, setGuestEmail] = useState('')
const [roomNumber, setRoomNumber] = useState('')
const [checkIn, setCheckIn] = useState('')
const [checkOut, setCheckOut] = useState('')
```

4. **Update form fields**:
```typescript
<div className="form-group">
  <label htmlFor="guestEmail">Guest Email</label>
  <input
    id="guestEmail"
    type="email"
    value={guestEmail}
    onChange={(e) => setGuestEmail(e.target.value)}
    required
  />
</div>

<div className="form-group">
  <label htmlFor="roomNumber">Room Number</label>
  <input
    id="roomNumber"
    type="text"
    value={roomNumber}
    onChange={(e) => setRoomNumber(e.target.value)}
    required
  />
</div>

<div className="form-group">
  <label htmlFor="checkIn">Check In Date</label>
  <input
    id="checkIn"
    type="date"
    value={checkIn}
    onChange={(e) => setCheckIn(e.target.value)}
    required
  />
</div>

<div className="form-group">
  <label htmlFor="checkOut">Check Out Date</label>
  <input
    id="checkOut"
    type="date"
    value={checkOut}
    onChange={(e) => setCheckOut(e.target.value)}
    required
  />
</div>
```

5. **Update submit handler**:
```typescript
const handleSubmit = (e: React.FormEvent) => {
  e.preventDefault()
  if (guestEmail && roomNumber && checkIn && checkOut) {
    onSubmit(guestEmail, roomNumber, checkIn, checkOut)
  }
}
```

### 5. Generated OpenAPI Types (`src/generated/demo/api-types.ts`)

**This file is auto-generated** - regenerate it after changing your NPL protocol:

```bash
# Run from your project root after NPL changes
npm run generate:api
# or
openapi-typescript openapi/demo-openapi.yml -o frontend/src/generated/demo/api-types.ts
```

## Reusable Components (No Changes Needed)

These components are protocol-agnostic and can be reused as-is:

- ✅ `src/components/auth/` - All authentication components
- ✅ `src/components/shared/LoadingState.tsx` - Loading spinner
- ✅ `src/api/client.ts` - OpenAPI fetch client (uses engine URL only; generated paths include `/npl/{package}`)
- ✅ `src/App.tsx` - Main app routing

**Important:** When switching to your own package, you only need to update the **import path** in `client.ts` (e.g., `from '../generated/demo/api-types'` → `from '../generated/mypackage/api-types'`). Do NOT append `/npl/{package}` to the base URL - the generated OpenAPI paths already include it.

## Step-by-Step Customization Process

### 1. Update NPL Backend
First, modify your NPL protocol definition and redeploy.

### 2. Regenerate OpenAPI Types
```bash
# Generate new OpenAPI spec from deployed NPL
npm run generate:api
```

### 3. Update Type Exports
Edit `src/api/types.ts` to export your protocol types:
```typescript
export type MyProtocol = components['schemas']['MyProtocol']
export type MyProtocolList = components['schemas']['MyProtocol_List']
export type MyProtocolCreate = components['schemas']['MyProtocol_Create']
// ... etc
```

### 4. Rename Component Folders
```bash
mv src/components/iou src/components/myprotocol
```

### 5. Update Dashboard
Edit `src/components/dashboard/Dashboard.tsx`:
- Update state variables
- Update API endpoints (e.g., `/npl/demo/MyProtocol/`)
- Update action handlers
- Update JSX to use new component names

### 6. Update Card Component
Edit your renamed card component:
- Update props interface
- Update data extraction
- Update role checks
- Update UI display
- Update action buttons

### 7. Update Create Modal
Edit your renamed modal component:
- Update props interface
- Update form fields
- Update validation
- Update submit handler

### 8. Test and Build
```bash
npm run test:ts  # Check types
npm run build    # Build for production
npm run dev      # Test locally
```

## Common Patterns

### Party Management
Always use the helper functions:
```typescript
// Creating a party
const party = partyFromEmail('user@example.com')

// Extracting email from party
const email = getPartyEmail(someParty)
```

### Error Handling
Follow this pattern consistently:
```typescript
try {
  setError(null)
  const { data, error: apiError } = await client.POST(...)
  if (apiError) {
    throw new Error(apiError.message || 'Operation failed')
  }
  // Success handling
} catch (err) {
  setError(err instanceof Error ? err.message : 'Operation failed')
}
```

### State Management
Keep it simple with useState:
```typescript
const [items, setItems] = useState<YourType[]>([])
const [loading, setLoading] = useState(true)
const [error, setError] = useState<string | null>(null)
```

### API Calls
Use openapi-fetch patterns:
```typescript
// GET
const { data, error } = await client.GET('/npl/demo/Protocol/')

// POST with body
const { data, error } = await client.POST('/npl/demo/Protocol/', {
  body: { ... }
})

// POST action with params
const { error } = await client.POST('/npl/demo/Protocol/{id}/action', {
  params: { path: { id: protocolId } },
  body: { ... }
})
```

## Example: Complete Booking Protocol Customization

Here's a complete example of adapting this template for a hotel booking system:

### Protocol Definition (NPL)
```npl
protocol[host, guest] Booking(
  var roomNumber: Text,
  var checkIn: LocalDate,
  var checkOut: LocalDate
) {
  initial state pending;
  state confirmed;
  final state completed;
  final state cancelled;

  permission[host] confirm() | pending { become confirmed; };
  permission[host | guest] cancel(reason: Text) | pending, confirmed { become cancelled; };
}
```

### Updated Files Summary
1. **types.ts**: Export `Booking`, `BookingList`, etc.
2. **Dashboard.tsx**: 
   - State: `bookings`, `setBookings`
   - Endpoints: `/npl/demo/Booking/`
   - Actions: `handleConfirm`, `handleCancel`
3. **BookingCard.tsx**: Display room, dates, host/guest info
4. **CreateBookingModal.tsx**: Form with guest email, room number, dates

## Tips for AI Agents

1. **Always regenerate types** after NPL changes
2. **Keep party helpers unchanged** - they're protocol-agnostic
3. **Maintain error handling patterns** - consistency is key
4. **Update all references** - search for old protocol name across all files
5. **Test after each major change** - use `npm run test:ts`
6. **Follow naming conventions** - PascalCase for components, camelCase for functions
7. **Preserve authentication flow** - focus on business logic only

## Validation Checklist

- [ ] NPL protocol deployed and OpenAPI spec generated
- [ ] `api-types.ts` regenerated from new OpenAPI spec
- [ ] Type exports updated in `src/api/types.ts`
- [ ] Component folders renamed
- [ ] Dashboard state and API calls updated
- [ ] Card component customized for protocol display
- [ ] Create modal form fields match protocol constructor
- [ ] All imports updated to new component names
- [ ] TypeScript compilation passes (`npm run test:ts`)
- [ ] Production build succeeds (`npm run build`)
- [ ] Manual testing with development server (`npm run dev`)
