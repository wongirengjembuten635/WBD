import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_service.dart';
import '../core/geo_utils.dart';

class LatLng {
  final double lat;
  final double lng;
  LatLng({required this.lat, required this.lng});
}

class AutoBidService {
  final SupabaseClient _client = Supabase.instance.client;
  final LocationService _locationService = LocationService();

  /// Cari driver aktif & assign otomatis ke order terdekat tanpa biaya.
  Future<Map<String, dynamic>?> autoAssignDriver({
    required String orderId,
    required double orderLat,
    required double orderLng,
  }) async {
    // 1. Ambil semua driver yang online
    final List<Map<String, dynamic>> drivers = await _fetchOnlineDrivers();
    if (drivers.isEmpty) return null;

    // 2. Hitung jarak tiap driver ke order dalam satuan kilometer
    final List<_DriverDistance> driverDistances = [];
    for (final driver in drivers) {
      final double? lat = _toDouble(driver['locationLat']);
      final double? lng = _toDouble(driver['locationLng']);
      if (lat == null || lng == null) continue;

      final double distanceKm = await _calculateDistanceKm(
        LatLng(lat: lat, lng: lng),
        LatLng(lat: orderLat, lng: orderLng),
      );
      driverDistances
          .add(_DriverDistance(driver: driver, distanceKm: distanceKm));
    }
    if (driverDistances.isEmpty) return null;

    // 3. Prioritaskan driver terdekat
    driverDistances.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    final chosenDriver = driverDistances.first.driver;

    // 4. Assign order ke driver terdekat
    final assigned = await _assignDriverToOrder(
      orderId: orderId,
      driverId: chosenDriver['id'].toString(),
    );
    if (!assigned) return null;

    // 5. Tidak ada potongan maupun biaya tambahan
    return {
      'driver': chosenDriver,
      'distance_km': driverDistances.first.distanceKm,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchOnlineDrivers() async {
    final result = await _client.from('drivers').select().eq('isOnline', true);
    return List<Map<String, dynamic>>.from(result);
  }

  Future<bool> _assignDriverToOrder({
    required String orderId,
    required String driverId,
  }) async {
    // Supabase Dart no longer requires .execute(), .update returns a PostgrestResponse or directly throws.
    // We should try/catch and check 'count' or if an exception is thrown
    try {
      final result = await _client
          .from('orders')
          .update({'driverId': driverId, 'status': 'assigned'})
          .eq('id', orderId)
          .select(); // To get the updated row and response status

      // Result is a List if successful, empty list if nothing updated.
      if (result.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Wrapper untuk hitung jarak antar dua titik dalam kilometer
  Future<double> _calculateDistanceKm(LatLng from, LatLng to) async {
    // Cek jika LocationService ada getDistanceKm, gunakan,
    // kalau tidak: simple Haversine fallback
    final locationService = _locationService;
    if ((locationService as dynamic).getDistanceKm != null) {
      // ignore: avoid_dynamic_calls
      return await (locationService as dynamic)
          .getDistanceKm(from: from, to: to) as double;
    } else {
      return _haversineDistanceKm(from, to);
    }
  }

  double _haversineDistanceKm(LatLng p1, LatLng p2) {
    const double R = 6371; // Earth radius in km
    final double dLat = _deg2rad(p2.lat - p1.lat);
    final double dLon = _deg2rad(p2.lng - p1.lng);
    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(p1.lat)) *
            cos(_deg2rad(p2.lat)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  /// Autobid dengan scoring system: prioritaskan driver dengan order bulanan sedikit & jarak dekat
  Future<void> runAutobid({
    required String orderId,
    required double orderLat,
    required double orderLng,
  }) async {
    // 1. Ambil driver online
    final drivers =
        await _client.from('drivers').select().eq('is_online', true);

    if (drivers.isEmpty) return;

    Map<String, dynamic>? bestDriver;
    double bestScore = double.negativeInfinity;

    for (final d in drivers) {
      if (d['lat'] == null || d['lng'] == null) continue;

      final distance = GeoUtils.distanceKm(
        orderLat,
        orderLng,
        d['lat'] as double,
        d['lng'] as double,
      );

      final completed = (d['monthly_completed'] as int?) ?? 0;
      final score = (-distance) + (10 - completed);

      if (score > bestScore) {
        bestScore = score;
        bestDriver = d;
      }
    }

    if (bestDriver == null) return;

    // 2. Assign order
    await _client.from('orders').update({
      'status': 'assigned',
      'driver_id': bestDriver['id'],
    }).eq('id', orderId);

    // 3. Update driver progress
    await _client.from('drivers').update({
      'monthly_completed': ((bestDriver['monthly_completed'] as int?) ?? 0) + 1,
    }).eq('id', bestDriver['id']);
  }
}

class _DriverDistance {
  final Map<String, dynamic> driver;
  final double distanceKm;
  _DriverDistance({required this.driver, required this.distanceKm});
}
