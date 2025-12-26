import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OrderCreateScreen extends StatefulWidget {
  const OrderCreateScreen({super.key});

  @override
  OrderCreateScreenState createState() => OrderCreateScreenState();
}

class OrderCreateScreenState extends State<OrderCreateScreen> {
  LatLng? _pickup;
  LatLng? _dropoff;

  double? _distanceKm;
  double? _estimatedPrice;

  // Price calculation constants
  final double baseFare = 5.0;
  final double perKmRate = 2.5;

  void _onMapTap(LatLng point) {
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
            const LatLng(
                37.7749, -122.4194), // Use initialCenter instead of center
        zoom: 12,
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
                    ? () {
                        // Proceed with order submission (to be implemented)
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                "Order created! (Submission logic not implemented.)")));
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
