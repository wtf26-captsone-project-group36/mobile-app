import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';
import 'package:hervest_ai/provider/profile_controller.dart';
import 'package:hervest_ai/utils/number_formatter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Enhanced Expenses Page with complete approval flow, error handling, and UX feedback
/// 
/// Features:
///  Confirmation dialogs for all actions (approve, reject, cancel)
///  Loading states during operations
///  Success/error messages
///  Rejection reason capture
///  Role-based action visibility
///  Real-time updates via Provider
///  User-friendly error messages
///  Expense summary display
class ExpensesPageEnhanced extends StatefulWidget {
  const ExpensesPageEnhanced({super.key});

  @override
  State<ExpensesPageEnhanced> createState() => _ExpensesPageEnhancedState();
}

class _ExpensesPageEnhancedState extends State<ExpensesPageEnhanced> {
  late final NumberFormat _currency;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currency = NumberFormat.currency(symbol: 'NGN ', decimalDigits: 0);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppStateController>().loadExpensesFromBackend();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateController>();
    final role = context.watch<ProfileController>().role.toLowerCase();
    final canReview = role == 'owner' || role == 'manager';

    return WillPopScope(
      onWillPop: () async {
        if (_isLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please wait for the current operation to complete')),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expenses'),
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Role: ${role.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _canSubmitExpense ? () => _openSubmitDialog(context) : null,
          icon: const Icon(Icons.add),
          label: const Text('Submit Expense'),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => context.read<AppStateController>().loadExpensesFromBackend(),
            child: ListView(
              children: [
                // =====================================================
                // SUMMARY CARD
                // =====================================================
                _buildExpenseSummaryCard(state),

                const SizedBox(height: 8),

                // =====================================================
                // FILTER CHIPS (Optional - for basic filtering)
                // =====================================================
                _buildFilterChips(),

                const SizedBox(height: 8),

                // =====================================================
                // EXPENSES LIST
                // =====================================================
                if (state.expenses.isEmpty)
                  _buildEmptyState()
                else
                  _buildExpensesList(state, canReview),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SUMMARY CARD
  // ===========================================================================

  Widget _buildExpenseSummaryCard(AppStateController state) {
    if (state.expenseSummary.isEmpty) return const SizedBox.shrink();

    final totalSubmitted = (state.expenseSummary['total_submitted'] as num?)?.toDouble() ?? 0;
    final totalApproved = (state.expenseSummary['total_approved'] as num?)?.toDouble() ?? 0;
    final totalPending = (state.expenseSummary['total_pending'] as num?)?.toDouble() ?? 0;
    final totalRejected = (state.expenseSummary['total_rejected'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expense Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _buildSummaryTile(
                    'Submitted',
                    _currency.format(totalSubmitted),
                    Colors.blue,
                  ),
                  _buildSummaryTile(
                    'Pending',
                    _currency.format(totalPending),
                    Colors.orange,
                  ),
                  _buildSummaryTile(
                    'Approved',
                    _currency.format(totalApproved),
                    Colors.green,
                  ),
                  _buildSummaryTile(
                    'Rejected',
                    _currency.format(totalRejected),
                    Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTile(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FILTER CHIPS
  // ===========================================================================

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        'Expenses',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Submit a new expense to get started',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // EXPENSES LIST
  // ===========================================================================

  Widget _buildExpensesList(AppStateController state, bool canReview) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.expenses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final expense = state.expenses[index];
          final status = expense.status.toLowerCase();
          final color = _getStatusColor(status);

          return Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.title.isNotEmpty ? expense.title : expense.category,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  expense.category,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _currency.format(expense.amount),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),

                  // Description and metadata
                  if (expense.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    Text(
                      expense.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Review info (if reviewed)
                  if (status != 'pending') ...[
                    const SizedBox(height: 8),
                    Text(
                      'Reviewed by: ${expense.reviewedBy ?? 'Unknown'} on ${_formatDate(expense.reviewedAt)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],

                  // Rejection reason (if rejected)
                  if (status == 'rejected' && (expense.reviewNote?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, size: 16, color: Colors.red.shade400),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Reason: ${expense.reviewNote}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.red.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Action buttons
                  const SizedBox(height: 12),
                  _buildActionButtons(context, expense, canReview),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    dynamic expense,
    bool canReview,
  ) {
    final status = expense.status.toLowerCase();
    final isPending = status == 'pending';

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // APPROVE button (pending + manager/owner only)
        if (isPending && canReview)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _showApprovalConfirmation(context, expense),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),

        // REJECT button (pending + manager/owner only)
        if (isPending && canReview)
          OutlinedButton.icon(
            onPressed: _isLoading ? null : () => _showRejectionDialog(context, expense),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),

        // CANCEL button (pending + anyone)
        if (isPending)
          OutlinedButton.icon(
            onPressed: _isLoading ? null : () => _showCancelDialog(context, expense),
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),

        // RESUBMIT button (rejected)
        if (status == 'rejected')
          ElevatedButton.icon(
            onPressed: () => _showResubmitInfo(context, expense),
            icon: const Icon(Icons.replay, size: 18),
            label: const Text('Resubmit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // CONFIRMATION DIALOGS
  // ===========================================================================

  Future<void> _showApprovalConfirmation(
    BuildContext context,
    dynamic expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Expense?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogInfoRow('Amount', _currency.format(expense.amount)),
              const SizedBox(height: 12),
              _buildDialogInfoRow('Category', expense.category),
              const SizedBox(height: 12),
              _buildDialogInfoRow('Submitted by', expense.submittedBy),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_outlined, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will deduct NGN ${_currency.format(expense.amount)} from your business balance.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      await _performApproval(context, expense);
    }
  }

  Future<void> _showRejectionDialog(
    BuildContext context,
    dynamic expense,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Expense?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogInfoRow('Amount', _currency.format(expense.amount)),
              const SizedBox(height: 12),
              _buildDialogInfoRow('Category', expense.category),
              const SizedBox(height: 16),
              Text(
                'Rejection Reason (Required)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g., Missing receipt, Exceeds budget, Duplicate submission...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              reasonController.dispose();
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: reasonController.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performRejection(context, expense, reasonController.text.trim());
    }

    reasonController.dispose();
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    dynamic expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Expense?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogInfoRow('Amount', _currency.format(expense.amount)),
            const SizedBox(height: 12),
            _buildDialogInfoRow('Category', expense.category),
            const SizedBox(height: 16),
            Text(
              'This expense will be marked as cancelled and cannot be reviewed. This action cannot be undone.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep It'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Cancel Expense'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performCancellation(context, expense);
    }
  }

  void _showResubmitInfo(BuildContext context, dynamic expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resubmit Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rejection Reason:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                expense.reviewNote ?? 'No reason provided',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'To resubmit, please address the above feedback and submit a new expense request through the Add Expense page.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openSubmitDialog(context);
            },
            child: const Text('Submit New'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // OPERATIONS
  // ===========================================================================

  Future<void> _performApproval(BuildContext context, dynamic expense) async {
    _showProcessingDialog(context);
    setState(() => _isLoading = true);

    try {
      await context.read<AppStateController>().reviewExpense(
        id: expense.id,
        decision: 'approve',
      );

      if (!mounted) return;
      Navigator.pop(context); // Close processing dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Expense approved! NGN ${_currency.format(expense.amount)} deducted from balance.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => context.push('/cashflow'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close processing dialog

      final errorMsg = _extractErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMsg'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _performRejection(
    BuildContext context,
    dynamic expense,
    String reason,
  ) async {
    _showProcessingDialog(context);
    setState(() => _isLoading = true);

    try {
      await context.read<AppStateController>().reviewExpense(
        id: expense.id,
        decision: 'reject',
        note: reason,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close processing dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Expense rejected. Requester will see your feedback.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close processing dialog

      final errorMsg = _extractErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMsg'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _performCancellation(BuildContext context, dynamic expense) async {
    _showProcessingDialog(context);
    setState(() => _isLoading = true);

    try {
      await context.read<AppStateController>().cancelExpense(expense.id);

      if (!mounted) return;
      Navigator.pop(context); // Close processing dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Expense cancelled.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close processing dialog

      final errorMsg = _extractErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMsg'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===========================================================================
  // SUBMIT NEW EXPENSE DIALOG
  // ===========================================================================

  Future<void> _openSubmitDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit New Expense'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Office Supplies Purchase',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                  CommaSeparatedNumberFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Amount (NGN)',
                  hintText: '20,000',
                  helperText: 'Commas auto-added (type 20000 or 20,000)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g., Supplies, Travel, etc.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'What is this expense for?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: titleController.text.trim().isEmpty ||
                amountController.text.trim().isEmpty ||
                categoryController.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // Strip commas from amount before parsing
      final amountText = amountController.text
          .replaceAll(',', '')
          .trim();
      final amount = double.tryParse(amountText) ?? 0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amount must be greater than 0')),
        );
        return;
      }

      _showProcessingDialog(context);
      setState(() => _isLoading = true);

      try {
        await context.read<AppStateController>().submitExpense(
          title: titleController.text.trim(),
          amount: amount,
          category: categoryController.text.trim(),
          description: descController.text.trim(),
        );

        if (!mounted) return;
        Navigator.pop(context); // Close processing dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense submitted for approval!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close processing dialog

        final errorMsg = _extractErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMsg'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }

    titleController.dispose();
    amountController.dispose();
    categoryController.dispose();
    descController.dispose();
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get _canSubmitExpense => !_isLoading;

  void _showProcessingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Processing...'),
        content: SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return DateFormat('MMM dd, yyyy').format(date);
  }

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

    if (message.contains('required_roles'))
      return 'You do not have permission for this action';

    return 'An error occurred. Please try again';
  }
}
