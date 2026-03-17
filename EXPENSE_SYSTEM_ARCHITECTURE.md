# Expense Approval System - Architecture & Integration Map
**Visual Reference Guide**

---

## 📊 System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    HerVest AI Expense System                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                   FRONTEND (Flutter)                         │   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │                                                              │   │
│  │  Pages:                                                      │   │
│  │  ├─ ExpensesPageEnhanced (NEW)                              │   │
│  │  │  ├─ Submit expense dialog                                │   │
│  │  │  ├─ Summary card (totals)                                │   │
│  │  │  ├─ Expense list with status badges                      │   │
│  │  │  ├─ Approve confirmation dialog + feedback               │   │
│  │  │  ├─ Reject reason dialog + feedback                      │   │
│  │  │  ├─ Cancel confirmation + feedback                       │   │
│  │  │  └─ Error handling with user messages                    │   │
│  │  │                                                          │   │
│  │  └─ CashflowScreen (UPDATED)                                │   │
│  │     ├─ Uses context.watch<AppStateController>()             │   │
│  │     ├─ Displays pending expenses (orange)                   │   │
│  │     ├─ Displays approved expenses (green)                   │   │
│  │     ├─ Auto-updates when AppStateController notifies        │   │
│  │     └─ Shows real-time pending/approved totals              │   │
│  │                                                              │   │
│  │  State Management:                                           │   │
│  │  └─ AppStateController (EXISTING)                           │   │
│  │     ├─ submitExpense()                                      │   │
│  │     ├─ reviewExpense(approve/reject) ← CRITICAL             │   │
│  │     ├─ cancelExpense()                                      │   │
│  │     ├─ loadExpensesFromBackend() + notifyListeners()        │   │
│  │     ├─ expenseSummary property (watched by CashflowScreen)  │   │
│  │     └─ expenses list property (watched by ExpensesPage)     │   │
│  │                                                              │   │
│  └────────────────────┬─────────────────────────────────────────┘   │
│                       │ HTTP                                         │
│                       ▼                                              │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                   API SERVICES (Dart)                        │   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │                                                              │   │
│  │  ExpenseApiService:                                          │   │
│  │  ├─ submitExpense(title, amount, category, description)      │   │
│  │  │  └─ POST /api/expenses                                    │   │
│  │  │                                                           │   │
│  │  ├─ reviewExpense(id, decision, note) ← CRITICAL             │   │
│  │  │  └─ PUT /api/expenses/:id/review                          │   │
│  │  │     decides: 'approve' or 'reject'                        │   │
│  │  │     returns: updated expense with new status              │   │
│  │  │                                                           │   │
│  │  ├─ cancelExpense(id)                                        │   │
│  │  │  └─ PUT /api/expenses/:id/cancel                          │   │
│  │  │     returns: cancelled expense                            │   │
│  │  │                                                           │   │
│  │  ├─ getExpenses() → List<Expense>                            │   │
│  │  │  └─ GET /api/expenses                                     │   │
│  │  │                                                           │   │
│  │  └─ getExpenseSummary() → Map (totals)                       │   │
│  │     └─ GET /api/expenses/summary                             │   │
│  │        returns: {total_pending, total_approved, ...}         │   │
│  │                                                              │   │
│  └────────────────────┬─────────────────────────────────────────┘   │
│                       │ REST API                                     │
│                       ▼                                              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
                              │
                    Network Layer (HTTP)
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       BACKEND (Node.js)                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Routes (api/src/routes/):                                           │
│  ├─ POST /api/expenses                                              │
│  │  └─ → submitExpense controller                                   │
│  │                                                                  │
│  ├─ PUT /api/expenses/:id/review ← CRITICAL                         │
│  │  └─ → reviewExpense controller                                   │
│  │     ├─ Validates decision (approve/reject)                      │
│  │     ├─ Updates expense.status                                    │
│  │     ├─ If approve:                                              │
│  │     │  ├─ Creates transaction                                   │
│  │     │  ├─ Decreases business.balance                            │
│  │     │  ├─ Updates budget.spent_amount                           │
│  │     │  └─ Triggers anomaly detection                            │
│  │     ├─ If reject:                                               │
│  │     │  └─ Records rejection_reason                              │
│  │     └─ Stores review_info                                        │
│  │                                                                  │
│  ├─ PUT /api/expenses/:id/cancel                                    │
│  │  └─ → cancelExpense controller                                   │
│  │     ├─ Validates only pending can be cancelled                  │
│  │     ├─ Updates expense.status = 'cancelled'                     │
│  │     └─ No financial impact                                       │
│  │                                                                  │
│  ├─ GET /api/expenses                                               │
│  │  └─ → getExpenses controller (with pagination)                   │
│  │                                                                  │
│  └─ GET /api/expenses/summary                                       │
│     └─ → getExpenseSummary controller                               │
│        Returns: {total_submitted, total_pending, ...}               │
│                                                                      │
│  Controllers (api/src/controllers/expenseController.js):             │
│  ├─ submitExpense()    ← 59 lines                                   │
│  ├─ reviewExpense()    ← 72 lines (main logic)                      │
│  ├─ cancelExpense()    ← 35 lines                                   │
│  ├─ getExpenses()      ← 33 lines                                   │
│  ├─ getExpenseById()   ← 23 lines                                   │
│  └─ getExpenseSummary() ← 39 lines                                  │
│                                                                      │
│  Models (Database):                                                  │
│  └─ expenses table                                                  │
│     ├─ expense_id (UUID)                                            │
│     ├─ business_id (FK)                                             │
│     ├─ requested_by (user_id)                                       │
│     ├─ status (pending|approved|rejected|cancelled)                 │
│     ├─ amount (decimal)                                             │
│     ├─ category (string)                                            │
│     ├─ reviewed_by (user_id, nullable)                              │
│     ├─ rejection_reason (text, nullable)                            │
│     ├─ reviewed_at (timestamp, nullable)                            │
│     └─ created_at, updated_at (timestamps)                          │
│                                                                      │
│  Side Effects:                                                       │
│  ├─ transactions table (new record on approve)                      │
│  ├─ budgets table (spent_amount updated on approve)                 │
│  ├─ businesses table (balance updated on approve)                   │
│  ├─ audit_logs table (all operations logged)                        │
│  └─ anomaly_detection (triggered on approve)                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow: Approval Process

