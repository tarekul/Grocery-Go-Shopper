import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home.dart';
import 'sign_up_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void toggleSignIn() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);

      if (userCredential.user != null) {
        // Navigate to the orders page
        if (mounted) {
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (context) => Home()));
        }
      }
    } catch (e) {
      String message;

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-credential':
            message = 'Invalid Credential';
            break;
          case 'invalid-email':
            message = 'Invalid email';
            break;
          case 'wrong-password':
            message = 'Wrong password';
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
  /*
    Meaning of Widget build(BuildContext context) is:
    - Widget specifies the return type of the build method.
    - build method is called whenever the state of the widget needs to be updated.
    - (BuildContext context) is an object that represents the location of the widget in the tree.
  */
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign In')),
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
          ElevatedButton(onPressed: toggleSignIn, child: Text('Sign In')),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => SignUpPage(),
                ),
              );
            },
            child: Text('Don\'t have an account? Sign up',
                style: TextStyle(
                    color: Colors.purple,
                    decoration: TextDecoration.underline)),
          )
        ]),
      ),
    );
  }
}
