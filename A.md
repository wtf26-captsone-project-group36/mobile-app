# Hervest AI - Complete API Endpoints Documentation

## Overview
The Hervest AI backend is built with **Node.js + Express** and connects to **Supabase** (PostgreSQL) for data persistence. The Flutter mobile app communicates with the API through dedicated API service classes in the `lib/core/network/` folder.

**Base URL**: `http://18.175.213.46:3000` (can be overridden with `API_BASE_URL` environment variable)
**API Prefix**: `/api`

---

## 1. AUTHENTICATION ENDPOINTS ✅ (FUNCTIONAL)

### Overview
Authentication is implemented using **JWT tokens** with access tokens and refresh tokens. User verification uses **OTP (One-Time Passwords)** sent via email.

### Endpoints Detail

#### 1.1 Sign Up
**Endpoint**: `POST /api/auth/signup`

**Purpose**: Create a new user account with business details.

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "full_name": "John Doe",
  "business_type": "restaurant",
  "business_name": "John's Restaurant",
  "role": "owner",
  "phone": "+234801234567"
}
```

**Response** (200):
```json
{
  "message": "Verification code sent to your email. Please verify to complete signup.",
  "email": "user@example.com"
}
```

**How It's Implemented**:
- Validates required fields and business type
- Password must be ≥8 characters
- Generates OTP and stores it with user data in memory
- Sends OTP via email
- Cleans up unverified accounts older than 10 minutes

**Frontend Implementation**:
- [lib/core/network/auth_api_service.dart](lib/core/network/auth_api_service.dart#L28) - `signUp()` method calls this endpoint
- Located in [Features → Onboarding → Sign Up Page](lib/features/onboarding/onboarding_first_page.dart)

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

#### 1.2 Verify Sign Up
**Endpoint**: `POST /api/auth/signup/verify`

**Purpose**: Verify OTP and complete user registration.

**Request Body**:
```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

**Response** (200):
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "user": {
    "id": "uuid-1234",
    "email": "user@example.com",
    "full_name": "John Doe",
    "business_id": "b-uuid-123"
  }
}
```

**Implementation Details**:
- Verifies OTP against stored value
- Creates Supabase auth user
- Stores user profile in database
- Returns JWT tokens for session management

**Frontend**:
- [lib/core/network/auth_api_service.dart](lib/core/network/auth_api_service.dart#L53) - `verifySignUp()` method
- Tokens stored in [AppSessionStore](lib/core/storage/app_session_store.dart)

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

#### 1.3 Sign In
**Endpoint**: `POST /api/auth/signin`

**Purpose**: Authenticate existing user.

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response** (200):
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "user": { /* user object */ }
}
```

