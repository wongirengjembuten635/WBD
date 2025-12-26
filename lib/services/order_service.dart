import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;
  final String table = 'orders';

  /// Membuat order baru dan mengembalikan data order jika sukses, atau null
  Future<Map<String, dynamic>?> createOrder(
      Map<String, dynamic> orderData) async {
    final response =
        await _client.from(table).insert(orderData).select().single();
    if (response == null || response is! Map<String, dynamic>) {
      return null;
    }
    return response;
  }

  /// Mengambil order by ID
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    final response =
        await _client.from(table).select().eq('id', orderId).maybeSingle();
    if (response == null || response is! Map<String, dynamic>) {
      return null;
    }
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

  /// Assign driver ke order (update workerId/driverId dan status)
  Future<bool> assignDriver({
    required String orderId,
    required String driverId,
  }) async {
    final response = await _client
        .from(table)
        .update({
          'workerId': driverId,
          'status': 'assigned',
        })
        .eq('id', orderId)
        .select()
        .single();

    // Jika response null, update gagal. Jika Map, sukses.
    return response != null && response is Map<String, dynamic>;
  }
}
