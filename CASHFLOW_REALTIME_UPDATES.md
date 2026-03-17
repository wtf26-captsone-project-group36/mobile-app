# Real-Time Cashflow Screen Integration
**For Expense Approval System**  
**Status:** Production-Ready Guide

---

## Overview

When a manager approves/rejects an expense on the **ExpensesPage**, the **CashflowScreen** (which the user might have open in the background or parallel view) should **automatically update** to reflect changes in:

- ✅ Pending expense total (orange badge)
- ✅ Approved expense total (green badge)  
- ✅ Business balance (if approved)
- ✅ Budget spending (if budget_id linked)
- ✅ Risk/alert indicators

---

## Current Implementation (How It Works)

### The Watch Pattern

**File:** [cashflow_screen.dart](lib/bottom_navigation/cashflow_screen.dart#L354)

```dart
@override
Widget build(BuildContext context) {
  final state = context.watch<AppStateController>(); // ← KEY: watch() not read()
  
  // This entire build() method reruns whenever AppStateController notifies listeners
  return _buildExpensePipeline(
    pending: state.expenseSummary['total_pending'] ?? 0,  // Fresh data
    approved: state.expenseSummary['total_approved'] ?? 0, // Fresh data
  );
}
```

### The Notification Chain

```
1. User taps "Approve" on ExpensesPage
   ↓
2. reviewExpense() API call made
   ↓
3. Backend updates database (status, balance, budget, transaction)
   ↓
4. Frontend receives success response
   ↓
5. AppStateController.loadExpensesFromBackend() called
   ↓
6. AppStateController.notifyListeners() called ← BROADCAST
   ↓
7. All watching widgets rebuild (CashflowScreen, ExpensesPage, etc.)
   ↓
8. _buildExpensePipeline() recalculates with fresh data
   ↓
9. UI shows updated pending/approved amounts
```

---

## Implementation Details

### 1. AppStateController Methods

**File:** [app_state_controller_mock.dart](lib/provider/app_state_controller_mock.dart#L384)

```dart
Future<void> reviewExpense({
  required String id,
  required String decision,
  String? note,
}) async {
  final token = await AppSessionStore.instance.getAccessToken();
  if (token == null || token.isEmpty) return;

  try {
    // 1. Call backend
    await _expenseApi.reviewExpense(
      accessToken: token,
      id: id,
      decision: decision,
      note: note,
    );

    // 2. Refresh ALL related data
    await loadExpensesFromBackend();  // Updates expenses list + summary
    
    // Optional: Also refresh related data that might have changed:
    // - If you want balance to update immediately:
    // await loadCashflowReport();  // Fetches updated business balance
    
    // - If you want budget spending to update immediately:
    // await loadBudgetsFromBackend(); // Fetches updated budgets
    
    // 3. Notify all listeners to rebuild
    notifyListeners(); // ← This triggers all watching widgets
    
  } catch (e) {
    // Keep fallback values on error
    rethrow;
  }
}
```

### 2. Frontend Widget Refresh

When `notifyListeners()` is called, these widgets automatically rebuild:

```dart
// In CashflowScreen
Widget _buildExpensePipeline(double pending, double approved) {
  return Container(
    child: Row(
      children: [
        Expanded(
          child: _pipelineTile(
            'Pending Requests',
            _currency.format(pending), // ← Updates automatically
            Colors.orange,
          ),
        ),
        Expanded(
          child: _pipelineTile(
            'Approved',
            _currency.format(approved), // ← Updates automatically
            Colors.green,
          ),
        ),
      ],
    ),
  );
}
```

---

## What Gets Updated on Approval?

### Backend Changes

```javascript
// expenseController.js - reviewExpense()

if (decision === 'approved') {
  // 1. Expense status updated
  await updateExpense({ status: 'approved' });
  
  // 2. Business balance decreased
  await decreaseBalance(approvedAmount); // ← Key impact
  
  // 3. Budget spending increased
  await incrementBudgetSpent(approvedAmount); // ← Key impact
  
  // 4. Transaction record created
  await createTransaction({ type: 'expense', amount });
  
  // 5. Anomaly detection triggered
  triggerAnomalyDetection();
}
```

### Frontend State Updates

```dart
// AppStateController.loadExpensesFromBackend()

try {
  // Fetches fresh data from backend
  final backend = await _expenseApi.getExpenses(accessToken: token);
  expenses = [...backend, ...localExpenses]; // ← Updates expenses list
  
  // Calculate fresh summary
  expenseSummary = await _expenseApi.getExpenseSummary(accessToken: token);
  // Result: {
  //   'total_submitted': 500000,
  //   'total_pending': 100000,    // ← Changed
  //   'total_approved': 250000,   // ← Changed  
  //   'total_rejected': 50000,
  //   'total_cancelled': 100000
  // }
  
  notifyListeners(); // ← Triggers all watching widgets
  
} catch (e) {
  // Fallback to local data
}
```

---

## Real-Time Update Flow (Detailed)

### Step-by-Step: Approval Workflow

```
═══════════════════════════════════════════════════════════════════

BEFORE APPROVAL:
├─ CashflowScreen visible
│  ├─ Pending: NGN 250,000 (orange badge)
│  └─ Approved: NGN 150,000 (green badge)
│
└─ ExpensesPage (user is here)
   └─ Expense #123 status = "pending"

═══════════════════════════════════════════════════════════════════

STEP 1: Manager taps "Approve"
├─ Button disabled (_isLoading = true)
└─ Processing dialog shown

STEP 2: ExpensesPageEnhanced._performApproval()
├─ API call:
│  └─ reviewExpense(id: "123", decision: "approve")
└─ Waits for response

STEP 3: Backend processing
├─ Verifies expense is pending
├─ Updates expenses.status = 'approved'
├─ Updates businesses.current_balance -= 250,000
├─ Updates budgets.spent_amount += 250,000
├─ Creates transaction record
├─ Triggers anomaly detection
└─ Returns updated expense object

STEP 4: Frontend receives success
├─ AppStateController.reviewExpense() completes
└─ Next: loadExpensesFromBackend()

STEP 5: Refresh expense data
├─ GET /api/expenses (fetches updated list)
│  └─ Expense #123 now has status = "approved"
│
├─ GET /api/expenses/summary (fetches totals)
│  ├─ total_pending = 0     (← was 250,000)
│  └─ total_approved = 400,000 (← was 150,000)
│
└─ notifyListeners() called ← BROADCAST event

STEP 6: All watching widgets rebuild
├─ ExpensesPage
│  └─ Expense list item refreshes (status badge changes green)
│
└─ CashflowScreen (if visible in background)
   └─ ExpensePipeline recalculates:
      ├─ Pending: NGN 0 (was 250,000)
      └─ Approved: NGN 400,000 (was 150,000)

STEP 7: User feedback
├─ Processing dialog closed
├─ Success SnackBar shown:
│  └─ "Expense approved! NGN 250,000 deducted from balance."
└─ UI fully updated

═══════════════════════════════════════════════════════════════════

AFTER APPROVAL:
├─ CashflowScreen (auto-updated!)
│  ├─ Pending: NGN 0 (orange badge gone)
│  └─ Approved: NGN 400,000 (green badge increased)
│
└─ ExpensesPage
   └─ Expense #123 now shows:
      ├─ Status badge = "APPROVED" (green)
      ├─ Reviewed by: Manager Name
      └─ No action buttons available
```

---

## Testing Real-Time Updates

### Test Scenario 1: Side-by-Side Screens

**Setup:**
- Split screen or two windows open
- CashflowScreen on left
- ExpensesPage on right

**Action:**
1. Approve expense on right (ExpensesPage)
2. Left screen (CashflowScreen) updates **automatically**

**Expected:**
- Pending amount decreases (orange badge)
- Approved amount increases (green badge)
- No manual refresh needed

**Code to verify:**

```dart
// In CashflowScreen.build():
final state = context.watch<AppStateController>(); // ← This watch() is key

// When AppStateController.notifyListeners() fires anywhere in app,
// this build() reruns with fresh state.expenseSummary data
```

### Test Scenario 2: Sequential Navigation

**Setup:**
- User on ExpensesPage
- Approves expense
- Navigates to CashflowScreen

**Action:**
1. Approve expense (data updated, notifyListeners called)
2. Navigate to CashflowScreen

**Expected:**
- CashflowScreen shows updated pending/approved amounts

**Code:**
```dart
// After approval, user can tap:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Expense approved!'),
    action: SnackBarAction(
      label: 'View', // User taps this
      onPressed: () => context.push('/cashflow'), // Navigate
    ),
  ),
);

// When screen loads, data is already fresh from notifyListeners()
```

### Test Scenario 3: Offline Then Online

**Setup:**
- Network disabled
- User tries to approve
- Network re-enabled
- User retries

**Action:**
1. Approve (fails, cached attempt stored)
2. Re-enable network
3. Retry approval
4. CashflowScreen updates

**Code:**
```dart
Future<void> reviewExpense({...}) async {
  try {
    // API call with fallback
    await _expenseApi.reviewExpense(...);
    await loadExpensesFromBackend(); // Refreshes data
    notifyListeners(); // Broadcasts to all widgets
  } catch (e) {
    // If API fails, local fallback data is kept
    // When network returns, retry succeeds
    // loadExpensesFromBackend() fetches fresh data
    rethrow;
  }
}
```

---

## Enhanced: Manual Refresh Button

If you want to add a manual refresh button for edge cases:

```dart
// In CashflowScreen
Widget _buildRefreshButton() {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: ElevatedButton.icon(
      onPressed: () async {
        // Manually trigger data refresh
        await context.read<AppStateController>().loadExpensesFromBackend();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cashflow updated')),
        );
      },
      icon: const Icon(Icons.refresh),
      label: const Text('Refresh'),
    ),
  );
}

// Or use RefreshIndicator (pull-to-refresh):
@override
Widget build(BuildContext context) {
  return RefreshIndicator(
    onRefresh: () => context.read<AppStateController>().loadExpensesFromBackend(),
    child: ListView(...),
  );
}
```

---

## Enhanced: Real-Time Expense Summary Card

**Location:** [expenses_page_enhanced.dart](lib/pages/expenses_page_enhanced.dart#L128)

```dart
Widget _buildExpenseSummaryCard(AppStateController state) {
  final totalSubmitted = (state.expenseSummary['total_submitted'] as num?)?.toDouble() ?? 0;
  final totalApproved = (state.expenseSummary['total_approved'] as num?)?.toDouble() ?? 0;
  final totalPending = (state.expenseSummary['total_pending'] as num?)?.toDouble() ?? 0;
  final totalRejected = (state.expenseSummary['total_rejected'] as num?)?.toDouble() ?? 0;

  // These values automatically refresh when notifyListeners() is called
  // You don't need to do anything - they're connected to AppStateController
  
  return Card(
    child: Column(
      children: [
        _buildSummaryTile('Pending', _currency.format(totalPending), Colors.orange),
        _buildSummaryTile('Approved', _currency.format(totalApproved), Colors.green),
        // ...
      ],
    ),
  );
}

// When manager approves an expense:
// totalPending automatically decreases
// totalApproved automatically increases
// No manual state update needed!
```

---

## Enhanced: Linking to Budget Screen Updates

When an expense is approved, its linked budget should also update:

```dart
// In AppStateController.reviewExpense()
Future<void> reviewExpense({...}) async {
  await _expenseApi.reviewExpense(...);
  await loadExpensesFromBackend();     // Updates expense list
  await loadBudgetsFromBackend();      // Updates budget spending
  notifyListeners();                    // Broadcasts to all widgets
}

// This ensures:
// 1. ExpensesPage updates (status changes)
// 2. CashflowScreen updates (pending/approved amounts change)
// 3. BudgetsPage updates (budget spending increases) - if open
// 4. Dashboard updates (budget alerts may trigger) - if open
```

---

## Key Code Pattern: The Watch-Notify Loop

```
Provider Pattern Auto-Update Flow:

┌─────────────────────────────────────────────────────────────┐
│ AppStateController (ChangeNotifier)                         │
├─────────────────────────────────────────────────────────────┤
│ Properties:                                                 │
│  ├─ expenses: List<Expense>                                 │
│  ├─ expenseSummary: Map<String, dynamic>                    │
│  └─ [notifyListeners() triggers all watching widgets]       │
│                                                             │
│ Methods:                                                     │
│  └─ reviewExpense()                                          │
│     ├─ calls API                                             │
│     ├─ refreshes data via loadExpensesFromBackend()          │
│     └─ calls notifyListeners() ← KEY                         │
└─────────────────────────────────────────────────────────────┘
         ↑
         └─────────────────────────┐
                                   │ notifyListeners()
                                   │ triggers rebuild
┌─────────────────────────────────────────────────────────────┐
│ Watching Widgets                                             │
├─────────────────────────────────────────────────────────────┤
│ final state = context.watch<AppStateController>();  ← KEY  │
│                                                             │
│ When state changes due to notifyListeners():                │
│  1. Entire build() method reruns                             │
│  2. state.expenseSummary has fresh data                      │
│  3. UI displays updated values automatically                 │
│                                                             │
│ Watching Widgets:                                            │
│  ├─ CashflowScreen (shows pending/approved)                  │
│  ├─ ExpensesPageEnhanced (shows all expenses)                │
│  ├─ Dashboard (shows alerts if triggered)                    │
│  └─ BudgetsPage (shows budget spending updated)              │
└─────────────────────────────────────────────────────────────┘
```

---

## Summary

✅ **Real-time updates are AUTOMATIC** via the Provider pattern  
✅ **No manual state management needed** - watch() handles it  
✅ **All watching widgets update simultaneously** when notifyListeners() called  
✅ **CashflowScreen updates instantly** when expense is approved  
✅ **Multi-screen synchronized** without special code  

**What You Need To Do:**
1. Ensure AppStateController calls `notifyListeners()` after each operation ✓ (already done)
2. Ensure CashflowScreen uses `context.watch<AppStateController>()` ✓ (already done)
3. Ensure ExpensesPageEnhanced calls `reviewExpense()` after user action ✓ (included in code)
4. Test that pending/approved amounts update when you approve an expense