**Frontend**:
- [lib/core/network/auth_api_service.dart](lib/core/network/auth_api_service.dart#L65) - `signIn()` method
- Login UI page

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

#### 1.4 Refresh Token
**Endpoint**: `POST /api/auth/refresh`

**Purpose**: Generate new access token using refresh token.

**Implementation**: Rate limited to 10 attempts per 15 minutes

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

#### 1.5 Password Reset - Send OTP
**Endpoint**: `POST /api/auth/password/reset`

**Purpose**: Initiate password reset by sending OTP to email.

**Request Body**:
```json
{
  "email": "user@example.com"
}
```

**Frontend**:
- [lib/core/network/auth_api_service.dart](lib/core/network/auth_api_service.dart#L72) - `sendPasswordResetOtp()` method

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

#### 1.6 Password Reset - Verify OTP & Reset
**Endpoint**: `POST /api/auth/password/verify`

**Purpose**: Verify OTP and set new password.

**Request Body**:
```json
{
  "email": "user@example.com",
  "otp": "123456",
  "new_password": "newSecurePassword123"
}
```

**Frontend**:
- [lib/core/network/auth_api_service.dart](lib/core/network/auth_api_service.dart#L85) - `verifyOtpAndResetPassword()` method

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

#### 1.7 Sign Out
**Endpoint**: `POST /api/auth/signout`

**Purpose**: Logout user and invalidate tokens.

**Authentication**: Required (Bearer token)

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

#### 1.8 Get Profile
**Endpoint**: `GET /api/auth/profile`

**Purpose**: Fetch current user's profile.

**Authentication**: Required (Bearer token)

**Response** (200):
```json
{
  "user_id": "uuid-1234",
  "email": "user@example.com",
  "full_name": "John Doe",
  "business_name": "John's Restaurant",
  "business_type": "restaurant",
  "phone": "+234801234567",
  "business_id": "b-uuid-123"
}
```

**Frontend**:
- Called in [ProfileController](lib/provider/profile_controller.dart) via `_syncFromBackend()`
- Displayed on [Profile Page](lib/pages/profile_page.dart)

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

#### 1.9 Update Profile
**Endpoint**: `PUT /api/auth/profile`

**Purpose**: Update user profile information.

**Request Body**:
```json
{
  "full_name": "John Doe Updated",
  "phone": "+234801234567",
  "business_name": "John's Updated Restaurant"
}
```

**Frontend**:
- [ProfileController](lib/provider/profile_controller.dart) - `updateProfile()` method

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

#### 1.10 Delete User
**Endpoint**: `DELETE /api/auth/user/:id`

**Purpose**: Delete user account (owner role only).

**Authentication**: Required + `requireRole('owner')` middleware

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

## 2. INVENTORY ENDPOINTS ✅ (FUNCTIONAL)

### Overview
Manages inventory items with stock tracking, expiry date monitoring, and low-stock alerts.

### Endpoints Detail

#### 2.1 Create Inventory Item
**Endpoint**: `POST /api/inventory`

**Purpose**: Add new inventory item.

**Request Body**:
```json
{
  "name": "Golden Penny Beans",
  "sku": "GP-001",
  "category": "Grains",
  "quantity": 100,
  "unit": "kg",
  "purchase_price": 5000,
  "reorder_level": 20,
  "expiry_date": "2026-06-15",
  "location": "Warehouse A"
}
```

**Response** (201):
```json
{
  "message": "Inventory item created",
  "item": {
    "item_id": "inv-uuid-123",
    "item_name": "Golden Penny Beans",
    "quantity": 100,
    "category": "Grains",
    "created_at": "2026-02-24T10:30:00Z"
  }
}
```

**Backend Logic**:
- Validates required fields (name, quantity)
- Stores item in Supabase `inventory` table
- **Auto-creates low-stock alert** if quantity ≤ reorder_level
- Logs activity with [ActivityLogger](lib/features/activity/services/activity_logger.dart)

**Frontend Implementation**:
- [InventoryApiService](lib/core/network/inventory_api_service.dart#L11) - `createInventoryItem()` method
- **UI Flow**: [Inventory Page 2](lib/bottom_navigation/inventory_page_two.dart) - User fills form → calls `addItemFromApi()` in [InventoryProvider](lib/provider/inventory_provider.dart)
- **Displayed on**: [Inventory Page 1](lib/bottom_navigation/inventory_screen.dart) - Shows all items in a list with status badges

**Status**: ✅ **FUNCTIONAL** - Connected to backend and displayed on UI

---

#### 2.2 Get Inventory Items
**Endpoint**: `GET /api/inventory?category=Grains&low_stock=true&search=beans`

**Purpose**: Fetch inventory items with filtering and pagination.

**Query Parameters**:
- `category`: Filter by category
- `low_stock`: Show only low-stock items (true/false)
- `expiring_soon_days`: Show items expiring within N days
- `search`: Search by item name or SKU
- `limit`: Results per page (default: 50)
- `offset`: Pagination offset (default: 0)
- `order_by`: Sort field (default: created_at)
- `order_dir`: Sort direction (asc/desc)

**Response** (200):
```json
{
  "items": [
    {
      "item_id": "inv-uuid-123",
      "item_name": "Golden Penny Beans",
      "quantity": 100,
      "category": "Grains",
      "expiry_date": "2026-06-15",
      "purchase_price": 5000,
      "quantity_status": "normal" | "low" | "expired"
    }
  ],
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

**Backend Logic**:
- Filters items by business_id (from authenticated user's profile)
- Checks stock levels and expiry dates
- Returns paginated results

**Frontend Implementation**:
- [InventoryApiService](lib/core/network/inventory_api_service.dart#L22) - `getInventory()` method
- **Called automatically** when [InventoryProvider](lib/provider/inventory_provider.dart#L12) initializes via `loadFromBackend()`
- **Displayed on**:
  - [Inventory Screen](lib/bottom_navigation/inventory_screen.dart) - Main inventory list
  - Shows items with color-coded badges:
    - 🟢 **Green**: Normal stock
    - 🟠 **Orange**: Low stock / Expiring soon
    - 🔴 **Red**: Expired / Missing data

**Status**: ✅ **FUNCTIONAL** - Connected to backend and displayed on UI

---

#### 2.3 Update Inventory Item
**Endpoint**: `PUT /api/inventory/:id`

**Purpose**: Update existing inventory item.

**Request Body**:
```json
{
  "quantity": 80,
  "expiry_date": "2026-06-20"
}
```

**Response** (200):
```json
{
  "message": "Inventory item updated",
  "item": { /* updated item data */ }
}
```

**Frontend Implementation**:
- [InventoryApiService](lib/core/network/inventory_api_service.dart#L38) - `updateInventoryItem()` method
- [InventoryProvider](lib/provider/inventory_provider.dart#L54) - `updateItemFromApi()` method performs optimistic update and syncs with backend
- Used when user edits quantity or other details

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

#### 2.4 Delete Inventory Item
**Endpoint**: `DELETE /api/inventory/:id`

**Purpose**: Remove inventory item.

**Response** (200):
```json
{
  "message": "Inventory item deleted"
}
```

**Frontend Implementation**:
- [InventoryApiService](lib/core/network/inventory_api_service.dart#L53) - `deleteInventoryItem()` method
- [InventoryProvider](lib/provider/inventory_provider.dart#L100) - `deleteItemFromApi()` method
- Called when user presses delete button with confirmation dialog

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

## 3. CASHFLOW / TRANSACTION ENDPOINTS ✅ (FUNCTIONAL)

### Overview
Tracks business income and expenses to calculate cash runway and financial health metrics.

### Endpoints Detail

#### 3.1 Create Transaction
**Endpoint**: `POST /api/transactions`

**Purpose**: Log a financial transaction (income, expense, refund, adjustment).

**Request Body**:
```json
{
  "type": "income",
  "amount": 50000,
  "category": "Sales",
  "description": "Marketplace sale",
  "transaction_date": "2026-02-24"
}
```

**Response** (201):
```json
{
  "message": "Transaction logged",
  "transaction": {
    "transaction_id": "txn-uuid-123",
    "type": "income",
    "amount": 50000,
    "date": "2026-02-24T00:00:00Z",
    "category": "Sales",
    "created_at": "2026-02-24T10:30:00Z"
  }
}
```

**Valid Type Values**: `"income"`, `"expense"`, `"refund"`, `"adjustment"`

**Backend Logic**:
- Validates transaction type
- Stores in Supabase `transactions` table
- Logs activity for audit trail
- Triggers anomaly detection for unusual patterns

**Frontend Implementation**:
- [CashflowApiService](lib/core/network/cashflow_api_service.dart#L24) - `createTransaction()` method
- **UI**: [Add Transaction Page](lib/pages/add_transaction_page.dart)
- User enters amount, category, description

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

#### 3.2 Get Transactions
**Endpoint**: `GET /api/transactions?type=income&from_date=2026-01-01&to_date=2026-02-28`

**Purpose**: Fetch transactions with filtering by date range, type, and category.

**Query Parameters**:
- `type`: Filter by transaction type (income/expense/refund/adjustment)
- `category`: Filter by category
- `from_date`: Start date (YYYY-MM-DD)
- `to_date`: End date (YYYY-MM-DD)
- `limit`: Results per page (default: 50)
- `offset`: Pagination offset

**Response** (200):
```json
{
  "transactions": [
    {
      "transaction_id": "txn-uuid-123",
      "type": "income",
      "amount": 50000,
      "category": "Sales",
      "description": "Marketplace sale",
      "date": "2026-02-24T00:00:00Z"
    }
  ],
  "total": 5,
  "limit": 50
}
```

**Frontend Implementation**:
- [CashflowApiService](lib/core/network/cashflow_api_service.dart#L8) - `getTransactions()` method
- Called in [CashflowProvider](lib/provider/cashflow_provider.dart) to load transaction list
- **Displayed on**:
  - [Cashflow Overview Page](lib/bottom_navigation/cashflow_overview_page.dart) - Recent transactions
  - [Transactions List Page](lib/pages/transactions_list_page.dart) - Full transaction history

**Status**: ✅ **FUNCTIONAL** - Connected to backend and displayed on UI

---

#### 3.3 Get Cashflow Report
**Endpoint**: `GET /api/transactions/report`

**Purpose**: Get financial summary (income, expenses, balance, cash runway).

**Response** (200):
```json
{
  "report": {
    "total_income": 500000,
    "total_expense": 350000,
    "balance": 150000,
    "cash_runway_days": 42,
    "average_daily_burn": 3571,
    "period": "current_month",
    "transactions_count": 25
  }
}
```

**Backend Logic**:
- Aggregates all transactions for the business
- Calculates average daily spending
- Projects days until cash runs out (runway)
- Returns summary metrics

**Frontend Implementation**:
- [CashflowApiService](lib/core/network/cashflow_api_service.dart#L38) - `getCashflowReport()` method
- Called in [Dashboard Page](lib/pages/dashboard_page.dart) to show financial health
- **Displayed on**:
  - [Cashflow Overview Page](lib/bottom_navigation/cashflow_overview_page.dart) - Shows:
    - "₦250,000" Available balance
    - "42 days remaining" Cash runway
    - Income vs Expenses breakdown

**Status**: ✅ **FUNCTIONAL** - Connected to backend and displayed on UI

---

## 4. ALERTS ENDPOINTS ✅ (FUNCTIONAL)

### Overview
Notifies users about risks: low stock, expired items, surplus availability, etc.

### Endpoints Detail

#### 4.1 Get Alerts
**Endpoint**: `GET /api/alerts?severity=high&is_read=false`

**Purpose**: Fetch user's alerts with filtering.

**Query Parameters**:
- `alert_type`: Filter by type (expiry_warning, low_stock, overstock, surplus_available)
- `severity`: Filter by severity (low, medium, high, critical)
- `is_read`: Filter by read status (true/false)
- `limit`: Results per page (default: 20)
- `offset`: Pagination offset

**Response** (200):
```json
{
  "alerts": [
    {
      "alert_id": "alrt-uuid-123",
      "alert_type": "low_stock",
      "severity": "high",
      "message": "Golden Penny Beans quantity is at 15 units - below reorder level",
      "inventory": {
        "item_name": "Golden Penny Beans",
        "quantity": 15,
        "unit": "kg"
      },
      "is_read": false,
      "created_at": "2026-02-24T10:30:00Z"
    }
  ],
  "total": 3
}
```

**Backend Logic**:
- Filters alerts by user_id
- Includes related inventory data
- Orders by creation date (newest first)

**Frontend Implementation**:
- [AlertsApiService](lib/core/network/alerts_api_service.dart#L9) - `getAlerts()` method
- Called in Alert Provider to load alerts list
- **Displayed on**:
  - [Alerts Screen / Notifications](lib/pages/alerts_page.dart) - Shows all alerts with icons and severity colors
  - **Auto-triggered alerts** when:
    - New low-stock item added
    - Item quantity drops below reorder level
    - Item expires

**Status**: ✅ **FUNCTIONAL** - Connected to backend and displayed on UI

---

#### 4.2 Mark Alert as Read
**Endpoint**: `PUT /api/alerts/:id/read`

**Purpose**: Mark alert as read (dismiss from notification).

**Response** (200):
```json
{
  "alert": { /* updated alert */ },
  "status": "updated"
}
```

**Frontend Implementation**:
- [AlertsApiService](lib/core/network/alerts_api_service.dart#L15) - `markAlertRead()` method

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

#### 4.3 Resolve Alert
**Endpoint**: `PUT /api/alerts/:id/resolve`

**Purpose**: Mark alert as resolved (closed/archived).

**Response** (200):
```json
{
  "alert": { /* updated alert */ },
  "status": "resolved"
}
```

**Frontend Implementation**:
- [AlertsApiService](lib/core/network/alerts_api_service.dart#L21) - `resolveAlert()` method

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

#### 4.4 Create Alert (Backend Only)
**Endpoint**: `POST /api/alerts`

**Purpose**: Insert alert (typically called by backend for auto-triggers like low stock).

**Request Body**:
```json
{
  "user_id": "user-uuid-123",
  "inventory_id": "inv-uuid-123",
  "alert_type": "low_stock",
  "message": "Item quantity is below reorder level",
  "severity": "high",
  "metadata": { }
}
```

**Note**: This endpoint is typically called by backend services (not from Flutter app) to automatically create alerts when:
- New inventory item added with low quantity
- Stock level drops below reorder point
- Item expiry date is approaching

**Status**: ✅ **FUNCTIONAL** - Backend creates automatically

---

## 5. SURPLUS MARKETPLACE ENDPOINTS ✅ (FUNCTIONAL)

### Overview
Enables businesses to list excess inventory for sale or donation to other businesses.

### Endpoints Detail

#### 5.1 Get Available Surplus
**Endpoint**: `GET /api/surplus?location=Lagos&limit=20`

**Purpose**: Browse marketplace surplus items from other businesses.

**Query Parameters**:
- `location`: Filter by location/city
- `limit`: Results per page (default: 20)
- `offset`: Pagination offset

**Response** (200):
```json
{
  "surplus": [
    {
      "surplus_id": "surp-uuid-123",
      "name": "Ripe Tomatoes",
      "quantity": 50,
      "unit": "kg",
      "description": "Fresh tomatoes - high quality",
      "is_free": true,
      "price": 0,
      "expiry_date": "2026-02-28",
      "location": "Lagos",
      "status": "available",
      "owner": {
        "full_name": "Farmer John",
        "business_name": "John's Farm",
        "business_type": "farmer"
      },
      "created_at": "2026-02-24T10:30:00Z"
    }
  ],
  "total": 15
}
```

**Frontend Implementation**:
- [SurplusApiService](lib/core/network/surplus_api_service.dart#L8) - `getAvailableSurplus()` method
- Called in [SurplusProvider](lib/provider/surplus_provider.dart)
- **Displayed on**: [Surplus Marketplace Page](lib/pages/surplus_marketplace_page.dart)
  - Shows cards with item details, quantity, and "Claim" button
  - Filters by location and search

**Status**: ✅ **FUNCTIONAL** - Connected to backend and displayed on UI

---

#### 5.2 Get My Surplus
**Endpoint**: `GET /api/surplus/mine`

**Purpose**: View your own listed surplus items.

**Response** (200):
```json
{
  "surplus": [
    {
      "surplus_id": "surp-uuid-123",
      "name": "Excess Rice",
      "quantity": 100,
      "status": "available" | "claimed" | "expired",
      /* ... other fields ... */
    }
  ]
}
```

**Frontend Implementation**:
- [SurplusApiService](lib/core/network/surplus_api_service.dart#L20) - `getMySurplus()` method
- **Displayed on**: [My Surplus Items Page](lib/pages/my_surplus_page.dart)

**Status**: ✅ **FUNCTIONAL** - Connected to backend and displayed on UI

---

#### 5.3 Create Surplus
**Endpoint**: `POST /api/surplus`

**Purpose**: List excess inventory for sale/donation.

**Request Body**:
```json
{
  "inventory_id": "inv-uuid-123",
  "name": "Excess Rice",
  "quantity": 100,
  "unit": "kg",
  "description": "Quality rice - bulk sale",
  "expiry_date": "2026-06-15",
  "pickup_deadline": "2026-03-10",
  "is_free": false,
  "price": 50000,
  "location": "Lagos"
}
```

**Response** (201):
```json
{
  "message": "Surplus listed",
  "surplus": {
    "surplus_id": "surp-uuid-123",
    "status": "available"
  }
}
```

**Frontend Implementation**:
- [SurplusApiService](lib/core/network/surplus_api_service.dart#L33) - `createSurplus()` method
- **UI**: [Create Surplus Modal](lib/pages/create_surplus_page.dart)

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

#### 5.4 Claim Surplus
**Endpoint**: `PUT /api/surplus/:id/claim`

**Purpose**: Claim another business's surplus item to add to your inventory.

**Response** (200):
```json
{
  "message": "Surplus claimed",
  "surplus": {
    "surplus_id": "surp-uuid-123",
    "status": "claimed",
    "claimed_by": "user-uuid-456",
    "claimed_at": "2026-02-24T12:00:00Z"
  }
}
```

**Backend Logic**:
- Validates item is still available
- Marks item as claimed
- Records claiming user and timestamp
- May auto-add to claiming user's inventory

**Frontend Implementation**:
- [SurplusApiService](lib/core/network/surplus_api_service.dart#L47) - `claimSurplus()` method
- Called when user taps "Claim" button on marketplace item
- Updates UI to show "Claimed" status

**Status**: ✅ **FUNCTIONAL** - Connected to backend and displayed on UI

---

#### 5.5 Update Surplus Status
**Endpoint**: `PUT /api/surplus/:id/status`

**Purpose**: Update surplus item status (available → claimed → expired).

**Request Body**:
```json
{
  "status": "expired" | "claimed" | "available"
}
```

**Frontend Implementation**:
- [SurplusApiService](lib/core/network/surplus_api_service.dart#L61) - `updateSurplusStatus()` method
- Called when business manually marks item as no longer available

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

## 6. ACTIVITY LOG ENDPOINTS ✅ (FUNCTIONAL)

### Overview
Tracks all user actions for audit purposes and analytics.

### Endpoints Detail

#### 6.1 Get Activities
**Endpoint**: `GET /api/activity?limit=50&offset=0`

**Purpose**: Fetch user's activity history.

**Query Parameters**:
- `limit`: Results per page (default: 50)
- `offset`: Pagination offset (default: 0)

**Response** (200):
```json
{
  "activities": [
    {
      "activity_id": "act-uuid-123",
      "user_id": "user-uuid-123",
      "action": "inventory.insert",
      "entity_type": "inventory",
      "entity_id": "inv-uuid-123",
      "details": {
        "name": "Golden Penny Beans",
        "quantity": 100
      },
      "created_at": "2026-02-24T10:30:00Z"
    }
  ]
}
```

**Example Actions**: 
- `inventory.insert` - Item added
- `inventory.update` - Item updated
- `transaction.insert` - Transaction created
- `surplus.create` - Surplus listed
- `auth.signin` - User logged in

**Frontend Implementation**:
- [ActivityApiService](lib/core/network/activity_api_service.dart#L9) - `getActivities()` method
- **Displayed on**: [Activity Log Page](lib/pages/activity_log_page.dart) - Shows timeline of all user actions

**Status**: ✅ **FUNCTIONAL** - Connected to backend and displayed on UI

---

#### 6.2 Insert Activity (Backend Only)
**Endpoint**: `POST /api/activity`

**Purpose**: Log a user action (typically called by backend after operations).

**Request Body**:
```json
{
  "action": "inventory.insert",
  "entity_type": "inventory",
  "entity_id": "inv-uuid-123",
  "details": { "name": "Beans", "quantity": 100 }
}
```

**Backend Logic**:
- Automatically called after every operation:
  - When inventory item is added/updated/deleted
  - When transaction is created
  - When surplus is listed/claimed
  - When alerts are created

**Note**: Automatically logged by backend; Flutter app doesn't directly call this.

**Status**: ✅ **FUNCTIONAL** - Backend auto-logs activities

---

## 7. PREDICTION & ANALYTICS ENDPOINTS ⚠️ (PARTIALLY FUNCTIONAL)

### Overview
AI/ML endpoints for predictive analytics about cashflow, inventory risks, and expense anomalies. These endpoints accept data but the frontend doesn't extensively display predictions yet.

### Endpoints Detail

#### 7.1 Get Latest Predictions
**Endpoint**: `GET /api/predictions`

**Purpose**: Fetch latest cashflow and inventory predictions for the business.

**Response** (200):
```json
{
  "cashflow_prediction": {
    "prediction_id": "pred-uuid-123",
    "business_id": "b-uuid-123",
    "risk_level": "medium",
    "days_until_broke": 42,
    "confidence_score": 0.87,
    "created_at": "2026-02-20T00:00:00Z"
  },
  "inventory_prediction": {
    "prediction_id": "pred-uuid-456",
    "business_id": "b-uuid-123",
    "critical_items": 2,
    "warning_items": 5,
    "total_value_at_risk": 250000,
    "created_at": "2026-02-20T00:00:00Z"
  }
}
```

**Prediction Types**:
- **Cashflow Prediction**: Estimates days until business runs out of cash based on income/expense patterns
- **Inventory Prediction**: Identifies items at risk of expiry or overstock

**Frontend Implementation**:
- [PredictionsApiService](lib/core/network/predictions_api_service.dart#L8) - `getLatestPredictions()` method
- Called in [PredictionsProvider](lib/provider/predictions_provider.dart)
- **Displayed on**: [AI Insights Page](lib/pages/ai_insights_page.dart) - Shows risk assessment and recommendations

**Status**: ⚠️ **PARTIALLY FUNCTIONAL** - API connected but limited UI integration

---

#### 7.2 Get Anomalies
**Endpoint**: `GET /api/predictions/anomalies`

**Purpose**: Detect unusual spending patterns.

**Response** (200):
```json
{
  "anomalies": [
    {
      "anomaly_id": "anom-uuid-123",
      "transaction_id": "txn-uuid-123",
      "anomaly_level": "high",
      "z_score": 3.2,
      "deviation_percentage": 185,
      "message": "This expense is 185% higher than average for this category",
      "created_at": "2026-02-24T10:30:00Z"
    }
  ]
}
```

**Z-Score Explanation**: Statistical measure of how unusual a transaction is (>2.0 is unusual)

**Frontend Implementation**:
- [PredictionsApiService](lib/core/network/predictions_api_service.dart#L20) - `getAnomalies()` method
- **Displayed on**: Anomaly alerts when unusual expenses are detected

**Status**: ⚠️ **PARTIALLY FUNCTIONAL** - API connected but limited UI display

---

#### 7.3 Insert Predictions (Backend Only)
**Endpoints**:
- `POST /api/predictions/cashflow`
- `POST /api/predictions/inventory`
- `POST /api/predictions/anomalies`

**Purpose**: Backend machine learning service submits predictions.

**Example Request** (Cashflow):
```json
{
  "business_id": "b-uuid-123",
  "risk_level": "medium",
  "days_until_broke": 42,
  "confidence_score": 0.87
}
```

**Note**: These are typically called by a separate Python ML service that analyzes business data and generates predictions. Flutter app doesn't call these endpoints.

**Status**: ⚠️ **PARTIALLY FUNCTIONAL** - Backend receives predictions but ML service may not be active

---

## 8. HEALTH CHECK ENDPOINT

#### 8.1 API Health Check
**Endpoint**: `GET /api/health`

**Purpose**: Verify API server is running and healthy.

**Response** (200):
```json
{
  "status": "ok",
  "timestamp": "2026-02-24T10:30:00Z",
  "environment": "production"
}
```

**Frontend Implementation**:
- [ApiHealthService](lib/core/network/api_health_service.dart) - Used to verify backend connectivity before making requests
- Called automatically on app startup

**Status**: ✅ **FUNCTIONAL** - Connected to backend

---

## Implementation Architecture

### Frontend → Backend Communication Flow

```
Flutter Widget
    ↓
Provider (State Management)
    ↓
API Service (Dart Http Client)
    ↓
Express Route Handler
    ↓
Controller Logic
    ↓
Supabase Database
```

### Example: Adding an Inventory Item

1. **User Action**: Taps "Add Item" button on [Inventory Page 2](lib/bottom_navigation/inventory_page_two.dart)
2. **Form Submission**: User enters item details and taps "Submit"
3. **Provider Update**: [InventoryProvider.addItemFromApi()](lib/provider/inventory_provider.dart#L125) is called
4. **API Call**: [InventoryApiService.createInventoryItem()](lib/core/network/inventory_api_service.dart#L11) sends HTTP POST
5. **Backend Processing**: [inventoryController.insertItem()](api/src/controllers/inventoryController.js#L1)
   - Validates input
   - Checks reorder level
   - Auto-creates low-stock alert if needed
   - Logs activity
   - Saves to Supabase
6. **Response**: Returns created item data
7. **Local Update**: Provider updates local state and notifies listeners
8. **UI Render**: [Inventory Page 1](lib/bottom_navigation/inventory_screen.dart) rebuilds with new item
9. **Navigation**: Success page shown

---

## API Security Features

### Authentication
- JWT tokens with expiry and refresh mechanism
- Bearer token required for protected endpoints
- Sessions stored in device secure storage

### Rate Limiting
- General: 100 requests per 15 minutes
- Auth endpoints (signin/signup): 10 requests per 15 minutes per IP
- Prevents brute force and DDoS attacks

### Validation
- Input validation on all endpoints
- Business type whitelist validation
- Password strength requirements (≥8 characters)

### CORS
- Configured to accept requests from Flutter app
- Specified allowed origins, methods, and headers

### Database
- Row-level security in Supabase
- Users can only access their own business data
- Automatic filtering by business_id on all queries

---

## Functional Status Summary

| Feature | Endpoints | Status | UI Display |
|---------|-----------|--------|-----------|
| **Authentication** | SignUp, SignIn, Refresh, Profile | ✅ Functional | ✅ Full Integration |
| **Inventory Management** | Create, Read, Update, Delete | ✅ Functional | ✅ Full Integration |
| **Cashflow Tracking** | Transactions, Reports | ✅ Functional | ✅ Full Integration |
| **Alerts/Notifications** | Get, Mark Read, Resolve | ✅ Functional | ✅ Full Integration |
| **Surplus Marketplace** | Browse, Create, Claim, Status | ✅ Functional | ✅ Full Integration |
| **Activity Logging** | Get Activities, Log Actions | ✅ Functional | ✅ Full Integration |
| **AI Predictions** | Cashflow, Inventory, Anomalies | ⚠️ Partial | ⚠️ Limited Display |
| **Health Check** | Server Status | ✅ Functional | ✅ Auto-Check |

---

## Running the Backend

```bash
cd api
npm install
npm start
```

Server runs on `http://localhost:3000` (or configured port)

---

## Environment Configuration

### Backend (.env file)
```
NODE_ENV=production
PORT=3000
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=xxxxx
SUPABASE_ADMIN_KEY=xxxxx
ALLOWED_ORIGINS=http://localhost:3000,http://18.175.213.46:3000
```

### Flutter (.env or build flag)
```
flutter run --dart-define=API_BASE_URL=http://18.175.213.46:3000
```

---

## Testing API Endpoints

Use cURL or Postman to test:

```bash
# Sign Up
curl -X POST http://18.175.213.46:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123456",
    "full_name": "Test User",
    "business_type": "restaurant",
    "business_name": "Test Business",
    "role": "owner"
  }'

# Get Inventory (with auth token)
curl -X GET http://18.175.213.46:3000/api/inventory \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## Key Files Reference

### Backend
- Routes: [api/src/routes/index.js](api/src/routes/index.js)
- Controllers: [api/src/controllers/](api/src/controllers/)
- Middleware: [api/src/middleware/](api/src/middleware/)

### Frontend
- API Services: [lib/core/network/](lib/core/network/)
- Providers: [lib/provider/](lib/provider/)
- Pages: [lib/bottom_navigation/](lib/bottom_navigation/), [lib/pages/](lib/pages/)
- Models: [lib/models/](lib/models/)

