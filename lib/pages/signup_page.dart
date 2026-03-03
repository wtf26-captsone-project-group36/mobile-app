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
  bool _agreedTerms = false;
  bool _agreedPrivacy = false;
  String? _errorMessage;
  static const String _termsText = '''
SHEBUILDSTECH'S TERMS AND CONDITIONS
1. Introduction
Welcome to HerVest AI ("App", "Platform", "Service"). It is an AI-embedded service that
These Terms and Conditions ("Terms") govern your access to and use of the HerVest AI mobile application and related services operated by SheBuildsTech ("Company", "we", "our", "us").
By creating an account or using the App, you agree to be bound by these Terms.
If you do not agree, please do not use the App.
2. Eligibility
You must:
Be at least 18 years old
Have legal capacity to operate a business
Provide accurate registration information
The App is designed for small and medium-sized enterprises (SMEs).
3. Nature of the Service
HerVest AI provides:
Business transaction tracking
Inventory management
Expense anomaly detection
Cashflow predictions
Inventory expiry alerts
HerVest AI uses artificial intelligence and statistical models to generate predictive insights.
These insights are informational and do not constitute financial, accounting, or legal advice.
4. Account Registration & Security
You agree to:
Provide accurate information
Maintain confidentiality of login credentials
Notify us promptly of unauthorized access
Passwords are stored in hashed format. The Company is not liable for losses resulting from your failure to safeguard your credentials.
We reserve the right to suspend accounts suspected of unauthorized activity.
5. User Responsibilities
You agree not to:
Use the App for unlawful purposes
Upload false or misleading financial data
Attempt to access another business's data
Reverse-engineer or exploit the platform
You are solely responsible for the accuracy of the records entered.
6. Multi-Tenant Data Separation
Each business account is logically separated.
Users may only access data belonging to their registered business entity.
Attempting to access another business's data constitutes a material breach.
7. AI-Generated Insights Disclaimer
Predictions, risk levels, anomaly alerts, and financial projections:
Are generated automatically
May not be 100% accurate
Depend on the quality of user-provided data
The Company shall not be liable for business losses resulting from reliance on AI-generated outputs.
Users are encouraged to seek independent professional advice where necessary.
8. Data Ownership
You retain ownership of the business data you input into the App.
By using the App, you grant the Company a limited license to:
Process your data
Generate insights
Improve system functionality
We do not sell user's data.
9. Fees (If Applicable)
If subscription fees apply:
Fees are billed monthly/annually
Non-payment may result in suspension
Fees are non-refundable unless required by law
10. Intellectual Property
All software, models, algorithms, and system architecture remain the property of the Company.
You may not copy, reproduce, or distribute the App's technology.
11. Security
We implement reasonable technical and organizational security measures including:
Encryption in transit
Encryption at rest
Access controls
Audit logging
However, no system is completely secure.
12. Limitation of Liability
To the fullest extent permitted by law:
The Company shall not be liable for:
Indirect or consequential losses
Loss of profits
Data loss caused by user negligence
Business decisions made using AI outputs
13. Suspension & Termination
We may suspend or terminate accounts for:
Violation of these Terms
Fraudulent activity
Security threats
Non-payment
Users may request account deletion at any time.
14. Governing Law
These Terms are governed by the Laws of the Federal Republic of Nigeria.
Disputes shall be resolved through arbitration before resorting to litigation.
15. Changes to Terms
We may update these Terms from time to time. Continued use constitutes acceptance.
''';
  static const String _privacyText = '''
SHEBUILDSTECH'S PRIVACY POLICY

Introduction
This Privacy Policy explains how SheBuildsTech collects, uses, processes, and protects personal data through HerVest AI. We are committed to privacy-by-design principles.

Data We Collect
A. Account Information
Full name
Email address
Role within business
Password (hashed)

B. Business Information
Business name
Business type
Currency
Timezone
Financial transaction data
Inventory records

AI-Generated Data
Risk levels
Anomaly indicators
Cashflow predictions
Expiry alerts

Legal Basis for Processing (NDPA 2023)
We process data based on:
Contractual necessity (to provide services)
Legitimate business interests
User consent (where required)
Legal compliance obligations

Purpose of Processing
We use data to:
Provide ledger and inventory services
Generate predictive analytics
Detect unusual expenses
Improve service performance
Ensure system security
We do not use your financial data for advertising.

Privacy-by-Design Principles
We apply:
Data minimization
Purpose limitation
Storage limitation
Role-based access control
Encryption at rest and in transit
Multi-tenant logical separation
Secure password hashing
Audit logging

AI Processing Disclosure
Automated processing is used to:
Assess financial risk levels
Predict cashflow sustainability
Detect expense anomalies
Identify inventory expiry risks
Users may request clarification regarding automated decisions.

Data Retention
We retain personal data only for as long as necessary to:
Provide services
Meet legal obligations
Resolve disputes
Users may request deletion of their account. Deleted data may remain in encrypted backups for limited periods.

Data Security
We implement:
TLS encryption
Database encryption
Secure access controls
Restricted service accounts for ML processing
Monitoring and logging

Data Sharing
We do not sell personal data. Data may however, be shared with:
Cloud infrastructure providers
Security monitoring providers
Legal authorities (where required by law)
All third parties are bound by confidentiality obligations.

Cross-Border Transfers
Where data is transferred or stored outside Nigeria, we ensure appropriate safeguards in line with NDPA 2023.

Your Rights (NDPA)
You have the right to:
Access your data
Correct inaccurate data
Request deletion
Withdraw consent (where applicable)
Lodge complaints with the Nigeria Data Protection Commission (NDPC)

Children's Data
The App is not intended for individuals under 18.

Updates to This Policy
We may update this Privacy Policy periodically.

Contact Information
Data Controller: ShebuildsTech
Email: privacy@shebuildstech.com
Address: 7, Omo Igodalo Street, Ogudu, Lagos State, Nigeria
''';

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

              _buildConsentRow(
                checked: _agreedTerms,
                onChanged: (value) => setState(() => _agreedTerms = value ?? false),
                prefix: "I have read and agreed to HerVest AI's ",
                linkText: "Terms and Conditions",
                onTapLink: () => _showPolicyDialog(
                  title: 'Terms & Conditions',
                  body: _termsText,
                  dark: false,
                ),
              ),
              const SizedBox(height: 4),
              _buildConsentRow(
                checked: _agreedPrivacy,
                onChanged: (value) => setState(() => _agreedPrivacy = value ?? false),
                prefix: "I have read and agreed to HerVest AI's ",
                linkText: "Privacy Policy",
                onTapLink: () => _showPolicyDialog(
                  title: 'Privacy Policy',
                  body: _privacyText,
                  dark: true,
                ),
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

  Widget _buildConsentRow({
    required bool checked,
    required ValueChanged<bool?> onChanged,
    required String prefix,
    required String linkText,
    required VoidCallback onTapLink,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: checked,
          onChanged: onChanged,
          activeColor: primaryGreen,
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              runSpacing: 4.0,
              children: [
                Text(
                  prefix,
                  style: const TextStyle(color: Colors.black87, fontSize: 12.6),
                ),
                GestureDetector(
                  onTap: onTapLink,
                  child: Text(
                    linkText,
                    style: const TextStyle(
                      color: Color(0xFF1877F2),
                      fontSize: 12.6,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPolicyDialog({
    required String title,
    required String body,
    required bool dark,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final screenHeight = MediaQuery.of(ctx).size.height;
        final textColor = dark ? Colors.white : Colors.black87;
        return AlertDialog(
          backgroundColor: dark ? Colors.black : Colors.white,
          title: Text(title, style: TextStyle(color: textColor)),
          content: SizedBox(
            width: double.maxFinite,
            height: screenHeight * 0.58,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Text(
                  body,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
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
    if (!_agreedTerms) {
      setState(() => _errorMessage = 'Please agree to the Terms and Conditions.');
      return;
    }
    if (!_agreedPrivacy) {
      setState(() => _errorMessage = 'Please agree to the Privacy Policy.');
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
