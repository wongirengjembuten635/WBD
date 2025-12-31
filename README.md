# 🚗 Nomaden App - Ojek Online Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A complete ride-hailing and delivery platform built with Flutter and Supabase, featuring real-time driver assignment, interactive maps, and role-based authentication.

## ✨ Features

### 👤 User Management
- **Role-based Authentication**: Separate interfaces for drivers and clients
- **Secure Registration**: Email/password with role selection (driver/client)
- **JWT Token Management**: Supabase Auth integration
- **Profile Management**: User profiles with role-specific data

### 🚗 Driver Dashboard
- **Real-time Order Stream**: Live updates of available orders
- **Online/Offline Status**: Toggle availability with database sync
- **Location Tracking**: Real-time GPS location updates
- **Order Management**: View active orders and order history
- **Manual Order Claiming**: "Ambil Order" button for available orders
- **Statistics Display**: Monthly completed orders and subscription status

### 📦 Order Creation
- **Interactive Map**: FlutterMap integration for pickup/dropoff selection
- **Service Type Selection**: Choose between ride and delivery services
- **Real-time Pricing**: Automatic price calculation based on distance
- **Auto Bid System**: Automatic driver assignment for ride orders
- **Manual Assignment**: Delivery orders require manual driver selection

### 🤖 Auto Bid System (Latest Implementation)
- **AutoBidService**: Complete automatic driver assignment system
  - `runAutobid(orderId, orderLat, orderLng)`: Main entry point for auto bid execution
  - `autoAssignDriver()`: Core logic for finding and assigning closest driver
  - **Distance Calculation**: Haversine formula for accurate distance calculation
  - **Driver Selection Algorithm**:
    - Filters online drivers only (isOnline = true)
    - Calculates distance from each driver to order pickup location
    - Sorts by distance (closest first)
    - Selects the nearest available driver
  - **Conditional Execution**: Only runs for ride orders (bike_ride, car_ride)
  - **Delivery Orders**: Remain 'waiting' for manual driver assignment
  - **Database Updates**: Automatically updates order status to 'assigned'
  - **Real-time Integration**: Works seamlessly with order creation flow

### 📱 Push Notifications (NEW)
- **Firebase Cloud Messaging**: Real-time push notifications
- **Order Updates**: Instant notifications for order status changes
- **Driver Assignment**: Alerts when driver is assigned
- **Ride Tracking**: Notifications during active rides
- **Local Notifications**: Fallback notifications when app is in foreground
- **Topic-based Messaging**: Subscribe to relevant notification topics

### 🚗 GPS Tracking & Ride Management (NEW)
- **Real-time GPS Tracking**: Live location updates during rides
- **RideTrackingService**: Comprehensive ride tracking system
  - Automatic location updates every 10 seconds
  - Route recording with timestamps and accuracy
  - Distance and duration calculations
  - Real-time location sharing with clients
- **Interactive Ride Map**: Visual tracking with route display
- **Ride Completion**: Automatic status updates and notifications
- **Route Storage**: Complete route data saved to database

### 📱 Multi-Platform Support
- **Android**: Full Android application support
- **iOS**: Complete iOS application with Swift integration
- **Web**: Browser-based application
- **Windows**: Desktop application for Windows
- **Linux**: Linux desktop support
- **macOS**: macOS desktop application

## 🏗️ Architecture

### Tech Stack
- **Frontend**: Flutter 3.x with Material Design 3
- **Backend**: Supabase (PostgreSQL + Auth + Real-time)
- **Maps**: FlutterMap with OpenStreetMap tiles
- **Location**: Geolocator for GPS services
- **State Management**: Provider pattern
- **Real-time**: Supabase Realtime subscriptions
- **Push Notifications**: Firebase Cloud Messaging

### Dependencies

#### Core Dependencies
- **supabase_flutter**: ^2.12.0 - Supabase Flutter client for backend services
- **provider**: ^6.1.2 - State management solution
- **geolocator**: ^11.0.0 - GPS location services and permissions
- **http**: ^1.2.1 - HTTP client for API calls
- **flutter_map**: ^6.1.0 - Interactive maps with OpenStreetMap tiles
- **latlong2**: ^0.9.0 - Geographic coordinate calculations
- **cupertino_icons**: ^1.0.2 - iOS-style icons

