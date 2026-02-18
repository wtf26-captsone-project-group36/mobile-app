import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// CheckEmailScreen
/// Screen 2 of 4 in the forgot password flow.
/// Shown after user submits their email. Tells them to check their inbox.
/// Design: HerVest AI — cream background, dark green primary, gold accent.
/// Backend: Supabase — resend via `supabase.auth.resetPasswordForEmail(email)`

class CheckEmailScreen extends StatefulWidget {
  final String email;

  const CheckEmailScreen({
    super.key,
    required this.email,
  });

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen>
    with SingleTickerProviderStateMixin {
  // ─── Theme Colors ─────────────────────────────────────────────────────────
  static const Color kCream = Color(0xFFF5F5DC);
  static const Color kDarkGreen = Color(0xFF1A5C3A);
  static const Color kMediumGreen = Color(0xFF2E7D52);
  static const Color kGold = Color(0xFFD4A017);
  static const Color kTextDark = Color(0xFF1A1A1A);
  static const Color kTextMuted = Color(0xFF6B7280);
  static const Color kSuccess = Color(0xFF16A34A);
  static const Color kError = Color(0xFFDC2626);

  // ─── Resend Cooldown ──────────────────────────────────────────────────────
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

  // ─── Resend Timer ─────────────────────────────────────────────────────────
  void _startCooldown() {
    setState(() => _secondsRemaining = kCooldownSeconds);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _secondsRemaining--);
      return _secondsRemaining > 0;
    });
  }

  // ─── Resend OTP ───────────────────────────────────────────────────────────
  Future<void> _handleResend() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _resendSuccess = false;
    });

    try {
      // ── SUPABASE INTEGRATION ─────────────────────────────────────────────
      // await Supabase.instance.client.auth.resetPasswordForEmail(
      //   widget.email,
      // );
      // ─────────────────────────────────────────────────────────────────────

      // ── MOCK DELAY (remove when Supabase is wired up) ────────────────────
      await Future.delayed(const Duration(milliseconds: 1000));
      // ─────────────────────────────────────────────────────────────────────

      if (!mounted) return;
      setState(() => _resendSuccess = true);
      _startCooldown();

      // Hide success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _resendSuccess = false);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to resend code. Please try again.'),
            backgroundColor: kError,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  // ─── Navigate to OTP Entry ────────────────────────────────────────────────
  void _handleOpenCode() {
    final encodedEmail = Uri.encodeComponent(widget.email);
    context.push('/forgot-password/enter-code/$encodedEmail');

    // ── OR direct push: ───────────────────────────────────────────────────
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => EnterCodeScreen(email: widget.email),
    //   ),
    // );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: _buildAppBar(),
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
                _buildHeading(),
                const SizedBox(height: 16),
                _buildEmailBadge(),
                const SizedBox(height: 12),
                _buildSubtitle(),
                const SizedBox(height: 40),
                if (_resendSuccess) _buildResendSuccessBanner(),
                if (_resendSuccess) const SizedBox(height: 16),
                _buildOpenCodeButton(),
                const SizedBox(height: 20),
                _buildResendRow(),
                const Spacer(flex: 3),
                _buildFooterNote(),
                const SizedBox(height: 24),
              ],
            ),
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
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: kMediumGreen.withOpacity(0.10),
        shape: BoxShape.circle,
      ),
      child: Center(
        // ── REPLACE with your actual illustration asset ────────────────────
        // child: Image.asset(
        //   'assets/images/email_sent_illustration.png',
        //   width: 120,
        //   height: 120,
        //   fit: BoxFit.contain,
        // ),
        //
        // ── PLACEHOLDER ───────────────────────────────────────────────────
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: kMediumGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mark_email_unread_outlined,
                  size: 52, color: kDarkGreen),
              const SizedBox(height: 6),
              Text(
                'IMG',
                style: TextStyle(
                  fontSize: 11,
                  color: kTextMuted,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Heading ──────────────────────────────────────────────────────────────
  Widget _buildHeading() {
    return Text(
      'Check Your Email',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: kDarkGreen,
        letterSpacing: -0.5,
      ),
    );
  }

  // ─── Email Badge ──────────────────────────────────────────────────────────
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

  // ─── Subtitle ─────────────────────────────────────────────────────────────
  Widget _buildSubtitle() {
    return Text(
      'We sent a 6-digit verification code to your\nemail address. Enter the code to continue.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        height: 1.65,
        color: kTextMuted,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  // ─── Resend Success Banner ────────────────────────────────────────────────
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
          Icon(Icons.check_circle_outline_rounded,
              color: kSuccess, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Code resent successfully! Check your inbox.',
              style:
                  TextStyle(color: kSuccess, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Primary CTA ─────────────────────────────────────────────────────────
  Widget _buildOpenCodeButton() {
    return SizedBox(
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

  // ─── Footer Note ──────────────────────────────────────────────────────────
  Widget _buildFooterNote() {
    return Text(
      'If you don\'t see the email, check your spam or\njunk folder.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        height: 1.6,
        color: kTextMuted.withOpacity(0.75),
      ),
    );
  }
}
