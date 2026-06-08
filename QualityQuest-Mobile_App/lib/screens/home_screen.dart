import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/mango_service.dart';
import '../services/customer_service.dart';
import '../models/mango_result.dart';
import '../session/user_session.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<MangoResult> mangoFuture;
  late int userId;

  bool showRipeness = false;
  bool showTime = false;
  bool showSugar = false;

  @override
  void initState() {
    super.initState();

    if (UserSession.userId == null) {
      throw Exception("User not logged in");
    }

    userId = UserSession.userId!;
    mangoFuture = MangoService.fetchLatestResult(userId);
  }

  /// ================= YES BUTTON =================
  void _updateDiabetesAndNavigate({
    required int isDiabetic,
    required String recommendation,
  }) {
    if (!mounted) return;

    Navigator.pushNamed(
      context,
      '/health',
      arguments: recommendation.trim(),
    );

    CustomerService.updateDiabetesStatus(
      userId: userId,
      isDiabetic: isDiabetic,
    ).catchError((e) {
      print("Background update error: $e");
    });

    UserSession.isDiabetic = true;
  }

  /// ================= NO BUTTON =================
  void _handleNoClick() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Enjoy the Mango!"),
        duration: Duration(seconds: 1),
      ),
    );

    CustomerService.updateDiabetesStatus(
      userId: userId,
      isDiabetic: 0,
    ).catchError((e) {
      print("Background update error: $e");
    });

    UserSession.isDiabetic = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<MangoResult>(
            future: mangoFuture,
            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              bool isError = snapshot.hasError;
              MangoResult? data = snapshot.data;

              final mangoMessage =
                  (data != null && data.sensorStatus == "NO_MANGO")
                      ? "No mango detected.\nPlease place the mango correctly."
                      : "Place the mango near\nthe sensor device.";

              return Column(
                children: [

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                          const SizedBox(height: 20),

                          /// ===== WELCOME CARD =====
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 18),
                            decoration: const BoxDecoration(
                              color: Color(0xFF6B8E5A),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(40),
                                bottomRight: Radius.circular(40),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage:
                                      UserSession.profilePicture != null
                                          ? FileImage(
                                              File(UserSession.profilePicture!))
                                          : const AssetImage(
                                                  'assets/images/C5.png')
                                              as ImageProvider,
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Welcome to QUALO",
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      UserSession.fullName,
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          /// ===== INSTRUCTION CARD =====
                          Center(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.80,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 6,
                                    color: Colors.black12,
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    "assets/images/mango.png",
                                    width: 36,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      mangoMessage,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF3E6B3C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          /// ===== RESULT BOX =====
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCADAC4),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Column(
                              children: [

                                Row(
                                  children: [
                                    _resultCard(
                                      title: "Mango\nRipeness",
                                      value: showRipeness
                                          ? (isError
                                              ? "Data Retrieval Fail"
                                              : data?.ripeness ?? "-")
                                          : "",
                                      onTap: () {
                                        setState(() => showRipeness = true);
                                      },
                                    ),
                                    const SizedBox(width: 15),
                                    _resultCard(
                                      title: "Time to\nConsume",
                                      value: showTime
                                          ? (isError
                                              ? "Data Retrieval Fail"
                                              : data?.time ?? "-")
                                          : "",
                                      onTap: () {
                                        setState(() => showTime = true);
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 15),

                                _wideResultCard(
                                  title: "Sugar Content",
                                  value: showSugar
                                      ? (isError
                                          ? "Data Retrieval Fail"
                                          : data?.sugar ?? "-")
                                      : "",
                                  onTap: () {
                                    setState(() => showSugar = true);
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 35),

                          /// ===== DIABETES QUESTION =====
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  thickness: 2.5,
                                  color: Colors.black54,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  "Do you suffer from\n diabetes?",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(
                                  thickness: 2.5,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          /// ===== YES / NO (FIXED) =====
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _choiceButton(
                                "Yes",
                                true,
                                () => _updateDiabetesAndNavigate(
                                  isDiabetic: 1,
                                  recommendation:
                                      data?.healthRecommendation ?? "Unknown",
                                ),
                              ),
                              const SizedBox(width: 20),
                              _choiceButton(
                                "No",
                                false,
                                _handleNoClick,
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),

                  /// ===== BOTTOM NAV =====
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6B8E5A),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Icon(Icons.home, size: 28),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: const Icon(Icons.person, size: 28),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _resultCard({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFAFC5A5),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (value.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _wideResultCard({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFAFC5A5),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            if (value.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _choiceButton(String text, bool filled, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(120, 45),
        backgroundColor:
            filled ? const Color(0xFF6B8E5A) : Colors.transparent,
        foregroundColor:
            filled ? Colors.white : const Color(0xFF6B8E5A),
        side: const BorderSide(color: Color(0xFF6B8E5A)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 0,
      ),
      child: Text(text),
    );
  }
}