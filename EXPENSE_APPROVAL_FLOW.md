# Expense Approval Flow - Complete Guide
**Location:** HerVest AI Flutter App  
**Last Updated:** March 17, 2026  
**Status:** Production-Ready Implementation Guide

---

## 1. OVERVIEW - What Happens on Each Action

When a new expense is added and requires approval, the system supports three operations:

| Action | Performer | What Happens | Status Change | Financial Impact |
|--------|-----------|--------------|---------------|-----------------|
| **APPROVE** | Owner/Manager only | Expense moves to approved, deducts from balance, increments budget spending, creates transaction record, triggers anomaly detection | pending → **approved** | ✅ Amount immediately deducted from business balance |
| **REJECT** | Owner/Manager only | Expense marked as rejected, stays in pending queue for reference, no financial impact | pending → **rejected** | ❌ No deduction, funds remain intact |
| **CANCEL** | Requester (staff) or Self | Only pending expenses can be cancelled, removed from approval queue, no financial impact | pending → **cancelled** | ❌ No deduction, funds remain intact |

---

## 2. DETAILED FLOW - APPROVAL OPERATION

### 2.1 User Action: Staff Submits Expense (Add Expense Page)

**Location:** [cashflow_addexpense_page.dart](lib/bottom_navigation/cashflow_addexpense_page.dart#L484)

```dart
// Step 1: User fills form and submits
await _expenseService.submitExpense(
  accessToken: token,
  body: {
    'budget_id': _selectedCategoryBudget?.id,
    'title': _categoryController.text.trim(),
    'category': _categoryController.text.trim(),
    'amount': amount,
    'description': _descriptionController.text.trim(),
    'purpose': _descriptionController.text.trim().isEmpty
        ? 'Expense submitted on ${_formatDisplayDate(_selectedDate)}'
        : _descriptionController.text.trim(),
  },
);

// Step 2: Local fallback for demo mode
await _fallbackStore.addExpense(
  title: _categoryController.text.trim(),
  amount: amount,
  category: _categoryController.text.trim(),
  description: _descriptionController.text.trim(),
  status: 'pending',
);

// Step 3: Show success feedback
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      submittedForApproval
          ? "Expense submitted for approval." // Staff flow
          : "Expense saved successfully!", // Owner/Manager flow
    ),
    backgroundColor: Colors.green,
  ),
);
```

**Expense Status:** `pending` → Awaits manager/owner review

---

### 2.2 State Update in AppStateController

**Location:** [app_state_controller_mock.dart](lib/provider/app_state_controller_mock.dart#L370)

```dart
Future<void> submitExpense({...}) async {
  // ... submit to backend ...
  await loadExpensesFromBackend(); // ✅ Refreshes entire expense list
}
```

---

### 2.3 Manager/Owner Reviews Expense (Expenses Page)

**Location:** [expenses_page.dart](lib/pages/expenses_page.dart#L68)

```dart
// APPROVE button (Owner/Manager only)
TextButton(
  onPressed: () async => state.reviewExpense(
    id: id,
    decision: 'approve', // ✅ Decision sent to backend
  ),
  child: const Text('Approve'),
),

// REJECT button (Owner/Manager only)
TextButton(
  onPressed: () async => state.reviewExpense(
    id: id,
    decision: 'reject',
  ),
  child: const Text('Reject'),
),

// CANCEL button (Anyone can cancel their own pending)
TextButton(
  onPressed: () async => state.cancelExpense(id),
  child: const Text('Cancel'),
),
```

---

## 3. BACKEND PROCESSING - What Happens on Approve/Reject/Cancel

### 3.1 APPROVE - Full Impact

**Backend Endpoint:** `PUT /api/expenses/:id/review`  
**Location:** [expenseController.js](api/src/controllers/expenseController.js#L152)

```javascript
async function reviewExpense(req, res) {
  // Verify only pending expenses can be reviewed
  if (existing.status !== 'pending') 
    return error('Only pending expenses can be reviewed');

  // 1️⃣ Update expense status
  await supabaseAdmin
    .from('expenses')
    .update({
      status: 'approved', // ← Status changed
      reviewed_by: req.user.id, // ← Reviewer recorded
      reviewed_at: new Date().toISOString()
    })
    .eq('expense_id', id);

  // 2️⃣ Create transaction record
  await supabaseAdmin
    .from('transactions')
    .insert({
      business_id: businessId,
      date: new Date().toISOString(),
      type: 'expense',
      amount: approvedAmount, // ← Amount logged
      category: existing.category,
      description: existing.purpose
    });

  // 3️⃣ Deduct from business balance
  const currentBalance = await getBusinessBalance(businessId);
  await supabaseAdmin
    .from('businesses')
    .update({
      current_balance: currentBalance - approvedAmount // ← Balance reduced
    })
    .eq('business_id', businessId);

  // 4️⃣ Increment budget spending
  await incrementBudgetSpendById(existing.budget_id, approvedAmount);
  // Updates: budget.spent_amount += approvedAmount
  // Result: budget.remaining_amount = allocated - spent

  // 5️⃣ Trigger AI anomaly detection
  setImmediate(() => triggerAnomalyDetection(supabaseAdmin, businessId));
  // Checks for unusual spending patterns

  // 6️⃣ Create audit log
  await auditLog({
    userId: req.user.id,
    action: 'expense.approved',
    entityType: 'expense',
    entityId: id,
    oldValue: {status: 'pending'},
    newValue: {status: 'approved'}
  });

  return res.status(200).json({
    message: 'Expense approved',
    expense: updatedExpenseObject
  });
}
```

**What Changed in Database:**
- ✅ `expenses.status` = `'approved'`
- ✅ `expenses.reviewed_by` = manager/owner ID
- ✅ `expenses.reviewed_at` = timestamp
- ✅ `businesses.current_balance` -= expense.amount
- ✅ `budgets.spent_amount` += expense.amount
- ✅ `transactions.type` = `'expense'` entry created
- ✅ Audit trail recorded

---

### 3.2 REJECT - Minimal Impact

**Backend Endpoint:** `PUT /api/expenses/:id/review`

```javascript
// Same flow as above, but:
async function reviewExpense(req, res) {
  const status = decision === 'reject' ? 'rejected' : 'approved';

  // Only status and review info updated
  const updates = {
    status: 'rejected', // ← Status changed
    reviewed_by: req.user.id,
    reviewed_at: new Date().toISOString(),
    rejection_reason: note // ← Reason recorded (optional)
  };

  // ❌ NO transaction created
  // ❌ NO balance deducted
  // ❌ NO budget spending incremented
  // ✅ Only status and metadata updated

  return {message: 'Expense rejected', expense: updatedObject};
}
```

**What Changed in Database:**
- ✅ `expenses.status` = `'rejected'`
- ✅ `expenses.reviewed_by` = manager/owner ID
- ✅ `expenses.reviewed_at` = timestamp
- ✅ `expenses.rejection_reason` = note (if provided)
- ❌ NO financial changes

---

### 3.3 CANCEL - Requester's Right

**Backend Endpoint:** `PUT /api/expenses/:id/cancel`  
**Location:** [expenseController.js](api/src/controllers/expenseController.js#L238)

```javascript
async function cancelExpense(req, res) {
  // Verify only pending expenses can be cancelled
  if (existing.status !== 'pending') 
    return error('Only pending expenses can be cancelled');

  // Check role: staff can cancel only their own
  if (role === 'staff' && existing.requested_by !== userId)
    return error('Cannot cancel other user\'s expense');

  // Update status only
  const updates = {
    status: 'cancelled', // ← Status changed
    updated_at: new Date().toISOString()
  };

  // ❌ NO financial changes
  // ❌ NO transaction created
  // ❌ NO budget impact
  // ✅ Only marked as cancelled

  await auditLog({
    action: 'expense.cancelled',
    entityId: id,
    newValue: {status: 'cancelled'}
  });

  return {message: 'Expense cancelled', expense: updatedObject};
}
```

**What Changed in Database:**
- ✅ `expenses.status` = `'cancelled'`
- ✅ `expenses.updated_at` = timestamp
- ❌ NO financial changes
- ✅ Audit trail recorded

---

## 4. FRONTEND STATE UPDATE - AppStateController

**Location:** [app_state_controller_mock.dart](lib/provider/app_state_controller_mock.dart#L384)

```dart
Future<void> reviewExpense({
  required String id,
  required String decision,
  String? note,
}) async {
  final token = await AppSessionStore.instance.getAccessToken();
  if (token == null || token.isEmpty) return;
  
  try {
    // Call API
    await _expenseApi.reviewExpense(
      accessToken: token,
      id: id,
      decision: decision, // 'approve' or 'reject'
      note: note,
    );
    
    // ✅ Refresh ALL expense data
    await loadExpensesFromBackend();
    
    // ✅ Refresh cashflow summary
    await loadCashflowReport(); // Updates balance
    
    // ✅ Refresh budget data since spending may have changed
    await loadBudgetsFromBackend();
    
  } catch (e) {
    // Handle error (see section 7)
  }
}

Future<void> cancelExpense(String id) async {
  final token = await AppSessionStore.instance.getAccessToken();
  if (token == null || token.isEmpty) return;
  
  try {
    // Call API
    await _expenseApi.cancelExpense(accessToken: token, id: id);
    
    // ✅ Refresh expense list
    await loadExpensesFromBackend();
    
  } catch (e) {
    // Handle error
  }
}
```

---

## 5. CASHFLOW SCREEN UPDATES

### 5.1 Current Display State

**Location:** [cashflow_screen.dart](lib/bottom_navigation/cashflow_screen.dart#L354)

The Cashflow Screen shows:

1. **Expense Pipeline Card** - Displays pending vs approved amounts
2. **Pending Requests** - Orange badge showing total pending expense amount
3. **Approved** - Green badge showing total approved expense amount

```dart
Widget _buildExpensePipeline(double pending, double approved) {
  return Container(
    child: Row(
      children: [
        Expanded(
          child: _pipelineTile('Pending Requests', 
            _currency.format(pending), // Orange - awaiting approval
            Colors.orange
          ),
        ),
        Expanded(
          child: _pipelineTile('Approved', 
            _currency.format(approved), // Green - already deducted
            Colors.green
          ),
        ),
      ],
    ),
  );
}
```

### 5.2 How Amounts Are Calculated

**Location:** [cashflow_screen.dart](lib/bottom_navigation/cashflow_screen.dart#L585)

```dart
// From AppStateController.expenseSummary
final pending = (state.expenseSummary['total_pending'] as num?)?.toDouble() ?? 0;
final approved = (state.expenseSummary['total_approved'] as num?)?.toDouble() ?? 0;

// Total pending = sum of all expenses where status == 'pending'
// Total approved = sum of all expenses where status == 'approved'
```

### 5.3 Real-Time Updates

**When Should CashflowScreen Update?**

| Action | Impact | Screen Update |
|--------|--------|---------------|
| Manager approves expense | Pending ↓ | Approved ↑ | **Automatic** - UI rebuilds when ReviewExpense completes |
| Manager rejects expense | Pending ↓ | Rejected ↑ | **Automatic** - UI rebuilds when ReviewExpense completes |
| Staff cancels expense | Pending ↓ | Cancelled ↑ | **Automatic** - UI rebuilds when CancelExpense completes |

**How It Works:**

```dart
// In AppStateController
void loadExpensesFromBackend() {
  // ... fetch data ...
  notifyListeners(); // ← Triggers all watching widgets to rebuild
}

// In CashflowScreen
Widget build(BuildContext context) {
  final state = context.watch<AppStateController>(); // ← Watches for changes
  
  // When state.expenses changes, this entire method rebuilds
  // ExpensePipeline card automatically recalculates pending/approved
  // based on updated expense list
  
  return _buildExpensePipeline(pending, approved); // Same data, auto-updated
}
```

---

## 6. UX FLOW - USER FEEDBACK

### 6.1 Current UX (Minimal Feedback)

**Location:** [expenses_page.dart](lib/pages/expenses_page.dart#L68)

```dart
TextButton(
  onPressed: () async => state.reviewExpense(
    id: id,
    decision: 'approve',
  ), // ← No feedback, no confirmation
  child: const Text('Approve'),
),
```

**Issues:**
- ❌ No confirmation before approving (expensive operation!)
- ❌ No success/error feedback to user
- ❌ No loading state while processing
- ❌ Screen doesn't update visually to show the change

### 6.2 ENHANCED UX - Recommended Implementation

```dart
// Add confirmation dialog + loading state + success feedback

TextButton(
  onPressed: id.isEmpty ? null : () => _showApprovalConfirmation(context, id),
  child: const Text('Approve'),
),

// ============================================================================

Future<void> _showApprovalConfirmation(BuildContext context, String expenseId) async {
  final expense = context.read<AppStateController>().expenses
    .firstWhere((e) => e.id == expenseId, orElse: () => null);
  
  if (expense == null) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Approve Expense?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount: NGN ${_currency.format(expense.amount)}'),
          const SizedBox(height: 8),
          Text('Category: ${expense.category}'),
          const SizedBox(height: 8),
          Text('Submitted by: ${expense.submittedBy}'),
          const SizedBox(height: 16),
          Text(
            'This will deduct NGN ${_currency.format(expense.amount)} from your business balance.',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Approve'),
        ),
      ],
    ),
  );

  if (confirmed == true && mounted) {
    // Show loading state
    _showProcessingDialog(context);

    try {
      // Perform approval
      await context.read<AppStateController>().reviewExpense(
        id: expenseId,
        decision: 'approve',
      );

      if (!mounted) return;
      Navigator.pop(context); // Close processing dialog

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense approved! NGN ${_currency.format(expense.amount)} deducted.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // UI automatically updates because AppStateController calls notifyListeners()
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close processing dialog

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${_extractErrorMessage(e)}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

void _showProcessingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      title: Text('Processing...'),
      content: SizedBox(
        height: 40,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    ),
  );
}
```

### 6.3 Rejection Dialog (with Reason)

```dart
Future<void> _showRejectionDialog(BuildContext context, String expenseId) async {
  final reasonController = TextEditingController();
  
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reject Expense?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Please provide a reason for rejection:'),
          const SizedBox(height: 12),
          TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g., Missing receipt, Exceeds category budget, etc.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Reject'),
        ),
      ],
    ),
  );

  if (confirmed == true && mounted) {
    _showProcessingDialog(context);

    try {
      await context.read<AppStateController>().reviewExpense(
        id: expenseId,
        decision: 'reject',
        note: reasonController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense rejected. Reason recorded.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${_extractErrorMessage(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  reasonController.dispose();
}
```

### 6.4 Cancel Dialog

```dart
Future<void> _showCancelDialog(BuildContext context, String expenseId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancel Expense?'),
      content: const Text('This cannot be undone. The expense will be marked as cancelled.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep It'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Cancel Expense'),
        ),
      ],
    ),
  );

  if (confirmed == true && mounted) {
    _showProcessingDialog(context);

    try {
      await context.read<AppStateController>().cancelExpense(expenseId);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense cancelled.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${_extractErrorMessage(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

---

## 7. ERROR HANDLING

### 7.1 Possible Errors & Handling

| Error | Cause | Handling |
|-------|-------|----------|
| **'Only pending expenses can be reviewed'** | Trying to approve/reject non-pending expense (already processed) | Show: "This expense has already been processed" |
| **'Access denied'** / **403** | Non-owner/manager trying to approve | Show: "Only managers can approve expenses" |
| **'Expense not found'** / **404** | Expense ID invalid or deleted | Show: "Expense no longer exists" |
| **'Only pending expenses can be cancelled'** | Trying to cancel approved/rejected/cancelled expense | Show: "Only pending expenses can be cancelled" |
| **Network error** | No internet connection | Show: "Connection error. Please check your network" |
| **'Insufficient balance'** | Approving would exceed available balance | Show: "Insufficient balance to approve this expense" |

### 7.2 Enhanced Error Identification

```dart
String _extractErrorMessage(dynamic error) {
  final message = error.toString().toLowerCase();
  
  if (message.contains('only pending')) 
    return 'This expense has already been processed';
  
  if (message.contains('access denied') || message.contains('403'))
    return 'Only managers can approve expenses';
  
  if (message.contains('not found') || message.contains('404'))
    return 'Expense no longer exists';
  
  if (message.contains('insufficient'))
    return 'Insufficient balance to approve';
  
  if (message.contains('network') || message.contains('socket'))
    return 'Connection error. Please check your network';
  
  return 'An error occurred. Please try again';
}
```

---

## 8. IMPACT ON CASHFLOW DATA

### 8.1 When Expense is APPROVED

```
BEFORE APPROVAL:
├─ Business Balance: NGN 1,000,000
├─ Expense Status: pending
├─ Expense Pipeline:
│  ├─ Pending: NGN 250,000 (includes this expense)
│  └─ Approved: NGN 150,000
└─ Budget Spending:
   └─ Office Supplies Budget: Spent = NGN 50,000 of 100,000

AFTER APPROVAL:
├─ Business Balance: NGN 750,000 (← reduced by 250,000)
├─ Expense Status: approved
├─ Expense Pipeline:
│  ├─ Pending: NGN 0 (← removed from pending)
│  └─ Approved: NGN 400,000 (← moved to approved)
└─ Budget Spending:
   └─ Office Supplies Budget: Spent = NGN 300,000 of 100,000 (← exceeded!)
      (Now triggers budget alert on dashboard)

SIDE EFFECTS:
✅ Transaction record created (for audit trail)
✅ Anomaly detection triggered (checks for unusual patterns)
✅ Audit log entry created (who approved, when, why)
```

### 8.2 When Expense is REJECTED

```
BEFORE REJECTION:
├─ Business Balance: NGN 1,000,000
├─ Expense Pipeline:
│  └─ Pending: NGN 250,000

AFTER REJECTION:
├─ Business Balance: NGN 1,000,000 (← NO CHANGE)
├─ Expense Pipeline:
│  ├─ Pending: NGN 0 (← removed from pending)
│  └─ Rejected: NGN 250,000 (← moved to rejected)

SIDE EFFECTS:
✅ Rejection reason recorded
✅ Requester can resubmit after addressing feedback
```

### 8.3 When Expense is CANCELLED

```
BEFORE CANCELLATION:
├─ Business Balance: NGN 1,000,000
├─ Expense Pipeline:
│  └─ Pending: NGN 250,000

AFTER CANCELLATION:
├─ Business Balance: NGN 1,000,000 (← NO CHANGE)
├─ Expense Pipeline:
│  ├─ Pending: NGN 0 (← removed from pending)
│  └─ Cancelled: NGN 250,000 (← moved to cancelled)

SIDE EFFECTS:
✅ Audit log entry created
✅ No rejection reason required
```

---

## 9. REAL-TIME CASHFLOW SCREEN INTEGRATION

### 9.1 How CashflowScreen Auto-Updates

**The Problem:** When manager approves expense on ExpensesPage, CashflowScreen (which might be visible in background) needs to update immediately.

**The Solution:** Automatic via Provider pattern

```dart
// In CashflowScreen build()
@override
Widget build(BuildContext context) {
  final state = context.watch<AppStateController>(); // ← This watches
  
  // When AppStateController.notifyListeners() is called,
  // this entire build() method reruns
  // ExpensePipeline recalculates with new data
  
  return _buildExpensePipeline(
    pending: state.expenseSummary['total_pending'] ?? 0,
    approved: state.expenseSummary['total_approved'] ?? 0,
  );
}

// In AppStateController.reviewExpense()
Future<void> reviewExpense({...}) async {
  await _expenseApi.reviewExpense(...);
  await loadExpensesFromBackend(); // ← Refreshes data
  notifyListeners(); // ← Triggers all watching widgets to rebuild
}
```

**Flow:**
1. Manager taps "Approve" on ExpensesPage
2. API call made to backend
3. `reviewExpense()` completes successfully
4. `loadExpensesFromBackend()` fetches updated data
5. `notifyListeners()` broadcasts change
6. **CashflowScreen automatically rebuilds** with updated pending/approved amounts
7. User sees the change instantly if both screens are visible (split-view / web)

### 9.2 Ensuring Immediate Visual Feedback

```dart
// In the approval button handler:
try {
  _showProcessingDialog(context); // Show spinner
  
  await context.read<AppStateController>().reviewExpense(id: id, decision: 'approve');
  
  Navigator.pop(context); // Close spinner
  
  // Update is already visible due to AppStateController.notifyListeners()
  // UI automatically refreshed above
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Expense approved!'))
  );
} catch (e) {
  Navigator.pop(context); // Close spinner
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e'))
  );
}
```

---

## 10. SUMMARY - DO'S AND DON'Ts

### ✅ DO:
- ✅ Show confirmation dialog before approving (expensive operation)
- ✅ Display amount to be deducted when approving
- ✅ Show success message with details after action
- ✅ Require rejection reason when rejecting
- ✅ Show loading state while processing
- ✅ Handle errors with user-friendly messages
- ✅ Let cashflow screen auto-update via Provider
- ✅ Allow requester to cancel only pending, their own expenses
- ✅ Keep audit trail for all operations
- ✅ Trigger anomaly detection on approval

### ❌ DON'T:
- ❌ Approve without confirmation
- ❌ Hide the financial impact from user
- ❌ Leave user wondering if action succeeded
- ❌ Allow rejection without reason
- ❌ Cancel approved/rejected expenses
- ❌ Let staff approve other's expenses
- ❌ Forget to refresh related data (budgets, balance, transactions)
- ❌ Manually update UI - let Provider handle it
- ❌ Show raw API errors to users
- ❌ Skip error handling

---

## 11. IMPLEMENTATION CHECKLIST

- [ ] Add confirmation dialog to Approve button
- [ ] Add confirmation dialog with reason to Reject button
- [ ] Add cancel confirmation dialog
- [ ] Add loading state during operations
- [ ] Add success messages to all three operations
- [ ] Add error handling with user-friendly messages
- [ ] Test with network disabled (fallback mode)
- [ ] Test manager can approve/reject
- [ ] Test staff cannot approve/reject
- [ ] Test requester can cancel own pending expense
- [ ] Test staff cannot cancel others' expenses
- [ ] Verify cashflow screen updates when approval happens
- [ ] Verify budget spending updates when approval happens
- [ ] Verify balance changes when approval happens
- [ ] Test rejection - verify no balance change
- [ ] Test cancellation - verify no balance change

---

## 12. QUICK REFERENCE

### API Endpoints

```
POST /api/expenses
  • Staff submits new expense awaiting approval
  • Body: {title, amount, category, description, budget_id}
  • Result: status = 'pending'

GET /api/expenses
  • Fetch all expenses with pagination
  • Query: ?status=pending&limit=20&offset=0

PUT /api/expenses/:id/review
  • Manager/Owner approves or rejects
  • Body: {decision: 'approve'|'reject', note?: string}
  • If approve: ↓ balance, ↑ budget.spent, create transaction
  • If reject: no financial impact, reason recorded

PUT /api/expenses/:id/cancel
  • Requester cancels pending only
  • No body, just status update
  • No financial impact

GET /api/expenses/summary
  • Get totals: total_submitted, total_approved, total_pending, total_rejected, total_cancelled
```

### Key Files to Update

| File | Change | Priority |
|------|--------|----------|
| [expenses_page.dart](lib/pages/expenses_page.dart) | Add confirmation dialogs, loading states, error handling | 🔴 HIGH |
| [app_state_controller_mock.dart](lib/provider/app_state_controller_mock.dart) | Ensure all refresh calls complete after action | 🟡 MEDIUM |
| [cashflow_screen.dart](lib/bottom_navigation/cashflow_screen.dart) | Verify watch() pattern working, test auto-update | 🟡 MEDIUM |

