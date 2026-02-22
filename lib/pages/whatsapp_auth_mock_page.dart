import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';
import 'package:provider/provider.dart';

class WhatsAppAuthMockPage extends StatefulWidget {
  const WhatsAppAuthMockPage({super.key});

  @override
  State<WhatsAppAuthMockPage> createState() => _WhatsAppAuthMockPageState();
}

class _WhatsAppAuthMockPageState extends State<WhatsAppAuthMockPage>
    with SingleTickerProviderStateMixin {
  static const Color kCream = Color(0xFFF5F5DC);
  static const Color kWhatsAppGreen = Color(0xFF25D366);
  static const Color kDeepTeal = Color(0xFF0F6A5B);
  static const Color kTextDark = Color(0xFF1A1A1A);
  static const Color kTextMuted = Color(0xFF6B7280);
  static const int kOtpLength = 6;
  static const int kResendSeconds = 60;
  static const String kMockOtpCode = '170036';

  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    kOtpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    kOtpLength,
    (_) => FocusNode(),
  );

  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();
  String _countryCode = '+234';
  int _step = 1;
  bool _isSendingCode = false;
  bool _isVerifyingOtp = false;
  bool _hasOtpError = false;
  String? _otpErrorText;
  int _attemptsRemaining = 3;
  int _secondsRemaining = kResendSeconds;
  Timer? _timer;
  late final AnimationController _successAnimationController;

  @override
  void initState() {
    super.initState();
    _successAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    _successAnimationController.dispose();
    super.dispose();
  }

  String get _normalizedPhone => _phoneController.text.replaceAll(RegExp(r'\D'), '');

  String get _fullPhoneNumber => '$_countryCode$_normalizedPhone';

  String get _maskedPhoneNumber {
    final digits = _normalizedPhone;
    if (digits.length < 4) return _fullPhoneNumber;
    final suffix = digits.substring(digits.length - 4);
    return '$_countryCode *** *** $suffix';
  }

  bool get _isOtpComplete => _otpControllers.every((controller) => controller.text.isNotEmpty);

  Future<void> _handleNextFromPhone() async {
    if (!_phoneFormKey.currentState!.validate() || _isSendingCode) {
      return;
    }

    setState(() => _isSendingCode = true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Verifying number...'),
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text('Connecting to WhatsApp Business channel'),
              ),
            ],
          ),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    context.pop();

    setState(() {
      _step = 2;
      _isSendingCode = false;
      _secondsRemaining = kResendSeconds;
      _hasOtpError = false;
      _otpErrorText = null;
      _attemptsRemaining = 3;
    });

    _startTimer();
    _focusFirstOtp();
  }

  void _focusFirstOtp() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _otpFocusNodes.first.requestFocus();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining == 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsRemaining -= 1);
    });
  }

  Future<void> _resendCode() async {
    if (_secondsRemaining > 0 || _isSendingCode) return;

    setState(() {
      _isSendingCode = true;
      _hasOtpError = false;
      _otpErrorText = null;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() {
      _isSendingCode = false;
      _secondsRemaining = kResendSeconds;
      _attemptsRemaining = 3;
    });
    _startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A fresh verification code was sent to your phone.'),
      ),
    );
  }

  void _onOtpChanged(int index, String value) {
    if (_hasOtpError) {
      setState(() {
        _hasOtpError = false;
        _otpErrorText = null;
      });
    }

    if (value.length > 1) {
      final chars = value.split('');
      for (int i = 0; i < kOtpLength; i++) {
        _otpControllers[i].text = i < chars.length ? chars[i] : '';
      }
      _otpFocusNodes.last.requestFocus();
      setState(() {});
      if (_isOtpComplete) {
        _verifyOtp();
      }
      return;
    }

    if (value.isNotEmpty && index < kOtpLength - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }

    setState(() {});
    if (_isOtpComplete) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    if (_isVerifyingOtp || !_isOtpComplete) return;
    if (_attemptsRemaining == 0) {
      setState(() {
        _hasOtpError = true;
        _otpErrorText = 'Too many attempts. Please resend a new code.';
      });
      return;
    }

    setState(() => _isVerifyingOtp = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final enteredCode = _otpControllers.map((c) => c.text).join();
    final accepted = enteredCode == kMockOtpCode;

    if (!accepted) {
      for (final controller in _otpControllers) {
        controller.clear();
      }
      _otpFocusNodes.first.requestFocus();
      setState(() {
        _isVerifyingOtp = false;
        _hasOtpError = true;
        _attemptsRemaining = (_attemptsRemaining - 1).clamp(0, 3);
        _otpErrorText = _attemptsRemaining > 0
            ? 'Incorrect code. $_attemptsRemaining attempts left.'
            : 'Too many attempts. Please resend a new code.';
      });
      return;
    }

    _timer?.cancel();
    setState(() {
      _step = 3;
      _isVerifyingOtp = false;
    });
    _successAnimationController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    await AppSessionStore.instance.setGuestMode(false);
    await AppSessionStore.instance.setLoggedIn(true);
    if (!mounted) return;

    context.read<AppStateController>().setUserName('Cynthia M.');
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kCream,
        elevation: 0,
        title: const Text('WhatsApp Sign In', style: TextStyle(color: kTextDark)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 560 : double.infinity),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _buildStepContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_step == 1) return _buildPhoneStep();
    if (_step == 2) return _buildOtpStep();
    return _buildSuccessStep();
  }

  Widget _buildHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: kWhatsAppGreen.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(FontAwesomeIcons.whatsapp, color: kDeepTeal, size: 28),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, height: 1.55, color: kTextMuted),
        ),
      ],
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      key: const ValueKey<int>(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(
          title: 'Use your WhatsApp account to securely access your HerVest AI dashboard',
          subtitle: "We'll send an SMS to verify your business account.",
        ),
        const SizedBox(height: 28),
        Form(
          key: _phoneFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phone number',
                style: TextStyle(fontWeight: FontWeight.w600, color: kTextDark),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: DropdownButtonFormField<String>(
                      initialValue: _countryCode,
                      decoration: _inputDecoration(),
                      items: const [
                        DropdownMenuItem(value: '+234', child: Text('+234')),
                        DropdownMenuItem(value: '+1', child: Text('+1')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _countryCode = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration(
                        hintText: 'Enter 10-digit number',
                      ).copyWith(counterText: ''),
                      validator: (value) {
                        final clean = (value ?? '').replaceAll(RegExp(r'\D'), '');
                        if (clean.isEmpty) return 'Phone number is required';
                        if (clean.length != 10) return 'Enter exactly 10 digits';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kDeepTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _handleNextFromPhone,
            child: _isSendingCode
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Next', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey<int>(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(
          title: 'Verify your WhatsApp access',
          subtitle: 'Enter the 6-digit code sent to $_maskedPhoneNumber',
        ),
        const SizedBox(height: 10),
        // Hidden to keep this mock flow visually close to a real WhatsApp OTP UX.
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        //   decoration: BoxDecoration(
        //     color: kWhatsAppGreen.withValues(alpha: 0.12),
        //     borderRadius: BorderRadius.circular(10),
        //   ),
        //   child: const Text(
        //     'Mock OTP: 170036',
        //     textAlign: TextAlign.center,
        //     style: TextStyle(
        //       color: kDeepTeal,
        //       fontWeight: FontWeight.w700,
        //     ),
        //   ),
        // ),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(kOtpLength, _buildOtpBox),
        ),
        const SizedBox(height: 10),
        const Text(
          'Waiting to automatically detect an SMS sent to your device.',
          textAlign: TextAlign.center,
          style: TextStyle(color: kTextMuted, fontSize: 13),
        ),
        const SizedBox(height: 14),
        if (_hasOtpError)
          Text(
            _otpErrorText ?? 'Enter the 6-digit code sent to your number.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
          ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kDeepTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isVerifyingOtp ? null : _verifyOtp,
            child: _isVerifyingOtp
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Verify code', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: _isVerifyingOtp
                ? null
                : () {
                    _timer?.cancel();
                    for (final controller in _otpControllers) {
                      controller.clear();
                    }
                    setState(() {
                      _step = 1;
                      _hasOtpError = false;
                      _otpErrorText = null;
                    });
                  },
            child: const Text(
              'Edit phone number',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: (_secondsRemaining == 0 && !_isSendingCode) ? _resendCode : null,
            child: _isSendingCode
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Text(
                    _secondsRemaining > 0
                        ? 'Resend code in ${_secondsRemaining}s'
                        : 'Resend code',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 44,
      height: 54,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: index == 0 ? kOtpLength : 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kDeepTeal.withValues(alpha: 0.2)),
            ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kDeepTeal, width: 1.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
              color: _hasOtpError ? Colors.red : kDeepTeal.withValues(alpha: 0.2),
            ),
          ),
        ),
        onChanged: (value) => _onOtpChanged(index, value),
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      key: const ValueKey<int>(3),
      children: [
        const SizedBox(height: 40),
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _successAnimationController,
            curve: Curves.easeOutBack,
          ),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kWhatsAppGreen.withValues(alpha: 0.18),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: kDeepTeal,
              size: 56,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Business account verified',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: kTextDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Redirecting you to your dashboard...',
          style: TextStyle(color: kTextMuted, fontSize: 14),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kDeepTeal.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kDeepTeal.withValues(alpha: 0.2)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kDeepTeal, width: 1.6),
      ),
    );
  }
}
