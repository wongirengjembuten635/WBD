import 'package:flutter/material.dart';

class PriceBreakdown extends StatelessWidget {
  final double basePrice;
  final double extraPrice;
  final double totalPrice;

  const PriceBreakdown({
    Key? key,
    required this.basePrice,
    required this.extraPrice,
    required this.totalPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Price Breakdown",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 18),
            _row('Base Price', basePrice),
            const SizedBox(height: 12),
            _row('Extra Price', extraPrice),
            const Divider(height: 25, thickness: 1.1),
            _row(
              'Total Price',
              totalPrice,
              isBold: true,
              color: Colors.green[800],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
              : const TextStyle(fontSize: 15),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            fontSize: isBold ? 16 : 15,
            color: color,
          ),
        ),
      ],
    );
  }
}
