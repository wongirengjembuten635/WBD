# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### Driver Dashboard Features
- **Profile Section**: Display driver email and ID from current user
- **Status Toggle**: Online/Offline toggle with real-time database update
- **Location Display**: Show current driver latitude and longitude
- **Monthly Statistics**: Display total completed orders and subscription status
- **Active Orders Section**: FutureBuilder showing assigned orders (status='assigned')
- **Order History Section**: FutureBuilder displaying completed orders (status='completed')
- **Available Orders Stream**: Real-time StreamBuilder showing all waiting orders (status='waiting')
- **Manual Order Claiming**: "Ambil Order" button to claim available orders

#### Order Management System
- **OrderService**: Centralized service for order operations
  - `createOrder()`: Create new order in database
  - `streamAvailableOrders()`: Real-time stream of waiting orders via Supabase Realtime
  - `getActiveOrders(driverId)`: Fetch assigned orders for specific driver
  - `getOrderHistory(driverId)`: Fetch completed orders ordered by creation date
  - `assignDriver(orderId, driverId)`: Assign driver and update order status
  - `claimOrder(orderId, driverId)`: Driver claims available order (manual assignment)

#### Auto-bid System (Latest Implementation)
- **AutoBidService**: Complete automatic driver assignment system
  - `runAutobid(orderId, orderLat, orderLng)`: Main entry point for auto bid execution
  - `autoAssignDriver()`: Core logic for finding and assigning closest driver
  - **Distance Calculation**: Haversine formula for accurate kilometer distance
  - **Driver Selection Algorithm**:
    - Filters online drivers only (isOnline = true)
    - Calculates distance from each driver to order pickup location
    - Sorts by distance (closest first)
    - Selects the nearest available driver
  - **Conditional Execution**: Only runs for ride orders (bike_ride, car_ride)
  - **Delivery Orders**: Remain 'waiting' for manual driver assignment
  - **Database Updates**: Automatically updates order status to 'assigned'
  - **Real-time Integration**: Works seamlessly with order creation flow

#### Authentication System
- **Login Screen**: Email/password authentication with role-based post-login navigation
  - `signInWithPassword()`: Authenticate user with Supabase Auth
  - Role detection: Reads user metadata for role assignment
  - Conditional routing: Routes to `/home_driver` for drivers, `/home_client` for clients
  - Error handling: Display error messages on failed login
  - Register link: Button to navigate to registration screen

- **Register Screen**: User registration with role selection
  - Email validation: Required and must be valid format
  - Password validation: Minimum 6 characters, must match confirmation
  - Role selection: Dropdown to choose between 'driver' and 'client'
  - `registerWithRole()`: AuthService method for registration with role metadata
  - Driver initialization: Auto-creates driver record in drivers table if role='driver'
  - Success feedback: SnackBar notification and return to login

- **AuthService Enhancement**:
  - `registerWithRole(email, password, role)`: New method for role-based registration
  - Metadata storage: Role stored in Supabase Auth JWT metadata during signup
  - Error handling: Try-catch wrapper for robust error management

#### Service Type System
- **Service Type Selection**: Dropdown in order creation screen
  - Bike Ride (bike_ride) - Auto bid enabled
  - Car Ride (car_ride) - Auto bid enabled
  - Bike Delivery (bike_delivery) - Manual assignment only
  - Car Delivery (car_delivery) - Manual assignment only
  - **Smart Logic**: Conditional auto bid based on service type

#### Order Creation Integration
- **Map-based Order Creation**: Interactive FlutterMap for pickup/dropoff selection
- **Real-time Distance Calculation**: Automatic price calculation using Haversine formula
- **Service Type Integration**: Dropdown selection with conditional auto bid
- **Auto Bid Trigger**: Automatically called after successful order creation for ride orders
- **User Feedback**: SnackBar notifications for order status and auto bid results
- **Error Handling**: Comprehensive try-catch blocks with user-friendly messages

#### Core Services
- **LocationService**: Real-time location tracking using geolocator
  - Current location fetching
  - Continuous position updates
  - Location permission handling

- **DriverService**: Driver data management
  - Update driver online status
  - Update location (latitude/longitude)
  - Fetch driver profile information

- **AuthService Extensions**:
  - Role-aware registration
  - Metadata-based role storage
  - Session management with role detection

#### Routing & Navigation
- **App Router**: Proper route configuration with role-based navigation
  - `/login`: Login screen entry point
  - `/register`: User registration screen
  - `/home_driver`: Driver dashboard (protected by role check)
  - `/home_client`: Client dashboard (protected by role check)
- **Role Checking**: app.dart `_decideHomeScreen()` method verifies user role from metadata

#### UI Improvements
- **Material Design 3**: Enabled useMaterial3 in theme configuration
- **Error Display**: User-friendly error messages and loading states
- **Real-time Feedback**: StreamBuilder for live data updates
- **Form Validation**: Pre-submission field validation with error messages
- **Interactive Map**: FlutterMap integration with marker placement
- **Responsive Design**: Proper layout for different screen sizes

