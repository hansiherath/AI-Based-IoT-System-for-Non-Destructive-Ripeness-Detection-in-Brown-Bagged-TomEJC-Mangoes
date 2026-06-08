import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  double accuracy = 94;
  String lastTrained = "2026-01-31";

  /// ===============================
  /// FETCH MODEL STATUS
  /// ===============================
  Future<void> fetchModelStatus() async {
    final response = await http.get(
      Uri.parse("http://10.17.5.39:3000/admin/model-status"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        accuracy = (data["Accuracy"] ?? 0).toDouble();
        lastTrained = data["LastTrained"] ?? "-";
      });
    }
  }

  /// ===============================
  /// MODEL POPUP
  /// ===============================
  void showModelPopup() async {
    await fetchModelStatus();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("ML Model"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Last Trained: $lastTrained"),
            const SizedBox(height: 20),
            CircularProgressIndicator(value: accuracy / 100),
            const SizedBox(height: 10),
            Text("${accuracy.toStringAsFixed(0)}% Accuracy"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// LOGOUT DIALOG
  /// ===============================
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: const Text(
            'Do you want to logout?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B8E5A),
              ),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  /// ===============================
  /// MENU BUTTON
  /// ===============================
  Widget menuButton(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 2,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // ⭐ LEFT ALIGN
              children: [
                const SizedBox(height: 20),

                /// ⭐ SYSTEM ADMIN LABEL (UPDATED STYLE)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B8E5A),
                    borderRadius:
                        BorderRadius.circular(10), // ⭐ small corner radius
                  ),
                  child: const Text(
                    "System Administrator",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20, // ⭐ bigger text
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7E2D2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      menuButton(
                        "Customer Activities",
                        () {
                          Navigator.pushNamed(
                              context, '/customer-activity');
                        },
                      ),
                      menuButton(
                        "Maintain the System model",
                        showModelPopup,
                      ),
                      menuButton(
                        "Monitor the system",
                        () {
                          Navigator.pushNamed(
                              context, '/monitor-system-screen');
                        },
                      ),
                    ],
                  ),
                ),

                /// ⭐ PUSH BUTTON SLIGHTLY UP
                const Spacer(),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B8E5A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    onPressed: _showLogoutDialog,
                    child: const Text(
                      "Logout",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20), // ⭐ bottom spacing like UI
              ],
            ),
          ),
        ),
      ),
    );
  }
}