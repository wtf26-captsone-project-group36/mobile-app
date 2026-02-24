import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/core/network/auth_api_service.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';
import 'package:hervest_ai/provider/profile_controller.dart';
import 'package:hervest_ai/provider/inventory_provider.dart';
import 'package:hervest_ai/provider/rescue_provider.dart';
import 'package:hervest_ai/widgets/auth_form_field.dart';

void main() => runApp(const MaterialApp(home: SignUpPage()));

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  static const Color kCream = Color(0xFFF5F5DC);
  static const Color kTextDark = Color(0xFF1A1A1A);
  static const Color kTextMuted = Color(0xFF6B7280);
  static const Color kError = Color(0xFFDC2626);
  static const Color kInputFill = Color(0xFFFFFFFF);
  static const Color kInputBorder = Color(0xFFD1D5DB);

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  String _selectedBusinessType = '';
  String _selectedRole = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // List of business types for the dropdown
  final List<String> businessTypes = [
    'Restaurant',
    'Store Owner',
    'Food Vendor',
    'Farmer/Agricultural Business',
    'Bakery',
    'Catering Service',
    'Cafe/Bistro',
    'Cafeteria',
    'Buka',
    'Mini-Mart',
    'Kiosk',
    'Other',
  ];

  // List of roles (example roles)
  final List<String> roles = ['Owner', 'Manager', 'Staff', 'Admin'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // Logo Placeholder replaced with Image
              Container(
                width: 150,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),

                  // Border added to match design
                  border: Border.all(color: primaryGreen, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/hervpdwhite.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.image, color: primaryGreen, size: 30);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'SIGN UP',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'To begin your journey with HerVest AI...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Form Fields
              _buildInputField(
                label: "Full Name",
                hint: "Boss Businessperson",
                controller: _fullNameController,
                focusNode: _fullNameFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _emailFocus.requestFocus(),
              ),
              _buildInputField(
                label: "Email Address",
                hint: "yourname@example.com",
                controller: _emailController,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              _buildInputField(
                label: "Password",
                hint: "Minimum 6 characters",
                controller: _passwordController,
                focusNode: _passwordFocus,
                isPassword: true,
                textInputAction: TextInputAction.done,
              ),

              // Populated Dropdowns
              _buildDropdownField(
                "Business Type",
                "Select business type",
                businessTypes,
                (val) => setState(() => _selectedBusinessType = val ?? ''),
              ),
              _buildDropdownField(
                "Your Role",
                "Select your role",
                roles,
                (val) => setState(() => _selectedRole = val ?? ''),
              ),

              const SizedBox(height: 30),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: kError, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async => _handleSignUp(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Login Redirect
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.black54),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: AuthFormField(
        label: label,
        controller: controller,
        hintText: hint,
        labelColor: kTextDark,
        textColor: kTextDark,
        hintColor: kTextMuted,
        fillColor: kInputFill,
        borderColor: kInputBorder,
        focusedBorderColor: primaryGreen,
        errorColor: kError,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: isPassword,
        autocorrect: false,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String hint,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryGreen, width: 2),
              ),
            ),
            hint: Text(hint, style: const TextStyle(color: Colors.grey)),
            items: items.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignUp(BuildContext context) async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final profile = context.read<ProfileController>();
    final appState = context.read<AppStateController>();
    final inventoryProvider = context.read<InventoryProvider>();
    final rescueProvider = context.read<RescueProvider>();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Full name, email, and password are required.');
      return;
    }
    if (_selectedBusinessType.isEmpty) {
      setState(() => _errorMessage = 'Please select a business type.');
      return;
    }
    if (_selectedRole.isEmpty) {
      setState(() => _errorMessage = 'Please select your role.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      const authApi = AuthApiService();
      await authApi.signUp(
        email: email,
        password: password,
        fullName: fullName,
        businessType: _normalizeBusinessType(_selectedBusinessType),
        businessName: _inferBusinessName(fullName),
        role: _normalizeRole(_selectedRole),
      );

      if (!context.mounted) return;
      final otp = await _promptOtp(email);
      if (otp == null || otp.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Verification code is required to complete signup.';
        });
        return;
      }

      final session = await authApi.verifySignUp(email: email, otp: otp);
      await AppSessionStore.instance.setAuthTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      await AppSessionStore.instance.setGuestMode(false);
      await AppSessionStore.instance.setLoggedIn(true);

      final user = session.user;
      final business = (user['business'] as Map?)?.cast<String, dynamic>() ?? {};
      if (!context.mounted) return;
      await profile.updateProfile(
        fullName: (user['full_name'] ?? fullName).toString(),
        email: (user['email'] ?? email).toString(),
        phone: '',
        businessName: (business['business_name'] ?? _inferBusinessName(fullName)).toString(),
        role: (user['role'] ?? _normalizeRole(_selectedRole)).toString(),
        businessType: (business['business_type'] ?? _normalizeBusinessType(_selectedBusinessType)).toString(),
        location: '',
      );

      await AppSessionStore.instance.setUserName((user['full_name'] ?? fullName).toString());
      if (!context.mounted) return;
      appState.setUserName((user['full_name'] ?? fullName).toString());
      await appState.loadTransactionsFromBackend();
      await appState.loadInsightsFromBackend();
      await inventoryProvider.loadFromBackend();
      await rescueProvider.loadMarketplaceSurplus();

      if (context.mounted) context.go('/dashboard');
    } on AuthApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Sign up failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _promptOtp(String email) async {
    final otpController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Verify Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter the 6-digit code sent to $email'),
              const SizedBox(height: 12),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '123456',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(otpController.text.trim()),
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  String _normalizeRole(String value) {
    switch (value.trim().toLowerCase()) {
      case 'owner':
        return 'owner';
      case 'manager':
        return 'manager';
      case 'staff':
        return 'staff';
      default:
        return 'owner';
    }
  }

  String _normalizeBusinessType(String value) {
    const map = <String, String>{
      'restaurant': 'restaurant',
      'store owner': 'store',
      'food vendor': 'food_truck',
      'farmer/agricultural business': 'farmer',
      'bakery': 'bakery',
      'catering service': 'catering',
      'cafe/bistro': 'cafe',
      'cafeteria': 'restaurant',
      'buka': 'restaurant',
      'mini-mart': 'supermarket',
      'kiosk': 'store',
      'other': 'store',
    };
    return map[value.trim().toLowerCase()] ?? 'store';
  }

  String _inferBusinessName(String fullName) {
    final name = fullName.trim();
    if (name.isEmpty) return 'My Business';
    return '$name Business';
  }
}
