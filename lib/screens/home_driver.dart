import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/order_service.dart';
import '../services/ride_tracking_service.dart';
import 'ride_tracking_screen.dart';

class HomeDriverScreen extends StatefulWidget {
  const HomeDriverScreen({super.key});

  @override
  State<HomeDriverScreen> createState() => _HomeDriverScreenState();
}

class _HomeDriverScreenState extends State<HomeDriverScreen> {
  final supabase = Supabase.instance.client;
  double? _currentLat;
  double? _currentLng;
  bool locationLoading = true;
  Future<Map<String, dynamic>?>? _driverFuture;
  Future<List<Map<String, dynamic>>>? _activeOrdersFuture;

  final OrderService _orderService = OrderService();
  final RideTrackingService _rideTrackingService = RideTrackingService();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _driverFuture = _fetchAndInitDriver();
    _activeOrdersFuture = _fetchActiveOrders();
    await _fetchLocationAndSave();
    setState(() {});
  }

  User? get _user => supabase.auth.currentUser;

  Future<Map<String, dynamic>?> _fetchAndInitDriver() async {
    if (_user == null) return null;
    final uid = _user!.id;

    final response = await supabase
        .from('drivers')
        .select()
        .eq('user_id', uid)
        .maybeSingle();

    if (response != null) {
      return response;
    }

    // Create initial driver record if it doesn't exist
    final initialData = {
      'user_id': uid,
      'is_online': false,
      'monthly_completed': 0,
      'subscription_active': true,
      'lat': null,
      'lng': null,
    };
    await supabase.from('drivers').insert(initialData);
    return initialData;
  }

  Future<List<Map<String, dynamic>>> _fetchActiveOrders() async {
    if (_user == null) return [];

    try {
      final response = await supabase
          .from('orders')
          .select()
          .eq('driverId', _user!.id)
          .or('status.eq.assigned,status.eq.in_progress')
          .order('createdAt', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching active orders: $e');
      return [];
    }
  }

  // UPGRADED: Place to plug in real location service in future
  Future<void> _fetchLocationAndSave() async {
    setState(() {
      locationLoading = true;
    });

    // --- Replace this with the real location fetching logic! ---
    await Future.delayed(const Duration(milliseconds: 700));
    double fakeLat = -6.2088; // Jakarta
    double fakeLng = 106.8456;
    setState(() {
      _currentLat = fakeLat;
      _currentLng = fakeLng;
      locationLoading = false;
    });

    if (_user != null) {
      await supabase.from('drivers').update({
        'lat': fakeLat,
        'lng': fakeLng,
      }).eq('user_id', _user!.id);

      setState(() {});
    }
  }

  Future<void> _toggleOnline(bool newValue, Map<String, dynamic> driver) async {
    if (_user == null) return;

    await supabase
        .from('drivers')
        .update({'is_online': newValue}).eq('user_id', _user!.id);

    setState(() {
      _driverFuture = _fetchAndInitDriver();
    });
  }

  void _handleLogout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _startRideTracking(Map<String, dynamic> order) async {
    final orderId = order['id'];
    try {
      await _rideTrackingService.startRideTracking(
        orderId: orderId,
        driverId: _user!.id,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RideTrackingScreen(
              orderId: orderId,
              driverId: _user!.id,
              orderData: order,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start ride tracking: $e')),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _activeOrdersFuture = _fetchActiveOrders();
    });
  }

  Widget _buildActiveOrders() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _activeOrdersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return const Center(
            child: Text(
              'No active orders',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            ...orders.map((order) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order['id']?.toString().substring(0, 8) ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Service: ${order['serviceType'] ?? 'Unknown'}'),
                        Text('Status: ${order['status'] ?? 'Unknown'}'),
                        Text('Price: Rp ${order['price']?.toString() ?? '0'}'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start Ride'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _startRideTracking(order),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _driverFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final driver = snapshot.data;
          if (driver == null) {
            return const Center(child: Text('Failed to load driver data'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver Status Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Driver Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Online Status:'),
                            const SizedBox(width: 10),
                            Switch(
                              value: driver['is_online'] ?? false,
                              activeThumbColor: Colors.green,
                              onChanged: (value) =>
                                  _toggleOnline(value, driver),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              (driver['is_online'] ?? false)
                                  ? 'Online'
                                  : 'Offline',
                              style: TextStyle(
                                color: (driver['is_online'] ?? false)
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                            'Monthly Completed: ${driver['monthly_completed'] ?? 0}'),
                        Text(
                            'Subscription: ${(driver['subscription_active'] ?? true) ? 'Active' : 'Inactive'}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Location Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (locationLoading)
                          const CircularProgressIndicator()
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Latitude: ${_currentLat?.toStringAsFixed(6) ?? 'N/A'}'),
                              Text(
                                  'Longitude: ${_currentLng?.toStringAsFixed(6) ?? 'N/A'}'),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Available Orders Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Orders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _orderService.streamAvailableOrders(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }

                            final orders = snapshot.data ?? [];
                            if (orders.isEmpty) {
                              return const Text(
                                'No available orders at the moment',
                                style: TextStyle(color: Colors.grey),
                              );
                            }

                            return Column(
                              children: orders
                                  .map((order) => ListTile(
                                        title: Text(
                                            'Order #${order['id']?.toString().substring(0, 8) ?? 'Unknown'}'),
                                        subtitle: Text(
                                            '${order['serviceType'] ?? 'Unknown'} - Rp ${order['price']?.toString() ?? '0'}'),
                                        trailing: ElevatedButton(
                                          child: const Text('Ambil Order'),
                                          onPressed: () async {
                                            try {
                                              await _orderService.assignDriver(
                                                orderId: order['id'],
                                                driverId: _user!.id,
                                              );
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Order assigned successfully!')),
                                              );
                                              _refreshData();
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'Failed to assign order: $e')),
                                              );
                                            }
                                          },
                                        ),
                                      ))
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildActiveOrders(),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _handleLogout,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
