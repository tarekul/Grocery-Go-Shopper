import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AcceptedOrderView extends StatelessWidget {
  final dynamic order;

  const AcceptedOrderView({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    print(order);
    return Scaffold(
      appBar: AppBar(title: Text('Order Details')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: ${order['orderId']}'),
            Text('Name: ${order['name']}'),
            Text('Phone: ${order['phone']}'),
            Text('Total Price: ${order['total_price']}'),
            Text('Total Items: ${order['num_items']}'),
            Text(
                'Ordered On: ${DateFormat('yyyy-MM-dd hh:mm a').format(order['created_at'].toDate())}'),
          ],
        ),
      ),
    );
  }
}
