import 'dart:math'; // for sin, cos, atan2, sqrt
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple LatLng struct (tanpa Google Maps)
class LatLng {
  final double lat;
  final double lng;
  LatLng({required this.lat, required this.lng});
}

class LocationService {
  /// Mendapatkan lokasi GPS saat ini (jika izin sudah diberikan)
  Future<LatLng?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    return LatLng(lat: position.latitude, lng: position.longitude);
  }

  /// Mendapatkan alamat dari lat/lng via OpenStreetMap Nominatim
  Future<String?> getAddressFromLatLng(LatLng location) async {
    final url =
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.lat}&lon=${location.lng}&zoom=18&addressdetails=1";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "User-Agent": "FlutterApp (yourdomain.com)",
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          return data['display_name'];
        }
      }
    } catch (e) {
      // ignore jika error jaringan
    }
    return null;
  }

  /// Hitung jarak (KM) antara dua titik lat/lng (Haversine formula)
  double calculateDistanceKm(LatLng start, LatLng end) {
    const double earthRadius = 6371; // KM
    final double dLat = _degToRad(end.lat - start.lat);
    final double dLng = _degToRad(end.lng - start.lng);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degToRad(start.lat)) *
            cos(_degToRad(end.lat)) *
            (sin(dLng / 2) * sin(dLng / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (3.141592653589793 / 180.0);
}
