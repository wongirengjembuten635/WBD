import 'package:flutter/material.dart';

class OrderStatusScreen extends StatelessWidget {
  final String orderStatus;
  final VoidCallback? onRefresh;

  const OrderStatusScreen({
    Key? key,
    required this.orderStatus,
    this.onRefresh,
  }) : super(key: key);

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'WAITING':
        return const Color.fromARGB(255, 0, 19, 61);
      case 'ASSIGNED':
        return Colors.blueAccent;
      case 'ONGOING':
        return Colors.amber;
      case 'DONE':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'WAITING':
        return 'Waiting for assignment...';
      case 'ASSIGNED':
        return 'Worker has been assigned!';
      case 'ONGOING':
        return 'Order is ongoing!';
      case 'DONE':
        return 'Order completed!';
      default:
        return 'Unknown order status.';
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'WAITING':
        return Icons.hourglass_empty;
      case 'ASSIGNED':
        return Icons.person_search;
      case 'ONGOING':
        return Icons.run_circle;
      case 'DONE':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = orderStatus.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Status"),
        actions: [
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRefresh,
            ),
        ],
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _statusIcon(status),
                  size: 60,
                  color: _statusColor(status),
                ),
                const SizedBox(height: 18),
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: _statusColor(status),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _statusLabel(status),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 40),
                _statusStepper(status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusStepper(String status) {
    // Horizontal stepper for status progress
    const List<String> steps = ['WAITING', 'ASSIGNED', 'ONGOING', 'DONE'];
    int currentStep = steps.indexOf(status);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (i) {
        bool isActive = i <= currentStep;
        return Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor:
                  isActive ? _statusColor(steps[i]) : Colors.grey[300],
              child: Icon(
                i == 0
                    ? Icons.hourglass_empty
                    : i == 1
                        ? Icons.person_search
                        : i == 2
                            ? Icons.run_circle
                            : Icons.check_circle,
                size: 18,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
            ),
            if (i < steps.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: Container(
                  width: 30,
                  height: 4,
                  color: isActive && i < currentStep
                      ? _statusColor(steps[i])
                      : Colors.grey[300],
                ),
              ),
          ],
        );
      }),
    );
  }
}
