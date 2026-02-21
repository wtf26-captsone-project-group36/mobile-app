import 'package:flutter/material.dart';

class AppInputStyles {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color error = Color(0xFFDC2626);
  static const Color inputFill = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFD1D5DB);

  static TextStyle labelStyle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textDark,
  );

  static InputDecoration decoration({
    String? hintText,
    String? labelText,
    Widget? suffixIcon,
    bool filled = true,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      labelStyle: const TextStyle(color: textDark, fontSize: 14),
      filled: filled,
      fillColor: inputFill,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: inputBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1.8),
      ),
      errorStyle: const TextStyle(color: error, fontSize: 12),
    );
  }
}
