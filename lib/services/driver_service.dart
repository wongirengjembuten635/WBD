import 'package:supabase_flutter/supabase_flutter.dart';

class DriverService {
  final SupabaseClient client;

  DriverService({SupabaseClient? client})
      : client = client ?? Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchDrivers() async {
    try {
      final response = await client.from('drivers').select().maybeSingle();

      if (response == null) {
        throw Exception('Failed to fetch drivers: response is null');
      }

      // The response from maybeSingle() will either be a Map if found, or null.
      // If it's a Map, wrap it in a list for consistency.
      if (response == null) {
        return [];
      }
      final data = [response];

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Error fetching drivers: $e');
    }
  }
}
