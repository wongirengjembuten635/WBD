import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;
  final String table = 'orders';

  /// Membuat order baru dan mengembalikan data order jika sukses, atau null
  Future<Map<String, dynamic>?> createOrder(
      Map<String, dynamic> orderData) async {
    try {
      final response =
          await _client.from(table).insert(orderData).select().single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Mengambil order by ID
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    final response =
        await _client.from(table).select().eq('id', orderId).maybeSingle();
    return response;
  }

  /// Stream perubahan status order, emit update tiap kali status berubah
  Stream<String?> streamOrderStatus(String orderId) {
    return _client
        .from('$table:id=eq.$orderId')
        .stream(primaryKey: ['id']).map((rows) {
      if (rows.isNotEmpty && rows[0]['status'] != null) {
        return rows[0]['status'] as String;
      }
      return null;
    });
  }

  /// Stream daftar order yang tersedia (status 'waiting')
  Stream<List<Map<String, dynamic>>> streamAvailableOrders() {
    return _client
        .from('$table:status=eq.waiting')
        .stream(primaryKey: ['id']).map((rows) {
      return rows;
    });
  }

  /// Assign driver ke order (update driverId dan status)
  Future<bool> assignDriver({
    required String orderId,
    required String driverId,
  }) async {
    try {
      final result = await _client
          .from(table)
          .update({
            'driverId': driverId,
            'status': 'assigned',
          })
          .eq('id', orderId)
          .select();

      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Mengambil order aktif driver (status 'assigned')
  Future<List<Map<String, dynamic>>> getActiveOrders(String driverId) async {
    final response = await _client
        .from(table)
        .select()
        .eq('driverId', driverId)
        .eq('status', 'assigned');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Mengambil riwayat order driver (status 'completed')
  Future<List<Map<String, dynamic>>> getOrderHistory(String driverId) async {
    final response = await _client
        .from(table)
        .select()
        .eq('driverId', driverId)
        .eq('status', 'completed')
        .order('createdAt', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
