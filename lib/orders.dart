import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'order_details.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});
  @override
  State<OrdersPage> createState() => OrderAppState();
}

class OrderAppState extends State<OrdersPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseDatabase database = FirebaseDatabase.instance;

  List orders = [];
  Map<String, bool> acceptedOrders = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getOrders();
  }

  Future<void> getOrders() async {
    isLoading = true;
    try {
      QuerySnapshot querySnapshot = await firestore.collection('orders').get();
      orders.clear();
      for (var doc in querySnapshot.docs) {
        var order = doc.data() as Map<String, dynamic>?;
        QuerySnapshot shopperSnapshot = await firestore
            .collection('accepted-orders')
            .where('order_id', isEqualTo: doc.id)
            .get();
        if (order?['deleted_at'] == null &&
            order?['is_completed'] == false &&
            shopperSnapshot.docs.isEmpty) {
          orders.add({...order!, 'orderId': doc.id});
        }
      }
    } catch (error) {
      print(error);
    } finally {
      isLoading = false;
      setState(() {});
    }
  }

  void acceptOrder(String orderId, String customerId) async {
    final user = FirebaseAuth.instance.currentUser!;
    try {
      var doc = await firestore
          .collection('accepted-orders')
          .where('order_id', isEqualTo: orderId)
          .where('shopper_id', isEqualTo: user.uid)
          .get();
      if (doc.docs.isNotEmpty) {
        return;
      }
      await firestore.collection('accepted-orders').doc().set({
        'order_id': orderId,
        'shopper_id': user.uid,
        'customer_id': customerId,
        'is_completed': false,
      });

      await database
          .ref('grocery-shopper')
          .child(user.uid)
          .set({'isAvailable': true});

      setState(() {
        acceptedOrders[orderId] = true;
      });
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: getOrders,
                child: orders.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          Center(child: Text('No orders available')),
                        ],
                      )
                    : ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          var order = orders[index];
                          return ListTile(
                            title: Text(order["orderId"],
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order['name']),
                                Text(order['phone']),
                                Text(
                                    "${order['address']}, ${order['city']}, ${order['zipcode']}"),
                                Text("Total: \$${order['total_price']}"),
                                Text("Total items: ${order['num_items']}"),
                                Text(
                                    "Ordered on: ${DateFormat('yyyy-MM-dd hh:mm a').format(order['created_at'].toDate())}"),
                                SizedBox(height: 10),
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    OrderDetailsPage(
                                                  order: order,
                                                  isComplete: true,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Text('View')),
                                      SizedBox(width: 10),
                                      acceptedOrders[order['orderId']] == true
                                          ? Text('Accepted')
                                          : ElevatedButton(
                                              onPressed: () {
                                                acceptOrder(order['orderId'],
                                                    order['customer_id'] ?? '');
                                              },
                                              child: Text('Accept')),
                                    ])
                              ],
                            ),
                          );
                        })));
  }
}
