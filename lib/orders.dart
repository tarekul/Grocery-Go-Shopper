import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});
  @override
  State<OrdersPage> createState() => OrderAppState();
}

class OrderAppState extends State<OrdersPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List orders = [];

  @override
  void initState() {
    super.initState();
    getOrders();
  }

  void getOrders() {
    print("Attempting to get orders from Firestore...");
    firestore.collection('orders').get().then((QuerySnapshot querySnapshot) {
      for (var doc in querySnapshot.docs) {
        var order = doc.data() as Map<String, dynamic>?;
        if (order?['deleted_at'] == null) {
          orders.add(order);
        }
      }
      print("Orders fetched successfully: $orders");
      setState(() {});
    }).catchError((error) {
      print("Error fetching orders: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: orders.isNotEmpty
          ? ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                var order = orders[index];
                return ListTile(
                  title: Text(order['name']),
                  subtitle: Text(order['email']),
                );
              })
          : Center(
              child: Text('No orders available'),
            ),
    );
  }
}