```
USER ACTION: Manager Taps "Approve" Button
│
├─ ExpensesPageEnhanced._showApprovalConfirmation()
│  ├─ Shows dialog: "Approve NGN X?warning icon"
│  └─ User confirms
│
├─ ExpensesPageEnhanced._performApproval()
│  ├─ setState(() => _isLoading = true)
│  ├─ _showProcessingDialog() [loading spinner]
│  │
│  └─ context.read<AppStateController>().reviewExpense(
│     id: expenseId,
│     decision: 'approve'
│  )
│
├─ AppStateController.reviewExpense()
│  ├─ Gets auth token
│  ├─ Calls _expenseApi.reviewExpense()
│  │
│  └─ _expenseApi.reviewExpense()
│     ├─ HTTP Request: PUT /api/expenses/:id/review
│     │  with body: {decision: 'approve'}
│     │
│     └─ Backend Processing:
│        ├─ Validates expense exists
│        ├─ Validates status is 'pending'
│        ├─ Updates expenses table:
│        │  ├─ status = 'approved'
│        │  ├─ reviewed_by = manager_id
│        │  └─ reviewed_at = now
│        │
│        ├─ Creates transaction:
│        │  └─ transactions.insert({type: 'expense', amount})
│        │
│        ├─ Updates business balance:
│        │  └─ businesses.update({balance: balance - amount})
│        │
│        ├─ Updates budget spending:
│        │  └─ budgets.update({spent: spent + amount})
│        │
│        ├─ Creates audit log:
│        │  └─ audit_logs.insert({action: 'expense.approved'})
│        │
│        ├─ Triggers anomaly detection
│        │
│        └─ Returns: {expense: updatedExpenseObject}
│
│  ├─ API call succeeds, response received
│  ├─ Calls await loadExpensesFromBackend()
│  │
│  └─ AppStateController.loadExpensesFromBackend()
│     ├─ Calls _expenseApi.getExpenses()
│     │  └─ GET /api/expenses
│     │     Returns: fresh list of all expenses
│     │
│     ├─ Updates: expenses = [...]
│     │
│     ├─ Calls _expenseApi.getExpenseSummary()
│     │  └─ GET /api/expenses/summary
│     │     Returns: {total_pending: NEW, total_approved: NEW, ...}
│     │
│     ├─ Updates: expenseSummary = {...}
│     │
│     └─ Calls notifyListeners() ← CRITICAL
│        │
│        └─ Broadcasting event:
│           "AppStateController changed! Rebuild all watching widgets!"
│
├─ Watching widgets rebuild:
│
│  1️⃣ ExpensesPageEnhanced rebuilds
│     ├─ Closes processing dialog
│     ├─ Shows success SnackBar:
│     │  "Expense approved! NGN X deducted."
│     ├─ Refreshes expense list
│     ├─ Expense status badge changes: PENDING → APPROVED (green)
│     ├─ Action buttons disappear (no more approve/reject)
│     └─ _isLoading = false
│
│  2️⃣ CashflowScreen rebuilds (if visible in background)
│     ├─ Calls build() again with fresh state
│     ├─ Gets fresh: state.expenseSummary['total_pending']
│     ├─ Gets fresh: state.expenseSummary['total_approved']
│     ├─ Orange badge "Pending: NGN Y" (decreased)
│     └─ Green badge "Approved: NGN Z" (increased)
│
│  3️⃣ BudgetsPage rebuilds (if visible)
│     ├─ Budget.spent_amount increased
│     └─ remaining changes
│
│  4️⃣ Dashboard rebuilds (if visible)
│     └─ May show budget alert if exceeded
│
└─ END: System is consistent across all screens
```

