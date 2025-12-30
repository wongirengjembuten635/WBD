import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/order_service.dart';
import '../services/autobid_service.dart' hide LatLng;

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
  bool _isCreatingOrder = false;
  String? _orderStatus;
  String? _driverInfo;

  // Services
  final OrderService _orderService = OrderService();
  final AutoBidService _autobidService = AutoBidService();

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

  Future<void> _createOrderWithAutobid() async {
    if (_pickup == null || _dropoff == null) return;

    setState(() {
      _isCreatingOrder = true;
      _orderStatus = null;
      _driverInfo = null;
    });

    try {
      // 1. Ambil user ID dari session
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _isCreatingOrder = false;
          _orderStatus = 'error';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda harus login terlebih dahulu')),
        );
        return;
      }

      // 2. Buat order di database
      final orderData = {
        'client_id': user.id,
        'pickup_lat': _pickup!.latitude,
        'pickup_lng': _pickup!.longitude,
        'dropoff_lat': _dropoff!.latitude,
        'dropoff_lng': _dropoff!.longitude,
        'distance_km': _distanceKm,
        'estimated_price': _estimatedPrice,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      final createdOrder = await _orderService.createOrder(orderData);
      if (createdOrder == null) {
        setState(() {
          _isCreatingOrder = false;
          _orderStatus = 'error';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat order')),
        );
        return;
      }

      final orderId = createdOrder['id'].toString();

      setState(() {
        _orderStatus = 'pending';
        _driverInfo = 'Mencari driver terdekat...';
      });

      // 3. Jalankan autobid untuk mencari driver terdekat
      await _autobidService.runAutobid(
        orderId: orderId,
        orderLat: _pickup!.latitude,
        orderLng: _pickup!.longitude,
      );

      // 4. Cek status order setelah autobid
      final updatedOrder = await _orderService.getOrderById(orderId);
      if (updatedOrder != null) {
        setState(() {
          _orderStatus = updatedOrder['status'] ?? 'pending';
          if (updatedOrder['status'] == 'assigned' &&
              updatedOrder['driver_id'] != null) {
            _driverInfo = 'Driver ditemukan! ID: ${updatedOrder['driver_id']}';
          } else {
            _driverInfo = 'Belum ada driver yang tersedia.';
          }
        });

        if (updatedOrder['status'] == 'assigned') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Driver terdekat telah ditemukan!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order dibuat, menunggu driver...'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _orderStatus = 'error';
        _driverInfo = 'Error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() {
        _isCreatingOrder = false;
      });
    }
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
                onPressed:
                    (_pickup != null && _dropoff != null && !_isCreatingOrder)
                        ? _createOrderWithAutobid
                        : null,
                child: _isCreatingOrder
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Mencari driver...'),
                        ],
                      )
                    : const Text("Create Order"),
              )),
          if (_orderStatus != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: _orderStatus == 'assigned'
                    ? Colors.green.shade50
                    : Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Order: $_orderStatus',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _orderStatus == 'assigned'
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                      if (_driverInfo != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _driverInfo!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
