import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsPage extends StatefulWidget {
  final dynamic order;
  final bool isComplete;

  const OrderDetailsPage(
      {super.key, required this.order, required this.isComplete});

  @override
  State<OrderDetailsPage> createState() => OrderDetailsPageState();
}

class OrderDetailsPageState extends State<OrderDetailsPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<dynamic> orderItems = [];
  List<bool> checkedStates = [];
  bool isLoading = false;
  bool isOrderComplete = false;
  bool editMode = false;
  var itemNameController = TextEditingController();
  var itemPriceController = TextEditingController();
  var itemQuantityController = TextEditingController();

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
        orderItems.add({...orderItem!, 'orderItemId': doc.id});
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

  void edit() {
    setState(() {
      editMode = !editMode;
    });
  }

  Future<void> deleteOrderItem(String orderId, int index) async {
    double itemPrice = orderItems[index]['item']['price'];
    itemPrice = double.parse(itemPrice.toStringAsFixed(2));

    try {
      await firestore.collection('order-items').doc(orderId).delete();

      DocumentSnapshot orderSnapshot = await firestore
          .collection('orders')
          .doc(widget.order['orderId'])
          .get();
      double currentTotalPrice = orderSnapshot['total_price'];

      double newTotalPrice =
          double.parse((currentTotalPrice - itemPrice).toStringAsFixed(2));

      await firestore.collection('orders').doc(widget.order['orderId']).update({
        'num_items': FieldValue.increment(-1),
        'total_price': newTotalPrice,
      });

      setState(() {
        orderItems.removeAt(index);
        checkedStates.removeAt(index);
        widget.order['num_items'] = widget.order['num_items'] - 1;
        widget.order['total_price'] = newTotalPrice;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> addItem() async {
    if (itemNameController.text.isEmpty ||
        itemPriceController.text.isEmpty ||
        itemQuantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter all item details')),
      );
      return;
    }

    if (itemPriceController.text.isEmpty ||
        !RegExp(r'^\d*\.?\d{0,2}$').hasMatch(itemPriceController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid item price')),
      );
      return;
    }

    if (itemQuantityController.text.isEmpty ||
        !RegExp(r'^\d+$').hasMatch(itemQuantityController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid item quantity')),
      );
      return;
    }

    if (itemNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid item name')),
      );
      return;
    }

    double itemPrice = double.parse(itemPriceController.text);
    itemPrice = double.parse(itemPrice.toStringAsFixed(2));
    int itemQuantity = int.parse(itemQuantityController.text);
    var itemName = itemNameController.text;

    try {
      await firestore.collection('order-items').add({
        'order_id': widget.order['orderId'],
        'item': {
          'name': itemName,
          'price': itemPrice,
        },
        'quantity': itemQuantity,
      });

      DocumentSnapshot orderSnapshot = await firestore
          .collection('orders')
          .doc(widget.order['orderId'])
          .get();
      double currentTotalPrice = orderSnapshot['total_price'];

      double newTotalPrice = double.parse(
          (currentTotalPrice + itemPrice * itemQuantity).toStringAsFixed(2));

      await firestore.collection('orders').doc(widget.order['orderId']).update({
        'num_items': FieldValue.increment(1),
        'total_price': newTotalPrice,
      });

      checkedStates.add(false);
      widget.order['total_price'] = newTotalPrice;

      itemNameController.clear();
      itemPriceController.clear();
      itemQuantityController.clear();

      setState(() {
        orderItems.add({
          'orderItemId': orderSnapshot.id,
          'order_id': widget.order['orderId'],
          'item': {
            'name': itemName,
            'price': itemPrice,
          },
          'quantity': itemQuantity,
        });
        // checkedStates.add(false);
        widget.order['num_items'] = widget.order['num_items'] + 1;
        widget.order['total_price'] = newTotalPrice;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    print(checkedStates);
    return Scaffold(
      appBar: AppBar(title: Text('Order Details')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
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
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Items',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            widget.isComplete
                                ? SizedBox.shrink()
                                : ElevatedButton(
                                    onPressed: () {
                                      edit();
                                    },
                                    child: Text(editMode ? 'Cancel' : 'Edit'))
                          ]),
                      SizedBox(height: 10),
                      Column(
                          children: orderItems.asMap().entries.map((entry) {
                        int index = entry.key;
                        var item = entry.value;

                        return editMode
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.5,
                                    child: Text(
                                      '${item['item']['name']} x ${item['quantity']}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      widget.isComplete
                                          ? SizedBox.shrink()
                                          : IconButton(
                                              onPressed: () {
                                                deleteOrderItem(
                                                    item['orderItemId'], index);
                                              },
                                              icon: Icon(Icons.delete)),
                                    ],
                                  ),
                                ],
                              )
                            : CheckboxListTile(
                                title: Text(
                                    '${item['item']['name']} x ${item['quantity']}'),
                                value: widget.isComplete
                                    ? true
                                    : checkedStates[index],
                                onChanged: (value) {
                                  setState(() {
                                    checkedStates[index] = value!;
                                  });
                                },
                              );
                      }).toList()),
                      SizedBox(height: 10),
                      editMode
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.5,
                                  child: TextField(
                                    controller: itemNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Item Name',
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.3,
                                      child: TextField(
                                        controller: itemPriceController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d*\.?\d{0,2}')),
                                        ],
                                        decoration: InputDecoration(
                                          labelText: 'Item Price',
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.2,
                                      child: TextField(
                                        controller: itemQuantityController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d*')),
                                        ],
                                        decoration: InputDecoration(
                                          labelText: 'Quantity',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                ElevatedButton(
                                    onPressed: () {
                                      addItem();
                                    },
                                    child: Text('Add Item')),
                              ],
                            )
                          : SizedBox.shrink(),
                      !isOrderComplete &&
                              !editMode &&
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
                          : checkedStates.every((element) => element == true) &&
                                  !editMode
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
            ),
    );
  }
}