---

## 🗂️ File Structure & Dependencies

```
PROJECT ROOT
├─ lib/
│  │
│  ├─ pages/
│  │  ├─ expenses_page.dart (OLD - can backup)
│  │  └─ expenses_page_enhanced.dart (NEW - REPLACES above)
│  │     ├─ Uses: AppStateController (provider)
│  │     ├─ Uses: ProfileController (provider)
│  │     ├─ Calls: reviewExpense(), cancelExpense(), submitExpense()
│  │     └─ Shows: Confirmation dialogs, loading states, success/error messages
│  │
│  ├─ bottom_navigation/
│  │  └─ cashflow_screen.dart (UPDATED)
│  │     ├─ MUST use: context.watch<AppStateController>()
│  │     ├─ Displays: pending & approved expense totals
│  │     └─ Auto-updates when AppStateController.notifyListeners()
│  │
│  ├─ provider/
│  │  └─ app_state_controller_mock.dart (KEY - unchanged, verify notifyListeners)
│  │     ├─ reviewExpense() → calls loadExpensesFromBackend() → notifyListeners()
│  │     ├─ cancelExpense() → calls loadExpensesFromBackend() → notifyListeners()
│  │     ├─ submitExpense() → calls loadExpensesFromBackend() → notifyListeners()
│  │     └─ loadExpensesFromBackend() → fetches fresh data → notifyListeners()
│  │
│  ├─ core/network/
│  │  └─ expense_api_service.dart (UNCHANGED - wrapper for API)
│  │     ├─ submitExpense() → POST /api/expenses
│  │     ├─ reviewExpense() → PUT /api/expenses/:id/review
│  │     ├─ cancelExpense() → PUT /api/expenses/:id/cancel
│  │     ├─ getExpenses() → GET /api/expenses
│  │     └─ getExpenseSummary() → GET /api/expenses/summary
│  │
│  ├─ models/
│  │  └─ api_response_models.dart (UNCHANGED)
│  │     └─ class Expense { status, amount, submittedBy, reviewedBy, reviewNote }
│  │
│  └─ router/
│     └─ app_router.dart (NEEDS UPDATE)
│        └─ Change: GoRoute('/expenses') → ExpensesPageEnhanced()
│
├─ api/
│  └─ src/
│     ├─ controllers/
│     │  └─ expenseController.js (BACKEND LOGIC)
│     │     ├─ submitExpense() ← 59 lines
│     │     ├─ reviewExpense() ← 72 lines (CRITICAL)
│     │     ├─ cancelExpense() ← 35 lines
│     │     ├─ getExpenses() ← 33 lines
│     │     ├─ getExpenseById() ← 23 lines
│     │     └─ getExpenseSummary() ← 39 lines
│     │
│     ├─ routes/
│     │  └─ index.js (ENDPOINTS)
│     │     ├─ POST /api/expenses
│     │     ├─ PUT /api/expenses/:id/review (auth required, role: owner|manager)
│     │     ├─ PUT /api/expenses/:id/cancel (auth required)
│     │     ├─ GET /api/expenses
│     │     └─ GET /api/expenses/summary
│     │
│     └─ middleware/
│        └─ validators.js
│           └─ expenseReviewValidator() ← Validates decision field
│
├─ DOCUMENTATION (NEW - Created from this issue)
│  ├─ EXPENSE_APPROVAL_FLOW.md (Complete workflow guide)
│  ├─ CASHFLOW_REALTIME_UPDATES.md (Real-time mechanism)
│  ├─ EXPENSE_IMPLEMENTATION_GUIDE.md (Step-by-step integration)
│  ├─ EXPENSE_SYSTEM_SUMMARY.md (Overview)
│  └─ EXPENSE_SYSTEM_ARCHITECTURE.md (This file)
│
└─ pubspec.yaml (UNCHANGED)
   └─ Dependencies: flutter, provider (already have)
```

