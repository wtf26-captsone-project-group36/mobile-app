/// Budget UI Components Library
/// Location: lib/widgets/budget_widgets.dart
/// Purpose: Reusable budget cards and analytics widgets

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hervest_ai/models/api_response_models.dart';

// Constants
const Color kBudgetPrimary = Color(0xFF006B4D);
const Color kBudgetAccent = Color(0xFF2E7D32);
const Color kBudgetWarning = Color(0xFFFF9500);
const Color kBudgetCritical = Color(0xFFDC2626);
const Color kBudgetSuccess = Color(0xFF10B981);

// ============================================================================
// SIMPLE HORIZONTAL BUDGET CARD
// ============================================================================
/// Compact budget card for dashboard or list views
class HorizontalBudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const HorizontalBudgetCard({
    super.key,
    required this.budget,
    this.onTap,
    this.onDelete,
  });

  Color _getStatusColor(double progress) {
    if (progress >= 0.9) return kBudgetCritical;
    if (progress >= 0.7) return kBudgetWarning;
    return kBudgetSuccess;
  }

  @override
  Widget build(BuildContext context) {
    final progress = (budget.allocatedAmount > 0
        ? budget.spentAmount / budget.allocatedAmount
        : 0).toDouble();
    final statusColor = _getStatusColor(progress);
    final remainingPercent = ((1 - progress) * 100).toInt();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Category + Progress Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budget.category,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (progress.clamp(0, 1)).toDouble(),
                            minHeight: 4,
                            backgroundColor: Colors.grey.shade200,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$remainingPercent%",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Delete button
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.clear,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CIRCULAR BUDGET GAUGE
// ============================================================================
/// Shows budget spending as a circular gauge
class CircularBudgetGauge extends StatelessWidget {
  final Budget budget;
  final double size;
  final bool showLabel;

  const CircularBudgetGauge({
    super.key,
    required this.budget,
    this.size = 120,
    this.showLabel = true,
  });

  Color _getStatusColor(double progress) {
    if (progress >= 0.9) return kBudgetCritical;
    if (progress >= 0.7) return kBudgetWarning;
    return kBudgetSuccess;
  }

  @override
  Widget build(BuildContext context) {
    final progress = budget.allocatedAmount > 0
        ? (budget.spentAmount / budget.allocatedAmount).toDouble()
        : 0.0;
    final statusColor = _getStatusColor(progress);
    final progressPercent = (progress * 100).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.1),
              ),
            ),
            // Progress arc (simplified with circular progress)
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: (progress.clamp(0, 1)).toDouble(),
                strokeWidth: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
            // Center text
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$progressPercent%",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  "Used",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (showLabel) ...[
          const SizedBox(height: 12),
          Text(
            budget.category,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "₦${NumberFormat('#,##0').format(budget.remainingAmount)} left",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// BUDGET ALERT BANNER
// ============================================================================
/// Warning banner when budget threshold is exceeded
class BudgetAlertBanner extends StatelessWidget {
  final Budget budget;
  final VoidCallback? onViewDetails;

  const BudgetAlertBanner({
    super.key,
    required this.budget,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final progress = budget.allocatedAmount > 0
        ? budget.spentAmount / budget.allocatedAmount
        : 0;

    // Only show if over 70%
    if (progress < 0.7) return const SizedBox.shrink();

    final isCritical = progress >= 0.9;
    final alertColor = isCritical ? kBudgetCritical : kBudgetWarning;
    final remaining = budget.allocatedAmount - budget.spentAmount;
    final daysInMonth = 30; // Simplified
    final dailyBudget = budget.allocatedAmount / daysInMonth;

    return GestureDetector(
      onTap: onViewDetails,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: alertColor.withOpacity(0.08),
          border: Border.all(color: alertColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isCritical ? Icons.error_rounded : Icons.warning_rounded,
              color: alertColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCritical ? "Critical: Over 90%" : "Warning: Over 70%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: alertColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remaining > 0
                        ? "₦${NumberFormat('#,##0').format(remaining)} remaining (${(remaining / dailyBudget).toStringAsFixed(1)} days left)"
                        : "Budget exceeded by ₦${NumberFormat('#,##0').format(-remaining)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: alertColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BUDGET COMPARISON CARD
// ============================================================================
/// Shows spending comparison with projected vs actual
class BudgetComparisonCard extends StatelessWidget {
  final Budget budget;
  final double projectedSpend;

  const BudgetComparisonCard({
    super.key,
    required this.budget,
    required this.projectedSpend,
  });

  @override
  Widget build(BuildContext context) {
    final variance =
        ((budget.spentAmount - projectedSpend) / projectedSpend * 100);
    final isUnderBudget = budget.spentAmount < projectedSpend;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            budget.category,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Actual Spend",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₦${NumberFormat('#,##0').format(budget.spentAmount)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Projected",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₦${NumberFormat('#,##0').format(projectedSpend)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isUnderBudget ? kBudgetSuccess.withOpacity(0.1) : kBudgetWarning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isUnderBudget
                  ? "✓ ${variance.abs().toStringAsFixed(1)}% under projection"
                  : "⚠ ${variance.toStringAsFixed(1)}% over projection",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isUnderBudget ? kBudgetSuccess : kBudgetWarning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BUDGET SUMMARY STATS
// ============================================================================
/// Shows overall budget statistics
class BudgetSummaryStats extends StatelessWidget {
  final List<Budget> budgets;

  const BudgetSummaryStats({super.key, required this.budgets});

  @override
  Widget build(BuildContext context) {
    final totalAllocated = budgets.fold<double>(
      0,
      (sum, b) => sum + b.allocatedAmount,
    );
    final totalSpent =
        budgets.fold<double>(0, (sum, b) => sum + b.spentAmount);
    final totalRemaining = totalAllocated - totalSpent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            label: "Allocated",
            value: "₦${NumberFormat('#,##0').format(totalAllocated.toInt())}",
            icon: Icons.account_balance_wallet_outlined,
            color: kBudgetPrimary,
          ),
          _StatItem(
            label: "Spent",
            value: "₦${NumberFormat('#,##0').format(totalSpent.toInt())}",
            icon: Icons.trending_down_outlined,
            color: kBudgetWarning,
          ),
          _StatItem(
            label: "Remaining",
            value: "₦${NumberFormat('#,##0').format(totalRemaining.toInt())}",
            icon: Icons.trending_up_outlined,
            color: kBudgetSuccess,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
