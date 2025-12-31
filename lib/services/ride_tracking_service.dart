import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RideTrackingService {
  final SupabaseClient _client = Supabase.instance.client;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _locationUpdateTimer;

  // Track current ride
  String? _currentOrderId;
  String? _currentDriverId;
  List<Map<String, dynamic>> _routePoints = [];

  // Settings
  static const Duration LOCATION_UPDATE_INTERVAL = Duration(seconds: 10);
  static const double LOCATION_ACCURACY = 10.0; // meters

  // Start tracking for a ride
  Future<void> startRideTracking({
    required String orderId,
    required String driverId,
  }) async {
    _currentOrderId = orderId;
    _currentDriverId = driverId;
    _routePoints.clear();

    // Request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Start location tracking
    _startLocationUpdates();

    // Update order status to 'in_progress'
    await _updateOrderStatus(orderId, 'in_progress');

    print('Started ride tracking for order: $orderId');
  }

  // Stop tracking
  Future<void> stopRideTracking() async {
    _positionSubscription?.cancel();
    _locationUpdateTimer?.cancel();

    if (_currentOrderId != null) {
      // Save final route to database
      await _saveRouteToDatabase();

      // Update order status to 'completed'
      await _updateOrderStatus(_currentOrderId!, 'completed');
    }

    _currentOrderId = null;
    _currentDriverId = null;
    _routePoints.clear();

    print('Stopped ride tracking');
  }

  // Start periodic location updates
  void _startLocationUpdates() {
    _locationUpdateTimer =
        Timer.periodic(LOCATION_UPDATE_INTERVAL, (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Add to route points
        _routePoints.add({
          'lat': position.latitude,
          'lng': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
          'accuracy': position.accuracy,
          'speed': position.speed,
        });

        // Update driver location in real-time
        if (_currentDriverId != null) {
          await _updateDriverLocation(position);
        }

        // Send location update to client (optional)
        if (_currentOrderId != null) {
          await _sendLocationUpdateToClient(position);
        }
      } catch (e) {
        print('Error getting location: $e');
      }
    });
  }

  // Update driver location in database
  Future<void> _updateDriverLocation(Position position) async {
    try {
      await _client.from('drivers').update({
        'lat': position.latitude,
        'lng': position.longitude,
        'last_location_update': DateTime.now().toIso8601String(),
      }).eq('user_id', _currentDriverId!);
    } catch (e) {
      print('Error updating driver location: $e');
    }
  }

  // Send location update to client via real-time
  Future<void> _sendLocationUpdateToClient(Position position) async {
    try {
      // This could be sent via Supabase real-time channels
      // For now, we'll just update the order with current location
      await _client.from('orders').update({
        'current_driver_lat': position.latitude,
        'current_driver_lng': position.longitude,
        'last_location_update': DateTime.now().toIso8601String(),
      }).eq('id', _currentOrderId!);
    } catch (e) {
      print('Error sending location to client: $e');
    }
  }

  // Update order status
  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _client.from('orders').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  // Save route to database
  Future<void> _saveRouteToDatabase() async {
    if (_routePoints.isEmpty || _currentOrderId == null) return;

    try {
      // Create route record
      await _client.from('ride_routes').insert({
        'order_id': _currentOrderId,
        'route_points': _routePoints,
        'total_distance_km': _calculateTotalDistance(),
        'duration_minutes': _calculateDuration(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving route: $e');
    }
  }

  // Calculate total distance traveled
  double _calculateTotalDistance() {
    if (_routePoints.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < _routePoints.length; i++) {
      final prev = _routePoints[i - 1];
      final current = _routePoints[i];

      totalDistance += _calculateDistance(
        prev['lat'],
        prev['lng'],
        current['lat'],
        current['lng'],
      );
    }

    return totalDistance;
  }

  // Calculate ride duration
  int _calculateDuration() {
    if (_routePoints.length < 2) return 0;

    final startTime = DateTime.parse(_routePoints.first['timestamp']);
    final endTime = DateTime.parse(_routePoints.last['timestamp']);

    return endTime.difference(startTime).inMinutes;
  }

  // Calculate distance between two points
  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double R = 6371; // Earth's radius in km
    final double dLat = _deg2rad(lat2 - lat1);
    final double dLng = _deg2rad(lng2 - lng1);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  // Get current route points
  List<Map<String, dynamic>> getRoutePoints() => _routePoints;

  // Get current order ID
  String? getCurrentOrderId() => _currentOrderId;

  // Check if tracking is active
  bool isTrackingActive() => _currentOrderId != null;

  // Get current driver location
  Future<Map<String, dynamic>?> getCurrentDriverLocation() async {
    if (_currentDriverId == null) return null;

    try {
      final response = await _client
          .from('drivers')
          .select('lat, lng, last_location_update')
          .eq('user_id', _currentDriverId!)
          .single();

      return response;
    } catch (e) {
      print('Error getting driver location: $e');
      return null;
    }
  }

  // Cleanup
  void dispose() {
    _positionSubscription?.cancel();
    _locationUpdateTimer?.cancel();
  }
}