---

## 🔐 Role-Based Access Control

```
WHO CAN DO WHAT:

┌─────────────┬──────────────┬─────────────┬──────────────┐
│ Action      │ Staff        │ Manager     │ Owner        │
├─────────────┼──────────────┼─────────────┼──────────────┤
│ Submit      │ ✅ Pending   │ ✅ Direct   │ ✅ Direct    │
│ Approve     │ ❌ No        │ ✅ Yes      │ ✅ Yes       │
│ Reject      │ ❌ No        │ ✅ Yes      │ ✅ Yes       │
│ Cancel Own  │ ✅ Pending   │ ✅ Pending  │ ✅ Pending   │
│ Cancel Other│ ❌ No        │ ❌ No       │ ❌ No (own++) │
│ View All    │ ❌ Own only  │ ✅ All      │ ✅ All       │
└─────────────┴──────────────┴─────────────┴──────────────┘

Implementation:
├─ ExpensesPageEnhanced:
│  ├─ canReview = role == 'owner' || role == 'manager'
│  ├─ Show approve/reject buttons only if canReview
│  └─ Show cancel button for all (pending only)
│
└─ Backend (expenseController.js):
   ├─ submitExpense: Any role
   ├─ reviewExpense: requireRole('owner', 'manager')
   ├─ cancelExpense: Any role (checks requested_by == user.id for staff)
   └─ getExpenses: Staff sees own only, managers see all
```

---

## 🚦 Status Flow & Colors

```
Expense Lifecycle:

                        ✅ APPROVED (Green)
                       /  │ → Creates transaction
      ⏳ PENDING ────────  │ → Deducts balance
     / (Orange)  \  │      │ → Updates budget
    /             │  │      │
Submit          Reject  Cancel
    │             │  │      │
    │          ❌ │  │      │ ❌ CANCELLED (Gray)
    │        REJECTED      │ → No impact
    │          (Red)       │
    │             │        │
    │          Resubmit    │
    │             │        │
    └─────────────┘        │
         └──────────────────┘

Status → Color → Actions Possible
- pending (Orange)  → Approve, Reject, Cancel
- approved (Green)  → None (view only)
- rejected (Red)    → Resubmit (new expense)
- cancelled (Gray)  → None (view only)
```

---

## 📡 API Response Format

