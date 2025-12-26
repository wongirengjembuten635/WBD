class DriverModel {
  final String id;
  final String name;
  final double locationLat;
  final double locationLng;
  final bool isOnline;
  final int monthlyCompletedOrder;
  final bool subscriptionActive;

  DriverModel({
    required this.id,
    required this.name,
    required this.locationLat,
    required this.locationLng,
    required this.isOnline,
    required this.monthlyCompletedOrder,
    required this.subscriptionActive,
  });

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    final int monthlyOrder = map['monthlyCompletedOrder'] ?? 0;

    // 10 order gratis per bulan
    // Jika >=10 order, subscription active di bulan berikutnya
    final bool activeSubscription =
        map['subscriptionActive'] ?? (monthlyOrderLastMonth(monthlyOrder, map));

    return DriverModel(
      id: map['id'] as String,
      name: map['name'] as String,
      locationLat: (map['locationLat'] as num).toDouble(),
      locationLng: (map['locationLng'] as num).toDouble(),
      isOnline: map['isOnline'] as bool,
      monthlyCompletedOrder: monthlyOrder,
      subscriptionActive: activeSubscription,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'isOnline': isOnline,
      'monthlyCompletedOrder': monthlyCompletedOrder,
      // Taruh subscriptionActive sesuai logika
      'subscriptionActive': subscriptionActive,
    };
  }

  /// Helper logic:
  /// Jika bulan lalu >=10 order, subscription bulan ini aktif (true).
  /// Asumsi: Data order bulan lalu bisa diakses lewat map, misal: 'lastMonthCompletedOrder'
  static bool monthlyOrderLastMonth(
      int thisMonthOrder, Map<String, dynamic> map) {
    int lastMonthOrder = map['lastMonthCompletedOrder'] ?? 0;
    return lastMonthOrder >= 10;
  }

  // 10 order gratis setiap bulan
  bool get isFree => monthlyCompletedOrder < 10;

  // Jika >=10 order di bulan lalu, subscription bulan ini aktif
  bool get mustSubscribeNextMonth => monthlyCompletedOrder >= 10;
}
