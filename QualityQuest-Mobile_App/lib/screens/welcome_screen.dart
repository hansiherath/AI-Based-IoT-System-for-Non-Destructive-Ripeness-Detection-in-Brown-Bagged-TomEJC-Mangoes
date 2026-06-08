import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool isSignupPressed = false;
  bool isLoginPressed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// Admin / Chatbot Icon (Top Right)
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/admin-login');
              },
              child: Image.asset(
                'assets/images/admin_icon.png',
                width: 40,
                height: 40,
              ),
            ),
          ),

          /// Main Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// Logo
              Image.asset(
                'assets/images/app_logo.png',
                width: 120,
                height: 120,
              ),

              const SizedBox(height: 20),

              /// App Name
              Text(
                'QUALO',
                style: GoogleFonts.jua(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6B8E5A),
                  letterSpacing: 2,
                  shadows: const [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),

              /// Sign Up Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isSignupPressed = true;
                      isLoginPressed = false;
                    });
                    Navigator.pushNamed(context, '/signup');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSignupPressed ? const Color(0xFF6B8E5A) : Colors.white,
                    foregroundColor:
                        isSignupPressed ? Colors.white : const Color(0xFF6B8E5A),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    side: const BorderSide(color: Color(0xFF6B8E5A)),
                  ),
                  child: const Text(
                    'Sign up',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              /// Login Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isLoginPressed = true;
                      isSignupPressed = false;
                    });
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isLoginPressed ? const Color(0xFF6B8E5A) : Colors.white,
                    foregroundColor:
                        isLoginPressed ? Colors.white : const Color(0xFF6B8E5A),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    side: const BorderSide(color: Color(0xFF6B8E5A)),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
