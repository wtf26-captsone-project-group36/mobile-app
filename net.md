# Complete Guide to API Service Methods (lib/core/network/)

## Overview
This document explains every method in the network folder, including:
- **Purpose**: What the method does
- **Async/Future Logic**: How asynchronous operations work
- **Implementation**: The actual code flow
- **Endpoint Connection**: Which backend endpoint it calls
- **Parameters**: Input requirements
- **Return Type**: What data is returned

---

## 1. API_CONFIG.DART
**File**: [lib/core/network/api_config.dart](lib/core/network/api_config.dart)

**Purpose**: Centralized configuration for API base URL and URI construction. Provides a single source of truth for all API endpoints.

### Methods

#### 1.1 `baseUrl` (static getter)
**Purpose**: Get normalized API base URL with trailing slashes removed.

**Implementation Logic**:
```dart
static String get baseUrl => _normalizeBaseUrl(_rawBaseUrl);
```

**Flow**:
1. Reads `API_BASE_URL` environment variable (set via `--dart-define`)
2. Default: `http://18.175.213.46:3000`
3. Calls `_normalizeBaseUrl()` to clean the URL

**No endpoint call** - Just URL processing.

---

#### 1.2 `uri()` (static method)
**Purpose**: Create a URI for non-API routes (e.g., `/health` as root-mounted route).

**Signature**:
```dart
static Uri uri(String path)
```

**Parameters**:
- `path`: Route path like `/health` or `health`

**Implementation**:
```dart
static Uri uri(String path) {
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$baseUrl$normalizedPath');
}
```

**Example**:
- Input: `/health`
- Output: `http://18.175.213.46:3000/health`

**Endpoint Connection**: Used as **fallback** when `/api/...` routes don't exist. Tries `/health` instead of `/api/health`.

---

#### 1.3 `apiUri()` (static method)
**Purpose**: Create a URI for API routes under `/api` prefix.

**Signature**:
```dart
static Uri apiUri(String path)
```

**Parameters**:
- `path`: Route path like `/inventory` or `inventory`

**Implementation**:
```dart
static Uri apiUri(String path) {
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  final alreadyHasApi = baseUrl.toLowerCase().endsWith('/api') ||
      baseUrl.toLowerCase().endsWith('/api/');
  final apiBase = alreadyHasApi ? _trimTrailingSlash(baseUrl) : '$baseUrl$apiPrefix';
  return Uri.parse('$apiBase$normalizedPath');
}
```

**Smart Logic**:
- If base URL already has `/api`, don't add it again
- Otherwise, append `/api` prefix
- Ensure no duplicate slashes

**Example**:
- Input: `/inventory`
- Output: `http://18.175.213.46:3000/api/inventory`

**Endpoint Connection**: Used as **primary** URI for all API calls.

---

#### 1.4 `_normalizeBaseUrl()` (static private method)
**Purpose**: Remove trailing slashes from URLs.

**Implementation**:
```dart
static String _normalizeBaseUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.endsWith('/')) {
    return trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}
```

**Example**:
- Input: `http://18.175.213.46:3000/`
- Output: `http://18.175.213.46:3000`

---

#### 1.5 `_trimTrailingSlash()` (static private method)
**Purpose**: Clean up trailing slashes for URL assembly.

**Implementation**: Same as `_normalizeBaseUrl()` but used in context of API prefix handling.

---

## 2. AUTH_API_SERVICE.DART
**File**: [lib/core/network/auth_api_service.dart](lib/core/network/auth_api_service.dart)

**Purpose**: Handle all authentication operations (signup, signin, token refresh, profile management).

**Helper Classes**:

### AuthApiException
Custom exception class for authentication errors.
```dart
class AuthApiException implements Exception {
  AuthApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}
```

### AuthSession
Data class returned on successful signin/signup.
```dart
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;
}
```

### Methods

#### 2.1 `signUp()`
**Purpose**: Initiate signup by sending user details and receiving OTP.

**Signature**:
```dart
Future<String> signUp({
  required String email,
  required String password,
  required String fullName,
  required String businessType,
  required String businessName,
  required String role,
}) async
```

**Parameters**:
- `email`: User's email address
- `password`: Password (validated server-side for ≥8 chars)
- `fullName`: User's full name
- `businessType`: Type of business (restaurant, farmer, etc.)
- `businessName`: Business name
- `role`: User role (owner, manager, staff)

**Async/Future Flow**:
```
signUp() 
  → _post('/auth/signup', body) 
    → http.post(...) with 12s timeout
      → response parsed to JSON
      → extract message
```

**Implementation Logic**:
1. Method marked `async` - can use `await`
2. Calls `_post()` helper which:
   - Creates HTTP POST request
   - Adds JSON headers and body
   - Sets 12-second timeout
   - Tries primary `/api/auth/signup` first
   - Falls back to `/auth/signup` if 404
3. Returns message from response (e.g., "Verification code sent")

**Endpoint Connection**:
- **Primary**: `POST /api/auth/signup`
- **Backend Handler**: [authController.signUp](../api/src/controllers/authController.js)
- **Response**: `{ message, email }`

**Return Type**: `Future<String>` - The message text for UI display

---

#### 2.2 `verifySignUp()`
**Purpose**: Verify OTP code and complete registration.

**Signature**:
```dart
Future<AuthSession> verifySignUp({
  required String email,
  required String otp,
}) async
```

