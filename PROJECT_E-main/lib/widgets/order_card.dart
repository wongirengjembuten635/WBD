import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  final String orderId;
  final String pickupLocation;
  final String dropoffLocation;
  final String status;
  final double? totalPrice;
  final void Function()? onTap;

  const OrderCard({
    Key? key,
    required this.orderId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.status,
    this.totalPrice,
    this.onTap,
  }) : super(key: key);

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'WAITING':
        return Colors.orange;
      case 'ASSIGNED':
        return Colors.blue;
      case 'ONGOING':
        return Colors.amber[700]!;
      case 'DONE':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.teal[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Order #$orderId",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red[400], size: 20),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      pickupLocation,
                      style: const TextStyle(fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.flag, color: Colors.green[800], size: 20),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      dropoffLocation,
                      style: const TextStyle(fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (totalPrice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.amber[800], size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Total: \$${totalPrice!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