#### Database Integration
- **Orders Table Fields**:
  - id: Order identifier (UUID)
  - clientId: Reference to client user (UUID)
  - driverId: Reference to assigned driver (UUID, nullable)
  - serviceType: Type of service (ride/delivery)
  - distanceKm: Order distance in kilometers (decimal)
  - price: Order price (decimal)
  - status: Order status (waiting/assigned/completed)
  - createdAt: Order creation timestamp (ISO 8601)

- **Drivers Table Fields**:
  - user_id: Reference to Supabase Auth user (UUID, primary key)
  - is_online: Online/offline status boolean (default: false)
  - monthly_completed: Counter for completed orders (integer, default: 0)
  - subscription_active: Subscription status boolean (default: true)
  - lat: Current latitude (decimal, nullable)
  - lng: Current longitude (decimal, nullable)

#### Platform Support
- **Multi-platform Flutter Project**: Regenerated for all platforms
  - Android: Full Android support with Gradle configuration
  - iOS: Complete iOS project with Xcode configuration
  - Web: Web deployment ready with proper manifest
  - Windows: Windows desktop application support
  - Linux: Linux desktop application support
  - macOS: macOS desktop application support

#### Documentation
- **README.md**: Comprehensive project documentation with setup instructions
- **CHANGELOG.md**: This file documenting all changes
- **Code Comments**: Extensive inline documentation for all major functions
- **API Documentation**: Clear method signatures and parameter descriptions

### Changed
- Fixed column naming consistency: client_id → clientId, distance_km → distanceKm, estimated_price → price, created_at → createdAt
- Removed deprecated `.execute()` method from Supabase API calls
- Simplified app.dart routing logic
- Reorganized main.dart with proper route definitions
- Clean separation between login and register screens

### Fixed
- Resolved undefined `registerWithRole()` method in AuthService
- Fixed 68+ compilation errors in login/register screens
- Removed duplicate MyApp class definition
- Fixed method not found errors in app.dart
- Corrected column name mismatches in order creation
- Resolved role checking in authentication flow

### Removed
- Removed old `RoleChooserScreen` widget
- Removed deprecated `.execute()` call on PostgrestTransformBuilder
- Removed duplicate code in register and login screens
- Removed placeholder widgets and conflicting imports

### Security
- Basic role-based access control implemented
- Password minimum length requirement (6 characters)
- Error messages don't expose sensitive information
- Supabase Auth JWT tokens used for session management

### Technical Details

#### Auto Bid Algorithm
```
1. Client creates order with service type selection
2. If service type contains 'delivery':
   - Skip auto bid, order status remains 'waiting'
   - Manual driver assignment required
3. If service type is ride ('bike_ride' or 'car_ride'):
   - Query all drivers with isOnline = true
   - Calculate distance from each driver to order pickup location
   - Sort drivers by distance (closest first)
   - Select the nearest driver
   - Update order: driverId = selected_driver.id, status = 'assigned'
   - Return success/failure status
```

#### Database Schema
```sql
-- Orders table
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

-- Drivers table
CREATE TABLE drivers (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  is_online BOOLEAN DEFAULT false,
  monthly_completed INTEGER DEFAULT 0,
  subscription_active BOOLEAN DEFAULT true,
  lat DECIMAL(10,8),
  lng DECIMAL(11,8)
);
```

#### Real-time Subscriptions
- **Orders Stream**: `streamAvailableOrders()` uses Supabase Realtime to listen for status='waiting' orders
- **Driver Dashboard**: StreamBuilder automatically updates when new orders become available
- **Auto Assignment**: Real-time updates ensure immediate driver notification

### Performance
- **Distance Calculation**: Optimized Haversine formula implementation
- **Real-time Updates**: Efficient Supabase subscriptions with minimal data transfer
- **Lazy Loading**: FutureBuilder for order history and active orders
- **Stream Optimization**: Filtered queries to reduce unnecessary data fetching

### Testing
- **Unit Tests**: Basic widget tests included (widget_test.dart)
- **Integration Tests**: Manual testing of auto bid flow completed
- **Platform Testing**: Multi-platform support verified (Android, iOS, Web, Windows)
- **Real-time Testing**: StreamBuilder functionality confirmed working

### Dependencies
- **Flutter**: 3.x with Material Design 3 support
- **Supabase**: Authentication, Database, Real-time subscriptions
- **Flutter Map**: Interactive map for order creation
- **Geolocator**: Location services for distance calculation
- **LatLong2**: Geographic coordinate handling
- **Provider**: State management (in pubspec but not extensively used yet)

### Future Enhancements
- [ ] Email verification before account activation
- [ ] Stronger password requirements and validation
- [ ] Row-Level Security (RLS) policies in Supabase
- [ ] Two-factor authentication (2FA)
- [ ] Rate limiting on auth endpoints
- [ ] Push notifications for order updates
- [ ] GPS tracking during active rides
- [ ] Payment integration
- [ ] Rating and review system
- [ ] Admin dashboard for monitoring
- [ ] Analytics and reporting
- [ ] Offline support for critical features

## Version History

### v0.0.1 (Current Development) - December 31, 2025
- Initial project structure with complete ojek online application
- Full authentication system with role-based access
- Driver dashboard with real-time order management
- Auto bid system for automatic driver assignment
- Order creation with map-based location selection
- Multi-platform Flutter application (Android, iOS, Web, Windows, Linux, macOS)
- Supabase backend integration with real-time features
- Comprehensive documentation and changelog
