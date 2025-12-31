import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ride_tracking_service.dart';
import '../services/firebase_service.dart';

class RideTrackingScreen extends StatefulWidget {
  final String orderId;
  final String driverId;
  final Map<String, dynamic> orderData;

  const RideTrackingScreen({
    super.key,
    required this.orderId,
    required this.driverId,
    required this.orderData,
  });

  @override
  RideTrackingScreenState createState() => RideTrackingScreenState();
}

class RideTrackingScreenState extends State<RideTrackingScreen> {
  final RideTrackingService _trackingService = RideTrackingService();
  bool _isTracking = false;
  List<Map<String, dynamic>> _routePoints = [];
  Map<String, dynamic>? _currentDriverLocation;

  // Order locations
  latlong2.LatLng? _pickupLocation;
  latlong2.LatLng? _dropoffLocation;

  @override
  void initState() {
    super.initState();
    _initializeLocations();
    _startTracking();
  }

  void _initializeLocations() {
    // Parse pickup location from order data
    if (widget.orderData['pickup_lat'] != null &&
        widget.orderData['pickup_lng'] != null) {
      _pickupLocation = latlong2.LatLng(
        widget.orderData['pickup_lat'],
        widget.orderData['pickup_lng'],
      );
    }

    // Parse dropoff location from order data
    if (widget.orderData['dropoff_lat'] != null &&
        widget.orderData['dropoff_lng'] != null) {
      _dropoffLocation = latlong2.LatLng(
        widget.orderData['dropoff_lat'],
        widget.orderData['dropoff_lng'],
      );
    }
  }

  Future<void> _startTracking() async {
    try {
      await _trackingService.startRideTracking(
        orderId: widget.orderId,
        driverId: widget.driverId,
      );

      setState(() {
        _isTracking = true;
      });

      // Send notification to client
      await FirebaseService.sendOrderNotification(
        userId: widget.orderData['clientId'],
        title: 'Ride Started',
        body: 'Your driver has started the ride. Track in real-time!',
        data: {'orderId': widget.orderId, 'status': 'in_progress'},
      );

      // Start periodic UI updates
      _startPeriodicUpdates();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start tracking: $e')),
      );
    }
  }

  void _startPeriodicUpdates() {
    // Update UI every 5 seconds
    Future.delayed(const Duration(seconds: 5), () async {
      if (mounted && _isTracking) {
        await _updateTrackingData();
        _startPeriodicUpdates();
      }
    });
  }

  Future<void> _updateTrackingData() async {
    final routePoints = _trackingService.getRoutePoints();
    final driverLocation = await _trackingService.getCurrentDriverLocation();

    setState(() {
      _routePoints = routePoints;
      _currentDriverLocation = driverLocation;
    });
  }

  Future<void> _completeRide() async {
    try {
      await _trackingService.stopRideTracking();

      setState(() {
        _isTracking = false;
      });

      // Send completion notification
      await FirebaseService.sendOrderNotification(
        userId: widget.orderData['clientId'],
        title: 'Ride Completed',
        body: 'Your ride has been completed successfully!',
        data: {'orderId': widget.orderId, 'status': 'completed'},
      );

      // Navigate back
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride completed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete ride: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Tracking'),
        actions: [
          if (_isTracking)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _completeRide,
              tooltip: 'Complete Ride',
            ),
        ],
      ),
      body: Column(
        children: [
          // Map View
          Expanded(
            flex: 3,
            child: _buildMap(),
          ),

          // Tracking Info
          Expanded(
            flex: 2,
            child: _buildTrackingInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final markers = <Marker>[];

    // Pickup marker
    if (_pickupLocation != null) {
      markers.add(
        Marker(
          point: _pickupLocation!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.green, size: 36),
        ),
      );
    }

    // Dropoff marker
    if (_dropoffLocation != null) {
      markers.add(
        Marker(
          point: _dropoffLocation!,
          width: 40,
          height: 40,
          child: const Icon(Icons.flag, color: Colors.red, size: 36),
        ),
      );
    }

    // Current driver location
    if (_currentDriverLocation != null &&
        _currentDriverLocation!['lat'] != null &&
        _currentDriverLocation!['lng'] != null) {
      markers.add(
        Marker(
          point: latlong2.LatLng(
            _currentDriverLocation!['lat'],
            _currentDriverLocation!['lng'],
          ),
          width: 40,
          height: 40,
          child: const Icon(Icons.directions_car, color: Colors.blue, size: 36),
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter:
            _pickupLocation ?? const latlong2.LatLng(37.7749, -122.4194),
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(markers: markers),
        // Route line
        if (_routePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints
                    .map((point) => latlong2.LatLng(point['lat'], point['lng']))
                    .toList(),
                color: Colors.blue,
                strokeWidth: 4.0,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTrackingInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: _isTracking ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              _isTracking ? 'Tracking Active' : 'Tracking Stopped',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // Order Details
          _buildInfoRow(
              'Service Type', widget.orderData['serviceType'] ?? 'N/A'),
          _buildInfoRow('Distance',
              '${widget.orderData['distanceKm']?.toStringAsFixed(2) ?? '0.00'} km'),
          _buildInfoRow('Price',
              '\$${widget.orderData['price']?.toStringAsFixed(2) ?? '0.00'}'),

          const SizedBox(height: 16),

          // Tracking Stats
          if (_routePoints.isNotEmpty) ...[
            _buildInfoRow('Route Points', _routePoints.length.toString()),
            _buildInfoRow('Duration', _calculateDuration()),
          ],

          const Spacer(),

          // Action Button
          if (_isTracking)
            ElevatedButton.icon(
              onPressed: _completeRide,
              icon: const Icon(Icons.check_circle),
              label: const Text('Complete Ride'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _calculateDuration() {
    if (_routePoints.length < 2) return '0 min';

    final startTime = DateTime.parse(_routePoints.first['timestamp']);
    final endTime = DateTime.parse(_routePoints.last['timestamp']);
    final duration = endTime.difference(startTime);

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes min $seconds sec';
  }

  @override
  void dispose() {
    _trackingService.dispose();
    super.dispose();
  }
}
