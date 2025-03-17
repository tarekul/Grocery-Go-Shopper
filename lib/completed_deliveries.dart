import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'order_details.dart';

class CompletedDeliveriesPage extends StatefulWidget {
  const CompletedDeliveriesPage({super.key});

  @override
  State<CompletedDeliveriesPage> createState() =>
      _CompletedDeliveriesPageState();
}

class _CompletedDeliveriesPageState extends State<CompletedDeliveriesPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser!;
  List<dynamic> completedOrders = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCompletedOrders();
  }

  Future<void> fetchCompletedOrders() async {
    setState(() {
      isLoading = true;
    });
    try {
      completedOrders.clear();
      QuerySnapshot querySnapshot = await firestore
          .collection('accepted-orders')
          .where('shopper_id', isEqualTo: user.uid)
          .where('is_completed', isEqualTo: true)
          .get();
      for (var doc in querySnapshot.docs) {
        var orderId = doc['order_id'];
        DocumentSnapshot orderSnapshot =
            await firestore.collection('orders').doc(orderId).get();
        if (orderSnapshot.exists) {
          var order = orderSnapshot.data() as Map<String, dynamic>?;
          completedOrders.add({...order!, 'orderId': orderId});
        }
      }
    } catch (error) {
      print(error);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Deliveries'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchCompletedOrders,
              child: completedOrders.isNotEmpty
                  ? ListView.builder(
                      itemCount: completedOrders.length,
                      itemBuilder: (context, index) {
                        var order = completedOrders[index];
                        return ListTile(
                          title: Text(order["orderId"]),
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
                              ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => OrderDetailsPage(
                                          order: order,
                                          isComplete: true,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text('View')),
                            ],
                          ),
                        );
                      })
                  : const Center(child: Text('No completed orders')),
            ),
    );
  }
}
