import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/widgets/auth_form_field.dart';

/// ForgotPasswordEmailScreen
/// Screen 1 of 4 in the forgot password flow.
/// Design: HerVest AI — cream background, dark green primary, gold accent.
/// Backend: Supabase — call `supabase.auth.resetPasswordForEmail(email)`

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  // Theme Colors 
  static const Color kCream = Color(0xFFF5F5DC);
  static const Color kDarkGreen = Color(0xFF1A5C3A);
  static const Color kMediumGreen = Color(0xFF2E7D52);
  static const Color kGold = Color(0xFFD4A017);
  static const Color kTextDark = Color(0xFF1A1A1A);
  static const Color kTextMuted = Color(0xFF6B7280);
  static const Color kInputBorder = Color(0xFFD1D5DB);
  static const Color kInputFill = Color(0xFFFFFFFF);
  static const Color kError = Color(0xFFDC2626);

  // ─── State ───────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  // ─── Validation ──────────────────────────────────────────────────────────
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // ─── Submit ───────────────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ── SUPABASE INTEGRATION ─────────────────────────────────────────────
      // Uncomment and replace with your actual Supabase client import:
      //
      // import 'package:supabase_flutter/supabase_flutter.dart';
      //
      // await Supabase.instance.client.auth.resetPasswordForEmail(
      //   _emailController.text.trim(),
      //   redirectTo: 'your.app://reset-callback', // optional deep link
      // );
      //
      // Supabase will send a 6-digit OTP to the user's email automatically.
      // ─────────────────────────────────────────────────────────────────────

      // ── MOCK DELAY (remove when Supabase is wired up) ────────────────────
      await Future.delayed(const Duration(milliseconds: 1200));
      // ─────────────────────────────────────────────────────────────────────

      if (!mounted) return;

      // Navigate to "Check Your Email" screen (Screen 2)
      final encodedEmail = Uri.encodeComponent(_emailController.text.trim());
      context.push('/forgot-password/check-email/$encodedEmail');

      // ── OR if you're not using named routes yet: ──────────────────────────
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => CheckEmailScreen(
      //       email: _emailController.text.trim(),
      //     ),
      //   ),
      // );
    } catch (e) {
      setState(() {
        // Supabase throws AuthException — the e.message has the details
        _errorMessage =
            'Something went wrong. Please check your email and try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
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
              const SizedBox(height: 48),
              _buildLogo(),
              const SizedBox(height: 40),
              _buildHeading(),
              const SizedBox(height: 40),
              _buildForm(),
              const SizedBox(height: 16),
              if (_errorMessage != null) _buildErrorBanner(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 32),
              _buildLoginLink(),
              const SizedBox(height: 24),
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
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 10),
        color: kDarkGreen,
        onPressed: () => context.pop(),
      ),
    );
  }

  // ─── Logo ─────────────────────────────────────────────────────────────────
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
            // ── Replace with your actual asset ────────────────────────────
            child: Image.asset('assets/hervbypd.png', fit: BoxFit.cover),
            //child: CustomPaint(painter: _HLogoPlaceholderPainter()),
          ),
        ),
      ),
    );
  }

  // ─── Heading ──────────────────────────────────────────────────────────────
  Widget _buildHeading() {
    return Column(
      children: [
        Text(
          'Forgot Password?',
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
          'Enter your email address and we\'ll send\nyou a 6-digit code to reset your password.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: kTextMuted,
            fontWeight: FontWeight.w400,
          ),
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
          AuthFormField(
            label: 'Email Address',
            controller: _emailController,
            hintText: 'youremail@example.com',
            labelColor: kTextDark,
            textColor: kTextDark,
            hintColor: kTextMuted,
            fillColor: kInputFill,
            borderColor: kInputBorder,
            focusedBorderColor: kMediumGreen,
            errorColor: kError,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            onFieldSubmitted: (_) => _handleSubmit(),
            validator: _validateEmail,
            suffixIcon: Icon(Icons.email_outlined, color: kTextMuted, size: 20),
          ),
        ],
      ),
    );
  }

  // ─── Error Banner ─────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kError.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kError.withOpacity(0.25)),
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

  // ─── Submit Button ────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: kDarkGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kDarkGreen.withOpacity(0.6),
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

// ─── Placeholder Logo Painter ─────────────────────────────────────────────────
// Remove this once you have your actual logo asset.
class _HLogoPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final greenPaint = Paint()
      ..color = const Color(0xFF0F3D26)
      ..style = PaintingStyle.fill;
    final goldPaint = Paint()
      ..color = const Color(0xFFD4A017)
      ..style = PaintingStyle.fill;

    // Left pillar of H
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * 0.25, size.height),
        const Radius.circular(4),
      ),
      greenPaint,
    );
    // Right pillar of H
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.75, 0, size.width * 0.25, size.height),
        const Radius.circular(4),
      ),
      greenPaint,
    );
    // Crossbar of H
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.40,
        size.width * 0.50,
        size.height * 0.20,
      ),
      greenPaint,
    );
    // Gold leaf accent
    final leafPath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.15)
      ..quadraticBezierTo(
        size.width * 0.65,
        size.height * 0.05,
        size.width * 0.70,
        size.height * 0.35,
      )
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.30,
        size.width * 0.35,
        size.height * 0.15,
      );
    canvas.drawPath(leafPath, goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