#### Push Notifications (NEW)
- **firebase_core**: ^4.3.0 - Firebase core functionality
- **firebase_messaging**: ^16.1.0 - Firebase Cloud Messaging for push notifications

### Project Structure
```
lib/
├── app.dart                 # Main app widget with routing
├── main.dart               # App entry point
├── constants.dart          # App-wide constants
├── core/                   # Core utilities
│   ├── constants.dart
│   ├── geo_utils.dart      # Geographic calculations
│   ├── price_engine.dart   # Pricing algorithms
│   └── user_role.dart      # Role definitions
├── models/                 # Data models
│   ├── bid_model.dart
│   ├── driver_model.dart
│   ├── order_model.dart
│   └── user_model.dart
├── screens/                # UI screens
│   ├── home_client.dart    # Client dashboard
│   ├── home_driver.dart    # Driver dashboard
│   ├── login_screen.dart   # Authentication
│   ├── register_screen.dart # User registration
│   └── order_create_screen.dart # Order creation
├── services/               # Business logic
│   ├── auth_service.dart   # Authentication
│   ├── autobid_service.dart # Auto assignment
│   ├── driver_service.dart # Driver operations
│   ├── location_service.dart # GPS services
│   └── order_service.dart  # Order management
└── widgets/                # Reusable UI components
    ├── order_card.dart
    └── price_breakdown.dart
```

### Database Schema

#### Orders Table
```sql
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clientId UUID NOT NULL REFERENCES auth.users(id),
  driverId UUID REFERENCES auth.users(id),
  serviceType TEXT NOT NULL CHECK (serviceType IN ('bike_ride', 'car_ride', 'bike_delivery', 'car_delivery')),
  distanceKm DECIMAL(10,2) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting', 'assigned', 'completed')),
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Drivers Table
```sql
CREATE TABLE drivers (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  is_online BOOLEAN DEFAULT false,
  monthly_completed INTEGER DEFAULT 0,
  subscription_active BOOLEAN DEFAULT true,
  lat DECIMAL(10,8),
  lng DECIMAL(11,8)
);
```

## 🚀 Getting Started

### Prerequisites
- Flutter 3.x or higher
- Dart SDK
- Supabase account and project
- Android Studio / Xcode (for mobile development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/wongirengjembuten635/WBD.git
   cd nomaden_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Supabase**
   - Create a new project at [supabase.com](https://supabase.com)
   - Copy your project URL and anon key
   - Update `lib/main.dart` with your credentials:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

4. **Set up Firebase (for Push Notifications)**
   - Create a new project at [Firebase Console](https://console.firebase.google.com/)
   - Add Android/iOS apps to your Firebase project
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place files in `android/app/` and `ios/Runner/` respectively
   - Enable Firebase Cloud Messaging in the Firebase Console

5. **Set up database tables**
   - Run the SQL scripts from the Database Schema section above
   - Enable Row Level Security (RLS) policies as needed

6. **Run the application**
   ```bash
   # For Android
   flutter run -d android

   # For iOS
   flutter run -d ios

   # For Web
   flutter run -d chrome

   # For Windows
   flutter run -d windows
   ```

### Environment Setup

Create a `.env` file in the root directory:
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
FIREBASE_SERVER_KEY=your_firebase_server_key
```

## 📱 Usage

### For Clients
1. **Register/Login**: Create account as client
2. **Create Order**:
   - Select service type (ride/delivery)
   - Tap map to set pickup location
   - Tap map to set dropoff location
   - Review price and confirm
3. **Track Order**: Monitor order status in real-time

### For Drivers
1. **Register/Login**: Create account as driver
2. **Go Online**: Toggle online status
3. **Receive Orders**: Auto-assigned for rides, manual claim for deliveries
4. **Manage Orders**: View active orders and history
5. **Update Location**: GPS tracking for accurate positioning

## 🔧 Configuration

### Supabase Setup
1. Create tables using the provided SQL schema
2. Enable real-time subscriptions for the `orders` table
3. Configure authentication providers (Email/Password)
4. Set up storage buckets if needed for profile images

### Firebase Setup (for Push Notifications)
1. Enable Firebase Cloud Messaging in Firebase Console
2. Get your Server Key from Firebase Console > Project Settings > Cloud Messaging
3. Add the Server Key to your `.env` file as `FIREBASE_SERVER_KEY`
4. Configure notification permissions in Android/iOS manifests
5. Test notifications using Firebase Console or API calls

