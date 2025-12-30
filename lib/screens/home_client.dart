import 'package:flutter/material.dart';

class HomeClientScreen extends StatefulWidget {
  const HomeClientScreen({Key? key}) : super(key: key);

  @override
  State<HomeClientScreen> createState() => _HomeClientScreenState();
}

class _HomeClientScreenState extends State<HomeClientScreen> {
  String? orderStatus;
  bool hasOrder = false;
  double? totalPrice;
  final Map<String, double> priceBreakdown = {
    'Base Fare': 10.0,
    'Service Fee': 2.0,
    'Taxes': 1.5,
    // No commission included
  };

  // Helper to get total, always as double and handling empty/nullable scenarios
  void _createOrder() {
    setState(() {
      hasOrder = true;
      orderStatus = 'Processing';
      // use safe double folding
      totalPrice = priceBreakdown.values.fold<double>(
        0.0,
        (a, b) => a + b,
      );
    });

    // Simulate processing
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        orderStatus = 'Completed';
      });
    });
  }

  void _showPriceBreakdown() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Price Breakdown'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...priceBreakdown.entries.map((entry) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text('\$${entry.value.toStringAsFixed(2)}'),
                  ],
                )),
            const SizedBox(height: 10),
            const Text(
              'No commission charged',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${priceBreakdown.values.fold<double>(0.0, (a, b) => a + b).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatus() {
    if (!hasOrder) {
      return const Text('No order placed yet.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Status: $orderStatus'),
        if (totalPrice != null)
          Text('Total Price: \$${totalPrice!.toStringAsFixed(2)}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Home'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: hasOrder ? null : _createOrder,
              child: const Text('Create Order'),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _showPriceBreakdown,
              child: const Text('Show Price Breakdown'),
            ),
            const SizedBox(height: 30),
            const Text(
              'Order Info',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildOrderStatus(),
            const SizedBox(height: 25),
            const Text(
              'No commission is charged for your orders.',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
