import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/network/auth_api_service.dart';
import 'package:hervest_ai/widgets/auth_form_field.dart';

/// ResetPasswordScreen
/// Screen 4 of 4 in the forgot password flow.
/// User sets a new password after successful OTP verification.
/// Design: HerVest AI — cream background, dark green primary, gold accent.
/// Backend: Supabase — update via `supabase.auth.updateUser(password: newPassword)`
/// Note: By the time the user reaches this screen, Supabase has already
/// established a session from the verifyOTP call on Screen 3.

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({super.key, required this.email, required this.otp});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // ─── Theme Colors
  static const Color kCream = Color(0xFFF5F5DC);
  static const Color kDarkGreen = Color(0xFF1A5C3A);
  static const Color kMediumGreen = Color(0xFF2E7D52);
  static const Color kGold = Color(0xFFD4A017);
  static const Color kTextDark = Color(0xFF1A1A1A);
  static const Color kTextMuted = Color(0xFF6B7280);
  static const Color kError = Color(0xFFDC2626);
  static const Color kSuccess = Color(0xFF16A34A);
  static const Color kInputFill = Color(0xFFFFFFFF);
  static const Color kInputBorder = Color(0xFFD1D5DB);

  // ─── State
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  // ─── Password strength
  double _strengthScore = 0;
  String _strengthLabel = '';
  Color _strengthColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_evaluateStrength);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_evaluateStrength);
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // ─── Password Strength Evaluator
  void _evaluateStrength() {
    final password = _passwordController.text;
    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    setState(() {
      _strengthScore = score / 5;
      if (password.isEmpty) {
        _strengthLabel = '';
        _strengthColor = Colors.transparent;
      } else if (score <= 1) {
        _strengthLabel = 'Weak';
        _strengthColor = kError;
      } else if (score <= 3) {
        _strengthLabel = 'Fair';
        _strengthColor = kGold;
      } else {
        _strengthLabel = 'Strong';
        _strengthColor = kSuccess;
      }
    });
  }

  // ─── Validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Include at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Include at least one number';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ─── Submit
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.otp.trim().isEmpty) {
        throw AuthApiException('Verification code missing. Please request a new code.');
      }

      const authApi = AuthApiService();
      await authApi.verifyOtpAndResetPassword(
        email: widget.email,
        otp: widget.otp,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;
      _showSuccessSheet();
    } on AuthApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Failed to reset password. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Success Bottom Sheet
  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessBottomSheet(
        onGoToLogin: () {
          context.go('/login');
          // ── OR navigate to named login route: ──
          // Navigator.pushNamedAndRemoveUntil(
          //   context, '/login', (route) => false,
          // );
        },
      ),
    );
  }

  // ─── Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              _buildLogo(),
              const SizedBox(height: 30),
              _buildHeading(),
              const SizedBox(height: 32),
              _buildForm(),
              const SizedBox(height: 12),
              if (_strengthLabel.isNotEmpty) _buildStrengthIndicator(),
              const SizedBox(height: 16),
              if (_errorMessage != null) _buildErrorBanner(),
              if (_errorMessage != null) const SizedBox(height: 16),
              _buildRequirements(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── App Bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kCream,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
        color: kDarkGreen,
        onPressed: () => context.pop(),
      ),
    );
  }

  // ─── Logo
  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 180,
        height: 150,
        decoration: BoxDecoration(
          color: kMediumGreen,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: kDarkGreen.withValues(alpha: 0.20),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(3),
            // ── REPLACE with your actual logo asset
            child: Image.asset('assets/hervbypd.png', fit: BoxFit.cover),
            //child: CustomPaint(painter: _HLogoPlaceholderPainter()),
          ),
        ),
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      children: [
        Text(
          'Reset Password',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: kDarkGreen,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Enter your new password below.\nMake sure it\'s something secure.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.65, color: kTextMuted),
        ),
      ],
    );
  }

  // ─── Form ─────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── New Password ────────────────────────────────────────────────
          AuthFormField(
            label: 'Password',
            controller: _passwordController,
            hintText: 'Enter new password',
            labelColor: kTextDark,
            textColor: kTextDark,
            hintColor: kTextMuted,
            fillColor: kInputFill,
            borderColor: kInputBorder,
            focusedBorderColor: kMediumGreen,
            errorColor: kError,
            focusNode: _passwordFocus,
            obscureText: _obscurePassword,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
            validator: _validatePassword,
            suffixIcon: _visibilityToggle(
              obscured: _obscurePassword,
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),

          const SizedBox(height: 20),

          // ── Confirm Password ─────────────────────────────────────────────
          AuthFormField(
            label: 'Confirm password',
            controller: _confirmController,
            hintText: 'Re-enter new password',
            labelColor: kTextDark,
            textColor: kTextDark,
            hintColor: kTextMuted,
            fillColor: kInputFill,
            borderColor: kInputBorder,
            focusedBorderColor: kMediumGreen,
            errorColor: kError,
            focusNode: _confirmFocus,
            obscureText: _obscureConfirm,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSubmit(),
            validator: _validateConfirm,
            suffixIcon: _visibilityToggle(
              obscured: _obscureConfirm,
              onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _visibilityToggle({
    required bool obscured,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Icon(
          obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: kTextMuted,
          size: 20,
        ),
      ),
    );
  }

  // ─── Strength Indicator ───────────────────────────────────────────────────
  Widget _buildStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _strengthScore,
                  minHeight: 5,
                  backgroundColor: kInputBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _strengthLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _strengthColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Error Banner ─────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kError.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: kError, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: kError, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Password Requirements ────────────────────────────────────────────────
  Widget _buildRequirements() {
    final password = _passwordController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password must have:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kTextMuted,
          ),
        ),
        const SizedBox(height: 8),
        _requirementRow('At least 8 characters', password.length >= 8),
        _requirementRow(
          'One uppercase letter',
          RegExp(r'[A-Z]').hasMatch(password),
        ),
        _requirementRow('One number', RegExp(r'[0-9]').hasMatch(password)),
      ],
    );
  }

  Widget _requirementRow(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            met
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: met ? kSuccess : kTextMuted,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: met ? kSuccess : kTextMuted,
              fontWeight: met ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Submit Button ────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: kDarkGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kDarkGreen.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Submit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

// ─── Success Bottom Sheet ─────────────────────────────────────────────────────
class _SuccessBottomSheet extends StatelessWidget {
  final VoidCallback onGoToLogin;

  static const Color kCream = Color(0xFFF5F5DC);
  static const Color kDarkGreen = Color(0xFF1A5C3A);
  static const Color kSuccess = Color(0xFF16A34A);
  static const Color kTextMuted = Color(0xFF6B7280);

  const _SuccessBottomSheet({required this.onGoToLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
      decoration: const BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 28),
            decoration: BoxDecoration(
              color: kTextMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: kSuccess.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: kSuccess,
              size: 44,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Password Reset!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: kDarkGreen,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Your password has been reset successfully.\nYou can now log in with your new password.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.65, color: kTextMuted),
          ),

          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onGoToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: kDarkGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Back to Login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Placeholder Logo Painter ─────────────────────────────────────────────────
// Remove once you have your actual logo asset.



