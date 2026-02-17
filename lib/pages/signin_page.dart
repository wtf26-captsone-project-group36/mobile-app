import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';

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
        child: SingleChildScrollView(
          // Use ClampingScrollPhysics to prevent the "bouncing" effect on short pages
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40), // Reduced from top centering
              // Logo: Reduced to 60x60
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    'assets/greentintborderico.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.image, color: primaryGreen, size: 36);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16), // Reduced gap
              // Header: Title reduced to 26
              const Text(
                'HerVest AI',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Text(
                'Smart Food Business Management',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.blueGrey,
                ), // Reduced sub-header
              ),
              const SizedBox(height: 32), // Reduced from 48
              // Email Field
              _buildLabel("Email Address"),
              TextField(
                decoration: InputDecoration(
                  hintText: "youremail@example.com",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Reduced gap
              // Password Field
              _buildLabel("Password"),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Enter your password",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 24), // Reduced from 32
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50, // Slightly shorter button
                child: ElevatedButton(
                  onPressed: () async {
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
                onPressed: () {},
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

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ), // Reduced label size
      ),
    );
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
