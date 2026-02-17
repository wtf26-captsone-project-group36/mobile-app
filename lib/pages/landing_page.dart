import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color facebookBlue = const Color(0xFF1877F2);
  final Color whatsappGreen = const Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              // Tightened Logo (60x60)
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: primaryGreen, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.asset(
                    'assets/hervbypd.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                        Icon(Icons.psychology_outlined, color: primaryGreen, size: 30),
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

              // 1. WhatsApp / Phone Option (High Priority for SMEs)
              _buildAuthButton(
                label: "Continue with WhatsApp",
                icon: FontAwesomeIcons.whatsapp,
                backgroundColor: whatsappGreen,
                onPressed: () {
                  // Logic for Phone/WhatsApp OTP
                },
              ),
              const SizedBox(height: 12),

              // 2. Google Option (Standard for Android)
              _buildAuthButton(
                label: "Continue with Google",
                icon: FontAwesomeIcons.google,
                backgroundColor: Colors.white,
                textColor: Colors.black87,
                showBorder: true,
                onPressed: () {},
              ),
              const SizedBox(height: 12),

              // 3. Facebook Option (Critical for African SMEs)
              _buildAuthButton(
                label: "Continue with Facebook",
                icon: FontAwesomeIcons.facebook,
                backgroundColor: facebookBlue,
                onPressed: () {},
              ),
              
              const SizedBox(height: 32),
              
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR", style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                    child: Text('Log In', 
                      style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text("|", style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () => context.push('/signup'),
                    child: Text('Sign Up', 
                      style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              
              // Explore Guest Mode
              TextButton(
                onPressed: () {},
                child: const Text('Explore as Guest', 
                    style: TextStyle(color: Colors.black54, decoration: TextDecoration.underline)),
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
        label: Text(label, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 0,
          side: showBorder ? BorderSide(color: Colors.grey.shade300) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}