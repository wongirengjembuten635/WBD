import 'dart:math';

double calculateHaversineDistance(
  double pickupLat,
  double pickupLng,
  double dropLat,
  double dropLng,
) {
  const double earthRadiusKm = 6371.0;

  double degToRad(double deg) => deg * (pi / 180.0);

  double dLat = degToRad(dropLat - pickupLat);
  double dLng = degToRad(dropLng - pickupLng);

  double a = (sin(dLat / 2) * sin(dLat / 2)) +
      cos(degToRad(pickupLat)) *
          cos(degToRad(dropLat)) *
          (sin(dLng / 2) * sin(dLng / 2));
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  double distance = earthRadiusKm * c;

  return distance;
}
