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

#### Auto-bid System
- **AutoBidService**: Automatic driver assignment for ride orders
  - Distance-based selection: Finds closest online driver
  - Score calculation: Prioritizes experienced drivers (more completed orders)
  - Conditional execution: Only runs for ride orders (bike_ride, car_ride)
  - Skips delivery orders: Delivery orders remain 'waiting' for manual driver assignment
  - Automatic status update: Updates order status to 'assigned' after driver selection

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
  - Bike Ride (bike_ride)
  - Car Ride (car_ride)
  - Bike Delivery (bike_delivery)
  - Car Delivery (car_delivery)
  - Conditional autobid: Only triggers for ride services, not delivery

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

#### Database Integration
- **Orders Table Fields**:
  - id: Order identifier
  - clientId: Reference to client user
  - driverId: Reference to assigned driver
  - serviceType: Type of service (ride/delivery)
  - distanceKm: Order distance in kilometers
  - price: Order price
  - status: Order status (waiting/assigned/completed)
  - createdAt: Order creation timestamp

- **Drivers Table Fields**:
  - user_id: Reference to Supabase Auth user
  - is_online: Online/offline status boolean
  - monthly_completed: Counter for completed orders
  - subscription_active: Subscription status boolean
  - lat: Current latitude
  - lng: Current longitude

#### Documentation
- **README.md**: Comprehensive project documentation with setup instructions
- **CHANGELOG.md**: This file documenting all changes

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

Note: Future enhancements should include:
- Email verification before account activation
- Stronger password requirements and validation
- Row-Level Security (RLS) policies in Supabase
- Two-factor authentication (2FA)
- Rate limiting on auth endpoints

## Version History

### v0.0.1 (Current Development)
- Initial project structure
- All features listed above in [Unreleased]
