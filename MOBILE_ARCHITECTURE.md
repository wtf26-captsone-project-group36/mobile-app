# HerVest AI Mobile App - Architecture & App Flow Documentation

## Table of Contents
1. [App Architecture](#1-app-architecture)
2. [Offline Handling](#2-offline-handling)
3. [Core Workflows](#3-core-workflows)
4. [Error & Edge Case Handling](#4-error--edge-case-handling)
5. [Technical Limitations](#5-technical-limitations)
6. [AI Integration Report](#6-ai-integration-report)
7. [State Management & Reusable Widgets](#7-state-management--reusable-widgets)
8. [Donation/Pledge Logic](#8-donationpledge-logic)
9. [CO2 Tracking & Impact Metrics](#9-co2-tracking--impact-metrics)
10. [JSON Data Models & Decoding](#10-json-data-models--decoding)

---

## 1. App Architecture

### 1.1 Folder Structure

```
lib/
├── main.dart                          # App entry point with MultiProvider setup
├── core/
│   ├── network/                       # API services layer
│   │   ├── api_config.dart           # Base URL configuration & URI builders
│   │   ├── auth_api_service.dart     # Authentication API calls
│   │   ├── inventory_api_service.dart # Inventory CRUD operations
│   │   ├── cashflow_api_service.dart # Transaction & cashflow reports
│   │   ├── alerts_api_service.dart   # Alert management
│   │   ├── surplus_api_service.dart  # Surplus marketplace API
│   │   ├── activity_api_service.dart # Activity logging
│   │   ├── budget_api_service.dart   # Budget operations
│   │   ├── expense_api_service.dart  # Expense tracking
│   │   ├── predictions_api_service.dart # AI predictions & anomalies
│   │   ├── audit_api_service.dart    # Audit logs
│   │   └── api_health_service.dart   # Health check utilities
│   ├── storage/
│   │   └── app_session_store.dart    # SharedPreferences for auth tokens & session data
│   └── utils/                         # Helper utilities
├── models/
│   └── inventory_model.dart           # InventoryItem data class
├── provider/                          # State management (Provider pattern)
│   ├── inventory_provider.dart        # Manages inventory items & AI suggestions
│   ├── app_state_controller_mock.dart # Global state: transactions, alerts, searches
│   ├── profile_controller.dart        # User profile data
│   ├── rescue_provider.dart           # Food rescue actions, badges, impact metrics
│   └── sales_provider.dart            # Sales/transaction tracking
├── router/
│   └── app_router.dart                # GoRouter navigation configuration
├── pages/                             # Full-screen authentication pages
│   ├── login_page.dart
│   ├── signup_page.dart
│   ├── landing_page.dart
│   └── ... auth flow pages
├── bottom_navigation/                 # Tab-based screens
│   ├── bottom_navigation.dart         # Navigation shell & tab bar
│   ├── dashboard_page.dart            # Overview & quick stats
│   ├── inventory_screen.dart          # Inventory management
│   ├── inventory_page_two.dart        # Item details & editing
│   ├── cashflow_screen.dart           # Financial overview
│   ├── cashflow_overview_page.dart    # Detailed cashflow report
│   ├── cashflow_addexpense_page.dart  # Expense form
│   ├── cashflow_addincome_page.dart   # Income form
│   ├── suggestions_screen.dart        # AI-powered rescue suggestions
│   ├── suggestions_logistics_page.dart # Rescue logistics & CO2 calculation
│   ├── profile_screen.dart            # User profile & settings
│   ├── ai_insights_page.dart          # AI predictions & anomalies
│   └── search/
│       └── global_search_overlay.dart # Global search functionality
├── features/
│   ├── onboarding/                   # Onboarding flow
│   │   ├── splash_screen.dart
│   │   ├── onboarding_first_page.dart
│   │   ├── onboarding_second_page.dart
│   │   └── onboarding_third_page.dart
│   └── rescue/                       # Food rescue subsystem
│       ├── models/
│       │   └── rescue_models.dart   # RescueAction, RescueSuggestion, enums
│       ├── services/
│       │   └── rescue_suggestion_service.dart # Suggestion generation logic
│       └── data/
│           └── rescue_local_db.dart # SQLite operations for rescue data
├── widgets/                          # Reusable UI components
│   ├── rescue_ai_assistant.dart     # Rescue AI chatbot widget
│   ├── app_input_styles.dart        # Form field styling
│   ├── auth_form_field.dart         # Authentication form components
│   └── ... other reusable widgets
└── mock_data/
    └── inventory_mock.dart           # Mock data for development
```

### 1.2 State Management

The app uses **Provider** (ChangeNotifier pattern) for state management, with multiple providers managing different domains:

#### **Core Providers:**

1. **InventoryProvider** (`provider/inventory_provider.dart`)
   - Manages the list of `InventoryItem` objects
   - Handles CRUD operations (create, update, delete)
   - Syncs with backend via `InventoryApiService`
   - Features:
     - Optimistic updates (local state changes immediately, reverted if API fails)
     - Item validation (checks for missing expiry dates, status determination)
     - Automatic suggestions for near-expiry items
     - Initial load from mock data, then backend sync

2. **AppStateController** (`provider/app_state_controller_mock.dart`)
   - Global application state covering:
     - User transactions & cashflow data
     - Alerts and anomalies
     - Activity logs & audit trails
     - Budgets and expense summaries
     - Search queries
   - Manages load operations from multiple API services
   - Fallback handling for offline scenarios

3. **RescueProvider** (`provider/rescue_provider.dart`)
   - Manages food rescue actions & suggestions
   - Handles pledge creation (donation or surplus sale paths)
   - Tracks completion & deferral of rescue actions
   - Badge system (commitment builder, rescue hero, etc.)
   - Impact metrics calculation (CO2 avoided, value recovered, donations)
   - Syncs to SQLite locally, with optional backend fallback

4. **ProfileController** (`provider/profile_controller.dart`)
   - User profile information (name, avatar, business details)
   - Settings and preferences
   - Loaded on app startup

#### **Provider Setup (main.dart):**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => InventoryProvider()),
    ChangeNotifierProvider(create: (_) => AppStateController()),
    ChangeNotifierProvider(create: (_) => ProfileController()..load()),
    ChangeNotifierProxyProvider<InventoryProvider, RescueProvider>(
      create: (_) {
        final rescue = RescueProvider();
        rescue.initialize();
        return rescue;
      },
      update: (_, inventory, rescue) {
        final active = rescue ?? RescueProvider();
        active.syncInventory(inventory.items);
        return active;
      },
    ),
  ],
  child: const SurplusApp(),
)
```

This proxy provider ensures `RescueProvider` stays synchronized with `InventoryProvider` whenever inventory changes.

### 1.3 Navigation Structure

The app uses **GoRouter** with a **StatefulShellRoute** for tab-based navigation:

#### **Navigation Hierarchy:**

```
/ (splash screen)
├── Onboarding Flow
│   ├── /onboarding-1
│   ├── /onboarding-2
│   └── /onboarding-3
├── Authentication
│   ├── /landing
│   ├── /login
│   ├── /signup
│   ├── /forgot-password
│   └── /forgot-password/check-email/{email}
└── MainApp (StatefulShellRoute with 5 tabs)
    ├── Dashboard (/dashboard)
    ├── Inventory (/inventory)
    │   ├── /inventory/page-2
    │   ├── /inventory/page-3
    │   ├── /inventory/page-4
    │   └── /inventory/donation-success
    ├── Cashflow (/cashflow)
    │   ├── /cashflow/add-expense
    │   ├── /cashflow/add-income
    │   └── /cashflow/transaction-history
    ├── Suggestions (/suggestions)
    │   ├── /suggestions/logistics/{itemId}
    │   ├── /suggestions/impact-dashboard
    │   ├── /suggestions/pledge-history
    │   └── /suggestions/success
    └── Profile (/profile)
        └── /account-settings

Global Routes:
├── /search (global search overlay)
└── /ai-insights (AI predictions page)
```

#### **Key Navigation Features:**

- **StatefulShellRoute**: Preserves bottom navigation state across tab switches
- **Nested navigators**: Each tab has its own navigator for independent stacks
- **Navigation keys**: Separate keys for home, inventory, cashflow, suggestions, and profile tabs
- **Deep linking**: Support for direct navigation via route names and parameters
- **Query parameters**: Used for email, OTP, and other data passing

---

## 2. Offline Handling

### 2.1 Local Storage & Offline Support

The app employs a **hybrid offline-first approach** with graceful degradation:

#### **Storage Mechanism:**

1. **SharedPreferences** (for small key-value data)
   - Location: `lib/core/storage/app_session_store.dart`
   - Stores:
     - Auth tokens (access_token, refresh_token)
     - User session state (is_logged_in, is_guest)
     - User metadata (name, has_seen_onboarding)
   - Persistence: Indefinite (survives app restart)

2. **SQLite Database** (for structured data)
   - Location: `lib/features/rescue/data/rescue_local_db.dart`
   - Stores:
     - **rescue_actions table**: All pledges, donations, and surplus sales
       - Columns: id, item_id, quantity, path, entity_category, note, state, timestamps, CO2 factor
     - **badge_earnings table**: Unlocked badges with timestamps
     - **impact_metrics table**: Aggregated stats (completed rescues, donations, CO2, value)
   - Scope: Food rescue actions only (inventory not locally cached)

3. **In-Memory State** (during session)
   - `InventoryProvider._items`: Current inventory list
   - `AppStateController`: Alerts, transactions, anomalies
   - Cleared on app termination

#### **Offline Support:**

**Read Operations:**
- Inventory: Cannot read offline (depends on API)
- Rescue actions: Read from SQLite if available
- Transactions: Cannot read offline
- User session: Available offline via SharedPreferences

**Write Operations (when offline):**
- Inventory items: Queued locally via try-catch (if API fails, exception is raised)
- Rescue pledges: Saved to both SQLite and attempt backend sync
- Transactions: Saved locally via optimistic update, synced when online

**UI Feedback:**
- No explicit loading spinner for offline state
- Failed API calls are silently caught and local data is kept
- Retry happens automatically when user refreshes or navigates

### 2.2 Sync Strategy

#### **When Sync Occurs:**

1. **On App Start (`_bootstrapAuthSession` in main.dart):**
   - Refresh access token using stored refresh token
   - If token refresh fails, clear auth and show login
   - Health check API to verify backend connectivity

2. **On Provider Initialization:**
   - `InventoryProvider`: Calls `loadFromBackend()` in constructor
   - `AppStateController`: Calls `loadTransactionsFromBackend()` and `loadInsightsFromBackend()` in constructor
   - `RescueProvider`: Syncs with `InventoryProvider` on item changes

3. **On Data Write:**
   - Optimistic local update first
   - Async backend sync in background
   - On API error, local state is reverted to previous value

4. **Manual Refresh:**
   - Users can pull-to-refresh within screens
   - Calls `loadFromBackend()` methods again

#### **Sync Logic Pattern (Optimistic Update):**

```dart
// Example from InventoryProvider
Future<void> updateItemFromApi({...}) async {
  // 1. Immediate local update (optimistic)
  _items[index] = updated;
  notifyListeners();

  // 2. Background sync
  try {
    final apiUpdated = await _api.updateInventoryItem(...);
    _items[index] = _fromApi(apiUpdated); // Final state from API
    notifyListeners();
  } catch (_) {
    // 3. Revert on error
    _items[index] = current;
    notifyListeners();
  }
}
```

### 2.3 Conflict Handling Logic

#### **Conflict Scenarios:**

1. **User edits item while offline, then online:**
   - Local update is applied immediately
   - Backend sync sends to API
   - If API succeeds, state matches
   - If API fails (e.g., permission denied), local state is reverted

2. **Multiple devices editing same item:**
   - Not handled (assumes single-user scenario)
   - Last write wins (backend processes requests sequentially)

3. **Rescue pledge created offline, then network restored:**
   - RescueProvider saves to SQLite immediately
   - Background task syncs to activity API
   - If sync fails, pledge stays in SQLite (eventually synced on retry)

4. **Badge earned but backend unaware:**
   - Badges stored in local database
   - Not synced back to backend (one-way from backend)
   - No conflict resolution needed

#### **Fallback Strategies:**

- **Network Error**: Keep local state, silently fail API call
- **Permission Denied (403)**: Revert local change, show error if critical
- **Timeout (12s)**: Treat as network error, keep local state
- **Malformed Response**: Parse with defensive casting, return empty defaults

---

## 3. Core Workflows

### 3.1 Inventory Tracking Flow

**User Journey: "I received new stock and need to track it"**

1. **Navigation:**
   - User taps Inventory tab → `/inventory` (InventoryScreen)

2. **Display Inventory:**
   - `InventoryProvider` loads items from backend on init
   - Items displayed in list with status badges:
     - 🟢 Normal (green)
     - 🟡 Warning (yellow) - expires in 0-3 days
     - 🔴 Expired (red)
     - ⚠️ Error (missing expiry date)

3. **Add New Item:**
   - User taps "Add Item" → `/inventory/page-2` (InventoryPageTwo)
   - Form inputs:
     - Item name (text)
     - Category (dropdown: Dairy, Grains, Fresh Produce, etc.)
     - Quantity (number)
     - Unit (dropdown: kg, units, bags, etc.)
     - Purchase price (number)
     - Expiry date (DatePicker)
   - **Calendar blocking**: Uses Flutter's `showDatePicker`, user cannot select past dates
   - Validation: Expiry date required (enforced before API call)

4. **Backend Sync:**
   - `InventoryProvider.addItemFromApi()` sends to API
   - API returns created item with ID
   - Item added to local list with new ID
   - If offline: local add only (will fail on API call)

5. **Edit/Update Item:**
   - User taps item → `/inventory/page-3`
   - Form displays current values
   - Changes trigger `updateItemFromApi()`
   - Optimistic update + backend sync

6. **Delete Item:**
   - User swipes/taps delete → confirmation
   - `deleteItemFromApi()` removes from local list
   - Backend delete happens async
   - On error, item restored to list

**Data Models:**
- `InventoryItem` (lib/models/inventory_model.dart)
- Status: enum ItemStatus { normal, warning, expired, error }

### 3.2 Expense/Cashflow Tracking Flow

**User Journey: "I spent ₦5,000 on transport today"**

1. **Navigation:**
   - User taps Cashflow tab → `/cashflow` (CashflowScreen)
   - Sees summary: Total income, total expenses, net balance

2. **Add Transaction:**
   - User taps "Add Expense" → `/cashflow/add-expense`
   - Form inputs:
     - Title/Category (e.g., "Transport", "Materials")
     - Amount (number)
     - Transaction type (dropdown: expense, income)
     - Date (DatePicker, defaults to today)
     - Note (optional)

3. **Submission:**
   - User taps "Save"
   - `AppStateController.addTransaction()` called
   - **Optimistic insert**: Transaction added to local list immediately
   - **Background sync**: `CashflowApiService.createTransaction()` posts to API
   - On success: Item updated with API response ID
   - On error: Transaction kept local (user sees it, but might not have backend ID)

4. **View Transactions:**
   - `/cashflow/transaction-history` shows all transactions
   - Sorted by date (newest first)
   - Displays: Title, amount, type, date, note

5. **Cashflow Report:**
   - `/cashflow/overview-page` or dashboard widget
   - Shows:
     - Total income (sum of income transactions)
     - Total expenses (sum of expense transactions)
     - Net balance
     - Monthly breakdown (if API provides it)

**Data Models:**
- Transaction JSON structure:
  ```json
  {
    "transaction_date": "2025-02-26",
    "type": "expense|income",
    "amount": 5000,
    "category": "Transport",
    "description": "Bike fuel"
  }
  ```

### 3.3 Cashflow Dashboard Flow

**Purpose:** Provide financial overview and insights

1. **Dashboard Components:**
   - **Summary Cards:**
     - Total income (week/month)
     - Total expenses (week/month)
     - Net balance
   - **Chart:** Income vs. Expenses (bar chart or pie chart)
   - **Recent Transactions:** Last 5 transactions with icons
   - **Alerts:** Low balance, high expenses (from predictions API)

2. **Real-time Updates:**
   - `AppStateController` manages alerts list
   - `AlertsApiService` fetches alerts from backend
   - Alert severity: normal, high, critical
   - Unread count displayed

3. **Anomaly Detection:**
   - `PredictionsApiService.getAnomalies()` returns unusual patterns
   - Examples: "Expenses 50% higher than last month"
   - Displayed as risk alerts with advisory tone

### 3.4 AI Alert Display Flow

**Purpose:** Guide users with intelligent suggestions and warnings

1. **Alert Types:**
   - **Inventory Alerts:** "Golden Penny Beans expire in 2 days"
   - **Financial Alerts:** "Monthly expenses exceed budget"
   - **Performance Alerts:** "Slow transaction processing"
   - **Risk Alerts:** "Unusual expense pattern detected"

2. **Display Locations:**
   - **Dashboard:** Alert banner at top
   - **Alert Center:** Full list at `/suggestions` (also hosts rescue suggestions)
   - **Rescue Assistant:** AI chatbot can explain alerts

3. **Alert Interactions:**
   - Mark as read: `AppStateController.markAlertRead()`
   - Resolve: `AppStateController.resolveAlert()`
   - Unread count tracked

4. **Rescue-Specific Suggestions:**
   - `RescueProvider` generates suggestions via `RescueSuggestionService`
   - Suggestions are NOT alerts—they're actionable pledges
   - Suggestion logic:
     - Item expires in 0-7 days → candidate for rescue
     - Days ≤ 2 → **Critical urgency**, recommend **Donation**
     - Days 3-7 + low value → **Near-expiry**, recommend **Donation**
     - Days 3-7 + high value (₦10k+) → **Near-expiry**, recommend **Surplus Sale**
   - Each suggestion includes:
     - Recommended rescue path (Donation or Sale)
     - Best entity category (School, Prison, Food Kitchen, etc.)
     - Reason (e.g., "High perishability, limited storage capacity")
     - Estimated CO2 savings (kg)
     - Estimated value recovery (₦)

---

## 4. Error & Edge Case Handling

### 4.1 Loading States

**Implementation:** No explicit loading state UI in current code. Instead:
- UI optimistically updates immediately
- Spinners shown only in specific contexts (e.g., form submission)

**Example Pattern:**
```dart
future: _api.getInventory(accessToken: token),
builder: (context, snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(child: CircularProgressIndicator());
  }
  if (snapshot.hasError) {
    return ErrorWidget();
  }
  return ItemList(items: snapshot.data ?? []);
}
```

### 4.2 Error States

**Network Errors (HTTP):**
- **Timeout (>12s):** Caught by `.timeout(Duration(seconds: 12))` on all requests
  - No retry logic
  - User sees stale local data or empty state
- **404 Not Found:** Fallback to alternate API endpoint
  - Primary: `/api/inventory` → Fallback: `/inventory`
  - Useful for API routing flexibility
- **400-499 (Client Error):**
  - Bad request: Validation error from backend
  - 403 Forbidden: Permission denied (staff can't add inventory)
  - 401 Unauthorized: Token expired (trigger re-login)
  - Caught and exception thrown with backend error message
- **500-599 (Server Error):**
  - Treated as temporary failure
  - Caught with try-catch, local state kept
  - User retries by refreshing or navigating away

**Parsing Errors:**
- JSON decode failure: Defensive casting with null coalescing
  - `(json['field'] ?? default).cast<Type>()`
  - Empty {} returned if parse fails
- Missing required fields: Type-safe with ?? operators
  - `(item['name'] ?? 'Unknown').toString()`

**Validation Errors:**
- **Missing Expiry Date:** Item marked with `ItemStatus.error`
  - Error message set: "Missing Expiry Date"
  - Cannot be used in rescue suggestions
- **Invalid Date:** DatePicker prevents past dates (calendar blocking)
- **Invalid Amount:** TextField accepts only numbers (input validation)

### 4.3 Retry Logic

**Current Approach:** Minimal explicit retry. Instead:

1. **Optimistic Update + Revert:**
   - User action updates local state immediately
   - API call in background
   - On error, local state reverted to previous value
   - User sees change briefly, then revert (OR no change if error)

2. **Manual Retry:**
   - User refreshes screen (pull-to-refresh)
   - User navigates away and back
   - User retries specific action (submit form again)

3. **Automatic Retry (Session Tokens):**
   - Expired access token detected
   - Attempt refresh using refresh token
   - If refresh succeeds: continue with new token
   - If refresh fails: clear tokens, force re-login

**Example:**
```dart
try {
  final response = await _api.updateItem(...);
  _items[index] = parseResponse(response);
  notifyListeners();
} catch (e) {
  // Revert on error
  _items[index] = originalState;
  notifyListeners();
  // No automatic retry—user must manually retry
}
```

### 4.4 Edge Cases & Protections

#### **1. Calendar Blocking (Inventory Date Selection)**
- **Issue:** User selects past date for expiry → invalid inventory
- **Solution:** `showDatePicker()` initialSelectableDayPredicate constrains to future dates only
- **Code:** Calendar UI prevents past date selection at the widget level

#### **2. Missing Auth Token**
- **Issue:** User offline or logged out
- **Solution:** Check token before every API call
  ```dart
  final token = await AppSessionStore.instance.getAccessToken();
  if (token == null || token.isEmpty) return; // Silently fail or return defaults
  ```

#### **3. Concurrent Updates (Inventory Item)**
- **Issue:** User edits item twice before first API response returns
- **Current Handling:** Last-write-wins
  - Second update reverts first update if first fails
  - No conflict detection
  - Works for single-user scenario

#### **4. Negative Quantities**
- **Issue:** User enters `-5` units in inventory
- **Current Handling:** No validation (accepted by API)
- **Recommendation:** Add numeric validation `quantity > 0`

#### **5. Duplicate Item Names**
- **Issue:** User adds same item multiple times
- **Current Handling:** Allowed (no uniqueness constraint)
- **Reason:** Multiple packs of same product is valid

#### **6. Empty Inventory List**
- **Issue:** User has no items
- **UI:** Empty state showing "Add your first item" prompt
- **Sync:** Displays local mock data initially, then clears on backend load

#### **7. Network Restored After Offline Period**
- **Issue:** User was offline, now online—what data is synced?
- **Current Handling:**
  - Rescue actions: Synced to backend activity log
  - Inventory: No offline caching, so no sync needed
  - Transactions: Optimistic entries kept local; not synced to backend if offline

#### **8. Very Large Inventory (1000+ items)**
- **Issue:** Performance degradation
- **Current Handling:** Loaded into memory as list
- **Pagination:** Not implemented (API supports `limit` and `offset`, but UI loads all)
- **Recommendation:** Implement lazy loading or pagination

---

## 5. Technical Limitations

### 5.1 API Timeout
- **Default:** 12 seconds per request
- **All services:** Apply `.timeout(Duration(seconds: 12))`
- **Implications:**
  - Large inventory loads with 1000+ items may timeout
  - Slow networks (3G/EDGE) may exceed timeout
  - No retry on timeout—user sees stale data

### 5.2 No Offline Inventory Caching
- Inventory not persisted locally
- User cannot view inventory offline
- Cache could be added via SQLite similar to rescue actions table
- Trade-off: Disk space vs. functionality

### 5.3 No Conflict Resolution
- Assumes single-user, single-device usage
- Simultaneous edits on multiple devices will have last-write-wins behavior
- Multi-device conflict resolution not implemented

### 5.4 No Explicit Sync Queue
- No persistent queue of pending updates
- Offline transactions lost if app is force-closed
- Could be implemented with SQLite + WorkManager

### 5.5 Alert Deduplication
- Duplicate alerts may be fetched
- No client-side dedup logic
- Server should deduplicate before sending

### 5.6 No Background Sync
- Sync only happens when app is active
- No background fetch or WorkManager integration
- Changes made on backend don't trigger app updates unless user manually refreshes

### 5.7 Limited Encryption
- Auth tokens stored in SharedPreferences (cleartext on some devices)
- Recommendation: Use flutter_secure_storage for sensitive data

### 5.8 No End-to-End Encryption
- All data transmitted over HTTPS but decrypted on client
- Suitable for internal use; not ideal for highly sensitive data

---

## 6. AI Integration Report

### 6.1 How AI Alerts Are Displayed

#### **Alert Channels:**

1. **Dashboard Banner:**
   - Top of dashboard shows most critical alert
   - Example: "Peak Milk expires in 2 days"
   - Tap to view full alert details

2. **Alert Center:**
   - `/ai-insights` page lists all alerts
   - Filtered by severity (Critical, High, Normal)
   - Marked as read/unread
   - Resolved alerts hidden or archived

3. **Rescue Suggestions:**
   - Not technically "alerts"—but AI-generated suggestions
   - `/suggestions` screen shows items recommended for rescue
   - Suggestions include reasoning: "High perishability + near expiry = recommend donation to food kitchen"

4. **AI Assistant Chatbot:**
   - Bottom-right FAB: "Ask me anything"
   - Ask questions like:
     - "What items expire soon?"
     - "Show me my impact"
     - "What's my next badge?"
   - Powered by `RescueProvider` data + simple prompts (not LLM)
   - Responses from `RescueProvider.answerPrompt()`:
     ```dart
     "Top rescue priorities: Golden Penny Beans (7d): Donation -> Food Kitchen | Peak Milk (2d): Donation -> School"
     ```

### 6.2 How Users Understand Why a Risk Alert Was Triggered

#### **Transparency Mechanism:**

1. **Reasoning Strings:**
   - Every suggestion includes a human-readable reason
   - Example: "Golden Penny Beans: High perishability (5/5) + 2 days to expiry = critical urgency. Recommend donation to Food Kitchen (accepts dairy products)."
   - Built by `RescueSuggestionService._buildReason()`

2. **Metric Visibility:**
   - Dashboard shows actual numbers:
     - "₦25,000 total inventory value"
     - "3 items expiring within a week"
     - "₦2,500 in expenses (28% increase from last month)"
   - Users see the data driving the alert

3. **Interactive Explanation:**
   - Tap alert → Details screen
   - Show: Item name, current quantity, expiry date, days until expiry
   - Show: Suggested action with entity recipient
   - Show: CO2 savings if donated

4. **AI Assistant Explanation:**
   - User can ask: "Why is Peak Milk an alert?"
   - Assistant responds: "Peak Milk expires in 2 days and has high perishability. We recommend donating to a food kitchen to prevent waste."

### 6.3 How We Position AI as Advisory, Not Automated

#### **Advisory Positioning Strategy:**

1. **Language:**
   - "We recommend..." (not "You must...")
   - "Consider donating..." (not "Donating...")
   - "High likelihood of..." (not "Will definitely...")
   - Suggestions are suggestions, not commands

2. **User Control:**
   - User explicitly pledges rescue actions
   - User can override AI recommendation:
     - Donate instead of selling (or vice versa)
     - Choose different recipient entity
     - Add custom notes explaining override
   - User can defer or skip suggestions

3. **Transparency on AI Limitations:**
   - Suggestions based on simple rules (expiry date, category, value)
   - Not a full machine learning model
   - Rules are documented: `RescueSuggestionService` code is readable

4. **Human Approval Workflows:**
   - No automatic actions happen without user confirmation
   - Pledge modal requires explicit user confirmation
   - Completion marked manually (not auto-detected)

5. **Badges as Positive Reinforcement:**
   - NOT penalties or negative alerts
   - Celebrate user achievements ("Rescue Hero - 5 donations")
   - Optional to pursue
   - No forced gamification

6. **Caveats & Disclaimers:**
   - CO2 calculation is estimate (category-based average)
   - Entity recommendations  based on past data (not real-time availability)
   - Value estimates are "expected" not "guaranteed sale price"

---

## 7. State Management & Reusable Widgets

### 7.1 Provider Pattern Recap

All state is managed via `ChangeNotifier` + `Provider`:

```dart
// In main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => InventoryProvider()),
    ChangeNotifierProvider(create: (_) => AppStateController()),
    ChangeNotifierProxyProvider<InventoryProvider, RescueProvider>(...),
  ],
  child: const SurplusApp(),
)

// In any widget
final inventory = Provider.of<InventoryProvider>(context);
// or
final inventory = context.watch<InventoryProvider>();
```

### 7.2 Reusable Widgets

#### **Authentication & Forms:**
- `AuthFormField` (lib/widgets/auth_form_field.dart)
  - Custom TextFormField with label, icon, validation
  - Used in login, signup, password reset forms

- `AppInputStyles` (lib/widgets/app_input_styles.dart)
  - Centralized theme for form inputs
  - Colors, borders, font sizes

#### **UI Components:**
- `OnboardingIndicator` (lib/widgets/onboarding_indicator.dart)
  - Dot indicator showing slide position
  - Typically at bottom of onboarding screens

- `ImagePrecache` (lib/widgets/image_precache.dart)
  - Preloads images for faster display

#### **Navigation:**
- `BottomNavigation` (lib/bottom_navigation/bottom_navigation.dart)
  - Shell navigation bar
  - 5 tabs: Dashboard, Inventory, Cashflow, Suggestions, Profile
  - Uses StatefulShellRoute for state preservation

#### **AI Features:**
- `RescueAIAssistantButton` (lib/widgets/rescue_ai_assistant.dart)
  - Floating action button triggering chat modal
  - Available on Suggestions and Dashboard screens

- `RescueAIAssistant` (internal widget in rescue_ai_assistant.dart)
  - Modal bottom sheet with chat interface
  - Input field + message list
  - Integrates with `RescueProvider` for context

#### **Feedback & Celebration:**
- Confetti animation on successful pledge
  - Imported from `confetti` package
  - Triggered on `SuggestionSuccessPage`

---

## 8. Donation/Pledge Logic

### 8.1 Pledge Workflow

**User Journey: "I want to donate 10 bags of Golden Penny Beans to a school"**

1. **Trigger:**
   - User sees suggestion for "Golden Penny Beans" on Suggestions screen
   - Suggestion shows: "Critical urgency (2 days), recommend donation to Food Kitchen"

2. **Open Pledge Dialog:**
   - User taps "Pledge to Donate" button
   - Modal shows:
     - Item name, quantity, expiry date
     - Recommended rescue path (donation)
     - Recommended entity (Food Kitchen)
     - Match score (1-100, based on entity capability)
     - Optional note field (for custom message)
     - Optional handover details (logistics info)

3. **Override Option:**
   - User can tap "Override" to change recommendation
   - Dropdowns allow selecting:
     - Rescue path: Donation OR Surplus Sale
     - Entity category: School, Prison, Food Kitchen, Orphanage, Church
   - Reason shown: "You are overriding the suggested path. This may affect impact calculation."

4. **Confirm Pledge:**
   - User fills note/handover details
   - User taps "Confirm Pledge"
   - Immediately added to local `_actions` list
   - `RescueProvider.pledge()` method:
     ```dart
     final action = RescueAction(
       id: latestAction?.id ?? newId,
       itemId: suggestion.itemId,
       finalPath: overridePath ?? suggestion.recommendedPath,
       finalEntityCategory: overrideEntity ?? suggestion.bestEntityCategory,
       wasOverridden: overridden,
       quantity: suggestion.quantity,
       estimatedValue: suggestion.estimatedValue,
       co2FactorPerUnit: suggestion.co2FactorPerUnit,
       isCompleted: false,
       ...
     );
     ```

5. **Success Screen:**
   - Navigate to `/inventory/donation-success`
   - Confetti animation
   - Shows:
     - Item name & quantity
     - Recipient: "School"
     - CO2 avoided (kg)
     - Points earned (based on value)
     - People helped estimate (value / 5000)
   - Buttons: "Return to Dashboard" or "View Lifetime Impact"

6. **Backend Sync:**
   - `RescueProvider._syncPledgeToBackend()` calls `ActivityApiService`
   - Logs action to activity log for audit trail
   - If offline: Saved to SQLite, synced when online

### 8.2 Pledge Types

#### **Donation Path:**
- Item given away for free
- Recommended for:
  - High perishability items (Dairy, Fresh Produce, Proteins)
  - Items expiring within 2 days
  - Low-value items
- Entity options: School, Prison, Food Kitchen, Orphanage, Church
- Impact: Counts toward "rescue hero" badge (threshold: 5 donations)
- No revenue

#### **Surplus Sale Path:**
- Item sold at discounted price to surplus marketplace
- Recommended for:
  - Items with value ≥ ₦10,000
  - Items expiring in 3-7 days
  - Lower-perishability items
- Backend integration: `SurplusApiService` manages marketplace
- Impact: Counts toward "surplus sales" metric
- Revenue recovered

### 8.3 Badge System

Badges are earned based on number of completed donations:

| Badge | Threshold | Theme |
|-------|-----------|-------|
| **Commitment Builder** | 5 pledges (any path) | Dedication |
| **Rescue Hero** | 5 donations | Community |
| **Community Champion** | 10 donations | Larger impact |
| **Impact Leader** | 20 donations | Regional influence |
| **Waste Warrior** | 35 donations | Sustainability focus |
| **Sustainability Legend** | 50 donations | Mastery |

**Badge Unlocking:**
- `RescueProvider._awardCommitmentBadgeIfNeeded()`
- Triggered after each pledge
- Stored in SQLite + SharedPreferences
- Persists across app sessions

**Badge Display:**
- Profile page shows unlocked badges
- Latest badge shown on dashboard
- Success screen shows next badge progress

---

## 9. CO2 Tracking & Impact Metrics

### 9.1 CO2 Calculation

**Formula:**
```
CO2 Avoided (kg) = Quantity (kg) × CO2 Factor (kg CO2e per kg item)
```

**Category-Based CO2 Factors:**
```dart
static final Map<String, double> _categoryCo2Factor = {
  'Dairy': 3.2 kg CO2e per kg,           // High impact (livestock feed, refrigeration)
  'Grains & Cereals': 1.2 kg CO2e per kg, // Transport, storage
  'Fresh Produce': 0.8 kg CO2e per kg,    // Lower impact, less processing
  'Proteins': 4.1 kg CO2e per kg,         // Highest (meat production)
  'Bakery': 1.6 kg CO2e per kg,           // Baking energy
  'default': 1.5 kg CO2e per kg,
};
```

**Unit Conversion:**
- If unit is "kg" → use quantity directly
- If unit is "g" or "grams" → convert to kg (divide by 1000)
- If unit is "bags", "units", etc. → cannot calculate (return null)

**Example:**
- Item: "Peak Milk" (Dairy category)
- Quantity: 10 cartons (units) → **cannot calculate** (unit not convertible)
- Item: "Gold Rice" (Grains, 50 kg bags)
- Quantity: 50
- CO2 avoided: 50 × 1.2 = **60 kg CO2e**

### 9.2 Impact Metrics Aggregation

**Calculation (from RescueProvider):**
```dart
ImpactMetrics get impactMetrics {
  final completed = _actions.where((a) => a.isCompleted).toList();
  
  return ImpactMetrics(
    totalCompletedRescues: completed.length,
    totalDonations: completed.where((a) => a.finalPath == RescuePath.donation).length,
    totalSurplusSales: completed.where((a) => a.finalPath == RescuePath.surplusSale).length,
    totalCo2AvoidedKg: completed.fold(
      0,
      (sum, a) => sum + (a.quantity * a.co2FactorPerUnit)
    ),
    totalValueRecovered: completed.fold(
      0,
      (sum, a) => sum + a.estimatedValue
    ),
  );
}
```

Only **completed** actions count toward impact metrics.

**Metrics Displayed:**
- **Impact Dashboard** (`/suggestions/impact-dashboard`):
  - 🏆 Total rescues: "35 items rescued from waste"
  - 💚 CO2 avoided: "120 kg CO2e prevented"
  - 💰 Value recovered: "₦45,000 in value saved"
  - 🤝 Donations: "28 donations made"
  - 🛒 Surplus sales: "7 marketplace sales"

- **Profile Screen:**
  - Shows badges earned
  - Summary of impact statistics

### 9.3 CO2 Communication to Users

**In UI:**
- Suggestions screen shows: "Donating will prevent 45 kg of CO2 from being emitted"
- Success screen shows: "You've prevented 45 kg of CO2 from being emitted!"
- Impact dashboard highlights total CO2 avoided

**Framing:**
- Positive reinforcement: "You are preventing carbon emissions"
- Tangible equivalent: "Equivalent to X km of car driving" (not implemented but recommended)
- Environmental education: Simple explanation of why this item's CO2 is high

**Caveats:**
- Estimates based on industry averages (not actual carbon footprint analysis)
- Actual CO2 depends on transportation, storage conditions, recipient's disposal method
- Conservative estimates to avoid overstating impact

---

## 10. JSON Data Models & Decoding

### 10.1 Core Models & JSON Structures

#### **A. InventoryItem (lib/models/inventory_model.dart)**

**Dart Class:**
```dart
class InventoryItem {
  final String id;
  String name;
  String category;
  double quantity;
  String unit;
  DateTime? dateReceived;
  DateTime? expiryDate;
  double? purchasePrice;
  ItemStatus status; // normal, warning, expired, error
  String? errorMessage;
}

enum ItemStatus { normal, warning, expired, error }
```

**JSON (from API):**
```json
{
  "item_id": "item-001",
  "item_name": "Golden Penny Beans",
  "category": "Grains & Cereals",
  "quantity": 20,
  "unit": "bags",
  "purchase_price": 1500,
  "expiry_date": "2025-03-10",
  "date_received": "2025-02-20"
}
```

**Decoding (InventoryProvider._fromApi):**
```dart
InventoryItem _fromApi(Map<String, dynamic> json) {
  final id = (json['item_id'] ?? json['id'] ?? '').toString();
  final name = (json['item_name'] ?? 'Unknown').toString();
  final quantity = (json['quantity'] as num?)?.toDouble() ?? 0.0;
  final expiryRaw = json['expiry_date']?.toString();
  final expiryDate = expiryRaw != null ? DateTime.tryParse(expiryRaw) : null;
  
  final item = InventoryItem(
    id: id,
    name: name,
    category: ...,
    quantity: quantity,
    unit: ...,
    expiryDate: expiryDate,
    purchasePrice: ...
  );
  
  // Validate and set status
  _validateItem(item);
  return item;
}
```

**Key Defensive Coding:**
- Used ?? for null coalescing
- Used as num? then toDouble() to handle numeric types
- DateTime.tryParse() returns null if invalid
- Validated items after parsing

---

#### **B. Transaction (implicit model in AppStateController)**

**JSON (from /transactions API):**
```json
{
  "id": "txn-001",
  "transaction_date": "2025-02-26",
  "type": "expense",
  "amount": 5000,
  "category": "Transport",
  "description": "Bike fuel"
}
```

**Mapping Function (AppStateController._mapApiTransaction):**
```dart
Map<String, dynamic> _mapApiTransaction(Map<String, dynamic> json) {
  return {
    'id': (json['id'] ?? '').toString(),
    'title': (json['category'] ?? json['description'] ?? '').toString(),
    'amount': _formatAmount((json['amount'] as num?)?.toDouble() ?? 0),
    'type': (json['type'] ?? 'unknown').toString(),
    'date': (json['transaction_date'] ?? '').toString(),
    'note': (json['description'] ?? '').toString(),
  };
}
```

---

#### **C. RescueAction (lib/features/rescue/models/rescue_models.dart)**

**Complete Dart Class:**
```dart
class RescueAction {
  final String id;
  final String itemId;
  final String itemName;
  final String itemCategory;
  final String unit;
  final RescuePath suggestedPath;    // donation, surplusSale
  final RescuePath finalPath;
  final RescueEntityCategory suggestedEntityCategory; // school, prison, ...
  final RescueEntityCategory finalEntityCategory;
  final String? backendSurplusId;
  final bool wasOverridden;
  final String? note;
  final String? handoverDetails;
  final DateTime pledgedAt;
  final DateTime? completedAt;
  final double quantity;
  final double estimatedValue;
  final double co2FactorPerUnit;
  final bool isCompleted;
  final bool isDeferred;
}

enum RescuePath { donation, surplusSale }
enum RescueEntityCategory { school, prison, foodKitchen, orphanage, church }
enum RescueSuggestionUrgency { nearExpiry, critical }
```

**JSON to Dart (RescueAction.fromJson):**
```dart
static RescueAction fromJson(Map<String, dynamic> json) {
  return RescueAction(
    id: (json['id'] ?? '').toString(),
    itemId: (json['itemId'] ?? '').toString(),
    itemName: (json['itemName'] ?? '').toString(),
    itemCategory: (json['itemCategory'] ?? '').toString(),
    unit: (json['unit'] ?? 'units').toString(),
    suggestedPath: RescuePath.values.firstWhere(
      (value) => value.name == json['suggestedPath'],
      orElse: () => RescuePath.donation,
    ),
    finalPath: RescuePath.values.firstWhere(
      (value) => value.name == json['finalPath'],
      orElse: () => RescuePath.donation,
    ),
    suggestedEntityCategory: RescueEntityCategory.values.firstWhere(
      (value) => value.name == json['suggestedEntityCategory'],
      orElse: () => RescueEntityCategory.foodKitchen,
    ),
    finalEntityCategory: RescueEntityCategory.values.firstWhere(
      (value) => value.name == json['finalEntityCategory'],
      orElse: () => RescueEntityCategory.foodKitchen,
    ),
    pledgedAt: DateTime.tryParse((json['pledgedAt'] ?? '').toString()) ?? DateTime.now(),
    completedAt: DateTime.tryParse((json['completedAt'] ?? '').toString()),
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
    estimatedValue: (json['estimatedValue'] as num?)?.toDouble() ?? 0,
    co2FactorPerUnit: (json['co2FactorPerUnit'] as num?)?.toDouble() ?? 0,
    isCompleted: json['isCompleted'] == true,
    isDeferred: json['isDeferred'] == true,
    ...
  );
}
```

**Dart to JSON (RescueAction.toJson):**
```dart
Map<String, dynamic> toJson() {
  return {
    'id': id,
    'itemId': itemId,
    'itemName': itemName,
    'suggestedPath': suggestedPath.name,
    'finalPath': finalPath.name,
    'suggestedEntityCategory': suggestedEntityCategory.name,
    'finalEntityCategory': finalEntityCategory.name,
    'pledgedAt': pledgedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'quantity': quantity,
    'estimatedValue': estimatedValue,
    'co2FactorPerUnit': co2FactorPerUnit,
    'isCompleted': isCompleted,
    'isDeferred': isDeferred,
    ...
  };
}
```

---

#### **D. RescueSuggestion (lib/features/rescue/models/rescue_models.dart)**

**Dart Class:**
```dart
class RescueSuggestion {
  final String itemId;
  final String itemName;
  final String itemCategory;
  final double quantity;
  final String unit;
  final int daysToExpiry;
  final RescueSuggestionUrgency urgency; // nearExpiry, critical
  final RescuePath recommendedPath;      // donation, surplusSale
  final RescueEntityCategory bestEntityCategory;
  final String reason;
  final int matchScore;                  // 1-100
  final double estimatedValue;
  final double co2FactorPerUnit;
}
```

**Generation (RescueSuggestionService.buildSuggestion):**
```dart
static RescueSuggestion? buildSuggestion(InventoryItem item) {
  if (!isRescueCandidate(item)) return null; // Must expire within 7 days
  
  final daysLeft = daysToExpiry(item.expiryDate);
  final urgency = daysLeft <= criticalMaxDays 
    ? RescueSuggestionUrgency.critical
    : RescueSuggestionUrgency.nearExpiry;
  
  final perishability = _scorePerishability(item.category); // 1-5
  final recommendedPath = _choosePath(
    daysLeft: daysLeft,
    perishability: perishability,
    estimatedValue: (item.purchasePrice ?? 0) * item.quantity,
  );
  
  final bestEntity = _chooseBestEntity(
    category: item.category,
    perishability: perishability,
    daysLeft: daysLeft,
    quantity: item.quantity,
  );
  
  final reason = _buildReason(...); // Human-readable explanation
  final matchScore = _calculateEntityScore(...); // Match quality 1-100
  final co2 = _categoryCo2Factor[item.category] ?? _categoryCo2Factor['default']!;
  
  return RescueSuggestion(
    itemId: item.id,
    itemName: item.name,
    itemCategory: item.category,
    quantity: item.quantity,
    unit: item.unit,
    daysToExpiry: daysLeft,
    urgency: urgency,
    recommendedPath: recommendedPath,
    bestEntityCategory: bestEntity,
    reason: reason,
    matchScore: matchScore,
    estimatedValue: (item.purchasePrice ?? 0) * item.quantity,
    co2FactorPerUnit: co2,
  );
}
```

---

#### **E. Alert (from AlertsApiService)**

**JSON (from /alerts API):**
```json
{
  "alerts": [
    {
      "id": "alert-001",
      "type": "expiry",
      "severity": "critical",
      "title": "Golden Penny Beans expire today",
      "description": "20 bags expiring now",
      "itemId": "item-001",
      "createdAt": "2025-02-26T10:00:00Z",
      "isRead": false
    }
  ],
  "unread": 3
}
```

**Parsing (AppStateController.loadInsightsFromBackend):**
```dart
final alertsPayload = await _alertsApi.getAlerts(accessToken: token);
final alertsList = alertsPayload['alerts'];
if (alertsList is List) {
  alerts = alertsList
    .whereType<Map>()
    .map((e) => e.cast<String, dynamic>())
    .toList();
  
  unreadAlerts = (alertsPayload['unread'] as num?)?.toInt() ?? 0;
  
  criticalAlerts = alerts.where((row) {
    final severity = (row['severity'] ?? '').toString().toLowerCase();
    return severity == 'critical' || severity == 'high';
  }).length;
}
```

---

#### **F. ImpactMetrics (lib/features/rescue/models/rescue_models.dart)**

**Dart Class:**
```dart
class ImpactMetrics {
  final int totalCompletedRescues;
  final int totalDonations;
  final int totalSurplusSales;
  final double totalCo2AvoidedKg;
  final double totalValueRecovered;
  
  const ImpactMetrics({...});
  
  static const ImpactMetrics empty = ImpactMetrics(
    totalCompletedRescues: 0,
    totalDonations: 0,
    totalSurplusSales: 0,
    totalCo2AvoidedKg: 0,
    totalValueRecovered: 0,
  );
}
```

**Stored in SQLite (RescueLocalDb):**
```sql
CREATE TABLE impact_metrics (
  id INTEGER PRIMARY KEY CHECK(id = 1),
  total_completed_rescues INTEGER NOT NULL,
  total_donations INTEGER NOT NULL,
  total_surplus_sales INTEGER NOT NULL,
  total_co2_avoided_kg REAL NOT NULL,
  total_value_recovered REAL NOT NULL
);
```

---

### 10.2 JSON Decoding Strategy (Defensive Coding)

**Pattern Used Throughout:**
```dart
// 1. Safe field extraction with ?? (null coalescing)
final id = (json['field'] ?? 'default').toString();

// 2. Type-aware numeric conversion
final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;

// 3. Enum parsing with fallback
final path = RescuePath.values.firstWhere(
  (v) => v.name == json['path'],
  orElse: () => RescuePath.donation,
);

// 4. Date parsing with null-safety
final date = DateTime.tryParse((json['date'] ?? '').toString());

// 5. List parsing with type safety
final items = (json['items'] is List)
  ? json['items'].whereType<Map>().map((e) => ...).toList()
  : [];

// 6. Nested object parsing
final user = json['user'] is Map
  ? Map<String, dynamic>.from(json['user'] ?? {})
  : {};
```

**Benefits:**
- No throws due to missing fields
- Type mismatches handled gracefully
- Empty defaults used when data unavailable
- App remains stable even with malformed JSON

---

## Summary

This documentation covers the complete mobile architecture, from app initialization through user interactions, local storage, offline support, error handling, and AI-driven features. The app is built on a **Provider-based state management pattern** with **GoRouter navigation**, **SQLite for persistent rescue data**, and **optimistic updates with fallback handling** for robust offline functionality.

The AI integration is positioned as **advisory, transparent, and user-controlled**—with clear reasoning shown for every suggestion and user override capabilities. Impact tracking via CO2 and badges provides meaningful feedback without aggressive automation.

---

**Document Version:** 1.0  
**Last Updated:** February 26, 2026  
**Author:** Technical Documentation Team
