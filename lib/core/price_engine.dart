class PriceBreakdown {
  final double basePrice;
  final double extraPrice;
  final double totalPrice;
  final String description;

  PriceBreakdown({
    required this.basePrice,
    required this.extraPrice,
    required this.totalPrice,
    required this.description,
  });
}

class PriceEngine {
  static PriceBreakdown calculatePrice({
    required double distanceKm,
    required String vehicleType,
    required String serviceType,
  }) {
    final String vehicle = vehicleType.toLowerCase().trim();
    final String service = serviceType.toLowerCase().trim();

    double basePrice = 0;
    double extraPrice = 0;
    double totalPrice = 0;
    String description = '';

    if (vehicle == 'bike' && service == 'delivery') {
      // Bike Delivery: 6000 per KM, +2000 per 1.5 KM
      basePrice = 6000 * distanceKm;
      int extraStep =
          (distanceKm / 1.5).floor(); // Berapa kelipatan 1.5 km (selalu >=0)
      extraPrice = extraStep * 2000;
      description =
          "Bike Delivery\n6000/km x ${distanceKm.toStringAsFixed(2)}km = ${basePrice.toStringAsFixed(0)}"
          "\n+2000 tiap 1.5km x $extraStep = ${extraPrice.toStringAsFixed(0)}";
    } else if (vehicle == 'bike' && service == 'ride') {
      // Bike Ride: 10000 per KM, +1500 per 1.5 KM
      basePrice = 10000 * distanceKm;
      int extraStep = (distanceKm / 1.5).floor();
      extraPrice = extraStep * 1500;
      description =
          "Bike Ride\n10000/km x ${distanceKm.toStringAsFixed(2)}km = ${basePrice.toStringAsFixed(0)}"
          "\n+1500 tiap 1.5km x $extraStep = ${extraPrice.toStringAsFixed(0)}";
    } else if (vehicle == 'car' && service == 'delivery') {
      // Car Delivery: 12000 per KM, +2500 per 1.5 KM
      basePrice = 12000 * distanceKm;
      int extraStep = (distanceKm / 1.5).floor();
      extraPrice = extraStep * 2500;
      description =
          "Car Delivery\n12000/km x ${distanceKm.toStringAsFixed(2)}km = ${basePrice.toStringAsFixed(0)}"
          "\n+2500 tiap 1.5km x $extraStep = ${extraPrice.toStringAsFixed(0)}";
    } else if (vehicle == 'car' && service == 'ride') {
      // Car Ride: 15000 per KM, +2500 per KM
      basePrice = 15000 * distanceKm;
      int extraStep = distanceKm.floor(); // Setiap km penuh (tidak 1.5km)
      extraPrice = extraStep * 2500;
      description =
          "Car Ride\n15000/km x ${distanceKm.toStringAsFixed(2)}km = ${basePrice.toStringAsFixed(0)}"
          "\n+2500 tiap 1km x $extraStep = ${extraPrice.toStringAsFixed(0)}";
    } else {
      // fallback, unknown type
      description = "Unknown vehicle/service";
    }

    totalPrice = basePrice + extraPrice;

    return PriceBreakdown(
      basePrice: basePrice,
      extraPrice: extraPrice,
      totalPrice: totalPrice,
      description: description,
    );
  }
}
