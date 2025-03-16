import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'home.dart';
import 'sign_in_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  SignUpPageState createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseDatabase database = FirebaseDatabase.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _phoneController = TextEditingController();

  void toggleSignUp() async {
    try {
      if (_emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _firstnameController.text.isEmpty ||
          _lastnameController.text.isEmpty ||
          _phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Center(child: Text('All fields are required'))));
        return;
      }
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);

      if (userCredential.user != null) {
        await firestore
            .collection('shoppers')
            .doc(userCredential.user!.uid)
            .set({
          'email': _emailController.text,
          'firstname': _firstnameController.text,
          'lastname': _lastnameController.text,
          'phone': _phoneController.text,
        });

        await database
            .ref('https://grocery-go-backend-default-rtdb.firebaseio.com/')
            .set({
          'grocery-shopper': {
            userCredential.user!.uid: {'isAvailable': false}
          }
        });
        // Navigate to the orders page
        if (mounted) {
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (context) => Home()));
        }
      }
    } catch (e) {
      String message;

      if (e is FirebaseAuthException) {
        print(e.code);
        print(e);
        switch (e.code) {
          case 'weak-password':
            message =
                'The password provided is too weak. Password should be at least 6 characters';
            break;
          case 'invalid-email':
            message = 'The email provided is badly formatted';
            break;
          case 'email-already-in-use':
            message = 'The account already exists for that email.';
            break;
          default:
            message = 'An error occurred. Please try again.';
        }
      } else {
        message = 'An error occurred: $e';
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Center(child: Text(message))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Center(
        child: Column(children: [
          SizedBox(
            width: 300,
            child: TextField(
              controller: _firstnameController,
              decoration: InputDecoration(
                labelText: 'First Name',
              ),
            ),
          ),
          SizedBox(
            width: 300,
            child: TextField(
              controller: _lastnameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
              ),
            ),
          ),
          SizedBox(
            width: 300,
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
          ),
          SizedBox(
            width: 300,
            child: TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone',
              ),
            ),
          ),
          SizedBox(
            width: 300,
            child: TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(onPressed: toggleSignUp, child: Text('Sign Up')),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => SignInPage(),
                ),
              );
            },
            child: Text('Already have an account? Log In',
                style: TextStyle(
                    color: Colors.purple,
                    decoration: TextDecoration.underline)),
          )
        ]),
      ),
    );
  }
}
