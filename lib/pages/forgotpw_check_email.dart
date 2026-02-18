import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CheckEmailScreen extends StatefulWidget {
  final String email;

  const CheckEmailScreen({super.key, required this.email});

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen>
    with SingleTickerProviderStateMixin {
  static const Color kCream = Color(0xFFF5F5DC);
  static const Color kDarkGreen = Color(0xFF1A5C3A);
  static const Color kMediumGreen = Color(0xFF2E7D52);
  static const Color kTextMuted = Color(0xFF6B7280);
  static const Color kSuccess = Color(0xFF16A34A);
  static const Color kError = Color(0xFFDC2626);

  static const int kCooldownSeconds = 60;
  int _secondsRemaining = 0;
  bool _isResending = false;
  bool _resendSuccess = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _resendSuccess = false;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      setState(() => _resendSuccess = true);
      _startCooldown();

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _resendSuccess = false);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to resend code. Please try again.'),
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

  void _handleOpenCode() {
    final encodedEmail = Uri.encodeComponent(widget.email);
    context.push('/forgot-password/enter-code/$encodedEmail');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: kDarkGreen,
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                _buildIllustration(),
                const SizedBox(height: 40),
                Text(
                  'Check Your Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: kDarkGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildEmailBadge(),
                const SizedBox(height: 12),
                Text(
                  'We sent a 6-digit verification code to your\nemail address. Enter the code to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.65,
                    color: kTextMuted,
                  ),
                ),
                const SizedBox(height: 40),
                if (_resendSuccess) _buildResendSuccessBanner(),
                if (_resendSuccess) const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _handleOpenCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDarkGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Enter Verification Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildResendRow(),
                const Spacer(flex: 3),
                Text(
                  'If you don\'t see the email, check your spam or\njunk folder.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: kTextMuted.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.mark_email_unread_outlined,
                size: 60,
                color: kDarkGreen,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: kDarkGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: kDarkGreen.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.email_outlined, size: 15, color: kDarkGreen),
          const SizedBox(width: 7),
          Text(
            widget.email,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kDarkGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendSuccessBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kSuccess.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kSuccess.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: kSuccess, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Code resent successfully! Check your inbox.',
              style: TextStyle(color: kSuccess, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

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
}
