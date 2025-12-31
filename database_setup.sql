-- Ride Routes Table for storing GPS tracking data
CREATE TABLE IF NOT EXISTS ride_routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  route_points JSONB NOT NULL, -- Array of {lat, lng, timestamp, accuracy, speed}
  total_distance_km DECIMAL(10,2) DEFAULT 0,
  duration_minutes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_ride_routes_order_id ON ride_routes(order_id);
CREATE INDEX IF NOT EXISTS idx_ride_routes_created_at ON ride_routes(created_at);

-- Add columns to orders table for real-time tracking
ALTER TABLE orders
ADD COLUMN IF NOT EXISTS current_driver_lat DECIMAL(10,8),
ADD COLUMN IF NOT EXISTS current_driver_lng DECIMAL(11,8),
ADD COLUMN IF NOT EXISTS last_location_update TIMESTAMP WITH TIME ZONE;

-- Create indexes for location queries
CREATE INDEX IF NOT EXISTS idx_orders_current_driver_lat ON orders(current_driver_lat);
CREATE INDEX IF NOT EXISTS idx_orders_current_driver_lng ON orders(current_driver_lng);

-- Enable Row Level Security
ALTER TABLE ride_routes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for ride_routes
CREATE POLICY "Users can view their own ride routes" ON ride_routes
  FOR SELECT USING (
    order_id IN (
      SELECT id FROM orders WHERE clientId = auth.uid() OR driverId = auth.uid()
    )
  );

CREATE POLICY "Drivers can insert ride routes for their orders" ON ride_routes
  FOR INSERT WITH CHECK (
    order_id IN (
      SELECT id FROM orders WHERE driverId = auth.uid()
    )
  );

-- Comments
COMMENT ON TABLE ride_routes IS 'Stores GPS tracking data for completed rides';
COMMENT ON COLUMN ride_routes.route_points IS 'Array of GPS points with timestamp, accuracy, and speed';
COMMENT ON COLUMN ride_routes.total_distance_km IS 'Total distance traveled during the ride';
COMMENT ON COLUMN ride_routes.duration_minutes IS 'Total duration of the ride in minutes';