**Parameters**:
- `email`: Email that received OTP
- `otp`: 6-digit OTP code from email

**Implementation**:
```dart
final response = await _post(
  '/auth/signup/verify',
  body: {'email': email, 'otp': otp},
);
return AuthSession(
  accessToken: (response['access_token'] ?? '').toString(),
  refreshToken: (response['refresh_token'] ?? '').toString(),
  user: Map<String, dynamic>.from(response['user'] ?? {}),
);
```

**Async Flow**:
1. Calls `_post('/auth/signup/verify', ...)`
2. Awaits response (blocks until server responds or 12s timeout)
3. Constructs `AuthSession` object with tokens
4. Returns session for storage in secure storage

**Endpoint Connection**:
- **POST /api/auth/signup/verify**
- **Backend**: Validates OTP, creates Supabase user, returns tokens
- **Response**: `{ access_token, refresh_token, user }`

**Return Type**: `Future<AuthSession>` - Session with tokens and user data

---

#### 2.3 `signIn()`
**Purpose**: Authenticate existing user with email/password.

**Signature**:
```dart
Future<AuthSession> signIn({
  required String email,
  required String password,
}) async
```

**Implementation**:
```dart
final response = await _post(
  '/auth/signin',
  body: {'email': email, 'password': password},
);
return AuthSession(
  accessToken: (response['access_token'] ?? '').toString(),
  refreshToken: (response['refresh_token'] ?? '').toString(),
  user: Map<String, dynamic>.from(response['user'] ?? {}),
);
```

**Async/Future**: Same pattern as `verifySignUp()` - await POST, parse response, return session.

**Endpoint Connection**:
- **POST /api/auth/signin**
- **Backend**: Validates credentials with Supabase, returns tokens
- **Response**: `{ access_token, refresh_token, user }`

**Return Type**: `Future<AuthSession>`

---

#### 2.4 `sendPasswordResetOtp()`
**Purpose**: Send password reset OTP to email.

**Signature**:
```dart
Future<void> sendPasswordResetOtp({required String email}) async
```

**Implementation**:
```dart
await _post('/auth/password/reset', body: {'email': email});
```

**Async/Future Logic**:
1. Awaits POST request completion
2. Error handling: If 404 (endpoint not found), tries fallback
3. Returns `void` (no return value, just side effect of email sent)

**Endpoint Connection**:
- **POST /api/auth/password/reset**
- **Fallback**: tries `POST /password/reset` if primary 404
- **Backend**: Generates OTP and sends email
- **Response**: Success or error

**Return Type**: `Future<void>` - Completes when request done

---

#### 2.5 `verifyOtpAndResetPassword()`
**Purpose**: Verify OTP and set new password.

**Signature**:
```dart
Future<void> verifyOtpAndResetPassword({
  required String email,
  required String otp,
  required String newPassword,
}) async
```

**Parameters**:
- `email`: User's email
- `otp`: OTP from email
- `newPassword`: New password to set

**Implementation**:
```dart
await _post(
  '/auth/password/verify',
  body: {
    'email': email,
    'otp': otp,
    'new_password': newPassword,
  },
);
```

**Endpoint Connection**:
- **POST /api/auth/password/verify**
- **Backend**: Validates OTP, updates password in Supabase
- **Response**: Success or error

---

#### 2.6 `signOut()`
**Purpose**: Logout user and invalidate tokens.

**Signature**:
```dart
Future<void> signOut({
  required String accessToken,
  String? refreshToken,
}) async
```

**Implementation**:
```dart
await _post(
  '/auth/signout',
  body: {
    if (refreshToken != null && refreshToken.isNotEmpty)
      'refreshToken': refreshToken,
  },
  headers: {
    'Authorization': 'Bearer $accessToken',
  },
);
```

**Key Points**:
- Uses `as` keyword to pass headers (custom headers)
- Authorization header contains Bearer token
- Refresh token is optional (nullable)

**Endpoint Connection**:
- **POST /api/auth/signout**
- **Backend**: Invalidates tokens in Redis/database
- **Authentication**: Required (Bearer token)

---

#### 2.7 `getProfile()`
**Purpose**: Fetch authenticated user's profile information.

**Signature**:
```dart
Future<Map<String, dynamic>> getProfile({
  required String accessToken,
}) async
```

**Implementation**:
```dart
final response = await _get(
  '/auth/profile',
  headers: {'Authorization': 'Bearer $accessToken'},
);
final user = response['user'];
if (user is Map) return user.cast<String, dynamic>();
return {};
```

**Async/Future Flow**:
1. Calls `_get()` (GET request helper)
2. Awaits response
3. Type-checks response to ensure it's a Map
4. Casts to correct type and returns
5. Returns empty map if parsing fails (safe fallback)

**Endpoint Connection**:
- **GET /api/auth/profile**
- **Authentication**: Required
- **Response**: `{ user: { id, email, full_name, business_name, ... } }`

**Return Type**: `Future<Map<String, dynamic>>` - User profile data

---

#### 2.8 `updateProfile()`
**Purpose**: Update user profile fields.

**Signature**:
```dart
Future<Map<String, dynamic>> updateProfile({
  required String accessToken,
  required Map<String, dynamic> body,
}) async
```

**Parameters**:
- `accessToken`: Bearer token
- `body`: Fields to update (flexible - can include name, phone, business_name, etc.)

