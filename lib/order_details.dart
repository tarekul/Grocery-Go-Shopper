import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool isOrderComplete = false;

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
    } catch (error) {
      print(error);
    } finally {
      isLoading = false;
      setState(() {});
    }
  }

  Future<void> completeOrder() async {
    try {
      await firestore.collection('orders').doc(widget.order['orderId']).update({
        'is_completed': true,
      });
      await firestore
          .collection('accepted-orders')
          .doc(widget.order['shopperAcceptedOrderId'])
          .update({
        'is_completed': true,
      });
      isOrderComplete = true;
      setState(() {});
      print('Delivery completed');
    } catch (e) {
      print(e);
    }
  }

  void launchMap(String app, String deliveryAddress) async {
    String url;

    if (app == 'Google Maps') {
      url =
          'https://www.google.com/maps/dir/?api=1&destination=$deliveryAddress';
    } else if (app == 'Apple Maps') {
      url = 'https://maps.apple.com/?daddr=$deliveryAddress';
    } else if (app == 'Waze') {
      url = 'https://waze.com/ul?ll=$deliveryAddress&navigate=yes';
    } else {
      return;
    }

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      try {
        await launchUrl(uri);
      } catch (e) {
        print('Error launching URL: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open maps: $e')),
        );
      }
    } else {
      throw 'Could not launch $url';
    }
  }

  void showMapSelectionDialog() {
    var deliveryAddress =
        '${widget.order['address']}, ${widget.order['city']}, ${widget.order['zipcode']}';
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text('Choose a navigation app'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                      onTap: () => launchMap('Google Maps', deliveryAddress),
                      title: Text('Google Maps')),
                  ListTile(
                      onTap: () => launchMap('Apple Maps', deliveryAddress),
                      title: Text('Apple Maps')),
                  ListTile(
                      onTap: () => launchMap('Waze', deliveryAddress),
                      title: Text('Waze')),
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
          : SingleChildScrollView(
              child: Padding(
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
                    Text('Items',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Column(
                        children: orderItems.asMap().entries.map((entry) {
                      int index = entry.key;
                      var item = entry.value;

                      return CheckboxListTile(
                        title: Text(
                            '${item['item']['name']} x ${item['quantity']}'),
                        value: checkedStates[index],
                        onChanged: (value) {
                          setState(() {
                            checkedStates[index] = value!;
                          });
                        },
                      );
                    }).toList()),
                    !isOrderComplete &&
                            checkedStates.every((element) => element == true)
                        ? ElevatedButton(
                            onPressed: () {
                              showMapSelectionDialog();
                            },
                            child: Text('Proceed to delivery'))
                        : SizedBox.shrink(),
                    SizedBox(height: 20),
                    isOrderComplete
                        ? Text('Order complete')
                        : checkedStates.every((element) => element == true)
                            ? SlideAction(
                                onSubmit: () {
                                  completeOrder();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Delivery completed'),
                                    ),
                                  );
                                },
                                outerColor: Colors.green,
                                innerColor: Colors.white,
                                sliderButtonIcon: Icon(Icons.arrow_forward,
                                    color: Colors.green),
                                submittedIcon:
                                    Icon(Icons.check, color: Colors.white),
                                child: Text('Complete Delivery',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              )
                            : SizedBox.shrink(),
                  ],
                ),
              ),
            ),
    );
  }
}
