import 'package:supabase_flutter/supabase_flutter.dart';

class DriverStatusService {
  final SupabaseClient client = Supabase.instance.client;

  /// Mengatur driver ONLINE + update lokasi + timestamp + device info optional + set last_online
  Future<void> goOnline(double lat, double lng, {String? deviceInfo}) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in');
    }

    final now = DateTime.now().toUtc().toIso8601String();

    final Map<String, dynamic> data = {
      'id': user.id,
      'is_online': true,
      'latitude': lat,
      'longitude': lng,
      'last_online': now,
      'location_updated_at': now,
    };

    if (deviceInfo != null) data['device_info'] = deviceInfo;

    try {
      final response =
          await client.from('drivers').upsert(data).select().execute();

      if (response.status != 200 && response.status != 201) {
        throw Exception('Failed to go online: ${response.data}');
      }
    } catch (e) {
      throw Exception('Error while setting online status: $e');
    }
  }

  /// Update lokasi driver tanpa ubah status online/offline
  Future<void> updateLocation(double lat, double lng) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      final response = await client
          .from('drivers')
          .update({
            'latitude': lat,
            'longitude': lng,
            'location_updated_at': now,
          })
          .eq('id', user.id)
          .execute();

      if (response.status != 200 && response.status != 204) {
        throw Exception('Failed to update location: ${response.data}');
      }
    } catch (e) {
      throw Exception('Error while updating driver location: $e');
    }
  }

  /// Mengatur driver OFFLINE + simpan last_online timestamp
  Future<void> goOffline() async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in');
    }
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      final response = await client
          .from('drivers')
          .update({'is_online': false, 'last_online': now})
          .eq('id', user.id)
          .execute();

      if (response.status != 200 && response.status != 204) {
        throw Exception('Failed to go offline: ${response.data}');
      }
    } catch (e) {
      throw Exception('Error while setting offline status: $e');
    }
  }

  /// Dapatkan detail status driver (online/offline & info lain)
  Future<Map<String, dynamic>?> getDriverStatus({String? driverId}) async {
    final uid = driverId ?? client.auth.currentUser?.id;
    if (uid == null) throw Exception('No user is currently logged in');
    try {
      final response = await client
          .from('drivers')
          .select()
          .eq('id', uid)
          .single()
          .execute();

      if (response.status != 200 && response.status != 206) {
        throw Exception('Error get driver status: ${response.data}');
      }
      if (response.data == null) {
        return null;
      }
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Error while getting driver status: $e');
    }
  }

  /// Dapatkan semua driver yang sedang online (misal untuk matching)
  Future<List<Map<String, dynamic>>> getOnlineDrivers() async {
    try {
      // Disambiguate the extension to resolve the lint error:
      final response = await (client
              .from('drivers')
              .select()
              .eq('is_online', true) as PostgrestFilterBuilder<dynamic>)
          .execute();

      if (response.status != 200 && response.status != 206) {
        throw Exception('Error get online drivers: ${response.data}');
      }
      final data = response.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Error while getting online drivers: $e');
    }
  }
}

extension on PostgrestFilterBuilder<dynamic> {
  Future<dynamic> execute() {
    throw UnimplementedError('execute() has not been implemented.');
  }
}

extension on PostgrestTransformBuilder<PostgrestList> {
  Future<dynamic> execute() {
    throw UnimplementedError('execute() has not been implemented.');
  }
}

extension on PostgrestTransformBuilder<PostgrestMap> {
  Future<dynamic> execute() {
    throw UnimplementedError('execute() has not been implemented.');
  }
}