**Implementation**:
```dart
final response = await _put(
  '/auth/profile',
  body: body,
  headers: {'Authorization': 'Bearer $accessToken'},
);
final user = response['user'];
if (user is Map) return user.cast<String, dynamic>();
return {};
```

**Endpoint Connection**:
- **PUT /api/auth/profile**
- **Backend**: Updates user in Supabase with provided fields
- **Response**: `{ user: { updated_user_data } }`

---

#### 2.9 `refreshSession()`
**Purpose**: Get new access token using refresh token.

**Signature**:
```dart
Future<AuthSession> refreshSession({
  required String refreshToken,
}) async
```

**Implementation**:
```dart
final response = await _post(
  '/auth/refresh',
  body: {'refresh_token': refreshToken},
);
return AuthSession(
  accessToken: (response['access_token'] ?? '').toString(),
  refreshToken: (response['refresh_token'] ?? '').toString(),
  user: const <String, dynamic>{},
);
```

**Endpoint Connection**:
- **POST /api/auth/refresh**
- **Backend**: Validates refresh token, returns new access token
- **Response**: `{ access_token, refresh_token }`

**Return Type**: `Future<AuthSession>`

---

### 2.10 Helper Methods in AuthApiService

#### `_post()` (private)
**Purpose**: Generic POST request handler with error handling.

**Signature**:
```dart
Future<Map<String, dynamic>> _post(
  String path, {
  required Map<String, dynamic> body,
  Map<String, String>? headers,
}) async
```

**Implementation Flow**:
```dart
1. Create primaryUri = ApiConfig.apiUri(path)
2. Create fallbackUri = ApiConfig.uri(path)
3. Try POST to primary with:
   - Content-Type: application/json
   - Custom headers if provided
   - JSON-encoded body
   - 12-second timeout
4. Parse response to JSON
5. If 404 and "route not found", try fallback URI
6. If status 200-299, return JSON
7. Otherwise throw AuthApiException with error message
```

**Async/Future Logic**:
- Marked `async` to use `await`
- `http.post()` returns `Future<http.Response>`
- `.timeout()` creates a timeout Future
- Both futures are awaited
- If timeout triggers, exception thrown

---

#### `_get()` (private)
**Purpose**: Generic GET request handler.

**Similar pattern to `_post()` but uses `http.get()` and no body.

---

#### `_put()` (private)
**Purpose**: Generic PUT request handler.

**Uses `_requestWithBody()` internally.

---

#### `_requestWithBody()` and `_requestWithoutBody()` (private)
**Purpose**: Abstracted request handling with fallback logic.

**Key Features**:
1. **Primary/Fallback pattern**: 
   - Try `/api/...` first
   - Fall back to `/...` if 404
2. **Error Handling**:
   - Check if error message contains "route not found"
   - Throw `AuthApiException` with meaningful message
3. **Status Code Checking**:
   - Success: 200-299
   - Failure: throw exception with parsed error message

---

#### `_decodeToMap()`
**Purpose**: Safely parse JSON response body.

**Implementation**:
```dart
Map<String, dynamic> _decodeToMap(String body) {
  if (body.trim().isEmpty) return {};
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  } catch (_) {
    return {};
  }
}
```

**Defensive Coding**:
- Handles empty responses
- Catches JSON decode errors
- Always returns a Map (never throws)
- Called defensive/safe parsing

---

#### `_isRouteNotFound()`
**Purpose**: Detect if error is "route not found" to trigger fallback.

**Logic**:
```dart
final message = (jsonBody['error'] ?? jsonBody['message'] ?? '').toString().toLowerCase();
return message.contains('route') && message.contains('not found');
```

---

## 3. INVENTORY_API_SERVICE.DART
**File**: [lib/core/network/inventory_api_service.dart](lib/core/network/inventory_api_service.dart)

**Purpose**: Manage inventory item CRUD operations.

### Methods

#### 3.1 `getInventory()`
**Purpose**: Fetch all inventory items for authenticated user.

**Signature**:
```dart
Future<List<Map<String, dynamic>>> getInventory({
  required String accessToken,
}) async
```

**Implementation**:
```dart
final response = await _get('/inventory', accessToken: accessToken);
final items = response['items'];
if (items is List) {
  return items
      .whereType<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList();
}
return [];
```

**Async/Future Flow**:
1. Calls `_get()` with access token (adds Authorization header)
2. Awaits GET request to `/inventory`
3. Parses response JSON
4. Extracts `items` array
5. Type-safely converts to `List<Map<String, dynamic>>`
6. Handles parsing errors by returning empty list

**Functional Programming**:
- `whereType<Map>()`: Filter only Map objects
- `.map()`: Transform each Map
- `.cast<String, dynamic>()`: Type cast safely
- `.toList()`: Convert to list

**Endpoint Connection**:
- **GET /api/inventory**
- **Backend**: Returns all items for user's business
- **Query Params** (backend supports): category, low_stock, search, limit, offset, etc.

**Return Type**: `Future<List<Map<String, dynamic>>>` - List of items

---

#### 3.2 `createInventoryItem()`
**Purpose**: Add new inventory item.

**Signature**:
```dart
Future<Map<String, dynamic>> createInventoryItem({
  required String accessToken,
  required Map<String, dynamic> body,
}) async
```

**Parameters**:
- `accessToken`: Bearer token
- `body`: Item data (name, sku, category, quantity, unit, price, expiry_date, etc.)

