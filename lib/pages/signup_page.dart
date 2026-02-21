import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
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
              ),
              _buildDropdownField("Your Role", "Select your role", roles),

              const SizedBox(height: 30),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    // Clear guest mode and mark as logged in
                    await AppSessionStore.instance.setGuestMode(false);
                    await AppSessionStore.instance.setLoggedIn(true);
                    if (context.mounted) {
                      context.go('/dashboard');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
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

  Widget _buildDropdownField(String label, String hint, List<String> items) {
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
            onChanged: (newValue) {},
          ),
        ],
      ),
    );
  }
}
