import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/core/network/auth_api_service.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';
import 'package:hervest_ai/provider/profile_controller.dart';
import 'package:hervest_ai/provider/inventory_provider.dart';
import 'package:hervest_ai/provider/rescue_provider.dart';
import 'package:hervest_ai/core/utils/user_name_utils.dart';
import 'package:hervest_ai/widgets/auth_form_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  static const Color kCream = Color(0xFFF5F5DC);
  static const Color kTextDark = Color(0xFF1A1A1A);
  static const Color kTextMuted = Color(0xFF6B7280);
  static const Color kError = Color(0xFFDC2626);
  static const Color kInputFill = Color(0xFFFFFFFF);
  static const Color kInputBorder = Color(0xFFD1D5DB);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: SingleChildScrollView(
          // Use ClampingScrollPhysics to prevent the "bouncing" effect on short pages
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40), // Reduced from top centering
              // Logo: Reduced to 60x60
              Container(
                width: 180,
                height: 150,
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withValues(alpha: 0.20),
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
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image, color: primaryGreen, size: 36);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16), // Reduced gap

              const Text(
                'Login to get back to managing your business with HerVest AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.blueGrey,
                ), // Reduced sub-header
              ),
              const SizedBox(height: 32), // Reduced from 48
              // Email Field
              AuthFormField(
                label: 'Email Address',
                controller: _emailController,
                hintText: 'youremail@example.com',
                labelColor: kTextDark,
                textColor: kTextDark,
                hintColor: kTextMuted,
                fillColor: kInputFill,
                borderColor: kInputBorder,
                focusedBorderColor: primaryGreen,
                errorColor: kError,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: 20), // Reduced gap
              // Password Field
              AuthFormField(
                label: 'Password',
                controller: _passwordController,
                hintText: 'Enter your password',
                labelColor: kTextDark,
                textColor: kTextDark,
                hintColor: kTextMuted,
                fillColor: kInputFill,
                borderColor: kInputBorder,
                focusedBorderColor: primaryGreen,
                errorColor: kError,
                focusNode: _passwordFocus,
                obscureText: true,
                autocorrect: false,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24), // Reduced from 32
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: kError, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50, // Slightly shorter button
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async => _handleLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 8), // Reduced gap
              // Forgot Password
              TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 16), // Reduced gap
              // Divider "OR"
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "OR",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 20), // Reduced gap
              // Create Account Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => context.push('/signup'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Create New Account',
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final profile = context.read<ProfileController>();
    final appState = context.read<AppStateController>();
    final inventoryProvider = context.read<InventoryProvider>();
    final rescueProvider = context.read<RescueProvider>();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Email and password are required.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      const authApi = AuthApiService();
      final session = await authApi.signIn(email: email, password: password);

      await AppSessionStore.instance.setAuthTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      await AppSessionStore.instance.setGuestMode(false);
      await AppSessionStore.instance.setLoggedIn(true);

      final user = session.user;
      final business = (user['business'] as Map?)?.cast<String, dynamic>() ?? {};
      final fullName =
          (user['full_name'] ?? '').toString().trim().isNotEmpty
              ? (user['full_name'] ?? '').toString().trim()
              : displayNameFromEmail(email);

      if (!context.mounted) return;
      await profile.updateProfile(
        fullName: fullName,
        email: (user['email'] ?? email).toString(),
        phone: '',
        businessName: (business['business_name'] ?? '').toString(),
        role: (user['role'] ?? 'owner').toString(),
        businessType: (business['business_type'] ?? '').toString(),
        location: '',
      );

      if (!context.mounted) return;
      appState.setUserName(fullName);
      await appState.loadTransactionsFromBackend();
      await appState.loadInsightsFromBackend();
      await inventoryProvider.loadFromBackend();
      await rescueProvider.loadMarketplaceSurplus();

      if (context.mounted) context.go('/dashboard');
    } on AuthApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Login failed. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/*void main() => runApp(const MaterialApp(home: LoginPage()));

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color primaryGreen = const Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo replaced with Image
              Container(
                width: 80, // Matches the total footprint of the previous icon + padding
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  // Optional: remove the color if your image already has a background
                  // color: primaryGreen, 
                ),
                // ClipRRect ensures the image corners match the container rounding
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/greentintborderico.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if the image isn't found
                      return Icon(Icons.image, color: primaryGreen, size: 48);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Header
              const Text(
                'HerVest AI',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const Text(
                'Smart Food Business Management',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.blueGrey),
              ),
              const SizedBox(height: 48),

              // Email Field
              _buildLabel("Email Address"),
              TextField(
                decoration: InputDecoration(
                  hintText: "youremail@example.com",
                  hintStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryGreen)),
                ),
              ),
              const SizedBox(height: 24),

              // Password Field
              _buildLabel("Password"),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Enter your password",
                  hintStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryGreen)),
                ),
              ),
              const SizedBox(height: 32),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Forgot Password
              TextButton(
                onPressed: () {},
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              
              const SizedBox(height: 24),

              // Divider "OR"
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR", style: TextStyle(color: Colors.grey.shade500)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 24),

              // Create Account Button (Outlined)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () => context.push('/signup'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Create New Account',
                    style: TextStyle(fontSize: 16, color: primaryGreen, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
*/