**Implementation**:
```dart
final response = await _post(
  '/inventory',
  accessToken: accessToken,
  body: body,
);
final item = response['item'];
if (item is Map) return item.cast<String, dynamic>();
return {};
```

**Endpoint Connection**:
- **POST /api/inventory**
- **Backend**: Validates input, checks reorder level, auto-creates alert if needed
- **Response**: `{ message, item: { item_id, item_name, quantity, ... } }`

**Return Type**: `Future<Map<String, dynamic>>` - Created item data

---

#### 3.3 `updateInventoryItem()`
**Purpose**: Update existing inventory item.

**Signature**:
```dart
Future<Map<String, dynamic>> updateInventoryItem({
  required String accessToken,
  required String itemId,
  required Map<String, dynamic> body,
}) async
```

**Implementation**:
```dart
final response = await _put(
  '/inventory/$itemId',
  accessToken: accessToken,
  body: body,
);
final item = response['item'];
if (item is Map) return item.cast<String, dynamic>();
return {};
```

**Endpoint Connection**:
- **PUT /api/inventory/:id**
- **Path Parameter**: itemId embedded in URL
- **Backend**: Updates item fields in database
- **Response**: `{ message, item: { updated_item_data } }`

---

#### 3.4 `deleteInventoryItem()`
**Purpose**: Remove inventory item.

**Signature**:
```dart
Future<void> deleteInventoryItem({
  required String accessToken,
  required String itemId,
}) async
```

**Implementation**:
```dart
await _delete(
  '/inventory/$itemId',
  accessToken: accessToken,
);
```

**Endpoint Connection**:
- **DELETE /api/inventory/:id**
- **Backend**: Soft delete (mark is_active=false) or hard delete
- **Response**: Success or error

**Return Type**: `Future<void>` - Completes when deleted

---

### 3.5 Helper Methods in InventoryApiService

#### `_get()` (private)
**Purpose**: Construct and execute GET request with fallback.

**Pattern**:
```dart
Future<Map<String, dynamic>> _get(String path, {required String accessToken}) async {
  final primary = ApiConfig.apiUri(path);
  final fallback = ApiConfig.uri(path);
  return _request(
    method: 'GET',
    primaryUri: primary,
    fallbackUri: fallback,
    headers: {'Authorization': 'Bearer $accessToken'},
  );
}
```

**Key Points**:
- Creates both primary (`/api/...`) and fallback (`/...`) URIs
- Passes to generic `_request()` handler
- Authorization header automatically included

---

#### `_post()` (private)
**Similar to `_get()` but with JSON body encoding**:
```dart
return _request(
  method: 'POST',
  // ...
  headers: {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  },
  body: jsonEncode(body),
);
```

---

#### `_put()`, `_delete()` (private)
**Similar pattern to `_post()` with appropriate HTTP method.

---

#### `_request()` (private)
**Purpose**: Generic request handler with primary/fallback logic.

**Async/Future Flow**:
```dart
1. Call _send() with primary URI
2. Parse response JSON
3. If 404 and "route not found":
   - Retry with fallback URI
   - Parse again
4. Check status code:
   - 200-299: return jsonBody
   - Otherwise: throw Exception
```

