# API Services - Quick Reference Cheatsheet

## Method Signature Pattern

All public API methods follow this pattern:

```dart
// Simple GET request returning a list
Future<List<Map<String, dynamic>>> methodName({
  required String accessToken,
}) async {
  final response = await _get('/endpoint', accessToken: accessToken);
  final items = response['key'];
  if (items is List) {
    return items.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
  return [];
}

// POST request with body
Future<Map<String, dynamic>> methodName({
  required String accessToken,
  required Map<String, dynamic> body,
}) async {
  final response = await _post(
    '/endpoint',
    accessToken: accessToken,
    body: body,
  );
  final item = response['item'];
  if (item is Map) return item.cast<String, dynamic>();
  return {};
}

// DELETE returning void
Future<void> methodName({
  required String accessToken,
  required String id,
}) async {
  await _delete('/endpoint/$id', accessToken: accessToken);
}
```

---

## Key Concepts

### 1. **async/await**
```dart
// "async" keyword = method returns Future<T>
Future<String> myMethod() async {
  // Inside async method, can use "await"
  final result = await someAsyncOperation();
  return result;
}

// Calling async method
final result = await myMethod();  // "await" pauses until done
```

### 2. **Future<T>**
```dart
Future<String>        // Will eventually return String
Future<List<Map>>     // Will eventually return List
Future<void>          // Will eventually complete (no return value)
Future<Map<String, dynamic>>  // Will eventually return a Map
```

### 3. **Bearer Token Authorization**
```dart
// Every authenticated request includes:
headers: {
  'Authorization': 'Bearer $accessToken'
}

// Obtained from login/signup response, stored in AppSessionStore
```

### 4. **Primary/Fallback URI Pattern**
```dart
// Every service tries two URIs:
final primary = ApiConfig.apiUri(path);      // /api/...
final fallback = ApiConfig.uri(path);        // /...

// Service tries primary first, falls back if 404 "route not found"
```

### 5. **Timeout Protection**
```dart
// Every HTTP request has 12-second timeout:
http.get(uri, headers: headers).timeout(const Duration(seconds: 12));

// If request takes >12s, TimeoutException is thrown
```

### 6. **Status Code Checking**
```dart
// Success: 200-299
// Failure: anything else throws Exception
if (response.statusCode >= 200 && response.statusCode < 300) {
  return jsonBody;
}
throw Exception('Request failed');
```

### 7. **Safe JSON Parsing**
```dart
// Never throws - always returns Map (or empty map)
Map<String, dynamic> _decode(String body) {
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

### 8. **Functional List Transformation**
```dart
// Transform response['items'] (untyped List) to typed List<Map>
final items = response['items'];
if (items is List) {
  return items
      .whereType<Map>()              // Keep only Maps
      .map((e) => e.cast<String, dynamic>())  // Cast each element
      .toList();                     // Convert to List
}
return [];  // Fallback
```

### 9. **Conditional Map Construction**
```dart
// Only include fields that are not null/empty
body: {
  'action': action,
  if (entityType != null && entityType.isNotEmpty) 'entity_type': entityType,
  if (details != null && details.isNotEmpty) 'details': details,
}
```

### 10. **JSON Encoding**
```dart
// Convert Dart objects to JSON string for request body:
body: jsonEncode(body)  // Map -> "{ \"key\": \"value\" }"

