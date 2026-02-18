import 'package:flutter/material.dart';

class AuthFormField extends StatelessWidget {
  const AuthFormField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    required this.labelColor,
    required this.textColor,
    required this.hintColor,
    required this.fillColor,
    required this.borderColor,
    required this.focusedBorderColor,
    required this.errorColor,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.autocorrect = true,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.validator,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final Color labelColor;
  final Color textColor;
  final Color hintColor;
  final Color fillColor;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color errorColor;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final bool autocorrect;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autocorrect: autocorrect,
          obscureText: obscureText,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: TextStyle(
            fontSize: 15,
            color: textColor,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: hintColor, fontSize: 14),
            filled: true,
            fillColor: fillColor,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: focusedBorderColor, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 1.8),
            ),
            errorStyle: TextStyle(color: errorColor, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
