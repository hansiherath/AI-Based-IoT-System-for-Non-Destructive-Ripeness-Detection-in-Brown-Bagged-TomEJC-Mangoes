import 'package:flutter/material.dart';

class HealthRecommendationScreen extends StatelessWidget {
  final String recommendation;

  const HealthRecommendationScreen({
    Key? key,
    required this.recommendation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final rec = recommendation.trim();

    bool isSafe = rec.startsWith("Safe to Eat");
    bool isLimit = rec.startsWith("Limit to Eat");
    bool isNotSafe = rec.startsWith("Not Safe to Eat");

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5EF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Health Recommendation',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      /// ⭐ SAME BACKGROUND AS HOME SCREEN
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

                if (isSafe)
                  _safeToEatCard()
                else if (isLimit)
                  _limitToEatCard(rec)
                else if (isNotSafe)
                  _notSafeToEatCard()
                else
                  const Text(
                    "Unable to generate recommendation. Please try again later",
                  ),

                const SizedBox(height: 24),
                _statusIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _safeToEatCard() {
    return _recommendationCard(
      color: const Color(0xFF7BA57A),
      icon: Icons.check,
      title: "SAFE TO EAT",
      fasting: "70–99 mg/ml",
      postMeal: "Below 140 mg/ml",
    );
  }

  Widget _limitToEatCard(String fullText) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.orange,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Row(
                  children: const [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.warning_amber_rounded,
                          color: Colors.orange),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "LIMIT TO EAT",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    fullText,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Blood Sugar Range',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 18),
                    SizedBox(width: 8),
                    Text('Fasting : 100–125 mg/ml'),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.restaurant, size: 18),
                    SizedBox(width: 8),
                    Text('Post meal : 140–199 mg/ml'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notSafeToEatCard() {
    return _recommendationCard(
      color: Colors.red,
      icon: Icons.close,
      title: "NOT SAFE TO EAT",
      fasting: "≥126 mg/ml",
      postMeal: "≥200 mg/ml",
    );
  }

  Widget _recommendationCard({
    required Color color,
    required IconData icon,
    required String title,
    required String fasting,
    required String postMeal,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Blood Sugar Range',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18),
                    const SizedBox(width: 8),
                    Text('Fasting : $fasting'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.restaurant, size: 18),
                    const SizedBox(width: 8),
                    Text('Post meal : $postMeal'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatusItem(
            icon: Icons.check_circle,
            label: 'Safe',
            color: Colors.green,
          ),
          _Divider(),
          _StatusItem(
            icon: Icons.warning_amber_rounded,
            label: 'Limit',
            color: Colors.orange,
          ),
          _Divider(),
          _StatusItem(
            icon: Icons.cancel,
            label: 'Not safe',
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey,
    );
  }
}