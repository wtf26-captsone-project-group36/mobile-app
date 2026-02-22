import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/core/utils/user_name_utils.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';
import 'package:provider/provider.dart';

class FacebookAuthMockPage extends StatefulWidget {
  const FacebookAuthMockPage({super.key});

  @override
  State<FacebookAuthMockPage> createState() => _FacebookAuthMockPageState();
}

class _FacebookAuthMockPageState extends State<FacebookAuthMockPage>
    with SingleTickerProviderStateMixin {
  static const Color kFacebookBlue = Color(0xFF1877F2);
  static const Color kDarkBlue = Color(0xFF166FE5);
  static const Color kBackground = Color(0xFFF0F2F5);
  static const Color kTextDark = Color(0xFF1C1E21);
  static const Color kTextMuted = Color(0xFF606770);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _keepSignedIn = true;
  bool _shareBusinessInsights = true;
  bool _isAuthenticating = false;
  int _step = 1;
  late final AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _emailController.text = 'bossbusiness@example.com';
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _submitCredentials() async {
    if (!_formKey.currentState!.validate() || _isAuthenticating) {
      return;
    }
    setState(() => _isAuthenticating = true);
    await _showProgressDialog(
      title: 'Connecting to Facebook...',
      subtitle: 'Checking account security and preparing sign-in',
    );
    if (!mounted) return;
    setState(() {
      _step = 2;
      _isAuthenticating = false;
    });
  }

  Future<void> _completeAuth() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    await _showProgressDialog(
      title: 'Authorizing HerVest AI...',
      subtitle: 'Applying your permission choices',
    );
    if (!mounted) return;

    setState(() {
      _step = 3;
      _isAuthenticating = false;
    });
    _successController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;

    final appState = context.read<AppStateController>();
    appState.setUserName(displayNameFromEmail(_emailController.text));
    await AppSessionStore.instance.setGuestMode(false);
    await AppSessionStore.instance.setLoggedIn(true);

    if (!mounted) return;
    context.go('/dashboard');
  }

  Future<void> _showProgressDialog({
    required String title,
    required String subtitle,
  }) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title),
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(subtitle)),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 520 : double.infinity),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: _buildStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    if (_step == 1) {
      return _buildCredentialStep();
    }
    if (_step == 2) {
      return _buildPermissionsStep();
    }
    return _buildSuccessStep();
  }

  Widget _buildCredentialStep() {
    return SingleChildScrollView(
      key: const ValueKey<int>(1),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        children: [
          _buildFacebookTopBar(),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Log in with Facebook',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use your Facebook account to securely access your HerVest business dashboard.',
                    style: TextStyle(color: kTextMuted, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('Mobile number or email'),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Enter your email or phone';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: _inputDecoration('Password'),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    value: _keepSignedIn,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => setState(() => _keepSignedIn = value),
                    activeThumbColor: kDarkBlue,
                    activeTrackColor: kDarkBlue.withValues(alpha: 0.4),
                    title: const Text(
                      'Keep me signed in',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kFacebookBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _submitCredentials,
                      child: _isAuthenticating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgotten password?',
                      style: TextStyle(color: kDarkBlue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'Cancel and return',
              style: TextStyle(color: kTextMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsStep() {
    return SingleChildScrollView(
      key: const ValueKey<int>(2),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        children: [
          _buildFacebookTopBar(),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Continue as Business Owner',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'HerVest AI is requesting access to help sync business records and personalize your dashboard.',
                  style: TextStyle(color: kTextMuted, height: 1.45),
                ),
                const SizedBox(height: 16),
                _permissionTile(
                  icon: Icons.person_outline,
                  title: 'Basic profile',
                  subtitle: 'Name and public profile photo',
                  enabled: true,
                  onChanged: null,
                ),
                const SizedBox(height: 10),
                _permissionTile(
                  icon: Icons.insights_outlined,
                  title: 'Business insights',
                  subtitle: 'Used for smarter ledger summaries',
                  enabled: _shareBusinessInsights,
                  onChanged: (value) =>
                      setState(() => _shareBusinessInsights = value),
                ),
                const SizedBox(height: 14),
                const Text(
                  'You can adjust these permissions later in account settings.',
                  style: TextStyle(fontSize: 12.5, color: kTextMuted),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kFacebookBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _completeAuth,
                    child: _isAuthenticating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setState(() => _step = 1),
                  child: const Text('Edit login details'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Container(
      key: const ValueKey<int>(3),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _successController,
              curve: Curves.easeOutBack,
            ),
            child: Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: kFacebookBlue.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: kDarkBlue, size: 56),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Facebook sign in successful',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Taking you to your business dashboard...',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildFacebookTopBar() {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: kFacebookBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.facebook, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          const Text(
            'facebook',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _permissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: kDarkBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kTextDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12.5, color: kTextMuted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: kDarkBlue,
            activeTrackColor: kDarkBlue.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCCD0D5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCCD0D5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kDarkBlue, width: 1.6),
      ),
    );
  }
}
