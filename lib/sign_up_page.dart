import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'orders.dart';
import 'sign_in_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  SignUpPageState createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void toggleSignUp() async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);

      if (userCredential.user != null) {
        // Navigate to the orders page
        if (mounted) {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => OrdersPage()));
        }
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Center(
        child: Column(children: [
          SizedBox(
            width: 300, // Adjust the width as needed
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
          ),
          SizedBox(
            width: 300, // Adjust the width as needed
            child: TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(onPressed: toggleSignUp, child: Text('Sign In')),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SignInPage(),
                ),
              );
            },
            child: Text('Don\'t have an account? Sign In',
                style: TextStyle(
                    color: Colors.purple,
                    decoration: TextDecoration.underline)),
          )
        ]),
      ),
    );
  }
}
