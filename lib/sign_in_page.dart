import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
          ElevatedButton(onPressed: () {}, child: Text('Sign In'))
        ]),
      ),
    );
  }
}
