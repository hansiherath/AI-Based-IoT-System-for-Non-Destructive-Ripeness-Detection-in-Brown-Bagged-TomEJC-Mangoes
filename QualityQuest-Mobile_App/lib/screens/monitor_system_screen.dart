import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MonitorSystemScreen extends StatelessWidget {
  const MonitorSystemScreen({super.key});

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔙 Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        Navigator.pop(context); // Admin Dashboard
                      },
                    ),
                    Text(
                      "Monitor the System",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                /// 🔲 System Status Large Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Small Cards Row
                        Row(
                          children: [
                            /// System Status
                            Expanded(
                              child: _infoBox(
                                icon: Icons.check_circle,
                                iconColor: Colors.green,
                                title: "System Status",
                                value: "Online",
                              ),
                            ),
                            const SizedBox(width: 12),

                            /// Active Users
                            Expanded(
                              child: _infoBox(
                                icon: Icons.person,
                                iconColor: Colors.black,
                                title: "256",
                                value: "Active Users",
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        /// Active Sensors
                        _infoBox(
                          icon: Icons.sensors,
                          iconColor: Colors.black,
                          title: "2",
                          value: "Active Sensors",
                        ),

                        const SizedBox(height: 12),

                        /// Last Maintains
                        Row(
                          children: const [
                            Icon(Icons.access_time, size: 16),
                            SizedBox(width: 6),
                            Text(
                              "Last Maintains: 5 mins ago",
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// 📡 Live Monitoring
                Text(
                  "Live Monitoring",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                /// 🔲 Sensor Status Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Sensor Status",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12),
                        SensorRow("AS7263", true),
                        SensorRow("BME688", false),
                        SensorRow("MPU6050", true),
                        SensorRow("Load Cell+HX711", false),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🧩 Small Info Box Widget
  Widget _infoBox({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 🔘 Sensor Row Widget
class SensorRow extends StatelessWidget {
  final String name;
  final bool active;

  const SensorRow(this.name, this.active, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 12,
                color: active ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(active ? "Active" : "Inactive"),
            ],
          ),
        ],
      ),
    );
  }
}
