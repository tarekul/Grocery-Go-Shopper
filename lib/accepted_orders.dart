import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'order_details.dart';

class AcceptedOrdersPage extends StatefulWidget {
  const AcceptedOrdersPage({super.key});
  @override
  State<AcceptedOrdersPage> createState() => AcceptedOrdersAppState();
}

class AcceptedOrdersAppState extends State<AcceptedOrdersPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser!;

  List orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getAcceptedOrders();
  }

  Future<void> getAcceptedOrders() async {
    isLoading = true;
    try {
      orders.clear();
      QuerySnapshot querySnapshot = await firestore
          .collection('accepted-orders')
          .where('shopper_id', isEqualTo: user.uid)
          .where('is_completed', isEqualTo: false)
          .get();

      for (var doc in querySnapshot.docs) {
        var orderId = doc['order_id'];
        DocumentSnapshot orderSnapshot =
            await firestore.collection('orders').doc(orderId).get();
        if (orderSnapshot.exists) {
          var order = orderSnapshot.data() as Map<String, dynamic>?;
          orders.add({
            ...order!,
            'orderId': orderSnapshot.id,
            'shopperAcceptedOrderId': doc.id
          });
        }
      }
    } catch (error) {
      print(error);
    } finally {
      isLoading = false;
      setState(() {});
    }
  }

  void removeOrder(String shopperAcceptedOrderId) async {
    try {
      await firestore
          .collection('accepted-orders')
          .doc(shopperAcceptedOrderId)
          .delete();
      setState(() {
        orders.removeWhere((order) =>
            order['shopperAcceptedOrderId'] == shopperAcceptedOrderId);
      });
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Accepted Orders'),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: getAcceptedOrders,
                child: orders.isNotEmpty
                    ? ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          var order = orders[index];
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
                                                isComplete: false,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text('View')),
                                    SizedBox(width: 10),
                                    ElevatedButton(
                                        onPressed: () {
                                          removeOrder(
                                              order['shopperAcceptedOrderId']);
                                        },
                                        child: Text('Cancel')),
                                  ],
                                )
                              ],
                            ),
                          );
                        })
                    : Center(
                        child: Text('No orders available'),
                      ),
              ));
  }
}
