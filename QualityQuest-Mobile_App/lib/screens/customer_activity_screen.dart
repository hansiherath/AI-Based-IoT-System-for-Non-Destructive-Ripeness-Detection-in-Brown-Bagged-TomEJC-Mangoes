import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'customer_detail_dialog.dart';
import '../session/admin_session.dart';
import 'dart:io';

class CustomerActivityScreen extends StatelessWidget {
  const CustomerActivityScreen({super.key});

  /// ===============================
  /// FETCH CUSTOMERS WITH PROFILE IMAGE
  /// ===============================
  Future<List<dynamic>> fetchCustomers() async {
    final response = await http.get(
      Uri.parse("http://10.17.5.39:3000/admin/customers"),
      headers: {
        "Authorization": "Bearer ${AdminSession.token}",
        "Content-Type": "application/json",
      },
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load customers");
    }
  }

  /// ===============================
  /// BUILD PROFILE IMAGE
  /// ===============================
  Widget buildProfileImage(String? path) {
    /// ⭐ NO IMAGE → SHOW EMPTY AVATAR
    if (path == null || path.toString().trim().isEmpty) {
      return const CircleAvatar(
        radius: 24,
        backgroundColor: Color(0xFFE0E0E0),
        child: Icon(Icons.person, color: Colors.grey),
      );
    }

    /// ⭐ LOCAL FILE (from image_picker)
    if (path.startsWith("/")) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: FileImage(File(path)),
      );
    }

    /// ⭐ NETWORK IMAGE (future use)
    return CircleAvatar(
      radius: 24,
      backgroundImage: NetworkImage(path),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// HEADER
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                            context, '/admin-dashboard');
                      },
                    ),
                    Expanded(
                      child: Text(
                        "Customer Activity",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: fetchCustomers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text("Failed to load customers"),
                        );
                      }

                      final customers = snapshot.data ?? [];

                      if (customers.isEmpty) {
                        return const Center(
                          child: Text("No customers found"),
                        );
                      }

                      return ListView.builder(
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final customer = customers[index];

                          final name = customer["name"] ?? "-";
                          final email = customer["Email"] ?? "-";
                          final status =
                              customer["AccountStatus"] ?? "Inactive";
                          final profilePicture =
                              customer["ProfilePicture"];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  buildProfileImage(profilePicture),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Text(
                                      name,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF6B8E5A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) =>
                                            CustomerDetailDialog(
                                          name: name,
                                          email: email,
                                          status: status,
                                          image:
                                              profilePicture ??
                                                  "",
                                        ),
                                      );
                                    },
                                    child: const Text("View"),
                                  ),

                                  const SizedBox(width: 8),

                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}