// Parse JSON string to Dart objects:
final decoded = jsonDecode(response.body)  // "{ ... }" -> Map
```

---

## Service File Summary

| File | Purpose | Key Methods | HTTP Methods |
|------|---------|-------------|--------------|
| **api_config.dart** | URL building | `baseUrl`, `apiUri()`, `uri()` | None |
| **auth_api_service.dart** | Authentication | `signUp()`, `signIn()`, `verifySignUp()` | POST, GET, PUT |
| **inventory_api_service.dart** | Item management | `getInventory()`, `createInventoryItem()`, `updateInventoryItem()`, `deleteInventoryItem()` | GET, POST, PUT, DELETE |
| **cashflow_api_service.dart** | Transactions | `getTransactions()`, `createTransaction()`, `getCashflowReport()` | GET, POST |
| **alerts_api_service.dart** | Notifications | `getAlerts()`, `markAlertRead()`, `resolveAlert()` | GET, PUT |
| **surplus_api_service.dart** | Marketplace | `getAvailableSurplus()`, `createSurplus()`, `claimSurplus()` | GET, POST, PUT |
| **predictions_api_service.dart** | AI/ML | `getLatestPredictions()`, `getAnomalies()` | GET, POST |
| **activity_api_service.dart** | Audit log | `getActivities()`, `insertActivity()` | GET, POST |
| **budget_api_service.dart** | Budgets | `getBudgets()`, `createBudget()`, `updateBudget()` | GET, POST, PUT, DELETE |
| **audit_api_service.dart** | Compliance | `getAuditLogs()` | GET |
| **expense_api_service.dart** | Expenses | `getExpenses()`, `submitExpense()`, `reviewExpense()` | GET, POST, PUT |
| **api_health_service.dart** | Health check | `check()` | GET |

---

## Helper Methods in Each Service

### Most Services Include:
```dart
_get(String path, {required String accessToken}) → _request()
_post(String path, {required String accessToken, required Map body}) → _request()
_put(String path, {...}) → _request()
_delete(String path, {...}) → _request()

_request({required String method, ...}) → _send()
_send({required String method, ...}) → http.get/post/put/delete

_decode(String body) → Map<String, dynamic>
_isRouteNotFound(Map<String, dynamic> jsonBody) → bool
```

### Call Chain:
```
publicMethod() 
  → _get/_post/_put/_delete() 
    → _request() 
      → _send() 
        → http.get/post/put/delete().timeout()
```

---

## Endpoint Connection Examples

### Creating an Item
```dart
// Frontend
const service = InventoryApiService();
final item = await service.createInventoryItem(
  accessToken: token,
  body: {'name': 'Beans', 'quantity': 100}
);

// Call chain:
// 1. createInventoryItem() calls _post('/inventory', ...)
// 2. _post() calls _request(method: 'POST', ...)
// 3. _request() calls _send() with http.post
// 4. http.post sends: POST http://18.175.213.46:3000/api/inventory
// 5. Backend handler: authController.insertItem()
// 6. Response: { message, item: {...} }
// 7. Returns: item as Future<Map>
```

### Getting a List
```dart
// Frontend
const service = InventoryApiService();
final items = await service.getInventory(accessToken: token);

// Response parsed as List<Map<String, dynamic>>
// Even if API returns: { items: [...] }
// Method extracts response['items'], validates type, and returns list
```

### Authentication Flow
```dart
// 1. signUp() → POST /auth/signup → "OTP sent to email"
// 2. verifySignUp() → POST /auth/signup/verify → { access_token, refresh_token, user }
// 3. Tokens stored in AppSessionStore
// 4. Future requests include: Authorization: Bearer <access_token>