### App Configuration
- **Map Settings**: Configure OpenStreetMap tile servers in `order_create_screen.dart`
- **Pricing**: Adjust base fare and per-km rates in `order_create_screen.dart`
- **Distance Calculation**: Modify Haversine parameters in `autobid_service.dart`
- **GPS Tracking**: Configure update intervals in `ride_tracking_service.dart`

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Manual Testing Checklist
- [ ] User registration and login
- [ ] Role-based navigation
- [ ] Order creation with map interaction
- [ ] Auto bid assignment for ride orders
- [ ] Manual order claiming for deliveries
- [ ] Real-time order updates
- [ ] Driver online/offline status
- [ ] Location tracking and distance calculation

## 📊 API Reference

### Authentication Service
```dart
// Register with role
await authService.registerWithRole(email, password, role);

// Login
await authService.login(email, password);

// Get current user
final user = authService.getCurrentUser();
```

### Order Service
```dart
// Create order
await orderService.createOrder(orderData);

// Stream available orders
final stream = orderService.streamAvailableOrders();

// Assign driver
await orderService.assignDriver(orderId: id, driverId: driverId);
```

### Auto Bid Service
```dart
// Run auto bid for order
await autoBidService.runAutobid(orderId, orderLat, orderLng);

// Manual driver assignment
await autoBidService.autoAssignDriver(
  orderId: orderId,
  orderLat: lat,
  orderLng: lng,
);
```

### Firebase Service (NEW)
```dart
// Initialize Firebase
await firebaseService.initialize();

// Send push notification
await firebaseService.sendNotification(
  title: 'Order Update',
  body: 'Your order has been assigned',
  token: userToken,
);

// Subscribe to topic
await firebaseService.subscribeToTopic('orders');

// Get FCM token
final token = await firebaseService.getToken();
```

### Ride Tracking Service (NEW)
```dart
// Start ride tracking
await rideTrackingService.startRideTracking(orderId);

// Stop ride tracking
await rideTrackingService.stopRideTracking();

// Get current route
final route = await rideTrackingService.getCurrentRoute();

// Calculate distance and duration
final stats = await rideTrackingService.getRideStats();
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter best practices
- Write comprehensive tests
- Update documentation
- Use meaningful commit messages
- Maintain code quality with `flutter analyze`

## 📈 Roadmap

### Phase 1 (Current) ✅
- Basic ride-hailing functionality
- Auto bid system
- Real-time updates
- Multi-platform support
- **Push notifications** ✅
- **GPS tracking during rides** ✅

### Phase 2 (Upcoming)
- [ ] Payment integration (Stripe/PayPal)
- [ ] Rating and review system
- [ ] Admin dashboard
- [ ] Email verification system
- [ ] Row-Level Security (RLS) policies

### Phase 3 (Future)
- [ ] Advanced analytics
- [ ] Machine learning for better assignments
- [ ] Multi-language support
- [ ] Offline functionality
- [ ] Advanced driver verification

## 🐛 Troubleshooting

### Common Issues

**Auto bid not working**
- Check if drivers are online
- Verify Supabase real-time is enabled
- Check console for error messages

**Map not loading**
- Verify internet connection
- Check OpenStreetMap tile server status
- Ensure proper permissions for location services

**Authentication errors**
- Verify Supabase credentials
- Check user role metadata
- Ensure email verification if enabled

**Push notifications not working**
- Verify Firebase configuration files are in correct locations
- Check Firebase Server Key in `.env` file
- Ensure notification permissions are granted
- Test with Firebase Console notification composer
- Check device token registration in logs

**GPS tracking issues**
- Verify location permissions in app settings
- Check GPS accuracy and signal strength
- Ensure background location permission (Android)
- Verify Supabase connection for location updates
- Check ride tracking service initialization

### Debug Commands
```bash
# Check Flutter version
flutter --version

# Clean and rebuild
flutter clean && flutter pub get

# Analyze code
flutter analyze

# Run with verbose logging
flutter run --verbose
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [Supabase](https://supabase.com/) - Backend as a service
- [OpenStreetMap](https://www.openstreetmap.org/) - Map data
- [FlutterMap](https://pub.dev/packages/flutter_map) - Map rendering

## 📞 Support

For support, email [your-email@example.com](mailto:your-email@example.com) or create an issue in this repository.

---

**Made with ❤️ using Flutter and Supabase**
