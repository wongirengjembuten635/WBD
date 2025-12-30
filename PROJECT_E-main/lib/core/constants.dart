const int freeOrderLimit = 10;
const int monthlyFee = 100000;

const String osrmBaseUrl = 'https://router.project-osrm.org';

// Supabase configuration
const String supabaseUrl = 'https://olhykkhbsihoglyrwpda.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9saHlra2hic2lob2dseXJ3cGRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY0MzAzNjAsImV4cCI6MjA4MjAwNjM2MH0.RyDS9tAeBt-i7gG7segs4RiXN_FGFvabkbpfADHQSlg';

/// Pricing rules (all values in IDR)
class PricingRules {
  // Bike Delivery
  static const int bikeDeliveryPerKm = 6000;
  static const int bikeDeliveryPer1_5Km = 2000;

  // Bike Ride
  static const int bikeRidePerKm = 10000;
  static const int bikeRidePer1_5Km = 1500;

  // Car Delivery
  static const int carDeliveryPerKm = 12000;
  static const int carDeliveryPer1_5Km = 2500;

  // Car Ride
  static const int carRidePerKm = 15000;
  static const int carRidePer1Km = 2500; // 2500 per 1km
}
