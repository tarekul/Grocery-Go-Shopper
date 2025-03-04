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
        if (order?['deleted_at'] == null && order?['is_completed'] == false) {
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
                child: orders.isNotEmpty
                    ? ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          var order = orders[index];
                          return ListTile(
                              title: Text(order["name"]),
                              subtitle: Text(order['phone']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                      onPressed: () {}, child: Text('View')),
                                  SizedBox(width: 10),
                                  ElevatedButton(
                                      onPressed: () {}, child: Text('Accept')),
                                ],
                              ));
                        })
                    : Center(
                        child: Text('No orders available'),
                      ),
              ));
  }
}
