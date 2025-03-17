import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'accepted_orders.dart';
import 'completed_deliveries.dart';
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
  StreamSubscription<DatabaseEvent>? userListener;

  @override
  void initState() {
    super.initState();
    var user = auth.currentUser;
    if (user != null) {
      userListener = database
          .ref('grocery-shopper')
          .child(user.uid)
          .onValue
          .listen((event) {
        setState(() {
          final data = event.snapshot.value as Map?;
          isToggled = data?['isAvailable'] ?? false;
        });
      });
    }
  }

  Future<void> toggle(bool value) async {
    if (auth.currentUser != null) {
      try {
        await database
            .ref('grocery-shopper')
            .child(auth.currentUser!.uid)
            .set({'isAvailable': value});
        setState(() => isToggled = value);
      } catch (e) {
        print('Error writing to database: $e');
      }
    } else {
      print('User is not logged in.');
    }
  }

  Future<void> signOut() async {
    await database
        .ref('grocery-shopper')
        .child(auth.currentUser!.uid)
        .set({'isAvailable': false});
    await auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SignInPage()),
      );
    }
  }

  @override
  void dispose() {
    userListener?.cancel();
    super.dispose();
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
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => CompletedDeliveriesPage()),
              );
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Show Completed Deliveries'),
              ),
            ),
          ),
          ElevatedButton(
              onPressed: () {
                signOut();
              },
              child: Text('Sign Out')),
        ]),
      ),
    );
  }
}
