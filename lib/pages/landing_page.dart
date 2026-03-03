import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const Color kCream = Color(0xFFF5F5DC);
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color facebookBlue = const Color(0xFF1877F2);
  final Color whatsappGreen = const Color(0xFF25D366);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Tightened Logo (60x60)
              Container(
                width: 180,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: primaryGreen, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.asset(
                    'assets/hervombreforflare.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.psychology_outlined,
                      color: primaryGreen,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Smart Food Business Management',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.blueGrey),
              ),

              const SizedBox(height: 60),

              // 1. WhatsApp (because SMEs might prefer it)
              _buildAuthButton(
                label: "Continue with WhatsApp",
                icon: FontAwesomeIcons.whatsapp,
                backgroundColor: whatsappGreen,
                onPressed: () {
                  context.push('/auth/whatsapp-mock');
                },
              ),
              const SizedBox(height: 12),

              /* 2. Google Option (Standard for Android)
              _buildAuthButton(
                label: "Continue with Google",
                icon: FontAwesomeIcons.google,
                backgroundColor: Colors.white,
                textColor: Colors.black87,
                showBorder: true,
                onPressed: () {},
              ),
              const SizedBox(height: 12), 
              */

              // 3. Facebook Option (Critical for African SMEs)
              _buildAuthButton(
                label: "Continue with Facebook",
                icon: FontAwesomeIcons.facebook,
                backgroundColor: facebookBlue,
                onPressed: () => context.push('/auth/facebook-mock'),
              ),

              const SizedBox(height: 32),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "OR",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 32),

              // Email-based Auth Links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text("|", style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () => context.push('/signup'),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Explore Guest Mode
              TextButton(
                onPressed: () async {
                  await AppSessionStore.instance.setGuestMode(true);
                  await AppSessionStore.instance.setLoggedIn(false);
                  if (context.mounted) context.go('/dashboard');
                },
                child: const Text(
                  'Explore as Guest',
                  style: TextStyle(
                    color: Colors.black54,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              GestureDetector(
                onTap: () => _showTermsDialog(context),
                child: const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    color: Color(0xFF1877F2),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable Button Builder
  Widget _buildAuthButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    Color textColor = Colors.white,
    bool showBorder = false,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon, color: textColor, size: 20),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 0,
          side: showBorder ? BorderSide(color: Colors.grey.shade300) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final screenHeight = MediaQuery.of(ctx).size.height;
        return AlertDialog(
          title: const Text('Terms & Conditions'),
          content: SizedBox(
            width: double.maxFinite,
            height: screenHeight * 0.55,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Text(
                  _termsText,
                  style: const TextStyle(fontSize: 13.2, height: 1.4),
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
}