// Token refresh:
// 5. refreshSession() → POST /auth/refresh → { new_access_token, new_refresh_token }
```

---

## Common Error Scenarios

### **Timeout (12 seconds exceeded)**
```
1. HTTP request takes >12s
2. .timeout(Duration(seconds: 12)) throws TimeoutException
3. UI catches error and shows "Connection timeout"
```

### **404 Route Not Found**
```
1. Primary endpoint /api/... returns 404
2. _isRouteNotFound() detects "route not found" in error message
3. Automatically retries with fallback endpoint /...
4. If fallback succeeds: return result
5. If fallback also fails: throw Exception
```

### **Non-200 Status Code**
```
1. Response status is not 200-299
2. Parse error message from response['error'] or response['message']
3. Throw Exception with meaningful message
```

### **JSON Parse Error**
```
1. Response body is not valid JSON
2. jsonDecode() throws FormatException
3. _decode() catches error and returns empty Map
4. Caller receives {} (safe fallback, not null)
```

### **Null Check Failure**
```
1. Expected response['items'] to be List
2. But it's null or wrong type
3. Type check: if (items is List) {...}
4. If false: return [] (safe fallback)
```

---

## Return Type Reference

### Map-returning Methods
```dart
Future<Map<String, dynamic>> getProfile()        // Single item
Future<Map<String, dynamic>> getCashflowReport() // Report data
Future<Map<String, dynamic>> createInventoryItem() // Created item
```

### List-returning Methods
```dart
Future<List<Map<String, dynamic>>> getInventory()      // Items list
Future<List<Map<String, dynamic>>> getActivities()     // Activities list
Future<List<Map<String, dynamic>>> getAvailableSurplus() // Surplus list
```

### Void Methods (fire & forget)
```dart
Future<void> deleteInventoryItem(...)  // No return, just success/error
Future<void> signOut(...)              // Just logout, no return
Future<void> insertActivity(...)       // Just log action
```

### Custom Return Types
```dart
Future<String> signUp(...)                    // Returns message string
Future<AuthSession> verifySignUp(...)         // Returns AuthSession object
Future<ApiHealthResult> check()               // Returns custom result object
```

---

## Type Casting Reference

```dart
// Safe type casting pattern
final item = response['item'];
if (item is Map) return item.cast<String, dynamic>();

// Safe list casting pattern
final items = response['items'];
if (items is List) {
  return items
      .whereType<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList();
}

// vs unsafe (don't do this):
return response['item'] as Map<String, dynamic>;  // ❌ Crashes if wrong type
return response['items'] as List;                  // ❌ Crashes if null
```

---

## Status Code Meanings

| Code | Meaning | Action |
|------|---------|--------|
| 200-299 | Success | Return parsed response |
| 400 | Bad request | Validation error, throw Exception |
| 401 | Unauthorized | Token invalid/expired, sign out user |
| 403 | Forbidden | Permission denied, show error |
| 404 | Not found | Route not found, try fallback URI |
| 429 | Too many requests | Rate limited, retry later |
| 500 | Server error | Backend error, show generic message |
| Timeout | Request took >12s | Network slow, ask user to retry |

---

## Authentication Headers

### With Bearer Token
```dart
headers: {
  'Authorization': 'Bearer eyJhbGc...',  // Token from login
  'Content-Type': 'application/json'
}
```

### Without Token (signup, health check)
```dart
headers: {
  'Content-Type': 'application/json'
}
// No Authorization header
```

---

## Query Parameters

### Activity Pagination
```dart
'/activity?limit=50&offset=0'  // Manually appended to path
```

### Backend-supported (not implemented in UI yet)
```
/inventory?category=Grains&low_stock=true&search=beans&limit=50
/transactions?type=income&from_date=2026-01-01&to_date=2026-02-28
/surplus?location=Lagos&limit=20
```

---

## Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| "Unable to reach server" | Check API_BASE_URL, backend running, network connectivity |
| "Route not found" | Normal - service tries /api/... then falls back to /... |
| Empty list returned | Response parsing failed - check API response format |
| Token expired | Call refreshSession(), store new tokens in AppSessionStore |
| Timeout on slow network | Increase timeout (currently 12s), or retry |
| Wrong data received | Check response parsing, may be nested differently |

---

## File Organization

```
lib/core/network/
├── api_config.dart                    # Configuration & URL building
├── auth_api_service.dart              # Authentication operations
├── inventory_api_service.dart         # Inventory CRUD
├── cashflow_api_service.dart          # Transactions
├── alerts_api_service.dart            # Alerts/notifications
├── surplus_api_service.dart           # Marketplace
├── predictions_api_service.dart       # AI/ML predictions
├── activity_api_service.dart          # Activity audit log
├── api_health_service.dart            # Server health check
├── budget_api_service.dart            # Budget management
├── audit_api_service.dart             # Audit logs
└── expense_api_service.dart           # Expense tracking
```

