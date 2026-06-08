class MangoResult {
  final String ripeness;
  final String sugar;
  final String time;
  final String healthRecommendation;
  final String sensorStatus; // ⭐ NEW

  MangoResult({
    required this.ripeness,
    required this.sugar,
    required this.time,
    required this.healthRecommendation,
    required this.sensorStatus, // ⭐ NEW
  });

  factory MangoResult.fromJson(Map<String, dynamic> json) {

    /// 🔥 KEEPING YOUR ORIGINAL LOGIC EXACTLY
    /// Accept BOTH camelCase and PascalCase from backend
    final recommendation =
        json['healthRecommendation'] ??
        json['HealthRecommendation'] ??
        "Unknown";

    /// ⭐ NEW — SENSOR STATUS (SAFE DEFAULT)
    final sensor =
        json['sensorStatus'] ??
        json['SensorStatus'] ??
        "NO_MANGO";

    return MangoResult(
      ripeness: json['RipenessStage'] ?? '-',
      sugar: json['SugarLevel']?.toString() ?? '-',
      time: json['TimeToConsume'] ?? '-',
      healthRecommendation: recommendation,
      sensorStatus: sensor, // ⭐ NEW
    );
  }
}