### Submit Request
```dart
POST /api/expenses
Content-Type: application/json
Authorization: Bearer <token>

{
  "title": "Office Supplies",
  "amount": 15000,
  "category": "Supplies",
  "description": "Monthly stationery"
}

// Response 201:
{
  "expense": {
    "expense_id": "exp-xxx",
    "title": "Office Supplies",
    "amount": 15000,
    "category": "Supplies",
    "status": "pending",
    "submitted_at": "2026-03-17T10:30:00Z",
    "created_at": "2026-03-17T10:30:00Z",
    "submitted_by": "user-123"
  }
}
```

### Review Request (Approve)
```dart
PUT /api/expenses/exp-xxx/review
Content-Type: application/json
Authorization: Bearer <token>
X-Requires-Role: owner, manager

{
  "decision": "approve"  // or "reject"
}

// Response 200:
{
  "message": "Expense approved",
  "expense": {
    "expense_id": "exp-xxx",
    "status": "approved",
    "reviewed_by": "manager-456",
    "reviewed_at": "2026-03-17T10:45:00Z"
  }
}
```

### Review Request (Reject)
```dart
PUT /api/expenses/exp-xxx/review
Content-Type: application/json
Authorization: Bearer <token>
X-Requires-Role: owner, manager

{
  "decision": "reject",
  "note": "Missing receipt"
}

// Response 200:
{
  "message": "Expense rejected",
  "expense": {
    "expense_id": "exp-xxx",
    "status": "rejected",
    "reviewed_by": "manager-456",
    "review_note": "Missing receipt",
    "reviewed_at": "2026-03-17T10:45:00Z"
  }
}
```

### Summary Request
```dart
GET /api/expenses/summary
Authorization: Bearer <token>

// Response 200:
{
  "summary": {
    "total_submitted": 500000,
    "total_approved": 250000,
    "total_pending": 100000,
    "total_rejected": 50000,
    "total_cancelled": 100000,
    "count": 5
  }
}
```

---

## ✨ Key Features Implemented

| Feature | Location | Status |
|---------|----------|--------|
| Submit Expense | ExpensesPageEnhanced | ✅ Included |
| Approval Dialog | ExpensesPageEnhanced | ✅ Included |
| Rejection Dialog + Reason | ExpensesPageEnhanced | ✅ Included |
| Cancel Dialog | ExpensesPageEnhanced | ✅ Included |
| Loading State | ExpensesPageEnhanced | ✅ Included |
| Success Messages | ExpensesPageEnhanced | ✅ Included |
| Error Handling | ExpensesPageEnhanced | ✅ Included |
| Status Badges | ExpensesPageEnhanced | ✅ Included |
| Summary Card | ExpensesPageEnhanced | ✅ Included |
| Real-Time Updates | CashflowScreen (watch) | ✅ Already works |
| Role-Based Access | ExpensesPageEnhanced | ✅ Included |
| Resubmit Button | ExpensesPageEnhanced | ✅ Included |

---

## 🎯 Success Indicators

✅ **System working when:**
1. Staff submits → appears as pending
2. Manager approves → balance updates, status changes
3. CashflowScreen pending/approved change instantly
4. All error cases handled gracefully
5. User always sees what happened (success/error message)
6. Rejection with reason works
7. Cancel works for pending only
8. Staff can't approve
9. Multiple managers see same data
10. Offline mode has fallback

---

## 📞 Quick Navigation

| Need | File |
|------|------|
| Complete workflow | [EXPENSE_APPROVAL_FLOW.md](EXPENSE_APPROVAL_FLOW.md) |
| Implementation steps | [EXPENSE_IMPLEMENTATION_GUIDE.md](EXPENSE_IMPLEMENTATION_GUIDE.md) |
| Real-time mechanism | [CASHFLOW_REALTIME_UPDATES.md](CASHFLOW_REALTIME_UPDATES.md) |
| Code to implement | [lib/pages/expenses_page_enhanced.dart](lib/pages/expenses_page_enhanced.dart) |
| High-level summary | [EXPENSE_SYSTEM_SUMMARY.md](EXPENSE_SYSTEM_SUMMARY.md) |

