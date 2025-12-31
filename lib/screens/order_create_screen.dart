import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/order_service.dart';
import '../services/autobid_service.dart';

class OrderCreateScreen extends StatefulWidget {
  const OrderCreateScreen({super.key});

  @override
  OrderCreateScreenState createState() => OrderCreateScreenState();
}

class OrderCreateScreenState extends State<OrderCreateScreen> {
  latlong2.LatLng? _pickup;
  latlong2.LatLng? _dropoff;

  double? _distanceKm;
  double? _estimatedPrice;

  // Service type selection
  String _serviceType = 'bike_ride'; // default

  // Services
  final OrderService _orderService = OrderService();
  final AutoBidService _autoBidService = AutoBidService();

  // Price calculation constants
  final double baseFare = 5.0;
  final double perKmRate = 2.5;

  void _onMapTap(latlong2.LatLng point) {
    setState(() {
      if (_pickup == null) {
        _pickup = point;
      } else if (_dropoff == null) {
        _dropoff = point;
      } else {
        // Reset selections if both are already picked
        _pickup = point;
        _dropoff = null;
        _distanceKm = null;
        _estimatedPrice = null;
      }

      if (_pickup != null && _dropoff != null) {
        _calculateDistanceAndPrice();
      }
    });
  }

  void _calculateDistanceAndPrice() {
    const Distance distance = Distance();
    final double meterDist = distance(_pickup!, _dropoff!);
    _distanceKm = meterDist / 1000.0;
    _estimatedPrice = baseFare + (_distanceKm! * perKmRate);
  }

  Widget _buildMap() {
    final markers = <Marker>[];
    if (_pickup != null) {
      markers.add(
        Marker(
          point: _pickup!,
          width: 40, // Required width for Marker
          height: 40, // Required height for Marker
          child: const Icon(Icons.location_on, color: Colors.green, size: 36),
        ),
      );
    }
    if (_dropoff != null) {
      markers.add(
        Marker(
          point: _dropoff!,
          width: 40, // Required width for Marker
          height: 40, // Required height for Marker
          child: const Icon(Icons.flag, color: Colors.red, size: 36),
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: _pickup ??
            const latlong2.LatLng(
                37.7749, -122.4194), // Use initialCenter instead of center
        initialZoom: 12,
        onTap: (_, point) => _onMapTap(point),
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(markers: markers),
        if (_pickup != null && _dropoff != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [_pickup!, _dropoff!],
                color: Colors.blue,
                strokeWidth: 4.0,
              )
            ],
          ),
      ],
    );
  }

  Widget _buildInfoPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Service Type Selection
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String>(
            initialValue: _serviceType,
            decoration: const InputDecoration(
              labelText: 'Service Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'bike_ride', child: Text('Bike Ride')),
              DropdownMenuItem(value: 'car_ride', child: Text('Car Ride')),
              DropdownMenuItem(
                  value: 'bike_delivery', child: Text('Bike Delivery')),
              DropdownMenuItem(
                  value: 'car_delivery', child: Text('Car Delivery')),
            ],
            onChanged: (value) {
              setState(() {
                _serviceType = value!;
              });
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.location_on, color: Colors.green),
          title: Text(_pickup == null
              ? "Tap map to set pickup"
              : "Pickup: ${_pickup!.latitude.toStringAsFixed(5)}, ${_pickup!.longitude.toStringAsFixed(5)}"),
        ),
        ListTile(
          leading: const Icon(Icons.flag, color: Colors.red),
          title: Text(_dropoff == null
              ? "Tap map to set drop-off"
              : "Drop-off: ${_dropoff!.latitude.toStringAsFixed(5)}, ${_dropoff!.longitude.toStringAsFixed(5)}"),
        ),
        if (_distanceKm != null)
          ListTile(
            leading: const Icon(Icons.straighten),
            title: Text("Distance: ${_distanceKm!.toStringAsFixed(2)} km"),
          ),
        if (_estimatedPrice != null)
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: Text(
                "Estimated Price: \$${_estimatedPrice!.toStringAsFixed(2)}"),
          ),
      ],
    );
  }

  Future<void> _createOrder() async {
    try {
      // Get current user
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
        return;
      }

      // Prepare order data
      final orderData = {
        'clientId': user.id,
        'serviceType': _serviceType,
        'distanceKm': _distanceKm,
        'price': _estimatedPrice,
        'status': 'waiting',
        'createdAt': DateTime.now().toIso8601String(),
        // Note: pickup and dropoff coordinates could be added to database if needed
      };

      // Create order
      final createdOrder = await _orderService.createOrder(orderData);
      if (createdOrder == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create order')),
        );
        return;
      }

      // Run auto bid only for ride services (not delivery)
      if (!_serviceType.contains('delivery')) {
        await _autoBidService.runAutobid(
          createdOrder['id'],
          _pickup!.latitude,
          _pickup!.longitude,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Order created! Auto-assigning driver...')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Delivery order created! Waiting for manual driver assignment')),
        );
      }

      // Navigate back or to order status screen
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Order"),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: _buildMap(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildInfoPanel(),
          ),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: (_pickup != null && _dropoff != null)
                    ? () async {
                        await _createOrder();
                      }
                    : null,
                child: const Text("Create Order"),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
