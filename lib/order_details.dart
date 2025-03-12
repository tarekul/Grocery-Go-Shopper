import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailsPage extends StatefulWidget {
  final dynamic order;

  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => OrderDetailsPageState();
}

class OrderDetailsPageState extends State<OrderDetailsPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<dynamic> orderItems = [];
  List<bool> checkedStates = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchOrderItems();
  }

  Future<void> fetchOrderItems() async {
    setState(() {
      isLoading = true;
    });
    try {
      orderItems.clear();
      QuerySnapshot querySnapshot = await firestore
          .collection('order-items')
          .where('order_id', isEqualTo: widget.order['orderId'])
          .get();
      for (var doc in querySnapshot.docs) {
        var orderItem = doc.data() as Map<String, dynamic>?;
        orderItems.add(orderItem);
        checkedStates.add(false);
      }
      print(orderItems);
    } catch (error) {
      print(error);
    } finally {
      isLoading = false;
      setState(() {});
    }
  }

  void showMapSelectionDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text('Choose a navigation app'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(title: Text('Google Maps')),
                  ListTile(title: Text('Apple Maps')),
                  ListTile(title: Text('Waze')),
                ],
              ));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order Details')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order ID: ${widget.order['orderId']}'),
                  Text('Name: ${widget.order['name']}'),
                  Text('Phone: ${widget.order['phone']}'),
                  Text(
                      'Address: ${widget.order['address']} ${widget.order['city']} ${widget.order['zipcode']}'),
                  Text('Total Price: ${widget.order['total_price']}'),
                  Text('Total Items: ${widget.order['num_items']}'),
                  Text(
                      'Ordered On: ${DateFormat('yyyy-MM-dd hh:mm a').format(widget.order['created_at'].toDate())}'),
                  SizedBox(height: 20),
                  Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Column(
                      children: orderItems.asMap().entries.map((entry) {
                    int index = entry.key;
                    var item = entry.value;

                    return CheckboxListTile(
                      title:
                          Text('${item['item']['name']} x ${item['quantity']}'),
                      value: checkedStates[index],
                      onChanged: (value) {
                        setState(() {
                          checkedStates[index] = value!;
                        });
                      },
                    );
                  }).toList()),
                  checkedStates.every((element) => element == true)
                      ? ElevatedButton(
                          onPressed: () {
                            showMapSelectionDialog();
                          },
                          child: Text('Proceed to delivery'))
                      : SizedBox.shrink()
                ],
              ),
            ),
    );
  }
}
