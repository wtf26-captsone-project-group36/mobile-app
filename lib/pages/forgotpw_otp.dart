import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// EnterCodeScreen
/// Screen 3 of 4 in the forgot password flow.
/// User enters the 6-digit OTP sent to their email.
/// Design: HerVest AI — cream background, dark green primary, gold accent.
/// Backend: Supabase — verify via `supabase.auth.verifyOTP(email, token, type: 'recovery')`

class EnterCodeScreen extends StatefulWidget {
  final String email;

  const EnterCodeScreen({super.key, required this.email});

  @override
  State<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen>
    with SingleTickerProviderStateMixin {
  // ─── Theme Colors ─────────────────────────────────────────────────────────
  static const Color kCream = Color(0xFFF5F5DC);
  static const Color kDarkGreen = Color(0xFF1A5C3A);
  static const Color kMediumGreen = Color(0xFF2E7D52);
  static const Color kTextDark = Color(0xFF1A1A1A);
  static const Color kTextMuted = Color(0xFF6B7280);
  static const Color kError = Color(0xFFDC2626);
  static const Color kInputFill = Color(0xFFFFFFFF);

  // ─── OTP Config ───────────────────────────────────────────────────────────
  static const int kOtpLength = 6;

  // ─── State ────────────────────────────────────────────────────────────────
  final List<TextEditingController> _controllers = List.generate(
    kOtpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    kOtpLength,
    (_) => FocusNode(),
  );

  bool _isVerifying = false;
  bool _hasError = false;
  String? _errorMessage;

  // Resend cooldown (carried over from Screen 2)
  static const int kCooldownSeconds = 60;
  int _secondsRemaining = 0;
  bool _isResending = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Auto-focus first box on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  // ─── Get full OTP string ──────────────────────────────────────────────────
  String get _otpValue => _controllers.map((c) => c.text).join();

  bool get _isComplete => _otpValue.length == kOtpLength;

  // ─── Handle digit input ───────────────────────────────────────────────────
  void _onChanged(int index, String value) {
    // Clear error state on new input
    if (_hasError) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
    }

    if (value.isNotEmpty) {
      // If user pastes full OTP into first box
      if (value.length == kOtpLength && index == 0) {
        for (int i = 0; i < kOtpLength; i++) {
          _controllers[i].text = value[i];
        }
        _focusNodes[kOtpLength - 1].requestFocus();
        setState(() {});
        if (_isComplete) _handleVerify();
        return;
      }

      // Move to next box
      if (index < kOtpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    setState(() {});

    // Auto-submit when last digit is entered
    if (_isComplete) {
      Future.delayed(const Duration(milliseconds: 150), _handleVerify);
    }
  }

  // ─── Handle backspace ─────────────────────────────────────────────────────
  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
        setState(() {});
      }
    }
  }

  // ─── Verify OTP ───────────────────────────────────────────────────────────
  Future<void> _handleVerify() async {
    if (!_isComplete || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // ── SUPABASE INTEGRATION ─────────────────────────────────────────────
      // import 'package:supabase_flutter/supabase_flutter.dart';
      //
      // await Supabase.instance.client.auth.verifyOTP(
      //   email: widget.email,
      //   token: _otpValue,
      //   type: OtpType.recovery,
      // );
      //
      // On success, Supabase returns a session. The user is now authenticated
      // and can proceed to set a new password.
      // ─────────────────────────────────────────────────────────────────────

      // ── MOCK (remove when Supabase is wired up) ──
      await Future.delayed(const Duration(milliseconds: 1400));
      // To test error state, uncomment the line below:
      // throw Exception('Invalid OTP');
      // ──

      if (!mounted) return;

      // Navigate to Reset Password screen (Screen 4)
      final encodedEmail = Uri.encodeComponent(widget.email);
      context.push('/forgot-password/reset-password/$encodedEmail');

      // ── OR direct push ────────────────────────────────────────────────────
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => ResetPasswordScreen(email: widget.email),
      //   ),
      // );
    } catch (e) {
      if (!mounted) return;
      _triggerErrorState('Invalid or expired code. Please try again.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  // ─── Error shake animation ────────────────────────────────────────────────
  void _triggerErrorState(String message) {
    // Clear all boxes
    for (final c in _controllers) {
      c.clear();
    }
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
    _shakeController.forward(from: 0);
    // Re-focus first box
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  // ─── Resend OTP ───────────────────────────────────────────────────────────
  Future<void> _handleResend() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // ── SUPABASE INTEGRATION ─────────────────────────────────────────────
      // await Supabase.instance.client.auth.resetPasswordForEmail(
      //   widget.email,
      // );
      // ─────────────────────────────────────────────────────────────────────

      await Future.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;

      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('A new code has been sent to your email.'),
          backgroundColor: kMediumGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to resend. Please try again.'),
            backgroundColor: kError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _startCooldown() {
    setState(() => _secondsRemaining = kCooldownSeconds);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _secondsRemaining--);
      return _secondsRemaining > 0;
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              _buildIllustration(),
              const SizedBox(height: 36),
              _buildHeading(),
              const SizedBox(height: 36),
              _buildOtpRow(),
              const SizedBox(height: 16),
              if (_hasError) _buildErrorMessage(),
              const Spacer(),
              _buildVerifyButton(),
              const SizedBox(height: 20),
              _buildResendRow(),
              const SizedBox(height: 12),
              _buildLoginLink(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kCream,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: kDarkGreen,
        onPressed: () => context.pop(),
      ),
    );
  }

  // ─── Illustration ─────────────────────────────────────────────────────────
  Widget _buildIllustration() {
    return Center(
      child: Container(
        width: 180,
        height: 150,
        decoration: BoxDecoration(
          color: kMediumGreen,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: kDarkGreen.withOpacity(0.20),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Image.asset(
              'assets/hervbypd.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.lock_outline_rounded, size: 60, color: kDarkGreen),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      children: [
        Text(
          'Enter Code',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: kDarkGreen,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(fontSize: 14, height: 1.65, color: kTextMuted),
            children: [
              const TextSpan(text: 'Enter the 6-digit OTP code sent to\n'),
              TextSpan(
                text: widget.email,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kDarkGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── OTP Input Row ────────────────────────────────────────────────────────
  Widget _buildOtpRow() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final dx = _hasError
            ? 8 *
                  (0.5 - (_shakeAnimation.value - 0.5).abs()) *
                  (_shakeAnimation.value < 0.5 ? -1 : 1)
            : 0.0;
        return Transform.translate(offset: Offset(dx * 6, 0), child: child);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(kOtpLength, (index) => _buildOtpBox(index)),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final isFilled = _controllers[index].text.isNotEmpty;
    final isFocused = _focusNodes[index].hasFocus;

    Color borderColor;
    if (_hasError) {
      borderColor = kError;
    } else if (isFocused) {
      borderColor = kMediumGreen;
    } else if (isFilled) {
      borderColor = kDarkGreen.withOpacity(0.5);
    } else {
      borderColor = const Color(0xFFD1D5DB);
    }

    return SizedBox(
      width: 48,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) => _onKeyEvent(index, event),
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: index == 0 ? kOtpLength : 1,
          // Allow paste into first box for full OTP
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _hasError ? kError : kTextDark,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: isFilled ? kDarkGreen.withOpacity(0.04) : kInputFill,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kError, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kError, width: 2.0),
            ),
          ),
          onChanged: (value) => _onChanged(index, value),
        ),
      ),
    );
  }

  // ─── Error Message ────────────────────────────────────────────────────────
  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: kError, size: 15),
          const SizedBox(width: 6),
          Text(
            _errorMessage ?? '',
            style: TextStyle(
              color: kError,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Verify Button ────────────────────────────────────────────────────────
  Widget _buildVerifyButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: (_isComplete && !_isVerifying) ? _handleVerify : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: kDarkGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kDarkGreen.withOpacity(0.35),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isVerifying
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Verify and Proceed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  // ─── Resend Row ───────────────────────────────────────────────────────────
  Widget _buildResendRow() {
    final bool canResend = _secondsRemaining == 0 && !_isResending;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive a code? ",
          style: TextStyle(fontSize: 14, color: kTextMuted),
        ),
        _isResending
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(kMediumGreen),
                ),
              )
            : GestureDetector(
                onTap: canResend ? _handleResend : null,
                child: Text(
                  _secondsRemaining > 0
                      ? 'Resend in ${_secondsRemaining}s'
                      : 'Resend code',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: canResend ? kMediumGreen : kTextMuted,
                    decoration: canResend
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: kMediumGreen,
                  ),
                ),
              ),
      ],
    );
  }

  // ─── Login Link ───────────────────────────────────────────────────────────
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(fontSize: 14, color: kTextMuted),
        ),
        GestureDetector(
          onTap: () => context.go('/login'),
          // ── OR if not using named routes: ─────────────────────────────────
          // onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
          child: Text(
            'Log in',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kMediumGreen,
              decoration: TextDecoration.underline,
              decorationColor: kMediumGreen,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Helper Extension ─────────────────────────────────────────────────────────
// Utility to pop back to the login route by name.
// If your login route is named differently, update '/login' below.
