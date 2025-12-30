import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/order_service.dart';

class HomeDriverScreen extends StatefulWidget {
  const HomeDriverScreen({super.key});

  @override
  State<HomeDriverScreen> createState() => _HomeDriverScreenState();
}

class _HomeDriverScreenState extends State<HomeDriverScreen> {
  final supabase = Supabase.instance.client;
  final OrderService _orderService = OrderService();
  double? _currentLat;
  double? _currentLng;
  bool locationLoading = true;
  Future<Map<String, dynamic>?>? _driverFuture;
  Future<List<Map<String, dynamic>>>? _activeOrdersFuture;
  Future<List<Map<String, dynamic>>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _driverFuture = _fetchAndInitDriver();
    await _fetchLocationAndSave();
    if (_user != null) {
      _activeOrdersFuture = _orderService.getActiveOrders(_user!.id);
      _historyFuture = _orderService.getOrderHistory(_user!.id);
    }
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
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _claimOrder(String orderId) async {
    final driver = await _driverFuture;
    if (driver == null || _user == null) return;

    final success = await _orderService.assignDriver(
      orderId: orderId,
      driverId: _user!.id,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order berhasil diambil!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil order.')),
      );
    }
  }

  Widget _statusRow(bool isOnline) {
    return Row(
      children: [
        const Text(
          "Status:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        Switch(
          value: isOnline,
          onChanged: (val) async {
            final driver = await _driverFuture;
            if (driver != null) {
              await _toggleOnline(val, driver);
            }
          },
          activeColor: Colors.green,
          inactiveThumbColor: Colors.red,
        ),
        const SizedBox(width: 8),
        Text(
          isOnline ? "ONLINE" : "OFFLINE",
          style: TextStyle(
            color: isOnline ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _locationRow(double? lat, double? lng) {
    return Row(
      children: [
        const Icon(Icons.location_on),
        const SizedBox(width: 8),
        locationLoading
            ? const Text("Memuat lokasi ...")
            : (lat != null && lng != null)
                ? Text(
                    "Lokasi: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}",
                  )
                : const Text("Lokasi tidak diketahui"),
        const Spacer(),
        IconButton(
          tooltip: "Refresh lokasi",
          icon: const Icon(Icons.refresh),
          onPressed: () async {
            await _fetchLocationAndSave();
            setState(() {
              _driverFuture = _fetchAndInitDriver();
            });
          },
        ),
      ],
    );
  }

  Widget _monthlyOrderRow(int monthlyCompleted) {
    return Row(
      children: [
        const Icon(Icons.assignment_turned_in),
        const SizedBox(width: 8),
        Text(
          "Order bulan ini: $monthlyCompleted / 10",
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _subscriptionRow(bool subscriptionActive) {
    return Row(
      children: [
        Icon(
          Icons.stars,
          color: subscriptionActive ? Colors.orange : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          subscriptionActive ? 'Status: Gratis' : 'Perlu bayar bulan depan',
          style: TextStyle(
            color: subscriptionActive ? Colors.orange : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _profileSection(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Email: ${user.email ?? 'N/A'}'),
            Text('ID: ${user.id}'),
            // Tambahkan lebih jika ada metadata
          ],
        ),
      ),
    );
  }

  Widget _activeOrdersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Aktif',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _activeOrdersFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snap.hasError) {
                  return const Text('Error loading active orders');
                }
                final orders = snap.data ?? [];
                if (orders.isEmpty) {
                  return const Text('Tidak ada order aktif.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return ListTile(
                      title: Text('Order ID: ${order['id']}'),
                      subtitle: Text(
                        'Jenis: ${order['serviceType']}\nStatus: ${order['status']}',
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _historySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Order',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _historyFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snap.hasError) {
                  return const Text('Error loading history');
                }
                final orders = snap.data ?? [];
                if (orders.isEmpty) {
                  return const Text('Tidak ada riwayat order.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return ListTile(
                      title: Text('Order ID: ${order['id']}'),
                      subtitle: Text(
                        'Jenis: ${order['serviceType']}\nHarga: Rp ${order['price']}\nTanggal: ${order['createdAt']}',
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _driverFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final driver = snap.data;
          if (driver == null || _user == null) {
            return const Center(child: Text('Gagal memuat data driver.'));
          }

          final monthlyCompleted = driver['monthly_completed'] ?? 0;
          final isOnline = driver['is_online'] ?? false;
          bool subscriptionActive = (monthlyCompleted < 10);
          final lat = driver['lat'] ?? _currentLat;
          final lng = driver['lng'] ?? _currentLng;

          return RefreshIndicator(
            onRefresh: () async {
              _driverFuture = _fetchAndInitDriver();
              await _fetchLocationAndSave();
              if (_user != null) {
                _activeOrdersFuture = _orderService.getActiveOrders(_user!.id);
                _historyFuture = _orderService.getOrderHistory(_user!.id);
              }
              setState(() {});
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 30),
                _profileSection(_user!),
                const SizedBox(height: 16),
                _statusRow(isOnline),
                const SizedBox(height: 16),
                _locationRow(lat, lng),
                const SizedBox(height: 16),
                _monthlyOrderRow(monthlyCompleted),
                const SizedBox(height: 16),
                _subscriptionRow(subscriptionActive),
                if (!subscriptionActive) ...[
                  const SizedBox(height: 12),
                  const Text(
                    "Anda sudah mencapai limit 10 order/bulan. Layanan gratis selesai, silakan hubungi admin untuk info lebih lanjut.",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                _activeOrdersSection(),
                const SizedBox(height: 16),
                _historySection(),
                const SizedBox(height: 40),
                const Text(
                  'Order Tersedia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _orderService.streamAvailableOrders(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return const Text('Error loading orders');
                    }
                    final orders = snap.data ?? [];
                    if (orders.isEmpty) {
                      return const Text('Tidak ada order tersedia saat ini.');
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text('Order ID: ${order['id']}'),
                            subtitle: Text(
                              'Jenis: ${order['serviceType']}\nJarak: ${order['distanceKm']} km\nHarga: Rp ${order['price']}',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _claimOrder(order['id']),
                              child: const Text('Ambil Order'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 40),
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
