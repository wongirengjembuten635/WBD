class OrderModel {
  final String id;
  final String clientId;
  final String? driverId;
  final String serviceType; // bike_delivery, bike_ride, car_delivery, car_ride
  final double distanceKm;
  final double price;
  final String status; // waiting, assigned, completed
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.clientId,
    required this.driverId,
    required this.serviceType,
    required this.distanceKm,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String,
      clientId: map['clientId'] as String,
      driverId: map['driverId'] as String?, // Nullable
      serviceType: map['serviceType'] as String,
      distanceKm: (map['distanceKm'] as num).toDouble(),
      price: (map['price'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'] as String)
          : (map['createdAt'] as DateTime),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'driverId': driverId,
      'serviceType': serviceType,
      'distanceKm': distanceKm,
      'price': price,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