**Key Feature**: Primary/fallback pattern handles both:
- `/api/inventory` (primary)
- `/inventory` (fallback if primary doesn't exist)

---

#### `_send()` (private)
**Purpose**: Execute actual HTTP request based on method.

**Implementation**:
```dart
if (method == 'GET') {
  return http.get(uri, headers: headers).timeout(const Duration(seconds: 12));
}
if (method == 'PUT') {
  return http.put(uri, headers: headers, body: body).timeout(...);
}
if (method == 'DELETE') {
  return http.delete(uri, headers: headers).timeout(...);
}
return http.post(uri, headers: headers, body: body).timeout(...);
```

**Conditional Branching**: Uses method name to determine which HTTP method to call.

**Timeout**: Every request has 12-second timeout to prevent indefinite hanging.

---

#### `_decode()` (private)
**Purpose**: Safely parse JSON response body (same safe pattern as AuthApiService).

---

## 4. CASHFLOW_API_SERVICE.DART
**File**: [lib/core/network/cashflow_api_service.dart](lib/core/network/cashflow_api_service.dart)

**Purpose**: Handle transaction and cashflow reporting.

### Methods

#### 4.1 `getTransactions()`
**Purpose**: Fetch financial transactions.

**Signature**:
```dart
Future<List<Map<String, dynamic>>> getTransactions({
  required String accessToken,
}) async
```

**Implementation**:
```dart
final response = await _get('/transactions', accessToken: accessToken);
final transactions = response['transactions'];
if (transactions is List) {
  return transactions
      .whereType<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList();
}
return [];
```

**Endpoint Connection**:
- **GET /api/transactions**
- **Query Params** (backend supports): type, category, from_date, to_date, limit, offset
- **Backend**: Returns list of all transactions for user's business
- **Response**: `{ transactions: [...], total, limit, offset }`

**Return Type**: `Future<List<Map<String, dynamic>>>` - List of transactions

---

#### 4.2 `createTransaction()`
**Purpose**: Log a financial transaction (income, expense, refund, adjustment).

**Signature**:
```dart
Future<Map<String, dynamic>> createTransaction({
  required String accessToken,
  required Map<String, dynamic> body,
}) async
```

**Body Parameters**:
- `type`: "income" | "expense" | "refund" | "adjustment"
- `amount`: Transaction amount
- `category`: Category name (e.g., "Sales", "Utilities")
- `description`: Optional description
- `transaction_date`: Optional date (default: now)

**Endpoint Connection**:
- **POST /api/transactions**
- **Backend**: Validates type, stores in database, triggers anomaly detection
- **Response**: `{ message, transaction: { id, type, amount, date, ... } }`

---

#### 4.3 `getCashflowReport()`
**Purpose**: Get financial summary report.

**Signature**:
```dart
Future<Map<String, dynamic>> getCashflowReport({
  required String accessToken,
}) async
```

**Implementation**:
```dart
final response = await _get('/transactions/report', accessToken: accessToken);
final report = response['report'];
if (report is Map) return report.cast<String, dynamic>();
return {};
```

**Endpoint Connection**:
- **GET /api/transactions/report**
- **Backend**: Aggregates all transactions, calculates:
  - Total income
  - Total expense
  - Available balance
  - Average daily burn
  - Cash runway (days until broke)
- **Response**: `{ report: { total_income, total_expense, balance, days_remaining, ... } }`

**Return Type**: `Future<Map<String, dynamic>>` - Report data

---

### 4.4 Helper Methods
**Similar to InventoryApiService with `_get()`, `_post()`, `_request()`, `_send()` helpers.**

---

## 5. ALERTS_API_SERVICE.DART
**File**: [lib/core/network/alerts_api_service.dart](lib/core/network/alerts_api_service.dart)

**Purpose**: Manage user alerts and notifications.

### Methods

#### 5.1 `getAlerts()`
**Purpose**: Fetch alerts for authenticated user.

**Signature**:
```dart
Future<Map<String, dynamic>> getAlerts({
  required String accessToken,
}) async
```

**Implementation**:
```dart
return _get('/alerts', accessToken: accessToken);
```

**Endpoint Connection**:
- **GET /api/alerts**
- **Query Params**: alert_type, severity, is_read, limit, offset
- **Response**: `{ alerts: [...], total }`

**Return Type**: `Future<Map<String, dynamic>>` - Alerts list and metadata

---

#### 5.2 `markAlertRead()`
**Purpose**: Mark alert as read (dismiss).

**Signature**:
```dart
Future<Map<String, dynamic>> markAlertRead({
  required String accessToken,
  required String alertId,
}) async
```

**Endpoint Connection**:
- **PUT /api/alerts/:id/read**
- **Backend**: Updates is_read flag in database
- **Response**: `{ alert: { updated_data } }`

---

#### 5.3 `resolveAlert()`
**Purpose**: Mark alert as resolved (closed/archived).

**Signature**:
```dart
Future<Map<String, dynamic>> resolveAlert({
  required String accessToken,
  required String alertId,
}) async
```

**Endpoint Connection**:
- **PUT /api/alerts/:id/resolve**
- **Backend**: Updates status to "resolved"
- **Response**: `{ alert: { resolved_at, status, ... } }`

---

## 6. SURPLUS_API_SERVICE.DART
**File**: [lib/core/network/surplus_api_service.dart](lib/core/network/surplus_api_service.dart)

**Purpose**: Manage surplus item marketplace operations.

### Methods

#### 6.1 `getAvailableSurplus()`
**Purpose**: Browse surplus items from other businesses.

**Signature**:
```dart
Future<List<Map<String, dynamic>>> getAvailableSurplus({
  required String accessToken,
}) async
```

**Endpoint Connection**:
- **GET /api/surplus**
- **Query Params**: location, is_free, limit, offset
- **Response**: `{ surplus: [...] }`

**Return Type**: `Future<List<Map<String, dynamic>>>` - Available surplus items

---

#### 6.2 `getMySurplus()`
**Purpose**: View user's own listed surplus items.

**Signature**:
```dart
Future<List<Map<String, dynamic>>> getMySurplus({
  required String accessToken,
}) async
```

**Endpoint Connection**:
- **GET /api/surplus/mine**
- **Backend**: Filters by owner_id (current user)
- **Response**: `{ surplus: [...] }`

---

#### 6.3 `createSurplus()`
**Purpose**: List excess inventory as surplus.

**Signature**:
```dart
Future<Map<String, dynamic>> createSurplus({
  required String accessToken,
  required Map<String, dynamic> body,
}) async
```

**Body Parameters**:
- `inventory_id`: Link to inventory item (optional)
- `name`: Surplus item name
- `quantity`: Quantity available
- `unit`: Unit (kg, units, liters, etc.)
- `description`: Item description
- `expiry_date`: When item expires
- `pickup_deadline`: When to pickup by
- `is_free`: Whether free or paid
- `price`: Price if not free
- `location`: Pickup location

**Endpoint Connection**:
- **POST /api/surplus**
- **Backend**: Creates entry in surplus table, logs activity
- **Response**: `{ message, surplus: { id, status: "available", ... } }`

---

#### 6.4 `claimSurplus()`
**Purpose**: Claim another business's surplus item.

**Signature**:
```dart
Future<Map<String, dynamic>> claimSurplus({
  required String accessToken,
  required String id,
}) async
```

**Endpoint Connection**:
- **PUT /api/surplus/:id/claim**
- **Backend**: Marks item as claimed, records claiming user
- **Response**: `{ surplus: { status: "claimed", claimed_by: user_id, ... } }`

---

#### 6.5 `updateSurplusStatus()`
**Purpose**: Update surplus item status.

**Signature**:
```dart
Future<Map<String, dynamic>> updateSurplusStatus({
  required String accessToken,
  required String id,
  required String status,
}) async
```

**Parameters**:
- `status`: "available" | "claimed" | "expired"

**Endpoint Connection**:
- **PUT /api/surplus/:id/status**
- **Backend**: Updates status field
- **Response**: `{ surplus: { updated_data } }`

---

## 7. PREDICTIONS_API_SERVICE.DART
**File**: [lib/core/network/predictions_api_service.dart](lib/core/network/predictions_api_service.dart)

**Purpose**: Handle AI/ML prediction endpoints.

### Methods

#### 7.1 `getLatestPredictions()`
**Purpose**: Fetch latest cashflow and inventory predictions.

**Signature**:
```dart
Future<Map<String, dynamic>> getLatestPredictions({
  required String accessToken,
}) async
```

**Endpoint Connection**:
- **GET /api/predictions**
- **Backend**: Returns latest predictions for business
- **Response**: `{ cashflow_prediction: {...}, inventory_prediction: {...} }`

---

#### 7.2 `getAnomalies()`
**Purpose**: Get detected spending anomalies.

**Signature**:
```dart
Future<List<Map<String, dynamic>>> getAnomalies({
  required String accessToken,
}) async
```

**Implementation**:
```dart
final response = await _get('/predictions/anomalies', accessToken: accessToken);
final anomalies = response['anomalies'];
if (anomalies is List) {
  return anomalies.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
}
return [];
```

**Endpoint Connection**:
- **GET /api/predictions/anomalies**
- **Response**: `{ anomalies: [ { z_score, deviation_percentage, ... } ] }`

---

#### 7.3 `insertCashflowPrediction()`
**Purpose**: Submit cashflow prediction (backend ML service use).

**Signature**:
```dart
Future<Map<String, dynamic>> insertCashflowPrediction({
  required String businessId,
  required String riskLevel,
  required int daysUntilBroke,
  required double confidenceScore,
}) async
```

**Note**: Called by backend ML service, not typically from Flutter app.

**Endpoint Connection**:
- **POST /api/predictions/cashflow**
- **Backend**: Stores prediction in database

---

#### 7.4 `insertInventoryPrediction()`
**Purpose**: Submit inventory risk prediction.

**Similar to `insertCashflowPrediction()` but for inventory data.

---

#### 7.5 `insertAnomaly()`
**Purpose**: Submit detected expense anomaly.

---

## 8. ACTIVITY_API_SERVICE.DART
**File**: [lib/core/network/activity_api_service.dart](lib/core/network/activity_api_service.dart)

**Purpose**: Log and retrieve user activities.

### Methods

#### 8.1 `getActivities()`
**Purpose**: Fetch user's activity history.

**Signature**:
```dart
Future<List<Map<String, dynamic>>> getActivities({
  required String accessToken,
  int limit = 50,
  int offset = 0,
}) async
```

**Parameters**:
- `limit`: Results per page (default 50)
- `offset`: Pagination offset (default 0)

**Implementation**:
```dart
final response = await _get(
  '/activity?limit=$limit&offset=$offset',
  accessToken: accessToken,
);
final rows = response['activities'];
if (rows is List) {
  return rows.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
}
return [];
```

**Endpoint Connection**:
- **GET /api/activity?limit=50&offset=0**
- **Query String Building**: Manually appends query params to path
- **Response**: `{ activities: [...], total }`

**Return Type**: `Future<List<Map<String, dynamic>>>` - Activity events

---

#### 8.2 `insertActivity()`
**Purpose**: Log a user action.

**Signature**:
```dart
Future<void> insertActivity({
  required String accessToken,
  required String action,
  String? entityType,
  String? entityId,
  Map<String, dynamic>? details,
}) async
```

**Parameters**:
- `action`: Action name (e.g., "inventory.insert", "transaction.insert")
- `entityType`: Optional entity type (e.g., "inventory", "transaction")
- `entityId`: Optional ID of affected entity
- `details`: Optional structured details

**Implementation**:
```dart
await _post(
  '/activity',
  accessToken: accessToken,
  body: {
    'action': action,
    if (entityType != null && entityType.isNotEmpty) 'entity_type': entityType,
    if (entityId != null && entityId.isNotEmpty) 'entity_id': entityId,
    if (details != null && details.isNotEmpty) 'details': details,
  },
);
```

**Conditional Map Building**:
- Uses `if (condition) key: value` syntax to conditionally include fields
- Only sends non-null and non-empty values
- Keeps API request lean

**Endpoint Connection**:
- **POST /api/activity**
- **Backend**: Stores activity log entry with timestamp
- **Response**: Success or error

**Return Type**: `Future<void>` - Completes when logged

---

### 8.3 Helper Methods
**Includes `_get()`, `_post()`, `_requestGet()`, `_request()` with similar patterns.

**Note**: Uses separate `_requestGet()` and `_request()` for GET vs POST operations.

---

## 9. API_HEALTH_SERVICE.DART
**File**: [lib/core/network/api_health_service.dart](lib/core/network/api_health_service.dart)

**Purpose**: Check if backend server is reachable and healthy.

### Helper Class: ApiHealthResult
```dart
class ApiHealthResult {
  const ApiHealthResult({
    required this.ok,
    required this.statusCode,
    required this.endpointTried,
    this.payload,
    this.error,
  });
  
  final bool ok;          // Was request successful?
  final int? statusCode;  // HTTP status code
  final String endpointTried; // Which endpoint was tried
  final Map<String, dynamic>? payload; // Response body
  final String? error;    // Error message
}
```

### Methods

#### 9.1 `check()`
**Purpose**: Verify backend connectivity without authentication.

**Signature**:
```dart
Future<ApiHealthResult> check() async
```

**Implementation Flow**:
```dart
1. Try primary: GET /api/health (8s timeout)
   - If 200: Success
   - If timeout/error: Continue to fallback
   
2. Try fallback: GET /health (8s timeout)
   - If 200: Success
   - If error: Return error result

3. Return ApiHealthResult with:
   - ok: true/false
   - statusCode: HTTP code
   - endpointTried: Which endpoint worked
   - payload: Response JSON
   - error: Error message if any
```

**Key Feature**: **No authentication required** - tests server health without tokens.

**Timeout Handling**:
```dart
final apiResponse = await http.get(apiHealth).timeout(
  const Duration(seconds: 8),
);
```

Timeout of 8 seconds (shorter than regular 12s).

**Async/Future Logic**:
```dart
try {
  // Try primary
  if (successful) return success result;
} catch (_) {
  // Swallow error, try fallback
}

try {
  // Try fallback
  return fallback result;
} catch (e) {
  // Return error result
  return error result;
}
```

**Multiple try-catch pattern**: Handles both primary and fallback gracefully.

**Return Type**: `Future<ApiHealthResult>` - Status details

---

#### 9.2 `_tryDecode()`
**Purpose**: Safely parse health check response.

**Defensive pattern**: Never throws, always returns `Map?`.

---

## 10. BUDGET_API_SERVICE.DART
**File**: [lib/core/network/budget_api_service.dart](lib/core/network/budget_api_service.dart)

**Purpose**: Handle budget CRUD operations (partially implemented).

### Methods

#### 10.1 `getBudgets()`
**Purpose**: Fetch all budgets for user.

**Signature**:
```dart
Future<List<Map<String, dynamic>>> getBudgets({
  required String accessToken,
}) async
```

**Endpoint**: `GET /api/budgets`

---

#### 10.2 `createBudget()`
**Purpose**: Create new budget.

**Endpoint**: `POST /api/budgets`

---

#### 10.3 `updateBudget()`
**Purpose**: Update existing budget.

**Endpoint**: `PUT /api/budgets/:id`

---

#### 10.4 `deleteBudget()`
**Purpose**: Delete budget.

**Endpoint**: `DELETE /api/budgets/:id`

---

### 10.5 Generic `_request()` Helper
**Purpose**: Unified request handler for all HTTP methods.

**Smart Implementation**:
```dart
Future<http.Response> _send({
  required String method,
  required Uri uri,
  required String accessToken,
  Map<String, dynamic>? body,
}) async {
  final headers = <String, String>{'Authorization': 'Bearer $accessToken'};
  if (body != null) headers['Content-Type'] = 'application/json';
  
  if (method == 'GET') {
    return http.get(uri, headers: headers).timeout(const Duration(seconds: 12));
  }
  if (method == 'PUT') {
    return http
        .put(uri, headers: headers, body: jsonEncode(body ?? {}))
        .timeout(const Duration(seconds: 12));
  }
  if (method == 'DELETE') {
    return http.delete(uri, headers: headers).timeout(const Duration(seconds: 12));
  }
  return http
      .post(uri, headers: headers, body: jsonEncode(body ?? {}))
      .timeout(const Duration(seconds: 12));
}
```

**Consolidates headers and method dispatch** into single helper.

---

## 11. AUDIT_API_SERVICE.DART
**File**: [lib/core/network/audit_api_service.dart](lib/core/network/audit_api_service.dart)

**Purpose**: Retrieve audit logs (compliance/tracking).

### Methods

#### 11.1 `getAuditLogs()`
**Purpose**: Fetch audit log entries.

**Signature**:
```dart
Future<List<Map<String, dynamic>>> getAuditLogs({
  required String accessToken,
}) async
```

**Implementation**:
```dart
final response = await _request(
  path: '/audit-logs',
  accessToken: accessToken,
);
final rows = response['audit_logs'];
if (rows is List) {
  return rows.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
}
return [];
```

**Endpoint**: `GET /api/audit-logs`

**Return Type**: `Future<List<Map<String, dynamic>>>` - Audit entries

---

### 11.2 Helper Methods
**Minimalist implementation**: Only `_request()` and helper methods.

No POST/PUT/DELETE - readonly audit logs.

---

## 12. EXPENSE_API_SERVICE.DART
**File**: [lib/core/network/expense_api_service.dart](lib/core/network/expense_api_service.dart)

**Purpose**: Handle expense submission and review workflow.

### Methods

#### 12.1 `getExpenses()`
**Purpose**: Fetch all expenses for user.

**Endpoint**: `GET /api/expenses`

---

#### 12.2 `getExpenseSummary()`
**Purpose**: Get expense summary/totals.

**Endpoint**: `GET /api/expenses/summary`

**Return Type**: `Future<Map<String, dynamic>>` - Summary metrics

---

#### 12.3 `submitExpense()`
**Purpose**: Submit new expense for review.

**Signature**:
```dart
Future<Map<String, dynamic>> submitExpense({
  required String accessToken,
  required Map<String, dynamic> body,
}) async
```

**Endpoint**: `POST /api/expenses`

**Body**: Expense details (amount, category, receipt, notes, etc.)

---

#### 12.4 `reviewExpense()`
**Purpose**: Approve or reject submitted expense (manager/owner only).

**Signature**:
```dart
Future<Map<String, dynamic>> reviewExpense({
  required String accessToken,
  required String id,
  required String decision,
  String? note,
}) async
```

**Parameters**:
- `decision`: "approved" | "rejected"
- `note`: Optional rejection reason

**Endpoint**: `PUT /api/expenses/:id/review`

---

#### 12.5 `cancelExpense()`
**Purpose**: Cancel submitted expense before review.

**Endpoint**: `PUT /api/expenses/:id/cancel`

---

### 12.6 Generic `_send()` Helper
**Similar pattern to BudgetApiService** - unified HTTP method dispatch.

---

## Common Patterns Across All Services

### 1. **Async/Future Pattern**
```dart
Future<T> methodName() async {
  final response = await _helper();  // Await async operation
  return parseResponse(response);     // Return parsed result
}
```

**Key Points**:
- Methods marked `async`
- Use `await` to wait for HTTP requests
- Return `Future<T>` where T is return type
- Calling code: `var result = await service.method();`

---

### 2. **Primary/Fallback URI Pattern**
```dart
final primary = ApiConfig.apiUri(path);      // /api/...
final fallback = ApiConfig.uri(path);        // /...
// Try primary first, fallback if 404
```

**Why**: Handles both:
- Standard `/api` routes (Express production)
- Non-prefixed routes (some edge cases)

---

### 3. **Type-Safe Parsing**
```dart
final response = await _get(...);
final items = response['items'];
if (items is List) {
  return items.whereType<Map>().map(...).toList();
}
return [];  // Safe fallback
```

**Defensive**: Never throws type errors, returns empty collection.

---

### 4. **Authorization Header**
```dart
'Authorization': 'Bearer $accessToken'
```

**Standard Bearer token pattern**: All authenticated endpoints require this.

---

### 5. **JSON Encoding/Decoding**
```dart
// Encoding (request body)
body: jsonEncode(body)

// Decoding (response)
final decoded = jsonDecode(response.body);
```

**Safe decoding**: Try-catch returns empty map on parse failure.

---

### 6. **12-Second Timeout**
```dart
.timeout(const Duration(seconds: 12))
```

**Applied to every HTTP request**: Prevents indefinite hangs.

---

### 7. **Error Handling**
```dart
if (response.statusCode >= 200 && response.statusCode < 300) {
  return jsonBody;
}
throw Exception(message);  // or AuthApiException
```

**Status Code Check**: 200-299 = success, anything else = error throw.

---

## Data Flow Example: Creating Inventory Item

```
User UI
  ↓ (taps "Add Item" button)
InventoryProvider.addItemFromApi()
  ↓
InventoryApiService.createInventoryItem(
  accessToken: token,
  body: { name, quantity, ... }
)
  ↓
_post('/inventory', accessToken, body)
  ↓
_request(method: 'POST', ...)
  ↓
_send(method: 'POST', uri: http://18.175.213.46:3000/api/inventory, ...)
  ↓
http.post(uri, headers: { Authorization, Content-Type }, body: jsonEncode(...))
  ↓ (12s timeout wraps this)
BACKEND: POST /api/inventory
  (validates, stores in Supabase, checks reorder level, creates alert...)
  ↓ response: { message, item: {...} }
  ↓ (200 status code)
_request() parses response
  ↓ returns jsonBody
createInventoryItem() extracts item from response
  ↓ returns Future<Map>
Provider receives item, updates _items list
  ↓ notifyListeners()
UI rebuilds, shows new item in list
```

---

## Summary Table

| Service | Methods | Primary Purpose | Endpoints |
|---------|---------|-----------------|-----------|
| **ApiConfig** | 5 | URL building | None - config only |
| **AuthApiService** | 9 | User auth | /auth/* endpoints |
| **InventoryApiService** | 4 | Item CRUD | /inventory endpoints |
| **CashflowApiService** | 3 | Transactions | /transactions endpoints |
| **AlertsApiService** | 3 | Notifications | /alerts endpoints |
| **SurplusApiService** | 5 | Marketplace | /surplus endpoints |
| **PredictionsApiService** | 5 | AI/ML | /predictions endpoints |
| **ActivityApiService** | 2 | Audit log | /activity endpoints |
| **ApiHealthService** | 1 | Server check | /health endpoint |
| **BudgetApiService** | 4 | Budget mgmt | /budgets endpoints |
| **AuditApiService** | 1 | Compliance | /audit-logs endpoint |
| **ExpenseApiService** | 5 | Expense tracking | /expenses endpoints |

---

## Async/Future Best Practices Used

1. ✅ **All network calls are async** - never blocks UI thread
2. ✅ **Timeouts enforced** - 12s max per request
3. ✅ **Error handling** - throws exceptions for caller to handle
4. ✅ **Safe null handling** - returns empty collections, not null
5. ✅ **Type safety** - `.cast<T>()` and `is T` checks
6. ✅ **Fallback logic** - primary/fallback URI pattern
7. ✅ **Authorization** - Bearer tokens on all authenticated calls
8. ✅ **Defensive parsing** - try-catch with safe defaults

