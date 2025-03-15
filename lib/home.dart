import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'accepted_orders.dart';
import 'orders.dart';
import 'sign_in_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  bool isToggled = false;
  final database = FirebaseDatabase.instance;
  final auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    DatabaseReference ref = database.ref('grocery-shopper');
    var user = auth.currentUser;
    if (user != null) {
      ref.child(user.uid).onValue.listen((event) {
        setState(() => isToggled = event.snapshot.value['isAvailable']);
      });
    }
  }

  Future<void> toggle(bool value) async {
    DatabaseReference ref = database.ref('grocery-shopper');
    var user = auth.currentUser;
    if (user != null) {
      try {
        await ref.child(user.uid).set({'isAvailable': value});
        setState(() => isToggled = value);
      } catch (e) {
        print('Error writing to database: $e');
      }
    } else {
      print('User is not logged in.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(isToggled ? 'Online' : 'Offline'),
          Switch(
            value: isToggled,
            onChanged: (value) => toggle(value),
            activeColor: Colors.green,
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => OrdersPage()),
              );
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('View All Orders'),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AcceptedOrdersPage()),
              );
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Show Accepted Orders'),
              ),
            ),
          ),
          ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => SignInPage()),
                );
              },
              child: Text('Sign Out')),
        ]),
      ),
    );
  }
}
