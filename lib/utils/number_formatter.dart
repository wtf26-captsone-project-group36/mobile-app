import 'package:flutter/services.dart';

/// Custom text input formatter that formats numbers with comma separators
/// 
/// Usage:
/// ```dart
/// TextField(
///   inputFormatters: [CommaSeparatedNumberFormatter()],
/// )
/// ```
/// 
/// Converts input like "1234567" to display "1,234,567"
class CommaSeparatedNumberFormatter extends TextInputFormatter {
  /// Maximum value allowed (optional, use null for unlimited)
  final int? maxValue;

  CommaSeparatedNumberFormatter({this.maxValue});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Empty string is valid (user clearing the field)
    if (text.isEmpty) {
      return newValue;
    }

    // Remove any non-digit characters (including existing commas)
    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Parse to int for formatting and validation
    int number;
    try {
      number = int.parse(digitsOnly);
    } catch (e) {
      // Failed to parse, revert to old value
      return oldValue;
    }

    // Check max value if specified
    if (maxValue != null && number > maxValue!) {
      // Number exceeds maximum, revert to old value
      return oldValue;
    }

    // Format with commas (e.g., 1234567 becomes 1,234,567)
    final formatted = _formatNumberWithCommas(number);

    // Calculate new cursor position to maintain logical position
    final newCursorOffset = _calculateNewCursorPosition(
      oldValue,
      newValue,
      formatted,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }

  /// Format integer with thousand separators
  /// Example: 1234567 → "1,234,567"
  String _formatNumberWithCommas(int number) {
    final str = number.toString();
    final buffer = StringBuffer();

    // Iterate in reverse to insert commas every 3 digits
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }

    return buffer.toString();
  }

  /// Calculate cursor position after formatting
  /// Maintains cursor position relative to digits typed
  int _calculateNewCursorPosition(
    TextEditingValue oldValue,
    TextEditingValue newValue,
    String formatted,
  ) {
    // Count digits before old cursor position
    final oldText = oldValue.text;
    final oldCursorPos = oldValue.selection.baseOffset;

    int digitCountBeforeCursor = 0;
    for (int i = 0; i < oldCursorPos && i < oldText.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(oldText[i])) {
        digitCountBeforeCursor++;
      }
    }

    // Find position in new formatted text with same digit count before it
    int digitCount = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(formatted[i])) {
        digitCount++;
        if (digitCount >= digitCountBeforeCursor) {
          // Return position right after this digit
          return i + 1;
        }
      }
    }

    // Default to end of string
    return formatted.length;
  }
}

/// Format a double number with comma separators for display
/// Example: formatNumberWithCommas(1234567.89) → "1,234,568"
String formatNumberWithCommas(double number) {
  // Round to avoid decimal places in display
  final rounded = number.round();
  return rounded.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

/// Format with decimal places
/// Example: formatNumberWithCommasAndDecimals(1234567.89, 2) → "1,234,567.89"
String formatNumberWithCommasAndDecimals(double number, int decimals) {
  final formatted = number.toStringAsFixed(decimals);
  final parts = formatted.split('.');
  
  // Format the integer part with commas
  final integerPart = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );

  // Combine with decimal part if exists
  if (parts.length > 1) {
    return '$integerPart.${parts[1]}';
  }
  return integerPart;
}

/// Parse comma-formatted string back to double
/// Handles: "1,234,567", "1234567", "1,234,567.89"
double parseCommaSeparatedNumber(String value) {
  final cleaned = value
    .replaceAll(',', '')  // Remove commas
    .trim();
  
  return double.tryParse(cleaned) ?? 0.0;
}

/// Parse comma-formatted string back to int
/// Handles: "1,234,567", "1234567"
int parseCommaSeparatedInt(String value) {
  final cleaned = value
    .replaceAll(RegExp(r'[^0-9]'), '')  // Remove all non-digits
    .trim();
  
  return int.tryParse(cleaned) ?? 0;
}

/// Validates if a comma-formatted string represents a valid monetary amount
bool isValidMonetaryAmount(String value) {
  try {
    final amount = parseCommaSeparatedNumber(value);
    return amount > 0;
  } catch (_) {
    return false;
  }
}

/// Convert formatted number to display format with currency symbol
/// Example: toNgnFormat(1234567.50) → "₦1,234,567.50"
String toNgnFormat(double amount) {
  return '₦${formatNumberWithCommasAndDecimals(amount, 2)}';
}
